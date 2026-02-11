using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    /// <summary>
    /// Một rule bị lỗi để chọn và lọc dữ liệu tab XML theo rule đó.
    /// </summary>
    public partial class OverlayErrorRuleItem : ObservableObject
    {
        [ObservableProperty]
        private string ruleId = string.Empty;

        [ObservableProperty]
        private string ruleName = string.Empty;

        [ObservableProperty]
        private string message = string.Empty;

        [ObservableProperty]
        private string validateFile = string.Empty;

        /// <summary>Danh sách lỗi chi tiết (ID dòng, nội dung).</summary>
        public List<OverlayErrorEntry> Errors { get; set; } = new();

        /// <summary>ID các dòng lỗi của rule này - dùng để lọc bảng XML khi chọn rule.</summary>
        public HashSet<int> ErrorIds { get; set; } = new();

        /// <summary>Tiêu đề hiển thị: RuleId - RuleName.</summary>
        public string TabHeader => string.IsNullOrWhiteSpace(RuleName) ? RuleId : $"{RuleId} - {RuleName}";

        public static OverlayErrorRuleItem FromValidationRule(ValidationRule rule)
        {
            var item = new OverlayErrorRuleItem
            {
                RuleId = rule.RuleId ?? "",
                RuleName = rule.RuleName ?? "",
                Message = rule.Message ?? "",
                ValidateFile = rule.ValidateFile ?? ""
            };
            if (rule.Errors != null)
            {
                foreach (var e in rule.Errors)
                {
                    item.Errors.Add(new OverlayErrorEntry
                    {
                        RowId = e.Id,
                        ErrorText = e.Error ?? ""
                    });
                    if (e.Id.HasValue)
                        item.ErrorIds.Add(e.Id.Value);
                }
            }
            return item;
        }
    }

    public partial class OverlayErrorEntry : ObservableObject
    {
        [ObservableProperty]
        private int? rowId;

        [ObservableProperty]
        private string errorText = string.Empty;

        public string RowIdDisplay => RowId.HasValue ? RowId.Value.ToString() : "—";
    }
}
