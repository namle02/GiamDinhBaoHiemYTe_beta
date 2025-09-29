using CommunityToolkit.Mvvm.ComponentModel;
using System;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class NhanVien : ObservableObject
    {
        [ObservableProperty] public int nhanVien_Id;
        [ObservableProperty] public string maNhanVien = string.Empty;
        [ObservableProperty] public string ho = string.Empty;
        [ObservableProperty] public string ten = string.Empty;
        [ObservableProperty] public string tenNhanVien = string.Empty;
        [ObservableProperty] public string tenNhanVien_RU = string.Empty;
        [ObservableProperty] public string tenNhanVien_EN = string.Empty;
        [ObservableProperty] public string tenTat = string.Empty;
        [ObservableProperty] public DateTime? ngaySinh;
        [ObservableProperty] public string gioiTinh = string.Empty;
        [ObservableProperty] public string diaChi = string.Empty;
        [ObservableProperty] public int? phongBan_Id;
        [ObservableProperty] public int? donViCongTac_Id;
        [ObservableProperty] public int? chucDanh_Id;
        [ObservableProperty] public int? chucVu_Id;
        [ObservableProperty] public int? trinhDoChuyenMon_Id;
        [ObservableProperty] public int? quocTich_Id;
        [ObservableProperty] public int? tinhThanh_Id;
        [ObservableProperty] public int? quanHuyen_Id;
        [ObservableProperty] public int? xaPhuong_Id;
        [ObservableProperty] public int? danToc_Id;
        [ObservableProperty] public int? ngheNghiep_Id;
        [ObservableProperty] public string cmnd = string.Empty;
        [ObservableProperty] public string hoChieu = string.Empty;
        [ObservableProperty] public bool? trucTiepSX;
        [ObservableProperty] public bool? tiepXucDocHai;
        [ObservableProperty] public bool? tamNgung;
        [ObservableProperty] public string tenKhongDau = string.Empty;
        [ObservableProperty] public DateTime? ngayTao;
        [ObservableProperty] public int? nguoiTao_Id;
        [ObservableProperty] public DateTime? ngayCapNhat;
        [ObservableProperty] public int? nguoiCapNhat_Id;
        [ObservableProperty] public string maDonVi = string.Empty;
        [ObservableProperty] public DateTime? ngayVao;
        [ObservableProperty] public string maNhanVienNSTL = string.Empty;
        [ObservableProperty] public DateTime? ngay_Sinh; // alias nếu view dùng tên này
        [ObservableProperty] public string soChungChiHanhNghe = string.Empty;
        [ObservableProperty] public string chungChiHanhNghe = string.Empty;
        [ObservableProperty] public string maLienThongBS = string.Empty;
        [ObservableProperty] public string seriCKS = string.Empty;
        [ObservableProperty] public string matKhauLienThongBS = string.Empty;
        [ObservableProperty] public string soBHXH = string.Empty;
        [ObservableProperty] public string userName = string.Empty;
        [ObservableProperty] public string passSign = string.Empty;
        [ObservableProperty] public string email = string.Empty;
        [ObservableProperty] public DateTime? ngayCKS;
        [ObservableProperty] public string clientIDSmartCA = string.Empty;
        [ObservableProperty] public string clientSecretSmartCA = string.Empty;
        [ObservableProperty] public string dutru1 = string.Empty;
    }
}
