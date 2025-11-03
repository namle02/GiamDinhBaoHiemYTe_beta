using System.Collections.Generic;
using System.Linq;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Implementation của IValidationResultBuilder
    /// </summary>
    public class ValidationResultBuilder : IValidationResultBuilder
    {
        public PatientValidationResult BuildValidationResult(XML1 xml1Data, List<ValidationRule>? validationRules)
        {
            var errorMessages = BuildErrorMessages(validationRules);

            return new PatientValidationResult
            {
                Ma_Lk = xml1Data.Ma_Lk ?? "",
                Ho_Ten = xml1Data.Ho_Ten ?? "",
                Gioi_Tinh = GetGenderString(xml1Data.Gioi_Tinh),
                Nam_Sinh = xml1Data.Ngay_Sinh ?? "",
                Noi_Dung_Loi = errorMessages.Count > 0 
                    ? string.Join("\n", errorMessages) 
                    : "Không có lỗi",
                IsError = errorMessages.Count > 0,
                ValidationRules = validationRules
            };
        }

        public List<string> BuildErrorMessages(List<ValidationRule>? validationRules)
        {
            var errorMessages = new List<string>();

            if (validationRules != null)
            {
                foreach (var rule in validationRules)
                {
                    if (!rule.IsValid)
                    {
                        errorMessages.Add($"• {rule.RuleName}");
                    }
                }
            }

            return errorMessages;
        }

        public string GetGenderString(int? gioiTinh)
        {
            return gioiTinh switch
            {
                1 => "Nam",
                2 => "Nữ",
                _ => "Khác"
            };
        }
    }
}

