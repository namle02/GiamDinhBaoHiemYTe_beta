using System.Collections.Generic;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service để build PatientValidationResult từ validation data
    /// </summary>
    public interface IValidationResultBuilder
    {
        /// <summary>
        /// Tạo PatientValidationResult từ XML1 data và validation results
        /// </summary>
        PatientValidationResult BuildValidationResult(XML1 xml1Data, List<ValidationRule>? validationRules);

        /// <summary>
        /// Tạo danh sách error messages từ validation rules
        /// </summary>
        List<string> BuildErrorMessages(List<ValidationRule>? validationRules);

        /// <summary>
        /// Tạo string gender từ mã giới tính
        /// </summary>
        string GetGenderString(int? gioiTinh);
    }
}

