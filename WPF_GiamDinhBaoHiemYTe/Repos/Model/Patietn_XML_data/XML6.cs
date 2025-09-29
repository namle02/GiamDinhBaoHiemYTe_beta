using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class XML6: ObservableObject
    {
        [ObservableProperty] private int id;
        [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private string? ma_The_Bhyt;
        [ObservableProperty] private string? so_Cccd;
        [ObservableProperty] private string? ngaykd_Hiv;
        [ObservableProperty] private string? bddt_Arv;
        [ObservableProperty] private string? ma_Phac_Do_Dieu_Tri_Bd;
        [ObservableProperty] private int? ma_Bac_Phac_Do_Bd;
        [ObservableProperty] private int? ma_Lydo_Dtri;
        [ObservableProperty] private int? loai_Dtri_Lao;
        [ObservableProperty] private int? phacdo_Dtri_Lao;
        [ObservableProperty] private string? ngaybd_Dtri_Lao;
        [ObservableProperty] private string? ngaykt_Dtri_Lao;
        [ObservableProperty] private int? ma_Lydo_Xntl_Vr;
        [ObservableProperty] private string? ngay_Xn_Tlvr;
        [ObservableProperty] private int? kq_Xntl_Vr;
        [ObservableProperty] private string? ngay_Kq_Xn_Tlvr;
        [ObservableProperty] private int? ma_Loai_Bn;
        [ObservableProperty] private string? ma_Tinh_Trang_Dk;
        [ObservableProperty] private int? lan_Xn_Pcr;
        [ObservableProperty] private string? ngay_Xn_Pcr;
        [ObservableProperty] private string? ngay_Kq_Xn_Pcr;
        [ObservableProperty] private int? ma_Kq_Xn_Pcr;
        [ObservableProperty] private string? ngay_Nhan_Tt_Mang_Thai;
        [ObservableProperty] private string? ngay_Bat_Dau_Dt_Ctx;
        [ObservableProperty] private int? ma_Xu_Tri;
        [ObservableProperty] private string? ngay_Bat_Dau_Xu_Tri;
        [ObservableProperty] private string? ngay_Ket_Thuc_Xu_Tri;
        [ObservableProperty] private string? ma_Phac_Do_Dieu_Tri;
        [ObservableProperty] private int? ma_Bac_Phac_Do;
        [ObservableProperty] private int? so_Ngay_Cap_Thuoc_Arv;
        [ObservableProperty] private string? du_Phong;
        [ObservableProperty] private string? ngay_Sinh;
        [ObservableProperty] private int? gioi_Tinh;
        [ObservableProperty] private string? dia_Chi;
        [ObservableProperty] private string? matinh_Cu_Tru;
        [ObservableProperty] private string? mahuyen_Cu_Tru;
        [ObservableProperty] private string? maxa_Cu_Tru;
        [ObservableProperty] private string? noi_Lay_Mau_Xn;
        [ObservableProperty] private string? noi_Xn_Kd;
        [ObservableProperty] private string? noi_Bddt_Arv;
        [ObservableProperty] private int? sang_Loc_Lao;
        [ObservableProperty] private int? kq_Dtri_Lao;
        [ObservableProperty] private int? giai_DoAn_Lam_Sang;
        [ObservableProperty] private int? nhom_Doi_Tuong;
        [ObservableProperty] private string? ngay_Chuyen_Phac_Do;
        [ObservableProperty] private int? ly_Do_Chuyen_Phac_Do;
        [ObservableProperty] private string? ma_Cskcb;
    }
}
