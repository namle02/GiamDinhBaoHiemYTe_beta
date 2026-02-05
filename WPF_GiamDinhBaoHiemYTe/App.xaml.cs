using CommunityToolkit.Mvvm.Messaging;
using Microsoft.Extensions.DependencyInjection;
using System.Windows;
using WPF_GiamDinhBaoHiem.DI_Register;
using WPF_GiamDinhBaoHiem.Messenger;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    private readonly IServiceProvider serviceProvider;
    public IServiceProvider ServiceProvider => serviceProvider;
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
        var configService = serviceProvider.GetRequiredService<IConfigReader>();
        await configService.GetConfigFromSheet();

        // Load rules khi app khởi động để cache sẵn dữ liệu
        var ruleService = serviceProvider.GetRequiredService<Services.Interface.IRuleServices>();
        await ruleService.LoadRulesAsync();

        var mainwindow = serviceProvider.GetRequiredService<MainWindow>();
        mainwindow.Show();
        base.OnStartup(e);

        // Kiểm tra phiên bản mới khi khởi động; nếu có bản mới thì hiện popup góc trên màn hình
        _ = CheckForUpdateOnStartupAsync();
    }

    /// <summary>
    /// Kiểm tra có phiên bản mới không khi khởi động. Nếu có thì hiện popup nhỏ ở góc trên màn hình.
    /// </summary>
    private async System.Threading.Tasks.Task CheckForUpdateOnStartupAsync()
    {
        try
        {
            await System.Threading.Tasks.Task.Delay(2500); // Đợi UI và mạng ổn định
            var updateService = serviceProvider.GetRequiredService<IUpdateService>();
            var (hasUpdate, latestVersion, _, _) = await updateService.CheckForUpdatesAsync();
            if (!hasUpdate || string.IsNullOrEmpty(latestVersion))
                return;
            await Current.Dispatcher.InvokeAsync(() =>
            {
                try
                {
                    WeakReferenceMessenger.Default.Send(new ShowUpdateNotificationMessage(latestVersion));
                }
                catch
                {
                    // Bỏ qua nếu không gửi được message
                }
            }, System.Windows.Threading.DispatcherPriority.Normal);
        }
        catch
        {
            // Bỏ qua lỗi khi kiểm tra update (mạng, API...) để không ảnh hưởng app
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        try
        {
            var cacheService = serviceProvider.GetService<IPatientCacheService>();
            cacheService?.ClearAllCache();
        }
        catch
        {
            // Ignore cleanup errors during shutdown
        }

        base.OnExit(e);
    }

}

