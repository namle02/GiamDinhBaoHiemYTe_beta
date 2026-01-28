using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Threading;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Service xử lý batch processing với Semaphore để quản lý thread pool
    /// </summary>
    public class BatchProcessorService : IBatchProcessorService
    {
        private readonly IPatientServices _patientServices;
        private readonly IDataMapper _dataMapper;
        private readonly IPatientCacheService _patientCacheService;
        private readonly SemaphoreSlim _semaphore;

        public BatchProcessorService(
            IPatientServices patientServices, 
            IDataMapper dataMapper,
            IPatientCacheService patientCacheService)
        {
            _patientServices = patientServices;
            _dataMapper = dataMapper;
            _patientCacheService = patientCacheService;
            
            // Khởi tạo Semaphore với số lượng thread tối đa
            // Mặc định là 20 để tăng throughput xử lý
            _semaphore = new SemaphoreSlim(5, 5);
        }

        public async Task<BatchProcessingResult> ProcessPatientsAsync(
            List<string> patientIds, 
            int maxConcurrency = 5,
            Action<BatchProgress>? onProgress = null,
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var result = new BatchProcessingResult
            {
                TotalProcessed = patientIds.Count
            };


            // Tạo Semaphore mới với maxConcurrency được chỉ định
            using var semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);
            
            // Biến để track thống kê real-time
            var currentSuccessCount = 0;
            var currentErrorCount = 0;
            var completedCount = 0;
            var processingCount = 0;

            // Tạo danh sách tasks để xử lý song song
            var tasks = patientIds.Select(async (patientId, index) =>
            {
                // Chờ semaphore để kiểm soát số lượng request đồng thời
                await semaphore.WaitAsync(cancellationToken);
                
                try
                {
                    // Tăng số lượng đang xử lý
                    var currentProcessingIndex = Interlocked.Increment(ref processingCount);
                    
                    // Cập nhật progress với thống kê hiện tại
                    onProgress?.Invoke(new BatchProgress
                    {
                        Current = currentProcessingIndex,
                        Total = patientIds.Count,
                        CurrentPatientId = patientId,
                        Status = $"Đang xử lý {currentProcessingIndex}/{patientIds.Count}: {patientId}",
                        SuccessCount = currentSuccessCount,
                        ErrorCount = currentErrorCount
                    });

                    // Xử lý patient
                    var patientResult = await ProcessSinglePatientAsync(patientId, cancellationToken);
                    
                    
                    // Cập nhật kết quả và thống kê
                    lock (result)
                    {
                        result.Results.Add(patientResult);
                        var currentCompleted = Interlocked.Increment(ref completedCount);
                        
                        if (patientResult.IsSuccess)
                        {
                            result.SuccessCount++;
                            Interlocked.Increment(ref currentSuccessCount);
                        }
                        else
                        {
                            result.ErrorCount++;
                            Interlocked.Increment(ref currentErrorCount);
                            result.Errors.Add($"{patientId}: {patientResult.ErrorMessage}");
                        }

                        // Cập nhật progress sau khi hoàn thành
                        onProgress?.Invoke(new BatchProgress
                        {
                            Current = currentCompleted,
                            Total = patientIds.Count,
                            CurrentPatientId = string.Empty,
                            Status = $"Hoàn thành {currentCompleted}/{patientIds.Count}",
                            SuccessCount = currentSuccessCount,
                            ErrorCount = currentErrorCount
                        });
                    }

                    return patientResult;
                }
                finally
                {
                    // Giải phóng semaphore
                    semaphore.Release();
                }
            });

            try
            {
                // Chờ tất cả tasks hoàn thành
                await Task.WhenAll(tasks);
            }
            catch (OperationCanceledException)
            {
                result.Errors.Add("Operation was cancelled");
            }
            catch (Exception ex)
            {
                result.Errors.Add($"Batch processing error: {ex.Message}");
            }

            stopwatch.Stop();
            result.TotalTime = stopwatch.Elapsed;


            // Cập nhật progress cuối cùng
            onProgress?.Invoke(new BatchProgress
            {
                Current = patientIds.Count,
                Total = patientIds.Count,
                CurrentPatientId = string.Empty,
                Status = $"Hoàn thành! Đã xử lý {result.SuccessCount}/{result.TotalProcessed} bệnh nhân thành công."
            });

            return result;
        }

        public async Task<PatientProcessingResult> ProcessSinglePatientAsync(
            string patientId, 
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var result = new PatientProcessingResult
            {
                PatientId = patientId
            };

            try
            {
                // Kiểm tra cache trước
                var cachedData = _patientCacheService.GetCachedPatient(patientId);
                if (cachedData != null)
                {
                    // Nếu có cache, tạo kết quả từ cache
                    result.ValidationResult = new ApiResponse<ValidateData>
                    {
                        Success = true,
                        Data = new ValidateData
                        {
                            ValidationResults = cachedData.ValidationRules
                        }
                    };
                    result.IsSuccess = true;
                    return result;
                }

                // Lấy dữ liệu từ database
                var patientData = await _dataMapper.GetDataFromDB(patientId);
                
                // Gọi API validation
                var apiResponse = await _patientServices.LoadPatientAndValidateData(patientId);
                
                result.ValidationResult = apiResponse;
                result.IsSuccess = apiResponse?.Success == true;

                // Lưu vào cache nếu thành công
                if (result.IsSuccess && apiResponse?.Data?.ValidationResults != null && patientData != null)
                {
                    _patientCacheService.AddPatientToCache(patientId, patientData, apiResponse.Data.ValidationResults);
                }
            }
            catch (Exception ex)
            {
                result.IsSuccess = false;
                result.ErrorMessage = ex switch
                {
                    Microsoft.Data.SqlClient.SqlException => $"Database error: {ex.Message}",
                    System.Net.Http.HttpRequestException => $"API connection error: {ex.Message}",
                    System.Text.Json.JsonException => $"JSON parsing error: {ex.Message}",
                    OperationCanceledException => "Operation was cancelled",
                    _ => $"{ex.GetType().Name}: {ex.Message}"
                };
            }
            finally
            {
                stopwatch.Stop();
                result.ProcessingTime = stopwatch.Elapsed;
            }

            return result;
        }

        /// <summary>
        /// Xử lý danh sách Excel data - tự động xử lý cả MA_LK và MA_BN format
        /// </summary>
        public async Task<BatchProcessingResult> ProcessExcelDataAsync(
            List<ExcelRowData> excelData,
            int maxConcurrency = 5,
            Action<BatchProgress>? onProgress = null,
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var result = new BatchProcessingResult
            {
                TotalProcessed = excelData.Count
            };

            // Tạo Semaphore mới với maxConcurrency được chỉ định
            using var semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);

            // Biến đếm
            int processedCount = 0;
            int successCount = 0;
            int errorCount = 0;
            var lockObj = new object();

            // Xử lý song song
            var tasks = excelData.Select(async rowData =>
            {
                await semaphore.WaitAsync(cancellationToken);
                try
                {
                    cancellationToken.ThrowIfCancellationRequested();

                    string? maLkToProcess = null;
                    string progressLabel = string.Empty;
                    string originalIdentifier = string.Empty;

                    // Xác định MA_LK cần xử lý
                    if (rowData.DataType == "MA_LK" && !string.IsNullOrWhiteSpace(rowData.MaLk))
                    {
                        maLkToProcess = rowData.MaLk;
                        progressLabel = maLkToProcess;
                    }
                    else if (rowData.DataType == "MA_BN" && rowData.IsValid())
                    {
                        originalIdentifier = $"{rowData.MaBn} ({rowData.NgayVao} - {rowData.NgayRa})";
                        progressLabel = originalIdentifier;

                        try
                        {
                            // Format ngày từ Excel (có thể là dd/MM/yyyy hoặc yyyyMMdd)
                            string ngayVaoFormatted = FormatDateForQuery(rowData.NgayVao, isEndDate: false);

                            // Tìm MA_LK từ MA_BN + ngày vào
                            var maLkResults = await _dataMapper.GetMaLkByMaBnAndDate(
                                rowData.MaBn!, 
                                ngayVaoFormatted);

                            if (maLkResults == null || maLkResults.Count == 0)
                            {
                                // KHÔNG tìm thấy MA_LK nào - LỖI
                                maLkToProcess = null;
                            }
                            else if (maLkResults.Count == 1)
                            {
                                // Tìm thấy ĐÚNG 1 MA_LK - OK
                                maLkToProcess = maLkResults[0].Ma_Lk;

                                if (!string.IsNullOrWhiteSpace(maLkToProcess))
                                {
                                    progressLabel = string.IsNullOrWhiteSpace(originalIdentifier)
                                        ? maLkToProcess
                                        : $"{maLkToProcess} ({originalIdentifier})";
                                }
                            }
                            else
                            {
                                // Tìm thấy NHIỀU MA_LK - LỖI (data không rõ ràng)
                                
                                // Tạo message chi tiết về các MA_LK tìm thấy
                                var maLkList = string.Join(", ", maLkResults.Select(x => x.Ma_Lk).Take(5));
                                if (maLkResults.Count > 5)
                                    maLkList += $", ... (và {maLkResults.Count - 5} MA_LK khác)";
                                
                                // Set null để báo lỗi
                                maLkToProcess = null;
                                
                                // Thêm error message chi tiết
                                lock (lockObj)
                                {
                                    result.Errors.Add($"❌ MA_BN {rowData.MaBn} ({rowData.NgayVao} - {rowData.NgayRa}): Tìm thấy {maLkResults.Count} MA_LK [{maLkList}]. Mỗi dòng Excel chỉ được map với 1 MA_LK duy nhất. Vui lòng kiểm tra lại dữ liệu hoặc thu hẹp khoảng thời gian.");
                                }
                            }
                        }
                        catch (Exception)
                        {
                            // Ignore errors when finding MA_LK
                        }
                    }

                    PatientProcessingResult patientResult;

                    // Nếu có MA_LK, xử lý validation
                    if (!string.IsNullOrWhiteSpace(maLkToProcess))
                    {
                        patientResult = await ProcessSinglePatientAsync(maLkToProcess, cancellationToken);
                        patientResult.PatientId = maLkToProcess; // Gắn ID chuẩn để các bước sau sử dụng
                    }
                    else
                    {
                        // Không tìm thấy MA_LK hoặc tìm thấy nhiều hơn 1
                        string errorMsg;
                        if (rowData.DataType == "MA_BN")
                        {
                            // Kiểm tra xem có phải lỗi "nhiều MA_LK" không
                            var multipleError = result.Errors.FirstOrDefault(e => e.Contains(rowData.MaBn!));
                            if (multipleError != null)
                            {
                                errorMsg = multipleError; // Lỗi chi tiết đã được thêm vào result.Errors
                            }
                            else
                            {
                                errorMsg = $"Không tìm thấy MA_LK cho MA_BN: {rowData.MaBn} trong khoảng thời gian {rowData.NgayVao} - {rowData.NgayRa}";
                            }
                        }
                        else
                        {
                            errorMsg = "Dữ liệu không hợp lệ";
                        }
                        
                        patientResult = new PatientProcessingResult
                        {
                            PatientId = string.IsNullOrWhiteSpace(originalIdentifier) ? progressLabel : originalIdentifier,
                            IsSuccess = false,
                            ErrorMessage = errorMsg
                        };
                    }

                    // Cập nhật thống kê
                    lock (lockObj)
                    {
                        processedCount++;
                        if (patientResult.IsSuccess)
                            successCount++;
                        else
                            errorCount++;

                        result.Results.Add(patientResult);

                        // Gọi callback progress
                        onProgress?.Invoke(new BatchProgress
                        {
                            Current = processedCount,
                            Total = excelData.Count,
                            CurrentPatientId = progressLabel,
                            Status = $"Đang xử lý: {progressLabel} ({processedCount}/{excelData.Count})",
                            SuccessCount = successCount,
                            ErrorCount = errorCount
                        });
                    }
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    lock (lockObj)
                    {
                        errorCount++;
                        result.Errors.Add($"Error: {ex.Message}");
                    }
                }
                finally
                {
                    semaphore.Release();
                }
            });

            try
            {
                await Task.WhenAll(tasks);
            }
            catch (OperationCanceledException)
            {
            }

            stopwatch.Stop();
            result.SuccessCount = successCount;
            result.ErrorCount = errorCount;
            result.TotalTime = stopwatch.Elapsed;

            return result;
        }

        /// <summary>
        /// Kiểm tra format ngày của hệ thống (mm/dd/yy hay dd/mm/yy)
        /// </summary>
        private bool IsSystemDateFormatMonthFirst()
        {
            var dateFormat = CultureInfo.CurrentCulture.DateTimeFormat;
            var shortDatePattern = dateFormat.ShortDatePattern;
            
            // Kiểm tra xem format có bắt đầu bằng M (month) hay d (day)
            // Loại bỏ các ký tự không phải chữ cái
            var cleanPattern = shortDatePattern.Replace("/", "").Replace("-", "").Replace(".", "");
            
            // Nếu pattern bắt đầu bằng 'M' hoặc 'm' thì là month first (mm/dd)
            // Nếu bắt đầu bằng 'd' thì là day first (dd/mm)
            if (cleanPattern.Length > 0)
            {
                char firstChar = cleanPattern[0];
                return firstChar == 'M' || firstChar == 'm';
            }
            
            // Mặc định kiểm tra bằng cách parse một ngày test
            // Nếu parse "01/02/2024" thành 1 tháng 2 (February) thì là mm/dd
            // Nếu parse thành 2 tháng 1 (January) thì là dd/mm
            if (DateTime.TryParse("01/02/2024", out DateTime testDate))
            {
                return testDate.Month == 1; // Nếu month = 1 thì là mm/dd format
            }
            
            // Fallback: mặc định là mm/dd (US format)
            return true;
        }

        /// <summary>
        /// Parse date string với hỗ trợ nhiều format, ưu tiên format của hệ thống
        /// </summary>
        private bool TryParseDateFlexible(string dateString, out DateTime date)
        {
            date = default;
            if (string.IsNullOrWhiteSpace(dateString))
                return false;

            dateString = dateString.Trim();

            // Bước 1: Thử parse với format hiện tại của hệ thống (culture-aware)
            if (DateTime.TryParse(dateString, CultureInfo.CurrentCulture, DateTimeStyles.None, out date))
            {
                return true;
            }

            // Bước 2: Nếu có chứa dấu /, phân tích và parse theo format của hệ thống
            if (dateString.Contains("/"))
            {
                var parts = dateString.Split(new[] { '/', ' ', ':' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length >= 3)
                {
                    bool isMonthFirst = IsSystemDateFormatMonthFirst();
                    int month, day, year;

                    if (isMonthFirst)
                    {
                        // Format: mm/dd/yyyy
                        if (int.TryParse(parts[0], out month) && 
                            int.TryParse(parts[1], out day) && 
                            int.TryParse(parts[2], out year))
                        {
                            // Xử lý năm 2 chữ số
                            if (year < 100)
                            {
                                year += year < 50 ? 2000 : 1900;
                            }

                            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100)
                            {
                                try
                                {
                                    date = new DateTime(year, month, day);
                                    // Nếu có thời gian
                                    if (parts.Length >= 4 && int.TryParse(parts[3], out int hour))
                                    {
                                        int minute = parts.Length >= 5 && int.TryParse(parts[4], out int min) ? min : 0;
                                        date = new DateTime(year, month, day, hour, minute, 0);
                                    }
                                    return true;
                                }
                                catch { }
                            }
                        }
                    }
                    else
                    {
                        // Format: dd/mm/yyyy
                        if (int.TryParse(parts[0], out day) && 
                            int.TryParse(parts[1], out month) && 
                            int.TryParse(parts[2], out year))
                        {
                            // Xử lý năm 2 chữ số
                            if (year < 100)
                            {
                                year += year < 50 ? 2000 : 1900;
                            }

                            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100)
                            {
                                try
                                {
                                    date = new DateTime(year, month, day);
                                    // Nếu có thời gian
                                    if (parts.Length >= 4 && int.TryParse(parts[3], out int hour))
                                    {
                                        int minute = parts.Length >= 5 && int.TryParse(parts[4], out int min) ? min : 0;
                                        date = new DateTime(year, month, day, hour, minute, 0);
                                    }
                                    return true;
                                }
                                catch { }
                            }
                        }
                    }

                    // Nếu parse theo format hệ thống không được, thử format ngược lại
                    if (isMonthFirst)
                    {
                        // Thử dd/mm/yyyy
                        if (int.TryParse(parts[0], out day) && 
                            int.TryParse(parts[1], out month) && 
                            int.TryParse(parts[2], out year))
                        {
                            if (year < 100) year += year < 50 ? 2000 : 1900;
                            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100)
                            {
                                try
                                {
                                    date = new DateTime(year, month, day);
                                    if (parts.Length >= 4 && int.TryParse(parts[3], out int hour))
                                    {
                                        int minute = parts.Length >= 5 && int.TryParse(parts[4], out int min) ? min : 0;
                                        date = new DateTime(year, month, day, hour, minute, 0);
                                    }
                                    return true;
                                }
                                catch { }
                            }
                        }
                    }
                    else
                    {
                        // Thử mm/dd/yyyy
                        if (int.TryParse(parts[0], out month) && 
                            int.TryParse(parts[1], out day) && 
                            int.TryParse(parts[2], out year))
                        {
                            if (year < 100) year += year < 50 ? 2000 : 1900;
                            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100)
                            {
                                try
                                {
                                    date = new DateTime(year, month, day);
                                    if (parts.Length >= 4 && int.TryParse(parts[3], out int hour))
                                    {
                                        int minute = parts.Length >= 5 && int.TryParse(parts[4], out int min) ? min : 0;
                                        date = new DateTime(year, month, day, hour, minute, 0);
                                    }
                                    return true;
                                }
                                catch { }
                            }
                        }
                    }
                }
            }

            // Bước 3: Thử parse với các format chuẩn khác (yyyy-MM-dd, etc.)
            string[] formats = {
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd",
                "yyyy/MM/dd HH:mm:ss",
                "yyyy/MM/dd HH:mm",
                "yyyy/MM/dd",
                "dd-MM-yyyy HH:mm:ss",
                "dd-MM-yyyy HH:mm",
                "dd-MM-yyyy",
                "MM-dd-yyyy HH:mm:ss",
                "MM-dd-yyyy HH:mm",
                "MM-dd-yyyy"
            };

            foreach (var format in formats)
            {
                if (DateTime.TryParseExact(dateString, format, null, DateTimeStyles.None, out date))
                {
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// Format ngày từ Excel sang format yyyyMMddHHmm cho query
        /// </summary>
        private string FormatDateForQuery(string? dateString, bool isEndDate = false)
        {
            if (string.IsNullOrWhiteSpace(dateString))
                return string.Empty;

            // Loại bỏ khoảng trắng
            dateString = dateString.Trim();

            // Nếu đã là format yyyyMMdd hoặc yyyyMMddHHmm
            if (dateString.Length >= 8 && dateString.All(char.IsDigit))
            {
                if (dateString.Length == 8)
                {
                    return dateString + (isEndDate ? "2359" : "0000");
                }

                if (dateString.Length >= 12)
                {
                    return dateString.Substring(0, 12);
                }

                var padChar = isEndDate ? '9' : '0';
                return dateString.PadRight(12, padChar);
            }

            // Thử parse với hàm flexible
            if (TryParseDateFlexible(dateString, out DateTime date))
            {
                bool hasExplicitTime = dateString.Contains(":") || dateString.Contains("T");

                if (hasExplicitTime && date.TimeOfDay != TimeSpan.Zero)
                {
                    return date.ToString("yyyyMMddHHmm");
                }

                var dayString = date.ToString("yyyyMMdd");
                return dayString + (isEndDate ? "2359" : "0000");
            }

            // Fallback: trả về string gốc
            return dateString;
        }

        public void Dispose()
        {
            _semaphore?.Dispose();
        }
    }
}
