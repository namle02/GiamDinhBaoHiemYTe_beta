using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để chuyển đổi string thành Visibility
    /// - Nếu string null hoặc empty -> Collapsed
    /// - Nếu string có giá trị -> Visible
    /// </summary>
    public class StringToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is string str)
            {
                return string.IsNullOrWhiteSpace(str) ? Visibility.Collapsed : Visibility.Visible;
            }
            
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
