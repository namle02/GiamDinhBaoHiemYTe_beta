using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class PatientData : ObservableObject
    {
        public string? PatientID { get; set; }
        public List<XML0>? Xml0 { get; set; }
        public List<XML1>? Xml1 { get; set; }
        public List<XML2>? Xml2 { get; set; }
        public List<XML3>? Xml3 { get; set; }
        public List<XML4>? Xml4 { get; set; }
        public List<XML5>? Xml5 { get; set; }
        public List<XML6>? Xml6 { get; set; }
        public List<XML7>? Xml7 { get; set; }
        public List<XML8>? Xml8 { get; set; }
        public List<XML9>? Xml9 { get; set; }
        public List<XML10>? Xml10 { get; set; }
        public List<XML11>? Xml11 { get; set; }
        public List<XML13>? Xml13 { get; set; }
        public List<XML14>? Xml14 { get; set; }
        public List<XML15>? Xml15 { get; set; }

        [ObservableProperty] private List<ErrorItem> _activatedErrors = new();
        
        // XML Header error states for UI binding
        [ObservableProperty] private bool _xml1HeaderError = false;
        [ObservableProperty] private bool _xml2HeaderError = false;
        [ObservableProperty] private bool _xml3HeaderError = false;
    }
}
