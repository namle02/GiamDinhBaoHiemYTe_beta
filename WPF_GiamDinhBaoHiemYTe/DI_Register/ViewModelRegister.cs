using Microsoft.Extensions.DependencyInjection;
using WPF_GiamDinhBaoHiem.ViewModel;
using WPF_GiamDinhBaoHiem.ViewModel.ControlViewModel;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.DI_Register
{
    public static class ViewModelRegister
    {
        public static void Register(IServiceCollection services)
        {
            services.AddSingleton<MainViewModel>();
            services.AddTransient<DashboardPageVM>();
            services.AddTransient<DM_BacSiVM>();
            services.AddTransient<DM_DichVuVM>();
            services.AddTransient<DM_DieuKienVM>();
            services.AddTransient<DM_ThuocVM>();
            services.AddTransient<QLHS_TaiBaoCaoVM>();
            services.AddTransient<QLHS_ThongKeLoiPageVM>();
            services.AddTransient<QLHS_TimKiemHoSoVM>();
            services.AddTransient<QTHT_HoSoNhanVienVM>();
            services.AddTransient<QTHT_TaiKhoanVM>();

            services.AddSingleton<SideBarVM>();

        }
    }
}
