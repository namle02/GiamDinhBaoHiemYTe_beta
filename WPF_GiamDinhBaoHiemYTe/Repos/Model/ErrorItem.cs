using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class ErrorItem : ObservableObject
    {

        [ObservableProperty] public int stt;
        [ObservableProperty] public string maCoSoKCB = string.Empty;
        [ObservableProperty] public string maChuyenDe = string.Empty;
        [ObservableProperty] public string maLyDoTuChoi = string.Empty;
        [ObservableProperty] public string noiDung = string.Empty;
        [ObservableProperty] public bool isSelected;
        [ObservableProperty] public string viTriLoi = string.Empty;
    }
}
