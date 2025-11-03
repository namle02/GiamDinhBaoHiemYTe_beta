using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service để export dữ liệu validation ra file Excel
    /// </summary>
    public interface IExcelExportService
    {
        /// <summary>
        /// Export kết quả validation ra file Excel với nhiều sheet
        /// </summary>
        /// <param name="validationResults">Danh sách kết quả validation</param>
        /// <param name="filePath">Đường dẫn file Excel</param>
        /// <param name="includeErrorDetailsOnly">Chỉ export bệnh nhân có lỗi</param>
        /// <returns>True nếu export thành công</returns>
        Task<bool> ExportValidationResultsToExcelAsync(
            List<PatientValidationResult> validationResults, 
            string filePath, 
            bool includeErrorDetailsOnly = false);
        
        /// <summary>
        /// Export báo cáo chi tiết với thông tin bệnh nhân đầy đủ
        /// </summary>
        /// <param name="validationResults">Danh sách kết quả validation</param>
        /// <param name="filePath">Đường dẫn file Excel</param>
        /// <returns>True nếu export thành công</returns>
        Task<bool> ExportDetailedReportToExcelAsync(
            List<PatientValidationResult> validationResults,
            string filePath);
    }
}
