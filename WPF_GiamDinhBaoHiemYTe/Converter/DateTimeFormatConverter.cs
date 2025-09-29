using System;
using System.Globalization;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class DateTimeFormatConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null || string.IsNullOrEmpty(value.ToString()))
                return string.Empty;

            string dateString = value.ToString();
            
            // Kiểm tra nếu là định dạng YYYYMMDDHHMM (12 ký tự)
            if (dateString.Length == 12 && dateString.All(char.IsDigit))
            {
                try
                {
                    int year = int.Parse(dateString.Substring(0, 4));
                    int month = int.Parse(dateString.Substring(4, 2));
                    int day = int.Parse(dateString.Substring(6, 2));
                    int hour = int.Parse(dateString.Substring(8, 2));
                    int minute = int.Parse(dateString.Substring(10, 2));
                    
                    DateTime dateTime = new DateTime(year, month, day, hour, minute, 0);
                    return dateTime.ToString("dd/MM/yyyy HH:mm");
                }
                catch
                {
                    return dateString; // Trả về nguyên gốc nếu không parse được
                }
            }
            
            // Kiểm tra nếu là định dạng YYYYMMDD (8 ký tự)
            if (dateString.Length == 8 && dateString.All(char.IsDigit))
            {
                try
                {
                    int year = int.Parse(dateString.Substring(0, 4));
                    int month = int.Parse(dateString.Substring(4, 2));
                    int day = int.Parse(dateString.Substring(6, 2));
                    
                    DateTime dateTime = new DateTime(year, month, day);
                    return dateTime.ToString("dd/MM/yyyy");
                }
                catch
                {
                    return dateString; // Trả về nguyên gốc nếu không parse được
                }
            }
            
            return dateString; // Trả về nguyên gốc nếu không match format nào
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}

