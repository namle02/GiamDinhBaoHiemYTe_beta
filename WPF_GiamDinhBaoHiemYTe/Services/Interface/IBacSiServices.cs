using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IBacSiServices
    {
        /// <summary>
        /// Lấy danh sách tất cả bác sĩ
        /// </summary>
        /// <returns>Danh sách bác sĩ</returns>
        Task<ApiResponse<List<BacSi>>> GetAllBacSi();

        /// <summary>
        /// Lấy thông tin bác sĩ theo mã bác sĩ
        /// </summary>
        /// <param name="maBacSi">Mã bác sĩ</param>
        /// <returns>Thông tin bác sĩ</returns>
        Task<ApiResponse<BacSi>> GetBacSiByMa(string maBacSi);

        /// <summary>
        /// Lấy thông tin bác sĩ theo ID
        /// </summary>
        /// <param name="id">ID bác sĩ</param>
        /// <returns>Thông tin bác sĩ</returns>
        Task<ApiResponse<BacSi>> GetBacSiById(int id);
    }
}
