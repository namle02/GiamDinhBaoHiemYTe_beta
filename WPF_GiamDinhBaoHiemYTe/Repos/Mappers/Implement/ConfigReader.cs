using Newtonsoft.Json;
using System.Configuration;
using System.Net.Http;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Implement
{
    public class ConfigReader : IConfigReader
    {
        private readonly HttpClient _httpClient;
        public Dictionary<string, string> Config { get; private set; } = new();


        public ConfigReader(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task GetConfigFromSheet()
        {
            try
            {
             
                using var firstHttp = new HttpClient();
                
             
                
                string SheetUrl = ConfigurationManager.AppSettings["ConfigUrl"]!;
                var result = await firstHttp.GetAsync(SheetUrl);
                if (!result.IsSuccessStatusCode)
                    throw new Exception("Lỗi khi kết nối với máy chủ (Cannot read config)");

                string json = await result.Content.ReadAsStringAsync();
                var sheetData = JsonConvert.DeserializeObject<SheetConfigRaw>(json);

                Config = (sheetData?.values ?? new List<List<string>>())
                    .Where(row => row.Count >= 2 && !string.IsNullOrEmpty(row[0]))
                    .ToDictionary(row => row[0], row => row[1]);
                
                // Kiểm tra và set BaseAddress cho HttpClient
                if (Config.ContainsKey("Server_API_Local") && !string.IsNullOrWhiteSpace(Config["Server_API_Local"]))
                {
                    string serverApi = Config["Server_API_Local"].Trim();
                    // Đảm bảo URL có format đúng (có http:// hoặc https://)
                    if (!serverApi.EndsWith("/"))
                    {
                        serverApi += "/";
                    }
                    _httpClient.BaseAddress = new Uri(serverApi);
                    System.Diagnostics.Debug.WriteLine($"BaseAddress set to: {_httpClient.BaseAddress}");
                }
                else
                {
                    throw new Exception("Không tìm thấy cấu hình 'Server_API' trong Google Sheet hoặc giá trị rỗng!");
                }
                
            }
            catch (Exception ex)
            {
                string errorMessage = $"Lỗi khi đọc cấu hình từ Google Sheet: {ex.Message}";
                MessageBox.Show(errorMessage, "Lỗi cấu hình", MessageBoxButton.OK, MessageBoxImage.Error);
                System.Diagnostics.Debug.WriteLine(errorMessage);
                throw; // Re-throw để app biết có lỗi
            }
        }
    }

}

