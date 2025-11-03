using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class XML4 : ObservableObject, IHasStt
    {
        [ObservableProperty] private int id;
        [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private int? stt;
        [ObservableProperty] private string? ma_Dich_Vu;
        [ObservableProperty] private string? ma_Chi_So;
        [ObservableProperty] private string? ten_Chi_So;
        [ObservableProperty] private string? gia_Tri;
        [ObservableProperty] private string? don_Vi_Do;
        [ObservableProperty] private string? mo_Ta;
        [ObservableProperty] private string? ket_Luan;
        [ObservableProperty] private string? ngay_Kq;
        [ObservableProperty] private string? ma_Bs_Doc_Kq;
        [ObservableProperty] private string? du_Phong;
        [ObservableProperty] private bool isError;
    }
}
