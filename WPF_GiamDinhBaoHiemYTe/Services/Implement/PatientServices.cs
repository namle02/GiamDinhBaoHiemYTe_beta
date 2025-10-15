using System.Net.Http;
using System.Text.Json;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class PatientServices : IPatientServices
    {
        private readonly IDataMapper _dataMapper;
        private readonly HttpClient _httpClient;
        private readonly IConfigReader _configReader;


       
        public PatientServices(IDataMapper dataMapper, HttpClient httpClient, IConfigReader configReader)
        {
            _dataMapper = dataMapper;
            _httpClient = httpClient;
            _configReader = configReader;
        }

      
        public async Task<ApiResponse<ValidateData>> LoadPatientAndValidateData(string PatientId)
        {
            try
            {
                // Lấy dữ liệu bệnh nhân từ cơ sở dữ liệu
                var patientData = await _dataMapper.GetDataFromDB(PatientId);

                // Gửi dữ liệu bệnh nhân đến API để kiểm tra điều kiện
                var json = JsonSerializer.Serialize(patientData);
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("/api/patient", content);
                var a = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<ApiResponse<ValidateData>>(a, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<ValidateData> { Success = false, Message = "Invalid response from server" };
            }
            catch(Exception ex)
            {
                MessageBox.Show(ex. Message);
                throw;
            }

        }

      
        public async Task<ApiResponse<PatientDto>> GetAllPatient()
        {
            try
            {
                var response = await _httpClient.GetAsync("/api/patient");
                var result = JsonSerializer.Deserialize<ApiResponse<PatientDto>>(await response.Content.ReadAsStringAsync(), new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return result ?? new ApiResponse<PatientDto> { Success = false, Message = "Invalid response from server" };
            }
            catch
            {
                throw;
            }
        }

    }
}
