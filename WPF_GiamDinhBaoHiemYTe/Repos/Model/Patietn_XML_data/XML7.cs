using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class XML7 : ObservableObject
    {
        [ObservableProperty] private int id;
        [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private string? so_Luu_Tru;
        [ObservableProperty] private string? ma_Yte;
        [ObservableProperty] private string? ma_Khoa_Rv;
        [ObservableProperty] private string? ngay_Vao;
        [ObservableProperty] private string? ngay_Ra;
        [ObservableProperty] private int? ma_Dinh_Chi_Thai;
        [ObservableProperty] private string? nguyenNhan_DinhChi;
        [ObservableProperty] private string? thoiGian_DinhChi;
        [ObservableProperty] private string? tuoi_Thai;
        [ObservableProperty] private string? chan_DoAn_Rv;
        [ObservableProperty] private string? pp_DieuTri;
        [ObservableProperty] private string? ghi_Chu;
        [ObservableProperty] private string? ma_Ttdv;
        [ObservableProperty] private string? ma_Bs;
        [ObservableProperty] private string? ten_Bs;
        [ObservableProperty] private string? ngay_Ct;
        [ObservableProperty] private string? ma_Cha;
        [ObservableProperty] private string? ma_Me;
        [ObservableProperty] private string? ma_The_Tam;
        [ObservableProperty] private string? ho_Ten_Cha;
        [ObservableProperty] private string? ho_Ten_Me;
        [ObservableProperty] private int? so_Ngay_Nghi;
        [ObservableProperty] private string? ngoaiTru_TuNgay;
        [ObservableProperty] private string? ngoaiTru_DenNgay;
        [ObservableProperty] private string? du_Phong;
    }
}
