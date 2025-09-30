using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    public partial class PatientDto : ObservableObject
    {
        [ObservableProperty] private List<PatientData> patients = new List<PatientData>();
    }
}
