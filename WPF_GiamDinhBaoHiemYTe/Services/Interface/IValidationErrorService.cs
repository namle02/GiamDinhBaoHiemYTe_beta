using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service xử lý validation errors và marking
    /// </summary>
    public interface IValidationErrorService
    {
        /// <summary>
        /// Extract error IDs và XML tabs từ validation results
        /// </summary>
        ErrorExtractionResult ExtractErrorIds(ValidateData validateData);

        /// <summary>
        /// Extract error IDs và XML tabs từ danh sách validation rules
        /// </summary>
        ErrorExtractionResult ExtractErrorIds(List<ValidationRule> validationRules);

        /// <summary>
        /// Đánh dấu các row có lỗi trong XML data
        /// </summary>
        void MarkErrorsInXmlData(PatientData patientData, HashSet<int> errorIds, HashSet<string> errorXmlTabs);

        /// <summary>
        /// Normalize XML tab name từ validateFile
        /// </summary>
        string? NormalizeXmlTabName(string validateFile);
    }

    /// <summary>
    /// Kết quả extract error IDs
    /// </summary>
    public class ErrorExtractionResult
    {
        public HashSet<int> ErrorIds { get; set; } = new();
        public HashSet<string> ErrorXmlTabs { get; set; } = new();

        /// <summary>
        /// Check xem có lỗi trong XML tab cụ thể không
        /// </summary>
        public bool HasErrorInTab(string tabName) => ErrorXmlTabs.Contains(tabName);

        /// <summary>
        /// Check xem ID có trong danh sách lỗi không
        /// </summary>
        public bool IsErrorId(int id) => ErrorIds.Contains(id);
    }
}

