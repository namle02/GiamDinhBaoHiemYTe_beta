using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using System.Net.Sockets;
using System.Text;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class ApiServices : IApiServices
    {
        private readonly HttpClient _httpClient;

        public ApiServices(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task SendPatientData(PatientData patient)
        {
            try
            {
                // 1. Serialize object thành JSON string với cài đặt để đảm bảo tính nhất quán
                var jsonSettings = new JsonSerializerSettings
                {
                    NullValueHandling = NullValueHandling.Include,
                    DateFormatHandling = DateFormatHandling.IsoDateFormat
                };
                var json = JsonConvert.SerializeObject(patient, jsonSettings);

                // 2. Bọc vào StringContent với Content-Type: application/json
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                // 3. Gửi POST tới endpoint (kèm retry khi server đang restart/không lắng nghe)
                HttpResponseMessage? response = null;
                const int maxAttempts = 3;
                for (int attempt = 1; attempt <= maxAttempts; attempt++)
                {
                    try
                    {
                        response = await _httpClient.PostAsync("api/patient/", content);
                        break; // thành công -> thoát vòng lặp
                    }
                    catch (HttpRequestException ex) when (ex.InnerException is SocketException se &&
                                                         (se.SocketErrorCode == SocketError.ConnectionRefused ||
                                                          se.SocketErrorCode == SocketError.TimedOut))
                    {
                        if (attempt == maxAttempts) throw; 
                        System.Diagnostics.Debug.WriteLine($"Backend chưa sẵn sàng (attempt {attempt}), sẽ thử lại...");
                        await Task.Delay(TimeSpan.FromMilliseconds(400 * attempt));
                    }
                }

                // 4. Xử lý response
                if (response != null && response.IsSuccessStatusCode)
                {
                    var responseContent = await response!.Content.ReadAsStringAsync();
                    MessageBox.Show(responseContent);
                   
                    // Log hoặc xử lý response thành công
                    System.Diagnostics.Debug.WriteLine($"Patient data sent successfully: {responseContent}");
                }
                else
                {
                    var errorContent = response == null
                        ? "No response"
                        : await response.Content.ReadAsStringAsync();
                    System.Diagnostics.Debug.WriteLine($"Error sending patient data: {response.StatusCode} - {errorContent}");
                    throw new HttpRequestException($"API call failed: {response.StatusCode} - {errorContent}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Exception sending patient data: {ex.Message}");
                throw;
            }
        }
    }
}
