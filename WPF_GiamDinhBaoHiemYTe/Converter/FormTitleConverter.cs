using System;
using System.Globalization;
using System.Windows.Data;

namespace WPF_GiamDinhBaoHiem.Converter
{
    public class FormTitleConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length >= 3 && 
                values[0] is bool isThemMoi && 
                values[1] is bool isChinhSua && 
                values[2] is bool isXemChiTiet)
            {
                if (isThemMoi) return "Thêm bác sĩ mới";
                if (isChinhSua) return "Chỉnh sửa bác sĩ";
                if (isXemChiTiet) return "Thông tin bác sĩ";
            }
            return "Thông tin bác sĩ";
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
