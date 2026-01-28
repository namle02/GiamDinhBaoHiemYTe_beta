using System;
using System.Globalization;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class ProgressBarWidthConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values == null || values.Length < 3)
                return 0.0;

            if (values[0] is int current && values[1] is int total && values[2] is double containerWidth)
            {
                if (total == 0)
                    return 0.0;

                double percentage = (double)current / total;
                // Subtract border thickness (3px total) and add some margin
                double availableWidth = containerWidth - 3;
                return Math.Max(0, percentage * availableWidth);
            }

            return 0.0;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
