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

        /// <summary>
        /// File lưu phiên bản đã cài (AppData). Ưu tiên đọc từ đây để app biết đúng phiên bản sau khi update.
        /// </summary>
        private static string GetInstalledVersionFilePath()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var dir = Path.Combine(appData, "GiamDinhBaoHiemYTe");
            return Path.Combine(dir, "installed_version.txt");
        }

        public UpdateService()
        {
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Add("User-Agent", "GiamDinhBaoHiemYTe");
        }

        public string GetCurrentVersion()
        {
            try
            {
                // Ưu tiên đọc phiên bản đã lưu (sau khi update, app restart sẽ biết đúng phiên bản mới)
                var versionFile = GetInstalledVersionFilePath();
                if (File.Exists(versionFile))
                {
                    var savedVersion = File.ReadAllText(versionFile)?.Trim();
                    if (!string.IsNullOrEmpty(savedVersion) && IsValidVersionString(savedVersion))
                        return savedVersion;
                }

                // Đọc trực tiếp từ file exe
                var exePath = Assembly.GetExecutingAssembly().Location;
                if (string.IsNullOrEmpty(exePath))
                {
                    exePath = Process.GetCurrentProcess().MainModule?.FileName;
                }
                
                if (!string.IsNullOrEmpty(exePath) && File.Exists(exePath))
                {
                    // Đọc từ FileVersionInfo để lấy version chính xác từ file
                    var fileVersionInfo = FileVersionInfo.GetVersionInfo(exePath);
                    if (!string.IsNullOrEmpty(fileVersionInfo.FileVersion))
                    {
                        // Parse version string (ví dụ: "1.0.9.0" -> "1.0.9")
                        var version = new Version(fileVersionInfo.FileVersion);
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
                }
                
                // Fallback: đọc từ Assembly (có thể là version cũ nếu assembly chưa reload)
                var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version;
                if (assemblyVersion != null)
                {
                    if (assemblyVersion.Revision > 0)
                    {
                        return $"{assemblyVersion.Major}.{assemblyVersion.Minor}.{assemblyVersion.Build}.{assemblyVersion.Revision}";
                    }
                    else if (assemblyVersion.Build > 0)
                    {
                        return $"{assemblyVersion.Major}.{assemblyVersion.Minor}.{assemblyVersion.Build}";
                    }
                    else
                    {
                        return $"{assemblyVersion.Major}.{assemblyVersion.Minor}";
                    }
                }
                
                return "1.0.0";
            }
            catch (Exception ex)
            {
                // Log error để debug
                System.Diagnostics.Debug.WriteLine($"Error getting version: {ex.Message}");
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

        public async Task<bool> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int> progress)
        {
            try
            {
                var tempPath = Path.GetTempPath();
                var zipPath = Path.Combine(tempPath, "update.zip");
                var extractPath = Path.Combine(tempPath, "update_extracted");

                // Lưu phiên bản đích trước khi update để sau khi app restart sẽ biết mình đang ở phiên bản mới
                if (!string.IsNullOrEmpty(targetVersion) && IsValidVersionString(targetVersion))
                {
                    try
                    {
                        var versionFile = GetInstalledVersionFilePath();
                        var dir = Path.GetDirectoryName(versionFile);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            Directory.CreateDirectory(dir);
                            File.WriteAllText(versionFile, targetVersion);
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"Could not save installed version file: {ex.Message}");
                    }
                }

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

                // Replace files using batch (version file đã lưu ở trên, app sau khi restart sẽ đọc được)
                await ReplaceApplicationFiles(extractPath);

                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error downloading/installing update: {ex.Message}");
                return false;
            }
        }

        private static bool IsValidVersionString(string version)
        {
            try
            {
                _ = new Version(version);
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
            var exeName = "WPF_GiamDinhBaoHiem.exe";
            
            // Xác định đúng thư mục cài đặt ứng dụng
            // Lấy đường dẫn từ process thực tế đang chạy
            var currentExePath = Process.GetCurrentProcess().MainModule?.FileName;
            if (string.IsNullOrEmpty(currentExePath))
            {
                currentExePath = Assembly.GetExecutingAssembly().Location;
            }
            
            var appPath = Path.GetDirectoryName(currentExePath);
            
            // Nếu đang chạy từ thư mục temp (.net extraction), cần tìm thư mục gốc
            // .NET single-file apps extract vào temp nhưng cần update vào thư mục gốc
            if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\"))
            {
                // Thử tìm thư mục cài đặt thực sự
                // Kiểm tra các vị trí thường gặp
                var possiblePaths = new[]
                {
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GiamDinhBaoHiemYTe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "GiamDinhBaoHiemYTe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "GiamDinhBaoHiemYTe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "GiamDinhBaoHiemYTe"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "GiamDinhBaoHiemYTe")
                };
                
                // Tìm thư mục nào có chứa file exe
                foreach (var possiblePath in possiblePaths)
                {
                    if (Directory.Exists(possiblePath))
                    {
                        var possibleExePath = Path.Combine(possiblePath, exeName);
                        if (File.Exists(possibleExePath))
                        {
                            appPath = possiblePath;
                            System.Diagnostics.Debug.WriteLine($"Found installation directory: {appPath}");
                            break;
                        }
                    }
                }
                
                // Nếu không tìm thấy, sử dụng AppData làm thư mục cài đặt mặc định
                if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\"))
                {
                    appPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GiamDinhBaoHiemYTe");
                    Directory.CreateDirectory(appPath);
                    System.Diagnostics.Debug.WriteLine($"Using default installation directory: {appPath}");
                }
            }
            
            if (string.IsNullOrEmpty(appPath))
            {
                appPath = AppDomain.CurrentDomain.BaseDirectory;
            }
            
            System.Diagnostics.Debug.WriteLine($"Update target directory: {appPath}");
            
            var exePath = Path.Combine(appPath, exeName);
            
            // Loại bỏ trailing backslash để tránh lỗi trong batch script
            appPath = appPath.TrimEnd('\\', '/');
            sourcePath = sourcePath.TrimEnd('\\', '/');
            
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
                    sourcePath = (exeDir ?? sourcePath).TrimEnd('\\', '/');
                }
            }

            var batchFile = Path.Combine(Path.GetTempPath(), $"update_{Guid.NewGuid():N}.bat");
            var tempPath = Path.GetTempPath();
            var zipPath = Path.Combine(tempPath, "update.zip");
            var extractPath = Path.Combine(tempPath, "update_extracted");

            // Kiểm tra xem có cần quyền admin không
            var needsAdmin = RequiresAdmin(appPath);
            var hasWriteAccess = CanWriteToDirectory(appPath);
            
            // Escape đường dẫn cho batch script (thay thế backslash và escape ký tự đặc biệt)
            var escapedAppPath = appPath.Replace("\"", "\"\"");
            var escapedSourcePath = sourcePath.Replace("\"", "\"\"");
            var escapedExePath = exePath.Replace("\"", "\"\"");
            
            var batchContent = $@"@echo off
