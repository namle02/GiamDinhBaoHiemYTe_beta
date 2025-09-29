using Microsoft.Extensions.DependencyInjection;


namespace WPF_GiamDinhBaoHiem.DI_Register
{
    public static class WindowRegister
    {
        public static void Register(IServiceCollection services)
        {
            services.AddSingleton<MainWindow>();
        }
    }
}
