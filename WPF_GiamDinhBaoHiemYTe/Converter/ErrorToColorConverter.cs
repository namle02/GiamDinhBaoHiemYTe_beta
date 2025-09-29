using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class ErrorToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isError && isError)
            {
                return Brushes.Red;
            }
            return Brushes.Black;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class SafeErrorToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            // Debug logging
            System.Diagnostics.Debug.WriteLine($"SafeErrorToColorConverter.Convert called with value: {value} (type: {value?.GetType()})");
            
            // Handle null values gracefully
            if (value == null)
            {
                System.Diagnostics.Debug.WriteLine("SafeErrorToColorConverter: value is null, returning Black");
                return Brushes.Black;
            }

            if (value is bool isError && isError)
            {
                System.Diagnostics.Debug.WriteLine("SafeErrorToColorConverter: error is true, returning Red");
                return Brushes.Red;
            }
            
            System.Diagnostics.Debug.WriteLine($"SafeErrorToColorConverter: error is false ({value}), returning Black");
            return Brushes.Black;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
