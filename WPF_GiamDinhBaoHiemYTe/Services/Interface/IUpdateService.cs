namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IUpdateService
    {
        /// <summary>
        /// Kiểm tra có phiên bản mới không
        /// </summary>
        Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync();
        
        /// <summary>
        /// Download và cài đặt update
        /// </summary>
        Task<bool> DownloadAndInstallAsync(string downloadUrl, IProgress<int> progress);
        
        /// <summary>
        /// Lấy version hiện tại của app
        /// </summary>
        string GetCurrentVersion();
    }
}

