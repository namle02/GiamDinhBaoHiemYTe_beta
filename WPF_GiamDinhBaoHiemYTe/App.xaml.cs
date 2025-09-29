using Microsoft.Extensions.DependencyInjection;
using System.Threading.Tasks;
using System.Windows;
using WPF_GiamDinhBaoHiem.DI_Register;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Implement;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using System.Diagnostics;
using System.Net.Http;
using System;
using System.IO;
using System.Threading;

namespace WPF_GiamDinhBaoHiem;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    private readonly IServiceProvider serviceProvider;
    private Process? backendProcess;
    
    public App()
    {
        var services = new ServiceCollection();
        ConfigureServices(services);
        serviceProvider = services.BuildServiceProvider();
        
    }

    public IServiceProvider Services => serviceProvider;

    private void ConfigureServices(IServiceCollection services)
    {
        WindowRegister.Register(services);
        ServicesRegister.Register(services);
        ViewModelRegister.Register(services);
    }

    protected override async void OnStartup(StartupEventArgs e)
    {
        // Đảm bảo Backend (Node) đã chạy. Nếu chưa, tự khởi động trong nền.
        await EnsureBackendRunningAsync();

        var _configReader = serviceProvider.GetRequiredService<IConfigReader>();
        await _configReader.GetConfigFromSheet();
        var mainwindow = serviceProvider.GetRequiredService<MainWindow>();
        mainwindow.Show();
        base.OnStartup(e);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        try
        {
            // Không bắt buộc: nếu muốn, có thể để backend chạy tiếp. Ở đây tắt nếu do app đã khởi.
            if (backendProcess != null && !backendProcess.HasExited)
            {
                backendProcess.Kill(true);
                backendProcess.Dispose();
            }
        }
        catch { }

        base.OnExit(e);
    }

    private static async Task<bool> IsBackendHealthyAsync(CancellationToken ct)
    {
        try
        {
            using var http = new HttpClient { BaseAddress = new Uri("http://localhost:3000/") };
            http.Timeout = TimeSpan.FromMilliseconds(800);
            using var resp = await http.GetAsync("", ct);
            return resp.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    private async Task EnsureBackendRunningAsync()
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(1));
        if (await IsBackendHealthyAsync(cts.Token)) return;

        // Xác định thư mục Backend: từ bin/Debug/netX → ../../../../Backend
        var baseDir = AppContext.BaseDirectory;
        var backendDir = Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..", "..", "Backend"));

        // Ưu tiên npm start (đã có script trong package.json)
        var psi = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = "/c npm run start",
            WorkingDirectory = backendDir,
            CreateNoWindow = true,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };

        try
        {
            backendProcess = Process.Start(psi);
        }
        catch
        {
            // Fallback: chạy trực tiếp node nếu npm không có trong PATH
            var nodePsi = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = "/c node src/app.js",
                WorkingDirectory = backendDir,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            backendProcess = Process.Start(nodePsi);
        }

        // Đợi server lắng nghe (poll nhanh 5-10 lần)
        for (int i = 0; i < 10; i++)
        {
            await Task.Delay(400);
            if (await IsBackendHealthyAsync(CancellationToken.None)) break;
        }
    }

}

