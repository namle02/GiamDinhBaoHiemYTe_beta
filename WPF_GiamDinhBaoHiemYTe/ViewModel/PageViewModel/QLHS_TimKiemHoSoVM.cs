using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class QLHS_TimKiemHoSoVM : ObservableObject
    {
        private readonly IPatientServices _patientServices;

        public QLHS_TimKiemHoSoVM(IPatientServices patientServices)
        {
            _patientServices = patientServices; 
        }

        [RelayCommand]
        private async Task Search(string patientId)
        {

           var a =  await _patientServices.LoadPatientAndValidateData(patientId);
        }
    }
}
