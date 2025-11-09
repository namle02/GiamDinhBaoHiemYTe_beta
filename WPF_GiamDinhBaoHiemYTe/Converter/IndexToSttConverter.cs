using System;
using System.Globalization;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để chuyển AlternationIndex thành STT (index + 1)
    /// </summary>
    public class IndexToSttConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is int index)
            {
                return index + 1;
            }
            return 1;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}

