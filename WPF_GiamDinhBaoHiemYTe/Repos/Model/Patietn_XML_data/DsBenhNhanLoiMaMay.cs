using CommunityToolkit.Mvvm.ComponentModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model.Patietn_XML_data
{
    
    public partial class DsBenhNhanLoiMaMay : ObservableObject
    {
        
         [ObservableProperty] private string? ma_Lk;
        [ObservableProperty] private string? ma_May;
        [ObservableProperty] private string? thoiGian;
       
        

    }
}
