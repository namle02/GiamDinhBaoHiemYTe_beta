using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class QTHT_CapNhatVM : ObservableObject
    {
        private readonly IUpdateService _updateService;

        [ObservableProperty] private string currentVersion;
        [ObservableProperty] private string latestVersion;
        [ObservableProperty] private string releaseNotes;
        [ObservableProperty] private string downloadUrl;
        [ObservableProperty] private bool hasUpdate;
        [ObservableProperty] private bool isChecking;
        [ObservableProperty] private bool isDownloading;
        [ObservableProperty] private int downloadProgress;
        [ObservableProperty] private string statusMessage;

        public QTHT_CapNhatVM(IUpdateService updateService)
        {
            _updateService = updateService;
            CurrentVersion = _updateService.GetCurrentVersion();
            StatusMessage = "Nhấn 'Kiểm tra cập nhật' để bắt đầu";
        }

        [RelayCommand]
        public async Task CheckForUpdates()
        {
            IsChecking = true;
            StatusMessage = "Đang kiểm tra phiên bản mới...";

            var (hasUpdate, latestVersion, downloadUrl, releaseNotes) = await _updateService.CheckForUpdatesAsync();

            HasUpdate = hasUpdate;
            LatestVersion = latestVersion;
            DownloadUrl = downloadUrl;
            ReleaseNotes = releaseNotes;

            if (hasUpdate)
            {
                StatusMessage = $"🎉 Đã có phiên bản mới v{latestVersion}!";
            }
            else
            {
                StatusMessage = "✅ Bạn đang sử dụng phiên bản mới nhất";
            }

            IsChecking = false;
        }

        [RelayCommand]
        public async Task DownloadAndInstall()
        {
            if (string.IsNullOrEmpty(DownloadUrl))
                return;

            IsDownloading = true;
            StatusMessage = "Đang tải xuống cập nhật...";

            var progress = new Progress<int>(percent =>
            {
                DownloadProgress = percent;
                StatusMessage = $"Đang tải xuống... {percent}%";
            });

            var success = await _updateService.DownloadAndInstallAsync(DownloadUrl, progress);

            if (!success)
            {
                StatusMessage = "❌ Có lỗi khi cập nhật. Vui lòng thử lại.";
                IsDownloading = false;
            }
            // Nếu success, app sẽ tự động tắt và restart
        }
    }
}

