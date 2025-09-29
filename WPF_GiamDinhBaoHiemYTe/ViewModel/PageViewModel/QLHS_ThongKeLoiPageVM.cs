using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;
using System.ComponentModel;
using System.Windows.Data;
using System.Globalization;
using System.Text;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class QLHS_ThongKeLoiPageVM : ObservableObject
    {
        private readonly IGoogleSheetService _googleSheetService;

        [ObservableProperty] private ObservableCollection<ErrorItem> errorList = new();
        [ObservableProperty] private string statusText = string.Empty;
        [ObservableProperty] private bool isLoading;
        [ObservableProperty] private string errorSearchText = string.Empty;
        [ObservableProperty] private ICollectionView? errorListView;

        public QLHS_ThongKeLoiPageVM(IGoogleSheetService googleSheetService)
        {
            _googleSheetService = googleSheetService;

            
            _ = LoadErrorsAsync();
        }

        [RelayCommand]
        public async Task LoadErrorsAsync()
        {
            try
            {
                IsLoading = true;
                StatusText = "Đang tải dữ liệu từ Google Sheet...";
                var list = await _googleSheetService.GetErrorListAsync();
                ErrorList = new ObservableCollection<ErrorItem>(list);
                ErrorListView = CollectionViewSource.GetDefaultView(ErrorList);
                if (ErrorListView != null)
                    ErrorListView.Filter = OnFilterError;
                StatusText = $"Đã tải {ErrorList.Count} dòng.";
            }
            catch (Exception ex)
            {
                StatusText = $"Lỗi khi tải: {ex.Message}";
            }
            finally
            {
                IsLoading = false;
            }
        }

        partial void OnErrorSearchTextChanged(string value)
        {
            ErrorListView?.Refresh();
        }

        private bool OnFilterError(object obj)
        {
            if (obj is not ErrorItem item) return false;
            if (string.IsNullOrWhiteSpace(ErrorSearchText)) return true;

            var term = NormalizeText(ErrorSearchText.Trim());
            var combined = $"{item.NoiDung} {item.MaLyDoTuChoi} {item.MaChuyenDe} {item.MaCoSoKCB} {item.Stt}";
            var haystack = NormalizeText(combined);
            return haystack.Contains(term);
        }

        private static string NormalizeText(string? input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            var normalized = input.Normalize(NormalizationForm.FormD);
            var sb = new StringBuilder(normalized.Length);
            foreach (var c in normalized)
            {
                var cat = CharUnicodeInfo.GetUnicodeCategory(c);
                if (cat != UnicodeCategory.NonSpacingMark)
                    sb.Append(char.ToLowerInvariant(c));
            }
            return sb.ToString().Normalize(NormalizationForm.FormC);
        }
    }
}
