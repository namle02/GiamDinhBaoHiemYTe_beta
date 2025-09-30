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
            services.AddSingleton<IConfigReader, ConfigReader>();
            services.AddSingleton<HttpClient>(new HttpClient
            {
                Timeout = TimeSpan.FromSeconds(30),
                BaseAddress = new Uri("http://localhost:3000") // Default base address, can be overridden by IConfigReader
            });
            services.AddSingleton<IDataMapper, DataMapper>();
            services.AddSingleton<IPatientServices, PatientServices>();
        }
    }
}
