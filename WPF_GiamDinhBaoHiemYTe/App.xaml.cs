using Microsoft.Extensions.DependencyInjection;
using System.Windows;
using WPF_GiamDinhBaoHiem.DI_Register;
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

