using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class DM_BacSiVM : ObservableObject
    {
        private readonly IBacSiServices _bacSiServices;

        [ObservableProperty]
        private string searchText = string.Empty;

        [ObservableProperty]
        private BacSi? selectedBacSi;

        [ObservableProperty]
        private bool isLoading;

        [ObservableProperty]
        private string statusMessage = string.Empty;

        public DM_BacSiVM(IBacSiServices bacSiServices)
        {
            _bacSiServices = bacSiServices;
        }

        [RelayCommand]
        private async Task TimKiem()
        {
            if (string.IsNullOrWhiteSpace(SearchText))
            {
                StatusMessage = "Vui lòng nhập mã bác sĩ hoặc tên bác sĩ";
                return;
            }

            try
            {
                IsLoading = true;
                StatusMessage = "Đang tìm kiếm...";

                // Gọi API để lấy thông tin bác sĩ
                var response = await _bacSiServices.GetAllBacSi();
                
                if (response.Success && response.Data != null)
                {
                    // Tìm bác sĩ theo mã hoặc tên
                    var bacSi = response.Data.FirstOrDefault(bs => 
                        bs.MaBacSi?.Contains(SearchText, StringComparison.OrdinalIgnoreCase) == true ||
                        bs.HoTen?.Contains(SearchText, StringComparison.OrdinalIgnoreCase) == true);

                    if (bacSi != null)
                    {
                        SelectedBacSi = bacSi;
                        StatusMessage = $"Tìm thấy bác sĩ: {bacSi.HoTen}";
                    }
                    else
                    {
                        SelectedBacSi = null;
                        StatusMessage = "Không tìm thấy bác sĩ nào phù hợp";
                    }
                }
                else
                {
                    SelectedBacSi = null;
                    StatusMessage = response.Message ?? "Lỗi khi tải dữ liệu từ server";
                }
            }
            catch (Exception ex)
            {
                SelectedBacSi = null;
                StatusMessage = $"Lỗi: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        private async Task NhapExcel()
        {
            StatusMessage = "Tính năng nhập Excel đang được phát triển";
        }

        [RelayCommand]
        private async Task XuatExcel()
        {
            StatusMessage = "Tính năng xuất Excel đang được phát triển";
        }
    }
}
