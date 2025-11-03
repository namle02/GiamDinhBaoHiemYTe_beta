using System.Net.Http;
using System.Text.Json;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class RuleServices : IRuleServices
    {
        private readonly HttpClient _httpClient;
        private List<RuleDto> _cachedRules = new List<RuleDto>();
        private bool _isLoaded = false;

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
            catch (JsonException)
            {
                // Lỗi khi parse JSON - thường xảy ra khi server tắt hoặc trả về không phải JSON
                MessageBox.Show("Server hiện đang bảo trì", "Thông báo", MessageBoxButton.OK, MessageBoxImage.Warning);
                return new ApiResponse<List<RuleDto>> 
                { 
                    Success = false, 
                    Message = "Server hiện đang bảo trì" 
                };
            }
            catch (Exception ex)
            {
                // Các lỗi khác (network, timeout, v.v.)
                MessageBox.Show("Lỗi server vui lòng liên hệ kĩ thuật", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return new ApiResponse<List<RuleDto>> 
                { 
                    Success = false, 
                    Message = "Lỗi server vui lòng liên hệ kĩ thuật" 
                };
            }
        }

        /// <summary>
        /// Tải danh sách rules từ API và cache vào bộ nhớ
        /// </summary>
        public async Task LoadRulesAsync()
        {
            if (_isLoaded) return; // Đã load rồi thì không load lại

            var response = await GetAllRule();
            if (response.Success && response.Data != null)
            {
                _cachedRules = response.Data;
                _isLoaded = true;
            }
        }

        /// <summary>
        /// Lấy danh sách rules từ cache (không cần gọi API)
        /// </summary>
        public List<RuleDto> GetCachedRules()
        {
            return _cachedRules;
        }
    }
}
