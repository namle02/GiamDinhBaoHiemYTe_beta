using CommunityToolkit.Mvvm.ComponentModel;


namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    public partial class ApiResponse<T> : ObservableObject
    {
        [ObservableProperty] private bool success;
        [ObservableProperty] private string message = string.Empty;
        [ObservableProperty] private string? error = string.Empty;
        [ObservableProperty] private T? data;
    }
}
