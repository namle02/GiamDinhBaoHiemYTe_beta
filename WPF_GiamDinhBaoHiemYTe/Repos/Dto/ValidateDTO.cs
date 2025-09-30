using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    public partial class ValidateData : ObservableObject
    {
        [ObservableProperty] private bool? overallValid;
        [ObservableProperty] private int? totalRules;
        [ObservableProperty] private int? activeRules;
        [ObservableProperty] private List<ValidationRule>? validationResults;
        [ObservableProperty] private summaryData? summary;
    }

    public partial class ValidationRule : ObservableObject
    {
        [ObservableProperty] private string ruleName = string.Empty;
        [ObservableProperty] private string ruleId = string.Empty;
        [ObservableProperty] private string validateField = string.Empty;
        [ObservableProperty] private bool isValid;
        [ObservableProperty] private string message = string.Empty;
        [ObservableProperty] private List<errorData>? errors;
        [ObservableProperty] private List<warningData>? warnings;
    }

    public partial class errorData : ObservableObject
    {
        [ObservableProperty] private int? id;
        [ObservableProperty] private string error = string.Empty;
    }

    public partial class warningData : ObservableObject
    {
        [ObservableProperty] private int? id;
        [ObservableProperty] private string? warning = string.Empty;
    }

    public partial class summaryData : ObservableObject
    {
        [ObservableProperty] private int? passed;
        [ObservableProperty] private int? failed;
        [ObservableProperty] private int? warnings;
        [ObservableProperty] private int? errors;
    }
}
