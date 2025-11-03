using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để highlight background của row khi có lỗi - Tối ưu hóa với frozen brushes
    /// </summary>
    public class ErrorRowConverter : IMultiValueConverter
    {
        private static readonly SolidColorBrush RedBrush = new SolidColorBrush(Colors.Red);
        private static readonly SolidColorBrush TransparentBrush = Brushes.Transparent;

        static ErrorRowConverter()
        {
            RedBrush.Freeze(); // Freeze để tái sử dụng và tăng performance
        }

        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values != null && values.Length >= 2 && values[0] is int id && values[1] is HashSet<int> errorIds)
            {
                if (errorIds.Contains(id))
                {
                    return RedBrush;
                }
            }
            return TransparentBrush;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Converter để highlight tab header khi có lỗi - Tối ưu hóa với frozen brushes
    /// </summary>
    public class ErrorTabHeaderConverter : IMultiValueConverter
    {
        private static readonly SolidColorBrush RedBrush = new SolidColorBrush(Colors.Red);
        private static readonly SolidColorBrush WhiteBrush = new SolidColorBrush(Colors.White);

        static ErrorTabHeaderConverter()
        {
            RedBrush.Freeze();
            WhiteBrush.Freeze();
        }

        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length >= 2 && values[0] is HashSet<string> errorTabs && values[1] is string tabName)
            {
                if (errorTabs.Contains(tabName))
                {
                    return RedBrush;
                }
            }
            return WhiteBrush;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Converter để highlight text color khi có lỗi - Tối ưu hóa với frozen brushes
    /// </summary>
    public class ErrorTextConverter : IMultiValueConverter
    {
        private static readonly SolidColorBrush RedBrush = new SolidColorBrush(Colors.Red);
        private static readonly SolidColorBrush BlackBrush = new SolidColorBrush(Colors.Black);

        static ErrorTextConverter()
        {
            RedBrush.Freeze();
            BlackBrush.Freeze();
        }

        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values != null && values.Length >= 2 && values[0] is int id && values[1] is HashSet<int> errorIds)
            {
                if (errorIds.Contains(id))
                {
                    return RedBrush;
                }
            }
            return BlackBrush;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