title Update Application - {exeName}
color 0A
echo ================================================
echo   UPDATE APPLICATION - {exeName}
echo ================================================
echo.
echo Source: {escapedSourcePath}
echo Target: {escapedAppPath}
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
if not exist ""{escapedSourcePath}"" (
    echo ERROR: Source folder does not exist: {escapedSourcePath}
    pause
    exit /b 1
)

REM Delete old exe file first to ensure it can be replaced
if exist ""{escapedExePath}"" (
    echo Deleting old executable...
    del /F /Q ""{escapedExePath}"" 2>NUL
    timeout /t 1 /nobreak > nul
)

REM Copy all files from extracted folder to application folder using robocopy (more reliable)
echo.
echo Copying files from {escapedSourcePath} to {escapedAppPath}...
echo This may take a few moments...
robocopy ""{escapedSourcePath}"" ""{escapedAppPath}"" /E /IS /IT /R:3 /W:2 /NP /NFL /NDL
set copyResult=%ERRORLEVEL%
REM Robocopy return codes: 0-7 = success/warnings, 8+ = failure
if %copyResult% GEQ 8 (
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
) else if %copyResult% EQU 1 (
    echo Copy completed successfully
) else (
    echo Copy completed with warnings (error code: %copyResult%)
    echo Note: Error codes 0-7 usually indicate success with some warnings
)

REM Verify that the main exe file was copied
timeout /t 1 /nobreak > nul
if not exist ""{escapedExePath}"" (
    echo ERROR: Main executable was not copied!
    echo Expected location: {escapedExePath}
    pause
    exit /b 1
)
echo Verification: Main executable exists at {escapedExePath}

REM Clean up temp files
echo.
echo Cleaning up temporary files...
if exist ""{zipPath}"" del /F /Q ""{zipPath}""
if exist ""{extractPath}"" rmdir /S /Q ""{extractPath}""

REM Start the updated application
echo.
echo Starting updated application...
start """" /D ""{escapedAppPath}"" ""{escapedExePath}""

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

