using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IPatientServices
    {
        Task<ApiResponse<ValidateData>> LoadPatientAndValidateData(string PatientId);

        Task<ApiResponse<PatientDto>> GetAllPatient();

    }
}
