using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Converter để đổi màu nội dung lỗi:
    /// - IsError = true → Màu đỏ
    /// - IsError = false → Màu xanh lá cây
    /// </summary>
    public class ErrorContentToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool isError)
            {
                if (isError)
                {
                    // Có lỗi → Màu đỏ
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#C62828"));
                }
                else
                {
                    // Không có lỗi → Màu xanh lá cây
                    return new SolidColorBrush((Color)ColorConverter.ConvertFromString("#2E7D32"));
                }
            }

            // Default: Màu đen
            return new SolidColorBrush(Colors.Black);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}

