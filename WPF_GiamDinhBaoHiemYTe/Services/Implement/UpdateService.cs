using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
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

        /// <summary>
        /// Thư mục chứa exe đang chạy (để đọc version.txt trong zip release).
        /// </summary>
        private static string GetAppDirectory()
        {
            try
            {
                var exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (string.IsNullOrEmpty(exePath))
                    exePath = Assembly.GetExecutingAssembly().Location;
                if (string.IsNullOrEmpty(exePath))
                    return AppDomain.CurrentDomain.BaseDirectory ?? "";
                var dir = Path.GetDirectoryName(exePath);
                return dir ?? AppDomain.CurrentDomain.BaseDirectory ?? "";
            }
            catch
            {
                return AppDomain.CurrentDomain.BaseDirectory ?? "";
            }
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
                var candidates = new List<string>();

                // 1) Phiên bản đã lưu (AppData, sau khi cập nhật trong app)
                var installedFile = GetInstalledVersionFilePath();
                if (File.Exists(installedFile))
                {
                    var savedVersion = File.ReadAllText(installedFile)?.Trim();
                    if (!string.IsNullOrEmpty(savedVersion) && IsValidVersionString(savedVersion))
                        candidates.Add(savedVersion);
                }

                // 2) version.txt trong thư mục app (có trong zip release)
                var appDir = GetAppDirectory();
                if (!string.IsNullOrEmpty(appDir))
                {
                    var versionTxtPath = Path.Combine(appDir, "version.txt");
                    if (File.Exists(versionTxtPath))
                    {
                        var versionFromFile = File.ReadAllText(versionTxtPath)?.Trim();
                        if (!string.IsNullOrEmpty(versionFromFile) && IsValidVersionString(versionFromFile))
                            candidates.Add(versionFromFile);
                    }
                }

                // 3) FileVersion từ exe đang chạy
                var exePath = Assembly.GetExecutingAssembly().Location;
                if (string.IsNullOrEmpty(exePath))
                    exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (!string.IsNullOrEmpty(exePath) && File.Exists(exePath))
                {
                    var fileVersionInfo = FileVersionInfo.GetVersionInfo(exePath);
                    if (!string.IsNullOrEmpty(fileVersionInfo.FileVersion))
                    {
                        var v = NormalizeVersionString(fileVersionInfo.FileVersion);
                        if (!string.IsNullOrEmpty(v))
                            candidates.Add(v);
                    }
                }

                // 4) Assembly version
                var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version;
                if (assemblyVersion != null)
                {
                    var v = $"{assemblyVersion.Major}.{assemblyVersion.Minor}.{assemblyVersion.Build}";
                    if (assemblyVersion.Revision > 0)
                        v += $".{assemblyVersion.Revision}";
                    if (IsValidVersionString(v))
                        candidates.Add(v);
                }

                // Trả về phiên bản mới nhất trong các nguồn (tránh hiển thị 1.1.8 khi đang chạy bản 1.1.9)
                if (candidates.Count > 0)
                {
                    var latest = candidates
                        .OrderByDescending(c => { try { return new Version(c); } catch { return new Version(0, 0); } })
                        .FirstOrDefault();
                    if (!string.IsNullOrEmpty(latest))
                        return latest;
                }

                return "1.0.0";
            }
            catch (Exception)
            {
                System.Diagnostics.Debug.WriteLine("Error getting version");
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

                // Chọn đúng zip theo 32/64-bit: Win 8 (x86) tải win-x86, Win 10/11 (x64) tải win-x64
                var zipAsset = GetDownloadAssetForCurrentProcess(release.assets);
                var downloadUrl = zipAsset?.browser_download_url ?? "";
                var releaseNotes = release.body ?? "";

                return (hasUpdate, latestVersion, downloadUrl, releaseNotes);
            }
            catch (Exception)
            {
                System.Diagnostics.Debug.WriteLine("Error checking for updates");
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
                    catch (Exception)
                    {
                        System.Diagnostics.Debug.WriteLine("Could not save installed version file");
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
            catch (Exception)
            {
                System.Diagnostics.Debug.WriteLine("Error downloading/installing update");
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

        /// <summary>Chuẩn hóa chuỗi version (vd: "1.1.9.0" -> "1.1.9").</summary>
        private static string NormalizeVersionString(string version)
        {
            if (string.IsNullOrWhiteSpace(version)) return "";
            try
            {
                var v = new Version(version);
                if (v.Revision > 0)
                    return $"{v.Major}.{v.Minor}.{v.Build}.{v.Revision}";
                if (v.Build > 0)
                    return $"{v.Major}.{v.Minor}.{v.Build}";
                return $"{v.Major}.{v.Minor}";
            }
            catch
            {
                return "";
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

        /// <summary>
        /// Chọn asset zip đúng theo 32/64-bit: máy x86 (Win 8) tải win-x86, máy x64 tải win-x64.
        /// Nếu release cũ chỉ có 1 file .zip thì dùng luôn (tương thích ngược).
        /// </summary>
        private static GitHubAsset GetDownloadAssetForCurrentProcess(List<GitHubAsset> assets)
        {
            if (assets == null || assets.Count == 0) return null;
            var zipAssets = assets.Where(a => a?.name != null && a.name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)).ToList();
            if (zipAssets.Count == 0) return null;
            // Release mới: 2 file *-win-x64.zip và *-win-x86.zip
            var prefer64 = Environment.Is64BitProcess;
            var preferred = zipAssets.FirstOrDefault(a => a.name.Contains("win-x64", StringComparison.OrdinalIgnoreCase));
            var fallback = zipAssets.FirstOrDefault(a => a.name.Contains("win-x86", StringComparison.OrdinalIgnoreCase));
            if (prefer64 && preferred != null) return preferred;
            if (!prefer64 && fallback != null) return fallback;
            if (preferred != null) return preferred;
            if (fallback != null) return fallback;
            return zipAssets.FirstOrDefault();
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

