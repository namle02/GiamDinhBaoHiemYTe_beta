using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class Thuoc: ObservableObject
    {
        [ObservableProperty] private string? duoc_Id;
        [ObservableProperty] private string? maDuoc;
        [ObservableProperty] private string? tenDuocDayDu;
        [ObservableProperty] private string? donViTinh;
        [ObservableProperty] private string? tenKhongDau;
        [ObservableProperty] private string? tenLoaiVatTu;
        [ObservableProperty] private string? taiSuDung;
        [ObservableProperty] private string? dangBaoChe_Id;
        [ObservableProperty] private string? nguonChiTra_Id;
        [ObservableProperty] private string? phuongPhapCheBien_Id;
        [ObservableProperty] private string? phamViThanhToan_Id;
        [ObservableProperty] private string? thongTinThau;
    }
}



