using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class DM_BacSiVM : ObservableObject
    {
        [ObservableProperty]
        private ObservableCollection<BacSi> _danhSachBacSi;

        [ObservableProperty]
        private BacSi _bacSiHienTai;

        [ObservableProperty]
        private BacSi _bacSiMoi;

        [ObservableProperty]
        private string _tuKhoaTimKiem = string.Empty;

        [ObservableProperty]
        private bool _isThemMoi = false;

        [ObservableProperty]
        private bool _isChinhSua = false;

        [ObservableProperty]
        private bool _isXemChiTiet = false;

        [ObservableProperty]
        private bool _coBacSiDuocChon = false;

        private readonly IDataMapper _dataMapper;

        [ObservableProperty]
        private string searchText = string.Empty; // Nhập NhanVien_Id hoặc Tên

        [ObservableProperty]
        private NhanVien? nhanVien; // Kết quả hiện tại

        [ObservableProperty]
        private bool isLoading;

        public DM_BacSiVM(IDataMapper dataMapper)
        {
            _dataMapper = dataMapper;
            DanhSachBacSi = new ObservableCollection<BacSi>();
            BacSiHienTai = new BacSi();
            BacSiMoi = new BacSi();
            //LoadDuLieuMau();
        }

        partial void OnBacSiHienTaiChanged(BacSi value)
        {
            CoBacSiDuocChon = value != null && value.Id > 0;
        }

        private void LoadDuLieuMau()
        {
            // Dữ liệu mẫu để test giao diện
            DanhSachBacSi.Add(new BacSi
            {
                Id = 1,
                MaBacSi = "BS001",
                HoTen = "Nguyễn Văn An",
                ChuyenKhoa = "Tim mạch",
                SoDienThoai = "0901234567",
                Email = "nguyenvanan@hospital.com",
                DiaChi = "123 Đường ABC, Quận 1, TP.HCM",
                NgaySinh = new DateTime(1980, 5, 15),
                GioiTinh = "Nam",
                BangCap = "Bác sĩ chuyên khoa Tim mạch",
                NgayVaoLam = new DateTime(2010, 3, 1),
                TrangThai = true,
                GhiChu = "Bác sĩ có kinh nghiệm 15 năm"
            });

            DanhSachBacSi.Add(new BacSi
            {
                Id = 2,
                MaBacSi = "BS002",
                HoTen = "Trần Thị Bình",
                ChuyenKhoa = "Nhi khoa",
                SoDienThoai = "0901234568",
                Email = "tranthibinh@hospital.com",
                DiaChi = "456 Đường XYZ, Quận 2, TP.HCM",
                NgaySinh = new DateTime(1985, 8, 20),
                GioiTinh = "Nữ",
                BangCap = "Bác sĩ chuyên khoa Nhi",
                NgayVaoLam = new DateTime(2012, 6, 15),
                TrangThai = true,
                GhiChu = "Chuyên về bệnh nhiễm trùng trẻ em"
            });

            DanhSachBacSi.Add(new BacSi
            {
                Id = 3,
                MaBacSi = "BS003",
                HoTen = "Lê Văn Cường",
                ChuyenKhoa = "Ngoại khoa",
                SoDienThoai = "0901234569",
                Email = "levancuong@hospital.com",
                DiaChi = "789 Đường DEF, Quận 3, TP.HCM",
                NgaySinh = new DateTime(1978, 12, 10),
                GioiTinh = "Nam",
                BangCap = "Bác sĩ chuyên khoa Ngoại",
                NgayVaoLam = new DateTime(2008, 9, 1),
                TrangThai = true,
                GhiChu = "Chuyên về phẫu thuật tim mạch"
            });
        }

        [RelayCommand]
        private void ThemMoi()
        {
            BacSiMoi = new BacSi
            {
                NgaySinh = DateTime.Now.AddYears(-30),
                NgayVaoLam = DateTime.Now,
                TrangThai = true
            };
            IsThemMoi = true;
            IsChinhSua = false;
            IsXemChiTiet = false;
        }

        [RelayCommand]
        private void ChinhSua()
        {
            if (BacSiHienTai != null && BacSiHienTai.Id > 0)
            {
                BacSiMoi = new BacSi
                {
                    Id = BacSiHienTai.Id,
                    MaBacSi = BacSiHienTai.MaBacSi,
                    HoTen = BacSiHienTai.HoTen,
                    ChuyenKhoa = BacSiHienTai.ChuyenKhoa,
                    SoDienThoai = BacSiHienTai.SoDienThoai,
                    Email = BacSiHienTai.Email,
                    DiaChi = BacSiHienTai.DiaChi,
                    NgaySinh = BacSiHienTai.NgaySinh,
                    GioiTinh = BacSiHienTai.GioiTinh,
                    BangCap = BacSiHienTai.BangCap,
                    NgayVaoLam = BacSiHienTai.NgayVaoLam,
                    TrangThai = BacSiHienTai.TrangThai,
                    GhiChu = BacSiHienTai.GhiChu
                };
                IsChinhSua = true;
                IsThemMoi = false;
                IsXemChiTiet = false;
            }
        }

        [RelayCommand]
        private void XemChiTiet()
        {
            if (BacSiHienTai != null && BacSiHienTai.Id > 0)
            {
                BacSiMoi = new BacSi
                {
                    Id = BacSiHienTai.Id,
                    MaBacSi = BacSiHienTai.MaBacSi,
                    HoTen = BacSiHienTai.HoTen,
                    ChuyenKhoa = BacSiHienTai.ChuyenKhoa,
                    SoDienThoai = BacSiHienTai.SoDienThoai,
                    Email = BacSiHienTai.Email,
                    DiaChi = BacSiHienTai.DiaChi,
                    NgaySinh = BacSiHienTai.NgaySinh,
                    GioiTinh = BacSiHienTai.GioiTinh,
                    BangCap = BacSiHienTai.BangCap,
                    NgayVaoLam = BacSiHienTai.NgayVaoLam,
                    TrangThai = BacSiHienTai.TrangThai,
                    GhiChu = BacSiHienTai.GhiChu
                };
                IsXemChiTiet = true;
                IsThemMoi = false;
                IsChinhSua = false;
            }
        }

        [RelayCommand]
        private void Xoa()
        {
            if (BacSiHienTai != null && BacSiHienTai.Id > 0)
            {
                var result = MessageBox.Show(
                    $"Bạn có chắc chắn muốn xóa bác sĩ {BacSiHienTai.HoTen}?",
                    "Xác nhận xóa",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question);

                if (result == MessageBoxResult.Yes)
                {
                    DanhSachBacSi.Remove(BacSiHienTai);
                    BacSiHienTai = new BacSi();
                    MessageBox.Show("Đã xóa bác sĩ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
        }

        [RelayCommand]
        private void Luu()
        {
            if (string.IsNullOrWhiteSpace(BacSiMoi.HoTen) || string.IsNullOrWhiteSpace(BacSiMoi.MaBacSi))
            {
                MessageBox.Show("Vui lòng nhập đầy đủ thông tin bắt buộc!", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (IsThemMoi)
            {
                BacSiMoi.Id = DanhSachBacSi.Count > 0 ? DanhSachBacSi.Max(x => x.Id) + 1 : 1;
                DanhSachBacSi.Add(BacSiMoi);
                MessageBox.Show("Đã thêm bác sĩ mới thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            else if (IsChinhSua)
            {
                var bacSiCu = DanhSachBacSi.FirstOrDefault(x => x.Id == BacSiMoi.Id);
                if (bacSiCu != null)
                {
                    var index = DanhSachBacSi.IndexOf(bacSiCu);
                    DanhSachBacSi[index] = BacSiMoi;
                    BacSiHienTai = BacSiMoi;
                    MessageBox.Show("Đã cập nhật thông tin bác sĩ thành công!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }

            Huy();
        }

        [RelayCommand]
        private void Huy()
        {
            IsThemMoi = false;
            IsChinhSua = false;
            IsXemChiTiet = false;
            BacSiMoi = new BacSi();
        }

        [RelayCommand]
        private async void TimKiem()
        {
            if (IsLoading) return;
            IsLoading = true;
            try
            {
                var key = string.IsNullOrWhiteSpace(SearchText) ? TuKhoaTimKiem : SearchText;
                var list = await _dataMapper.SearchNhanVienAsync(key?.Trim());
                var nv = list.FirstOrDefault();
                NhanVien = nv;
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        private void XuatExcel()
        {
            MessageBox.Show("Chức năng xuất Excel sẽ được implement sau!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        [RelayCommand]
        private void NhapExcel()
        {
            MessageBox.Show("Chức năng nhập Excel sẽ được implement sau!", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}
