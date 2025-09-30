using System.Net.Http;
using System.Text.Json;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class RuleServices : IRuleServices
    {
        private readonly HttpClient _httpClient;
        public RuleServices(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        /// <summary>
        /// Lấy tất cả các quy tắc từ API
        /// </summary>
        /// <returns></returns>
        public async Task<ApiResponse<List<RuleDto>>> GetAllRule()
        {
            try
            {
                var response = await _httpClient.GetAsync("/api/validate/rules");
                var result = JsonSerializer.Deserialize<ApiResponse<List<RuleDto>>>(await response.Content.ReadAsStringAsync(), new System.Text.Json.JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<List<RuleDto>> { Success = false, Message = "Invalid response from server" };
            }
            catch
            {
                throw;
            }
        }
    }
}
