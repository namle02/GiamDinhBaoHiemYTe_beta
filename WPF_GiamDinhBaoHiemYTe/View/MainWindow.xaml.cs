using System.Windows;
using WPF_GiamDinhBaoHiem.ViewModel;

namespace WPF_GiamDinhBaoHiem;

/// <summary>
/// Interaction logic for MainWindow.xaml
/// </summary>
public partial class MainWindow : Window
{
    public MainWindow(MainViewModel vm)
    {
        InitializeComponent();
        DataContext = vm;
    }
}
