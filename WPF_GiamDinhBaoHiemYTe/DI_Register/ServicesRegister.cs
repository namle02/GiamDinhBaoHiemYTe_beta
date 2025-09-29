using Microsoft.Extensions.DependencyInjection;
using System.Net.Http;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Implement;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Services.Implement;
using WPF_GiamDinhBaoHiem.Services.Interface;



namespace WPF_GiamDinhBaoHiem.DI_Register
{
    public static class ServicesRegister
    {
        public static void Register(IServiceCollection services)
        {
            services.AddTransient<IDataMapper, DataMapper>();
            services.AddSingleton<IConfigReader, ConfigReader>();
            services.AddSingleton(new HttpClient
            {
                Timeout = TimeSpan.FromSeconds(30),
                BaseAddress = new Uri("https://cbd5875aaf92.ngrok-free.app/")

            });
            services.AddSingleton<IGoogleSheetService, GoogleSheetService>();

            services.AddTransient<IApiServices, ApiServices>();
            services.AddTransient<IDynamicValidationService, DynamicValidationService>();
        }
    }
}
