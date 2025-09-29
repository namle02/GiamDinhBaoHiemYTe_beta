using System.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public class BacSi : INotifyPropertyChanged
    {
        private int _id;
        private string _maBacSi = string.Empty;
        private string _hoTen = string.Empty;
        private string _chuyenKhoa = string.Empty;
        private string _soDienThoai = string.Empty;
        private string _email = string.Empty;
        private string _diaChi = string.Empty;
        private DateTime _ngaySinh;
        private string _gioiTinh = string.Empty;
        private string _bangCap = string.Empty;
        private DateTime _ngayVaoLam;
        private bool _trangThai;
        private string _ghiChu = string.Empty;

        public int Id
        {
            get => _id;
            set
            {
                _id = value;
                OnPropertyChanged(nameof(Id));
            }
        }

        public string MaBacSi
        {
            get => _maBacSi;
            set
            {
                _maBacSi = value;
                OnPropertyChanged(nameof(MaBacSi));
            }
        }

        public string HoTen
        {
            get => _hoTen;
            set
            {
                _hoTen = value;
                OnPropertyChanged(nameof(HoTen));
            }
        }

        public string ChuyenKhoa
        {
            get => _chuyenKhoa;
            set
            {
                _chuyenKhoa = value;
                OnPropertyChanged(nameof(ChuyenKhoa));
            }
        }

        public string SoDienThoai
        {
            get => _soDienThoai;
            set
            {
                _soDienThoai = value;
                OnPropertyChanged(nameof(SoDienThoai));
            }
        }

        public string Email
        {
            get => _email;
            set
            {
                _email = value;
                OnPropertyChanged(nameof(Email));
            }
        }

        public string DiaChi
        {
            get => _diaChi;
            set
            {
                _diaChi = value;
                OnPropertyChanged(nameof(DiaChi));
            }
        }

        public DateTime NgaySinh
        {
            get => _ngaySinh;
            set
            {
                _ngaySinh = value;
                OnPropertyChanged(nameof(NgaySinh));
            }
        }

        public string GioiTinh
        {
            get => _gioiTinh;
            set
            {
                _gioiTinh = value;
                OnPropertyChanged(nameof(GioiTinh));
            }
        }

        public string BangCap
        {
            get => _bangCap;
            set
            {
                _bangCap = value;
                OnPropertyChanged(nameof(BangCap));
            }
        }

        public DateTime NgayVaoLam
        {
            get => _ngayVaoLam;
            set
            {
                _ngayVaoLam = value;
                OnPropertyChanged(nameof(NgayVaoLam));
            }
        }

        public bool TrangThai
        {
            get => _trangThai;
            set
            {
                _trangThai = value;
                OnPropertyChanged(nameof(TrangThai));
            }
        }

        public string GhiChu
        {
            get => _ghiChu;
            set
            {
                _ghiChu = value;
                OnPropertyChanged(nameof(GhiChu));
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
