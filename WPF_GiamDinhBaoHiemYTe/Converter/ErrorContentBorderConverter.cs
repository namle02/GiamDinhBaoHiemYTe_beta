using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để đổi màu border của nội dung lỗi:
    /// - IsError = true → Màu đỏ (#FFCDD2)
    /// - IsError = false → Màu xanh lá cây (#A5D6A7)
    /// </summary>
    public class ErrorContentBorderConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isError)
            {
                if (isError)
                {
                    // Có lỗi → Màu đỏ
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FFCDD2"));
                }
                else
                {
                    // Không có lỗi → Màu xanh lá cây
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#A5D6A7"));
                }
            }

            // Default: Màu xám
            return new SolidColorBrush(Colors.LightGray);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}

