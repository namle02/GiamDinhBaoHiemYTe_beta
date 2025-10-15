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
                _httpClient.BaseAddress = new Uri($"{Config["Server_API"]}");
                
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }
    }

}

