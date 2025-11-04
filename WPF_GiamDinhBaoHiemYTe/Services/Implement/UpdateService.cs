using System;
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
            var exeName = "WPF_GiamDinhBaoHiem.exe";
            var exePath = Path.Combine(appPath, exeName);
            
            // Kiểm tra xem có file exe trong thư mục extract không
            var extractedExePath = Path.Combine(sourcePath, exeName);
            if (!File.Exists(extractedExePath))
            {
                // Nếu không có trong root, tìm trong các thư mục con (có thể do cấu trúc zip)
                var allExes = Directory.GetFiles(sourcePath, exeName, SearchOption.AllDirectories);
                if (allExes.Length > 0)
                {
                    // Nếu tìm thấy trong thư mục con, copy toàn bộ thư mục đó
                    var exeDir = Path.GetDirectoryName(allExes[0]);
                    sourcePath = exeDir ?? sourcePath;
                }
            }

            var batchFile = Path.Combine(Path.GetTempPath(), $"update_{Guid.NewGuid():N}.bat");
            var tempPath = Path.GetTempPath();
            var zipPath = Path.Combine(tempPath, "update.zip");
            var extractPath = Path.Combine(tempPath, "update_extracted");

            var batchContent = $@"@echo off
echo Waiting for application to close...
:wait
tasklist /FI ""IMAGENAME eq {exeName}"" 2>NUL | find /I /N ""{exeName}"">NUL
if ""%ERRORLEVEL%""==""0"" (
    timeout /t 1 /nobreak > nul
    goto wait
)
echo Application closed, starting update...
timeout /t 2 /nobreak > nul

REM Copy all files from extracted folder to application folder
echo Copying files...
xcopy ""{sourcePath}\*"" ""{appPath}"" /E /Y /I /H /R
if %ERRORLEVEL% NEQ 0 (
    echo Copy failed with error code %ERRORLEVEL%
    pause
    exit /b 1
)

REM Verify that the main exe file was copied
if not exist ""{exePath}"" (
    echo ERROR: Main executable was not copied!
    pause
    exit /b 1
)

REM Clean up temp files
echo Cleaning up temporary files...
if exist ""{zipPath}"" del /F /Q ""{zipPath}""
if exist ""{extractPath}"" rmdir /S /Q ""{extractPath}""

REM Start the updated application
echo Starting updated application...
start """" /D ""{appPath}"" ""{exePath}""

REM Clean up batch file
timeout /t 1 /nobreak > nul
del ""%~f0""
echo Update completed!
";
            await File.WriteAllTextAsync(batchFile, batchContent);

            // Tạo process với quyền admin để đảm bảo có thể replace files
            var processInfo = new ProcessStartInfo
            {
                FileName = batchFile,
                CreateNoWindow = false, // Hiển thị để debug
                UseShellExecute = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            Process.Start(processInfo);

            // Đóng tất cả resources trước khi shutdown
            GC.Collect();
            GC.WaitForPendingFinalizers();
            
            // Đợi một chút để đảm bảo batch file đã được tạo và chạy
            await Task.Delay(500);
            
            Application.Current.Shutdown();
        }
    }
}

