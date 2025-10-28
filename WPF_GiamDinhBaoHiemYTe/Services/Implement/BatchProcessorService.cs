using System.Diagnostics;
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

        public void Dispose()
        {
            _semaphore?.Dispose();
        }
    }
}
