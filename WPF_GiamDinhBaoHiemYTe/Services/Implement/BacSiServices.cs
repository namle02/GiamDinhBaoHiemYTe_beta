using System.Net.Http;
using System.Text.Json;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

// !+! = 2
namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class BacSiServices : IBacSiServices
    {
        private readonly HttpClient _httpClient;

        /// <summary>
        /// Hàm khởi tạo mặc định
        /// </summary>
        public BacSiServices(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        /// <summary>
        /// Lấy danh sách tất cả bác sĩ
        /// </summary>
        /// <returns>Danh sách bác sĩ</returns>
        public async Task<ApiResponse<List<BacSi>>> GetAllBacSi()
        {
            try
            {
                var response = await _httpClient.GetAsync("/api/doctor/");
                var result = JsonSerializer.Deserialize<ApiResponse<List<BacSi>>>(await response.Content.ReadAsStringAsync(), new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<List<BacSi>> { Success = false, Message = "Invalid response from server" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<List<BacSi>> 
                { 
                    Success = false, 
                    Message = $"Error retrieving doctors: {ex.Message}" 
                };
            }
        }

        /// <summary>
        /// Lấy thông tin bác sĩ theo mã bác sĩ
        /// </summary>
        /// <param name="maBacSi">Mã bác sĩ</param>
        /// <returns>Thông tin bác sĩ</returns>
        public async Task<ApiResponse<BacSi>> GetBacSiByMa(string maBacSi)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/doctor/{maBacSi}");
                var result = JsonSerializer.Deserialize<ApiResponse<BacSi>>(await response.Content.ReadAsStringAsync(), new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<BacSi> { Success = false, Message = "Invalid response from server" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<BacSi> 
                { 
                    Success = false, 
                    Message = $"Error retrieving doctor by code: {ex.Message}" 
                };
            }
        }

        /// <summary>
        /// Lấy thông tin bác sĩ theo ID
        /// </summary>
        /// <param name="id">ID bác sĩ</param>
        /// <returns>Thông tin bác sĩ</returns>
        public async Task<ApiResponse<BacSi>> GetBacSiById(int id)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/doctor/id/{id}");
                var result = JsonSerializer.Deserialize<ApiResponse<BacSi>>(await response.Content.ReadAsStringAsync(), new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<BacSi> { Success = false, Message = "Invalid response from server" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<BacSi> 
                { 
                    Success = false, 
                    Message = $"Error retrieving doctor by ID: {ex.Message}" 
                };
            }
        }
    }
}
