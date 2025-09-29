using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    /// <summary>
    /// Complete DichVu model với tất cả các fields từ database
    /// </summary>
    public partial class DichVu : ObservableObject
    {
        // === CORE PROPERTIES ===
        [ObservableProperty] private int _dichVu_Id;
        [ObservableProperty] private int _nhomDichVu_Id;
        [ObservableProperty] private string _maDichVu = string.Empty;
        [ObservableProperty] private string? _maDichVu_Seg01;
        [ObservableProperty] private string? _maDichVu_Seg02;
        [ObservableProperty] private string? _maDichVu_Seg03;
        [ObservableProperty] private string? _maDichVu_Seg04;
        [ObservableProperty] private string _tenDichVu = string.Empty;
        [ObservableProperty] private string? _tenDichVu_En;
        [ObservableProperty] private string? _tenDichVu_Ru;
        [ObservableProperty] private int _cap;
        [ObservableProperty] private int? _capTren_Id;
        [ObservableProperty] private string? _donViTinh;
        [ObservableProperty] private int _idx;
        [ObservableProperty] private int _chonHetCapDuoi;
        [ObservableProperty] private int _coGiaDichVu;
        [ObservableProperty] private int _giaCoDinh;
        [ObservableProperty] private int _thucHienBenNgoai;
        [ObservableProperty] private string? _soPhim;
        [ObservableProperty] private string? _maQuiDinh;
        [ObservableProperty] private int _tamNgung;
        [ObservableProperty] private string? _tenKhongDau;
        [ObservableProperty] private DateTime? _ngayTao;
        [ObservableProperty] private int _nguoiTao_Id;
        [ObservableProperty] private DateTime? _ngayCapNhat;
        [ObservableProperty] private int? _nguoiCapNhat_Id;
        [ObservableProperty] private int _coGiaTriChuan;
        [ObservableProperty] private int _test;
        [ObservableProperty] private string? _attribute1;
        [ObservableProperty] private string? _attribute2;
        [ObservableProperty] private string? _attribute3;
        [ObservableProperty] private string? _attribute4;
        [ObservableProperty] private string? _attribute5;
        [ObservableProperty] private string? _nhomDichVu_Report_Local_Id;
        [ObservableProperty] private string? _nhomDichVu_Report_Global_Id;
        [ObservableProperty] private string? _shortName;
        [ObservableProperty] private string? _inputCode;
        [ObservableProperty] private int _noResult;
        [ObservableProperty] private string? _applyFor;
        [ObservableProperty] private int _printWhenNull;
        [ObservableProperty] private string? _reportCode;
        [ObservableProperty] private string? _reportTitle;
        [ObservableProperty] private int _doUuTienDichVu;
        [ObservableProperty] private string? _maMay;
        [ObservableProperty] private int _bHYT;
        [ObservableProperty] private int _isThongSo;
        [ObservableProperty] private string? _costCenter_Id;
        [ObservableProperty] private string? _ma37;
        [ObservableProperty] private string? _ma50;
        [ObservableProperty] private string? _tenDVTheoTT37;
        [ObservableProperty] private string? _ghiChuTT37;
        [ObservableProperty] private string? _maDichVu_BenhVien;
        [ObservableProperty] private string? _loaiPTTT;
        [ObservableProperty] private string? _iD_CODE;
        [ObservableProperty] private string? _pSXN;
        [ObservableProperty] private string? _sLDV;
        [ObservableProperty] private int _soNgayDichVu;
        [ObservableProperty] private int _iCD9_CM_Id;
        [ObservableProperty] private string? _maXangDau;
        [ObservableProperty] private string? _maChiSo;
        [ObservableProperty] private int? _phamViTT_ID;
        [ObservableProperty] private int? _iCD9_ID;
        [ObservableProperty] private int _dDchidinh;
        [ObservableProperty] private int? _maQuiDinhCu;
        [ObservableProperty] private string? _tenQuiDinhCu;
        [ObservableProperty] private string? _tGTHMin;

        // === CONSTRUCTOR ===
        public DichVu()
        {
            // Initialize with default values if needed
        }

        // === HELPER METHODS ===
        public bool IsActive => TamNgung != 1;
        public bool HasPrice => CoGiaDichVu == 1;
        public bool IsBHYTCovered => BHYT == 1;
        public string DisplayName => !string.IsNullOrEmpty(ShortName) ? ShortName : TenDichVu;
    }
}


