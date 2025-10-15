using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class XML2 : ObservableObject
    {
        [ObservableProperty] private int id;
        [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private int? stt;
        [ObservableProperty] private string? ma_Thuoc;
        [ObservableProperty] private string? ma_Pp_CheBien;
        [ObservableProperty] private string? ma_Cskcb_Thuoc;
        [ObservableProperty] private int? ma_Nhom;
        [ObservableProperty] private string? ten_Thuoc;
        [ObservableProperty] private string? don_Vi_Tinh;
        [ObservableProperty] private string? ham_Luong;
        [ObservableProperty] private string? duong_Dung;
        [ObservableProperty] private string? dang_Bao_Che;
        [ObservableProperty] private string? lieu_Dung;
        [ObservableProperty] private string? cach_Dung;
        [ObservableProperty] private string? so_Dang_Ky;
        [ObservableProperty] private string? tt_Thau;
        [ObservableProperty] private int? pham_Vi;
        [ObservableProperty] private decimal? tyle_Tt_Bh;
        [ObservableProperty] private decimal? so_Luong;
        [ObservableProperty] private decimal? don_Gia;
        [ObservableProperty] private decimal? thanh_Tien_Bv;
        [ObservableProperty] private decimal? thanh_Tien_Bh;
        [ObservableProperty] private decimal? t_NguonKhac_Nsnn;
        [ObservableProperty] private decimal? t_NguonKhac_Vtnn;
        [ObservableProperty] private decimal? t_NguonKhac_Vttn;
        [ObservableProperty] private decimal? t_NguonKhac_Cl;
        [ObservableProperty] private decimal? t_NguonKhac;
        [ObservableProperty] private decimal? muc_Huong;
        [ObservableProperty] private decimal? t_Bntt;
        [ObservableProperty] private decimal? t_Bncct;
        [ObservableProperty] private decimal? t_Bhtt;
        [ObservableProperty] private string? ma_Khoa;
        [ObservableProperty] private string? ma_Bac_Si;
        [ObservableProperty] private string? ma_Dich_Vu;
        [ObservableProperty] private string? ngay_Yl;
        [ObservableProperty] private int? ma_Pttt;
        [ObservableProperty] private int? nguon_Ctra;
        [ObservableProperty] private int? vet_Thuong_Tp;
        [ObservableProperty] private string? du_Phong;
        [ObservableProperty] private string? ngay_Th_Yl;
        [ObservableProperty] private bool isError;
    }
}
