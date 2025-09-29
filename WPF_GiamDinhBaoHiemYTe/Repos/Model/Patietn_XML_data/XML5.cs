using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class XML5: ObservableObject
    {
        [ObservableProperty] private int id;
        [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private int? stt;
        [ObservableProperty] private string? dien_Bien_Ls;
        [ObservableProperty] private string? giai_DoAn_Benh;
        [ObservableProperty] private string? hoi_Chan;
        [ObservableProperty] private string? phau_Thuat;
        [ObservableProperty] private string? thoi_Diem_Dbls;
        [ObservableProperty] private string? nguoi_Thuc_Hien;
        [ObservableProperty] private string? du_Phong;
    }
}
