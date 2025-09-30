using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    public partial class RuleDto : ObservableObject
    {
        [ObservableProperty] private string id = string.Empty;
        [ObservableProperty] private string name = string.Empty;
        [ObservableProperty] private string file = string.Empty;
        [ObservableProperty] private bool isActive;
    }
}
