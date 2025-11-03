using System.IO;
using System.IO.Compression;
using System.Net.Http;
using System.Text.Json;
using System.Diagnostics;
using System.Reflection;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class UpdateService : IUpdateService
    {
        private readonly HttpClient _httpClient;
        private const string GITHUB_API_URL = "https://api.github.com/repos/namle02/GiamDinhBaoHiemYTe_beta/releases/latest";

        public UpdateService()
        {
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Add("User-Agent", "GiamDinhBaoHiemYTe");
        }

        public string GetCurrentVersion()
        {
            var version = Assembly.GetExecutingAssembly().GetName().Version;
            return $"{version.Major}.{version.Minor}.{version.Build}";
        }

        public async Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync()
        {
            try
            {
                var response = await _httpClient.GetStringAsync(GITHUB_API_URL);
                var release = JsonSerializer.Deserialize<GitHubRelease>(response);

                var latestVersion = release.tag_name.TrimStart('v');
                var currentVersion = GetCurrentVersion();
                var hasUpdate = IsNewerVersion(currentVersion, latestVersion);

                var zipAsset = release.assets.FirstOrDefault(a => a.name.EndsWith(".zip"));
                var downloadUrl = zipAsset?.browser_download_url ?? "";
                var releaseNotes = release.body ?? "";

                return (hasUpdate, latestVersion, downloadUrl, releaseNotes);
            }
            catch
            {
                return (false, "", "", "");
            }
        }

        public async Task<bool> DownloadAndInstallAsync(string downloadUrl, IProgress<int> progress)
        {
            try
            {
                var tempPath = Path.GetTempPath();
                var zipPath = Path.Combine(tempPath, "update.zip");
                var extractPath = Path.Combine(tempPath, "update_extracted");

                // Download
                using (var response = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    response.EnsureSuccessStatusCode();
                    var totalBytes = response.Content.Headers.ContentLength ?? -1L;

                    using (var contentStream = await response.Content.ReadAsStreamAsync())
                    using (var fileStream = new FileStream(zipPath, FileMode.Create))
                    {
                        var buffer = new byte[8192];
                        var totalRead = 0L;
                        int bytesRead;

                        while ((bytesRead = await contentStream.ReadAsync(buffer, 0, buffer.Length)) != 0)
                        {
                            await fileStream.WriteAsync(buffer, 0, bytesRead);
                            totalRead += bytesRead;

                            if (totalBytes != -1)
                            {
                                progress?.Report((int)((totalRead * 100) / totalBytes));
                            }
                        }
                    }
                }

                // Extract
                if (Directory.Exists(extractPath))
                    Directory.Delete(extractPath, true);
                
                ZipFile.ExtractToDirectory(zipPath, extractPath);

                // Replace files using batch
                await ReplaceApplicationFiles(extractPath);

                return true;
            }
            catch
            {
                return false;
            }
        }

        private bool IsNewerVersion(string current, string latest)
        {
            try
            {
                return new Version(latest) > new Version(current);
            }
            catch
            {
                return false;
            }
        }

        private async Task ReplaceApplicationFiles(string sourcePath)
        {
            var appPath = AppDomain.CurrentDomain.BaseDirectory;
            var batchFile = Path.Combine(Path.GetTempPath(), "update.bat");

            var batchContent = $@"
@echo off
timeout /t 2 /nobreak > nul
xcopy ""{sourcePath}\*"" ""{appPath}"" /E /Y /I
start """" ""{Path.Combine(appPath, "WPF_GiamDinhBaoHiem.exe")}""
del ""%~f0""
";
            await File.WriteAllTextAsync(batchFile, batchContent);

            Process.Start(new ProcessStartInfo
            {
                FileName = batchFile,
                CreateNoWindow = true,
                UseShellExecute = true
            });

            Application.Current.Shutdown();
        }
    }
}

