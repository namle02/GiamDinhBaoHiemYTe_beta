using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using WPF_GiamDinhBaoHiem.Messenger;



namespace WPF_GiamDinhBaoHiem.ViewModel.ControlViewModel
{
    public partial class SideBarVM : ObservableObject
    {

        [ObservableProperty] private string greeting = "Xin chào!";

        [RelayCommand]
        private void Navigation(string PageName)
        {
            WeakReferenceMessenger.Default.Send(new NavigationMessage(PageName));
        }
    }
}
