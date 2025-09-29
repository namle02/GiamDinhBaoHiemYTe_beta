
using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model {
public class ErrorXML0 : ObservableObject
    {
    public bool Du_Phong { get; set; }
    public bool Gioi_Tinh { get; set; }
    public bool Gt_The_Den { get; set; }
    public bool Gt_The_Tu { get; set; }
    public bool Ho_Ten { get; set; }
    public bool Id { get; set; }
    public bool Ly_Do_Vnt { get; set; }
    public bool Ma_Bn { get; set; }
    public bool Ma_Cskcb { get; set; }
    public bool Ma_Dich_Vu { get; set; }
    public bool Ma_Dkbd { get; set; }
    public bool Ma_DoiTuong_Kcb { get; set; }
    public bool Ma_Lk { get; set; }
    public bool Ma_Loai_Kcb { get; set; }
    public bool Ma_Ly_Do_Vnt { get; set; }
    public bool Ma_The_Bhyt { get; set; }
    public bool Ma_Thuoc { get; set; }
    public bool Ma_Vat_Tu { get; set; }
    public bool Ngay_Sinh { get; set; }
    public bool Ngay_Vao { get; set; }
    public bool Ngay_Vao_Noi_Tru { get; set; }
    public bool Ngay_Yl { get; set; }
    public bool So_Cccd { get; set; }
    public bool Stt { get; set; }
    public bool Ten_Dich_Vu { get; set; }
    public bool Ten_Thuoc { get; set; }
    public bool Ten_Vat_Tu { get; set; }

    public bool HasAnyError => Du_Phong || Gioi_Tinh || Gt_The_Den || Gt_The_Tu || Ho_Ten || Id || Ly_Do_Vnt || Ma_Bn || Ma_Cskcb || Ma_Dich_Vu || Ma_Dkbd || Ma_DoiTuong_Kcb || Ma_Lk || Ma_Loai_Kcb || Ma_Ly_Do_Vnt || Ma_The_Bhyt || Ma_Thuoc || Ma_Vat_Tu || Ngay_Sinh || Ngay_Vao || Ngay_Vao_Noi_Tru || Ngay_Yl || So_Cccd || Stt || Ten_Dich_Vu || Ten_Thuoc || Ten_Vat_Tu;
}
}