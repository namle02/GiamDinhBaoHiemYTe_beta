using System;
using System.IO;
using System.IO.Compression;
using System.Net.Http;
using System.Text.Json;
using System.Diagnostics;
using System.Reflection;
using System.Windows;
using System.Security.Principal;
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
            try
            {
                var version = Assembly.GetExecutingAssembly().GetName().Version;
                if (version == null)
                {
                    // Fallback: đọc từ file version info
                    var fileVersionInfo = FileVersionInfo.GetVersionInfo(Assembly.GetExecutingAssembly().Location);
                    return fileVersionInfo.FileVersion ?? "1.0.0";
                }
                
                // Hiển thị version đầy đủ, bao gồm Revision nếu > 0
                if (version.Revision > 0)
                {
                    return $"{version.Major}.{version.Minor}.{version.Build}.{version.Revision}";
                }
                else if (version.Build > 0)
                {
                    return $"{version.Major}.{version.Minor}.{version.Build}";
                }
                else
                {
                    return $"{version.Major}.{version.Minor}";
                }
            }
            catch
            {
                // Fallback nếu không đọc được version
                return "1.0.0";
            }
        }

        public async Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync()
        {
            try
            {
                var response = await _httpClient.GetStringAsync(GITHUB_API_URL);
                var release = JsonSerializer.Deserialize<GitHubRelease>(response);

                if (release == null)
                    return (false, "", "", "");

                var latestVersion = release.tag_name?.TrimStart('v') ?? "";
                var currentVersion = GetCurrentVersion();
                var hasUpdate = IsNewerVersion(currentVersion, latestVersion);

                var zipAsset = release.assets?.FirstOrDefault(a => a.name.EndsWith(".zip"));
                var downloadUrl = zipAsset?.browser_download_url ?? "";
                var releaseNotes = release.body ?? "";

                return (hasUpdate, latestVersion, downloadUrl, releaseNotes);
            }
            catch (Exception ex)
            {
                // Log error để debug
                System.Diagnostics.Debug.WriteLine($"Error checking for updates: {ex.Message}");
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
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error downloading/installing update: {ex.Message}");
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

        private bool RequiresAdmin(string appPath)
        {
            try
            {
                // Kiểm tra xem đường dẫn có nằm trong Program Files không
                var programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                var programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
                
                return appPath.StartsWith(programFiles, StringComparison.OrdinalIgnoreCase) ||
                       appPath.StartsWith(programFilesX86, StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        private bool CanWriteToDirectory(string directoryPath)
        {
            try
            {
                var testFile = Path.Combine(directoryPath, $"test_write_{Guid.NewGuid():N}.tmp");
                File.WriteAllText(testFile, "test");
                File.Delete(testFile);
                return true;
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

            // Kiểm tra xem có cần quyền admin không
            var needsAdmin = RequiresAdmin(appPath);
            var hasWriteAccess = CanWriteToDirectory(appPath);
            
            var batchContent = $@"@echo off
title Update Application - {exeName}
color 0A
echo ================================================
echo   UPDATE APPLICATION - {exeName}
echo ================================================
echo.
echo Source: {sourcePath}
echo Target: {appPath}
echo.

echo Waiting for application to close...
:wait
tasklist /FI ""IMAGENAME eq {exeName}"" 2>NUL | find /I /N ""{exeName}"">NUL
if ""%ERRORLEVEL%""==""0"" (
    echo Process still running, waiting...
    timeout /t 2 /nobreak > nul
    goto wait
)
echo Application closed, forcing cleanup...
timeout /t 2 /nobreak > nul

REM Force kill any remaining processes (just in case)
taskkill /F /IM ""{exeName}"" 2>NUL
timeout /t 2 /nobreak > nul

REM Kiểm tra xem thư mục source có tồn tại không
if not exist ""{sourcePath}"" (
    echo ERROR: Source folder does not exist: {sourcePath}
    pause
    exit /b 1
)

REM Delete old exe file first to ensure it can be replaced
if exist ""{exePath}"" (
    echo Deleting old executable...
    del /F /Q ""{exePath}"" 2>NUL
    timeout /t 1 /nobreak > nul
)

REM Copy all files from extracted folder to application folder using robocopy (more reliable)
echo.
echo Copying files from {sourcePath} to {appPath}...
echo This may take a few moments...
robocopy ""{sourcePath}"" ""{appPath}"" /E /IS /IT /R:3 /W:2 /NP /NFL /NDL
set copyResult=%ERRORLEVEL%
if %copyResult% GTR 1 (
    echo Copy completed with warnings (error code: %copyResult%)
) else if %copyResult% EQU 1 (
    echo Copy completed successfully
) else (
    echo.
    echo ERROR: Copy failed with error code %copyResult%
    echo This may be due to insufficient permissions.
    echo.
    echo If you see this error, please try:
    echo 1. Run the application as Administrator, or
    echo 2. Ensure you have write permissions to the application folder
    echo.
    pause
    exit /b 1
)

REM Verify that the main exe file was copied
timeout /t 1 /nobreak > nul
if not exist ""{exePath}"" (
    echo ERROR: Main executable was not copied!
    echo Expected location: {exePath}
    pause
    exit /b 1
)
echo Verification: Main executable exists at {exePath}

REM Clean up temp files
echo.
echo Cleaning up temporary files...
if exist ""{zipPath}"" del /F /Q ""{zipPath}""
if exist ""{extractPath}"" rmdir /S /Q ""{extractPath}""

REM Start the updated application
echo.
echo Starting updated application...
start """" /D ""{appPath}"" ""{exePath}""

REM Clean up batch file
timeout /t 2 /nobreak > nul
echo.
echo ================================================
echo   UPDATE COMPLETED SUCCESSFULLY!
echo ================================================
timeout /t 3 /nobreak > nul
del ""%~f0""
";
            await File.WriteAllTextAsync(batchFile, batchContent);

            // Kiểm tra xem batch file đã được tạo thành công
            if (!File.Exists(batchFile))
            {
                System.Diagnostics.Debug.WriteLine("ERROR: Failed to create batch file!");
                return;
            }

            ProcessStartInfo processInfo;
            
            // Chỉ yêu cầu admin nếu thực sự cần thiết
            if (needsAdmin && !hasWriteAccess)
            {
                // Tạo PowerShell script để chạy batch với quyền admin
                var psScript = Path.Combine(Path.GetTempPath(), $"update_{Guid.NewGuid():N}.ps1");
                var psContent = $@"
Start-Process -FilePath '{batchFile}' -Verb RunAs -Wait
";
                await File.WriteAllTextAsync(psScript, psContent);

                processInfo = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -File \"{psScript}\"",
                    CreateNoWindow = false,
                    UseShellExecute = true,
                    WindowStyle = ProcessWindowStyle.Normal
                };
            }
            else
            {
                // Chạy batch script trực tiếp không cần admin
                processInfo = new ProcessStartInfo
                {
                    FileName = batchFile,
                    CreateNoWindow = false,
                    UseShellExecute = true,
                    WindowStyle = ProcessWindowStyle.Normal
                };
            }

            System.Diagnostics.Debug.WriteLine($"Starting update batch script: {batchFile}");
            System.Diagnostics.Debug.WriteLine($"Source path: {sourcePath}");
            System.Diagnostics.Debug.WriteLine($"App path: {appPath}");
            System.Diagnostics.Debug.WriteLine($"Needs admin: {needsAdmin}, Has write access: {hasWriteAccess}");
            
            if (needsAdmin && !hasWriteAccess)
            {
                System.Diagnostics.Debug.WriteLine("Requesting admin privileges for update...");
            }
            else
            {
                System.Diagnostics.Debug.WriteLine("Updating without admin privileges...");
            }

            var process = Process.Start(processInfo);

            // Đợi một chút để đảm bảo batch file đã được tạo và chạy
            await Task.Delay(1000);
            
            // Đóng tất cả resources trước khi shutdown
            _httpClient?.Dispose();
            GC.Collect();
            GC.WaitForPendingFinalizers();
            
            // Shutdown application sau khi batch đã bắt đầu
            Application.Current?.Dispatcher.Invoke(() =>
            {
                Application.Current.Shutdown();
            });
        }
    }
}

