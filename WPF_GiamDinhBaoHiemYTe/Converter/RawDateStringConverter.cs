using System;
using System.Globalization;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    /// <summary>
    /// Chuyển chuỗi ngày thô (20260102 hoặc 202601020830) sang dd/mm/yy hoặc dd/mm/yy HH:mm.
    /// </summary>
    public class RawDateStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null || string.IsNullOrWhiteSpace(value.ToString()))
                return string.Empty;

            var s = value.ToString()!.Trim();
            if (string.IsNullOrEmpty(s))
                return string.Empty;

            // Định dạng 20260102 (8 ký tự) -> dd/mm/yy
            if (s.Length == 8 && int.TryParse(s, out _))
            {
                if (TryParseDate(s, 0, 4, 4, 6, 6, 8, out var year, out var month, out var day))
                    return $"{day:D2}/{month:D2}/{year % 100:D2}";
            }
            // Định dạng 202601020830 (12 ký tự) -> dd/mm/yy HH:mm
            else if (s.Length >= 12 && long.TryParse(s.Substring(0, 12), out _))
            {
                if (TryParseDate(s, 0, 4, 4, 6, 6, 8, out var year, out var month, out var day))
                {
                    var hour = int.Parse(s.Substring(8, 2));
                    var min = int.Parse(s.Substring(10, 2));
                    return $"{day:D2}/{month:D2}/{year % 100:D2} {hour:D2}:{min:D2}";
                }
            }

            return s;
        }

        private static bool TryParseDate(string s, int yS, int yE, int mS, int mE, int dS, int dE,
            out int year, out int month, out int day)
        {
            year = month = day = 0;
            if (s.Length < dE) return false;
            if (!int.TryParse(s.Substring(yS, yE - yS), out year)) return false;
            if (!int.TryParse(s.Substring(mS, mE - mS), out month)) return false;
            if (!int.TryParse(s.Substring(dS, dE - dS), out day)) return false;
            return month >= 1 && month <= 12 && day >= 1 && day <= 31;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
