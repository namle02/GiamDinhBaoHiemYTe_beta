using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class QLHS_TimKiemHoSoVM : ObservableObject
    {
        private readonly IDataMapper _dataMapper;
        private readonly IApiServices _apiServices;

        private const int BasePageSize = 20;
        private int _take = BasePageSize;

      
        private DateTime _cursorNgayVao = DateTime.Today.AddDays(1).AddTicks(-1);

        [ObservableProperty] private bool isLoading;
        [ObservableProperty] private bool isBrowseRecentMode = true;  
        [ObservableProperty] private bool hasMore = true;

        [ObservableProperty] private string patientID = string.Empty;

        // Danh sách hồ sơ (đã hydrate XML1..XML15)
        public ObservableCollection<PatientData> Patients { get; } = new();

        // Item đang chọn
        [ObservableProperty] private PatientData? selectedPatient;

        public QLHS_TimKiemHoSoVM(IDataMapper dataMapper, IApiServices apiServices)
        {
            _dataMapper = dataMapper;
            _apiServices = apiServices;

            // Load GoogleSheet ngay khi khởi tạo
            _ = LoadGoogleSheetAsync();
        }

        // Load danh sách lỗi từ GoogleSheet
        private async Task LoadGoogleSheetAsync()
        {
            try
            {
                // Gọi GoogleSheetService để load danh sách lỗi
                var errorList = await _dataMapper.GetErrorListFromGoogleSheetAsync();
                // Có thể lưu vào một property để sử dụng sau này
                // ErrorList = errorList;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Load GoogleSheet error: {ex.Message}");
            }
        }

    
        private static DateTime? TryParseNgayVaoKey(string? key)
        {
            if (string.IsNullOrWhiteSpace(key)) return null;

            string[] formats = { "yyyyMMddHHmm", "yyyyMMdd" };
            if (DateTime.TryParseExact(key, formats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dt))
                return dt;

            return null;
        }

        // ===== Reset & load trang đầu (duyệt gần đây)
        private async Task LoadRecentInitialAsync()
        {
            // Tạm thời tắt chức năng browse recent mode
            IsBrowseRecentMode = false;
            HasMore = false;

            _take = BasePageSize;
            _cursorNgayVao = DateTime.Today.AddDays(1).AddTicks(-1);

            await ReloadAsync(clear: true);

            // TODO: Implement lại logic browse recent khi có method mới
        }

        // ===== Load 1 page theo _cursorNgayVao
        private async Task ReloadAsync(bool clear = false)
        {
            if (IsLoading) return;
            IsLoading = true;
            try
            {
             
                HasMore = false;
                IsBrowseRecentMode = false;

                if (clear)
                {
                    Patients.Clear();
                    SelectedPatient = null;
                }

            }
            finally
            {
                IsLoading = false;
            }
        }

        // ===== Tra cứu theo ID (1 hồ sơ đầy đủ)
        [RelayCommand]
        private async Task TraCuuHoSo()
        {
            var input = PatientID?.Trim();
            if (string.IsNullOrEmpty(input))
            {
                await LoadRecentInitialAsync();
                return;
            }

            IsBrowseRecentMode = false; // tắt scroll khi tra cứu đơn lẻ
            HasMore = false;
            Patients.Clear();
            SelectedPatient = null;

            var result = await _dataMapper.GetDataFromDB(input);
            await _apiServices.SendPatientData(result);
            if (result != null)
            {
                Patients.Add(result);
                SelectedPatient = result;
            }
        }

       
    }
}
