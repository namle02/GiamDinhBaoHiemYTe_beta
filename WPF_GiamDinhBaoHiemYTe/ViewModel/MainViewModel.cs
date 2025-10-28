using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;
using Microsoft.Extensions.DependencyInjection;
using WPF_GiamDinhBaoHiem.Messenger;
using WPF_GiamDinhBaoHiem.View.PageView;
using WPF_GiamDinhBaoHiem.ViewModel.ControlViewModel;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;




namespace WPF_GiamDinhBaoHiem.ViewModel
{
    public partial class MainViewModel : ObservableObject, IRecipient<NavigationMessage>
    {

        private readonly IServiceProvider serviceProvider;

        [ObservableProperty] SideBarVM sideBarVM;        
        [ObservableProperty] object? currentPage;
        public MainViewModel(IServiceProvider serviceProvider)
        {
            this.serviceProvider = serviceProvider;
            WeakReferenceMessenger.Default.RegisterAll(this);
            CurrentPage = serviceProvider.GetRequiredService<QLHS_TimKiemHoSoVM>();
            sideBarVM = serviceProvider.GetRequiredService<SideBarVM>();
        }

        public void Receive(NavigationMessage message)
        {
            switch (message.PageName)
            {
                case "DashboardPage":
                    CurrentPage = serviceProvider.GetRequiredService<DashboardPageVM>();
                    break;
                case "DM_BacSiPage":
                    CurrentPage = serviceProvider.GetRequiredService<DM_BacSiVM>();
                    break;
                case "DM_DichVuPage":
                    CurrentPage = serviceProvider.GetRequiredService<DM_DichVuVM>();
                    break;
                case "DM_DieuKienPage":
                    CurrentPage = serviceProvider.GetRequiredService<DM_DieuKienVM>();
                    break;
                case "DM_ThuocPage":
                    CurrentPage = serviceProvider.GetRequiredService<DM_ThuocVM>();
                    break;
                case "QLHS_TaiBaoCaoPage":
                    CurrentPage = serviceProvider.GetRequiredService<QLHS_TaiBaoCaoVM>();
                    break;
                case "QLHS_ThongKeLoiPage":
                    CurrentPage = serviceProvider.GetRequiredService<QLHS_ThongKeLoiPageVM>();
                    break;
                case "QLHS_TimKiemHoSoPage":
                    CurrentPage = serviceProvider.GetRequiredService<QLHS_TimKiemHoSoVM>();
                    break;
                case "QTHT_HoSoNhanVienPage":
                    CurrentPage = serviceProvider.GetRequiredService<QTHT_HoSoNhanVienVM>();
                    break;
                case "QTHT_TaiKhoanPage":
                    CurrentPage = serviceProvider.GetRequiredService<QTHT_TaiKhoanVM>();
                    break;
                default:
                    break;

            }
        }
    }
}
