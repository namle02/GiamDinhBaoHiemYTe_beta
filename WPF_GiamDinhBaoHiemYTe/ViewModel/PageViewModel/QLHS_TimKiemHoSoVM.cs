using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using System.Linq;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class QLHS_TimKiemHoSoVM : ObservableObject
    {
        private readonly IPatientServices _patientServices;
        private readonly IDataMapper _dataMapper;

        [ObservableProperty]
        private bool isLoading;

        [ObservableProperty]
        private string patientID = string.Empty;

        [ObservableProperty]
        private ObservableCollection<PatientValidationResult> validationResults = new();

        public QLHS_TimKiemHoSoVM(IPatientServices patientServices, IDataMapper dataMapper)
        {
            _patientServices = patientServices;
            _dataMapper = dataMapper;
        }

        [RelayCommand]
        private async Task Search(string patientId)
        {
            if (string.IsNullOrWhiteSpace(patientId))
                return;

            try
            {
                IsLoading = true;
                ValidationResults.Clear();

                // Lấy dữ liệu bệnh nhân từ DB
                var patientData = await _dataMapper.GetDataFromDB(patientId);
                
                // Gọi API validate
                var apiResponse = await _patientServices.LoadPatientAndValidateData(patientId);

                // Kiểm tra kết quả
                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    var validateData = apiResponse.Data;
                    
                    // Lấy thông tin XML1 - CHỈ LẤY RECORD ĐẦU TIÊN hoặc khớp với patientId
                    if (patientData?.Xml1 != null && patientData.Xml1.Count > 0)
                    {
                        // Tìm record khớp với patientId hoặc lấy record đầu tiên
                        var xml1 = patientData.Xml1.FirstOrDefault(x => 
                            x.Ma_Lk?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true ||
                            x.Ma_Bn?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true
                        ) ?? patientData.Xml1[0];

                        // Tạo string tổng hợp các lỗi
                        var errorMessages = new List<string>();
                        
                        if (validateData.ValidationResults != null)
                        {
                            foreach (var rule in validateData.ValidationResults)
                            {
                                if (!rule.IsValid)
                                {
                                    errorMessages.Add($"• {rule.RuleName}");
                                }
                            }
                        }

                        var result = new PatientValidationResult
                        {
                            Ma_Lk = xml1.Ma_Lk ?? "",
                            Ho_Ten = xml1.Ho_Ten ?? "",
                            Gioi_Tinh = xml1.Gioi_Tinh == 1 ? "Nam" : (xml1.Gioi_Tinh == 2 ? "Nữ" : "Khác"),
                            Nam_Sinh = xml1.Ngay_Sinh ?? "",
                            Noi_Dung_Loi = errorMessages.Count > 0 
                                ? string.Join("\n", errorMessages) 
                                : "Không có lỗi",
                            ValidationRules = validateData.ValidationResults
                        };

                        ValidationResults.Add(result);
                    }
                }
            }
            catch (Exception ex)
            {
                // Log hoặc hiển thị lỗi
                System.Diagnostics.Debug.WriteLine($"Error: {ex.Message}");
            }
            finally
            {
                IsLoading = false;
            }
        }
    }

    // Model kết hợp để hiển thị trong DataGrid
    public partial class PatientValidationResult : ObservableObject
    {
        [ObservableProperty]
        private string ma_Lk = string.Empty;

        [ObservableProperty]
        private string ho_Ten = string.Empty;

        [ObservableProperty]
        private string gioi_Tinh = string.Empty;

        [ObservableProperty]
        private string nam_Sinh = string.Empty;

        [ObservableProperty]
        private string noi_Dung_Loi = string.Empty;

        // Lưu danh sách ValidationRule để dùng cho overlay chi tiết
        public List<ValidationRule>? ValidationRules { get; set; }
    }
}
