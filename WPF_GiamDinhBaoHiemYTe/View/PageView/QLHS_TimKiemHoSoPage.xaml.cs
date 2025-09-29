using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using CommunityToolkit.Mvvm.Input;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.View.PageView
{
    /// <summary>
    /// Interaction logic for QLHS_TimKiemHoSoPage.xaml
    /// </summary>
    public partial class QLHS_TimKiemHoSoPage : UserControl
    {
        private DataGridRow? _lastClickedRow;
        private DateTime _lastClickTime;
        private void DataGridRow_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (sender is not DataGridRow row) return;

            var now = DateTime.UtcNow;
            bool sameRow = ReferenceEquals(row, _lastClickedRow);
            bool isDouble = sameRow && (now - _lastClickTime).TotalMilliseconds <= 500;
            _lastClickedRow = row;
            _lastClickTime = now;

            if (isDouble)
            {
                row.DetailsVisibility = row.DetailsVisibility == Visibility.Visible
                    ? Visibility.Collapsed
                    : Visibility.Visible;
                e.Handled = true;
            }
        }
        public QLHS_TimKiemHoSoPage()
        {
            InitializeComponent();
        }

        
    }
}
