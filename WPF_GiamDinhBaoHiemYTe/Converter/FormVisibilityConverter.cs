using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class FormVisibilityConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length >= 3 && 
                values[0] is bool isThemMoi && 
                values[1] is bool isChinhSua && 
                values[2] is bool isXemChiTiet)
            {
                return (isThemMoi || isChinhSua || isXemChiTiet) ? Visibility.Visible : Visibility.Collapsed;
            }
            return Visibility.Collapsed;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
