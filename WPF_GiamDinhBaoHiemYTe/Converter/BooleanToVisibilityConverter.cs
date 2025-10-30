using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class BooleanToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            bool boolValue = false;
            
            // Handle bool values
            if (value is bool b)
            {
                boolValue = b;
            }
            // Handle int values (for Count properties)
            else if (value is int intValue)
            {
                boolValue = intValue > 0;
            }
            
            // Check if parameter is "Inverse"
            bool inverse = parameter?.ToString()?.ToLower() == "inverse";
            
            if (inverse)
            {
                return boolValue ? Visibility.Collapsed : Visibility.Visible;
            }
            
            return boolValue ? Visibility.Visible : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is Visibility visibility)
            {
                bool inverse = parameter?.ToString()?.ToLower() == "inverse";
                bool result = visibility == Visibility.Visible;
                return inverse ? !result : result;
            }
            return false;
        }
    }
}
