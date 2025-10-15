using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public partial class CachedPatientInfo : ObservableObject
    {
        [ObservableProperty]
        private string patientId = string.Empty;

        [ObservableProperty]
        private string patientName = string.Empty;

        [ObservableProperty]
        private string gender = string.Empty;

        [ObservableProperty]
        private string birthYear = string.Empty;

        [ObservableProperty]
        private string errorCount = string.Empty;

        [ObservableProperty]
        private DateTime cachedTime;

        [ObservableProperty]
        private bool hasErrors;

        // Dữ liệu gốc
        public PatientData? PatientData { get; set; }
        public List<ValidationRule>? ValidationRules { get; set; }
    }
}
