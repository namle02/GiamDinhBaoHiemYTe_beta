using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để đổi màu background của nội dung lỗi:
    /// - IsError = true → Màu đỏ nhạt (#FFEBEE)
    /// - IsError = false → Màu xanh lá cây nhạt (#E8F5E9)
    /// </summary>
    public class ErrorContentBackgroundConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isError)
            {
                if (isError)
                {
                    // Có lỗi → Màu đỏ nhạt
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#FFEBEE"));
                }
                else
                {
                    // Không có lỗi → Màu xanh lá cây nhạt
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#E8F5E9"));
                }
            }

            // Default: Màu trắng
            return new SolidColorBrush(Colors.White);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}

