using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Windows.Data;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class Xml1ErrorCountConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is List<ErrorItem> errors && errors.Any())
            {
                var xml1Count = errors.Count(e => e.ViTriLoi?.ToUpper() == "XML1");
                return xml1Count.ToString();
            }
            return "0";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class Xml2ErrorCountConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is List<ErrorItem> errors && errors.Any())
            {
                var xml2Count = errors.Count(e => e.ViTriLoi?.ToUpper() == "XML2");
                return xml2Count.ToString();
            }
            return "0";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class Xml3ErrorCountConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is List<ErrorItem> errors && errors.Any())
            {
                var xml3Count = errors.Count(e => e.ViTriLoi?.ToUpper() == "XML3");
                return xml3Count.ToString();
            }
            return "0";
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
