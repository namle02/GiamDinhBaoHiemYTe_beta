using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service để xử lý batch processing với thread pool management
    /// </summary>
    public interface IBatchProcessorService
    {
        /// <summary>
        /// Xử lý danh sách patient IDs song song với Semaphore để quản lý thread pool
        /// </summary>
        /// <param name="patientIds">Danh sách mã bệnh nhân cần xử lý</param>
        /// <param name="maxConcurrency">Số lượng request đồng thời tối đa (mặc định 5)</param>
        /// <param name="onProgress">Callback để cập nhật tiến trình</param>
        /// <param name="cancellationToken">Token để hủy operation</param>
        /// <returns>Kết quả xử lý batch</returns>
        Task<BatchProcessingResult> ProcessPatientsAsync(
            List<string> patientIds, 
            int maxConcurrency = 5,
            Action<BatchProgress>? onProgress = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Xử lý một patient ID đơn lẻ
        /// </summary>
        /// <param name="patientId">Mã bệnh nhân</param>
        /// <param name="cancellationToken">Token để hủy operation</param>
        /// <returns>Kết quả xử lý</returns>
        Task<PatientProcessingResult> ProcessSinglePatientAsync(
            string patientId, 
            CancellationToken cancellationToken = default);
    }

    /// <summary>
    /// Kết quả xử lý batch
    /// </summary>
    public class BatchProcessingResult
    {
        public int TotalProcessed { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount { get; set; }
        public List<PatientProcessingResult> Results { get; set; } = new();
        public TimeSpan TotalTime { get; set; }
        public List<string> Errors { get; set; } = new();
    }

    /// <summary>
    /// Kết quả xử lý một patient
    /// </summary>
    public class PatientProcessingResult
    {
        public string PatientId { get; set; } = string.Empty;
        public bool IsSuccess { get; set; }
        public string? ErrorMessage { get; set; }
        public ApiResponse<ValidateData>? ValidationResult { get; set; }
        public TimeSpan ProcessingTime { get; set; }
    }

    /// <summary>
    /// Thông tin tiến trình batch processing
    /// </summary>
    public class BatchProgress
    {
        public int Current { get; set; }
        public int Total { get; set; }
        public string CurrentPatientId { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public int SuccessCount { get; set; }
        public int ErrorCount { get; set; }
        public double Percentage => Total > 0 ? (double)Current / Total * 100 : 0;
    }
}
