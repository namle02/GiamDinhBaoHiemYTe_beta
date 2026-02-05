namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IUpdateService
    {
        /// <summary>
        /// Kiểm tra có phiên bản mới không
        /// </summary>
        Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync();
        
        /// <summary>
        /// Download và cài đặt update.
        /// targetVersion: phiên bản đang cài (để lưu lại, app sau khi restart sẽ biết mình đang ở phiên bản này).
        /// </summary>
        Task<bool> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int> progress);
        
        /// <summary>
        /// Lấy version hiện tại của app
        /// </summary>
        string GetCurrentVersion();
    }
}

