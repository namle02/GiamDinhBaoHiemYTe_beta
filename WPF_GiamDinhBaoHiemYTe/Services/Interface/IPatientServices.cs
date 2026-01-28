using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IPatientServices
    {
        Task<ApiResponse<ValidateData>> LoadPatientAndValidateData(string PatientId);

        Task<ApiResponse<PatientDto>> GetAllPatient();

        /// <summary>
        /// Lấy danh sách bệnh nhân lỗi mã máy
        /// </summary>
        /// <returns>Danh sách bệnh nhân lỗi mã máy</returns>
        Task<List<BenhNhanLoiMaMayResult>> GetDsBenhNhanLoiMaMay();

    }
}
