using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class BacSi : ObservableObject
    {
        [ObservableProperty]
        private int id;

        [ObservableProperty]
        private string maBacSi = string.Empty;

        [ObservableProperty]
        private string hoTen = string.Empty;

        [ObservableProperty]
        private string chuyenKhoa = string.Empty;

        [ObservableProperty]
        private string soDienThoai = string.Empty;

        [ObservableProperty]
        private string email = string.Empty;

        [ObservableProperty]
        private string diaChi = string.Empty;

        [ObservableProperty]
        private DateTime ngaySinh;

        [ObservableProperty]
        private string gioiTinh = string.Empty;

        [ObservableProperty]
        private string bangCap = string.Empty;

        [ObservableProperty]
        private DateTime ngayVaoLam;

        [ObservableProperty]
        private bool trangThai;

        [ObservableProperty]
        private string ghiChu = string.Empty;
    }
}
