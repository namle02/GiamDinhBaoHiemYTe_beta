
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IApiServices
    {
        Task SendPatientData(PatientData patient);
    }
}
