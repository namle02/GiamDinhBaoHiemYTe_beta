using CommunityToolkit.Mvvm.ComponentModel;
using System;

namespace WPF_GiamDinhBaoHiem.Repos.Model.Patietn_XML_data
{
    public partial class PhanLoaiBenhAn : ObservableObject
    {
        [ObservableProperty] private string? ma_TN;

        [ObservableProperty] private string? ma_BA;

        [ObservableProperty] private DateTime? ngay_vao_vien;

        [ObservableProperty] private int loaiBenhAn;
    }
}
