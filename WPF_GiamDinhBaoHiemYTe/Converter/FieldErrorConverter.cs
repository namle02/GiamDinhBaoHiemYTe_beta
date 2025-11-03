using System;
using System.Globalization;
using System.Linq;
using System.Windows.Data;
using System.Windows.Media;
using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class FieldErrorConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length >= 2 && values[0] is string fieldName && values[1] is List<ValidationRule> validationRules)
            {
                // Kiểm tra xem field này có lỗi validation không
                // ValidateField từ API response sẽ chứa tên field bị lỗi
                var hasError = validationRules?.Any(rule => 
                    !rule.IsValid && 
                    !string.IsNullOrEmpty(rule.ValidateField) &&
                    rule.ValidateField.Equals(fieldName, StringComparison.OrdinalIgnoreCase)
                ) == true;

                // Trả về màu đỏ nếu có lỗi, màu đen nếu không có lỗi
                return hasError ? new SolidColorBrush(Colors.Red) : new SolidColorBrush(Colors.Black);
            }

            return new SolidColorBrush(Colors.Black);
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
