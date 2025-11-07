using System.Diagnostics;
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
                        Debug.WriteLine($"Excel: Xử lý trực tiếp MA_LK = {maLkToProcess}");
                    }
                    else if (rowData.DataType == "MA_BN" && rowData.IsValid())
                    {
                        originalIdentifier = $"{rowData.MaBn} ({rowData.NgayVao} - {rowData.NgayRa})";
                        progressLabel = originalIdentifier;
                        Debug.WriteLine($"Excel: Tìm MA_LK cho MA_BN = {rowData.MaBn}, Ngày vào = {rowData.NgayVao}, Ngày ra = {rowData.NgayRa}");

                        try
                        {
                            // Format ngày từ Excel (có thể là dd/MM/yyyy hoặc yyyyMMdd)
                            string ngayVaoFormatted = FormatDateForQuery(rowData.NgayVao, isEndDate: false);
                            string ngayRaFormatted = FormatDateForQuery(rowData.NgayRa, isEndDate: true);

                            // Tìm MA_LK từ MA_BN + dates
                            var maLkResults = await _dataMapper.GetMaLkByMaBnAndDate(
                                rowData.MaBn!, 
                                ngayVaoFormatted, 
                                ngayRaFormatted);

                            if (maLkResults == null || maLkResults.Count == 0)
                            {
                                // KHÔNG tìm thấy MA_LK nào - LỖI
                                Debug.WriteLine($"Excel: ❌ KHÔNG tìm thấy MA_LK cho MA_BN = {rowData.MaBn}");
                                maLkToProcess = null;
                            }
                            else if (maLkResults.Count == 1)
                            {
                                // Tìm thấy ĐÚNG 1 MA_LK - OK
                                maLkToProcess = maLkResults[0].Ma_Lk;
                                Debug.WriteLine($"Excel: ✓ Tìm thấy MA_LK = {maLkToProcess} cho MA_BN = {rowData.MaBn}");

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
                                Debug.WriteLine($"Excel: ⚠️ Tìm thấy {maLkResults.Count} MA_LK cho MA_BN = {rowData.MaBn} → LỖI DATA KHÔNG RÕ RÀNG");
                                
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
                        catch (Exception ex)
                        {
                            Debug.WriteLine($"Excel: Lỗi khi tìm MA_LK cho MA_BN = {rowData.MaBn}: {ex.Message}");
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
                        
                        Debug.WriteLine($"Excel: ❌ Lỗi cho {patientResult.PatientId}: {errorMsg}");
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
                    Debug.WriteLine($"Excel: Processing cancelled");
                    throw;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"Excel: Error processing row: {ex.Message}");
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
                Debug.WriteLine("Batch processing was cancelled");
            }

            stopwatch.Stop();
            result.SuccessCount = successCount;
            result.ErrorCount = errorCount;
            result.TotalTime = stopwatch.Elapsed;

            return result;
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

            // Thử parse các format khác (dd/MM/yyyy HH:mm, dd-MM-yyyy, etc.)
            if (DateTime.TryParse(dateString, out DateTime date))
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
