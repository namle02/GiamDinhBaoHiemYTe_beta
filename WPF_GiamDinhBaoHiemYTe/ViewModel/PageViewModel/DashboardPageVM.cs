using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using OxyPlot;
using OxyPlot.Axes;
using OxyPlot.Series;
// Alias cho rõ ràng
using BarSeriesAlias = OxyPlot.Series.BarSeries;
using BarItemAlias = OxyPlot.Series.BarItem;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public class DashboardPageVM : INotifyPropertyChanged
    {
        // ===== KPIs (binding ra Card/Tile ngoài UI) =====
        private int _tongHoSoTrongNgay;
        public int TongHoSoTrongNgay { get => _tongHoSoTrongNgay; set { if (_tongHoSoTrongNgay != value) { _tongHoSoTrongNgay = value; OnPropertyChanged(); } } }

        private int _tongHoSoTrongThang;
        public int TongHoSoTrongThang { get => _tongHoSoTrongThang; set { if (_tongHoSoTrongThang != value) { _tongHoSoTrongThang = value; OnPropertyChanged(); } } }

        private int _dieuTriNoiTruNgay;
        public int DieuTriNoiTruNgay { get => _dieuTriNoiTruNgay; set { if (_dieuTriNoiTruNgay != value) { _dieuTriNoiTruNgay = value; OnPropertyChanged(); } } }

        private int _dieuTriNoiTruThang;
        public int DieuTriNoiTruThang { get => _dieuTriNoiTruThang; set { if (_dieuTriNoiTruThang != value) { _dieuTriNoiTruThang = value; OnPropertyChanged(); } } }

        private int _raVienNgay;
        public int RaVienNgay { get => _raVienNgay; set { if (_raVienNgay != value) { _raVienNgay = value; OnPropertyChanged(); } } }

        private int _raVienThang;
        public int RaVienThang { get => _raVienThang; set { if (_raVienThang != value) { _raVienThang = value; OnPropertyChanged(); } } }

        private double _tiLeBHYT;
        public double TiLeBHYT { get => _tiLeBHYT; set { if (Math.Abs(_tiLeBHYT - value) > 1e-9) { _tiLeBHYT = value; OnPropertyChanged(); } } }

        private double _tiLeBHYTThang;
        public double TiLeBHYTThang { get => _tiLeBHYTThang; set { if (Math.Abs(_tiLeBHYTThang - value) > 1e-9) { _tiLeBHYTThang = value; OnPropertyChanged(); } } }

        // ===== PlotModels để binding vào PlotView =====
        private PlotModel _kcbPlot;
        public PlotModel KcbPlot { get => _kcbPlot; private set { _kcbPlot = value; OnPropertyChanged(); } }

        private PlotModel _chiPhiPlot;
        public PlotModel ChiPhiPlot { get => _chiPhiPlot; private set { _chiPhiPlot = value; OnPropertyChanged(); } }

        private PlotModel _benhPhoBienPlot;
        public PlotModel BenhPhoBienPlot { get => _benhPhoBienPlot; private set { _benhPhoBienPlot = value; OnPropertyChanged(); } }

        public event PropertyChangedEventHandler? PropertyChanged;

        public DashboardPageVM()
        {
            
            TongHoSoTrongNgay = 180;
            TongHoSoTrongThang = 4200;
            DieuTriNoiTruNgay = 20;
            DieuTriNoiTruThang = 1500;
            RaVienNgay = 60;
            RaVienThang = 1300;
            TiLeBHYT = 0.68;
            TiLeBHYTThang = 0.71;

            // DEMO: dữ liệu giả để render lần đầu
            var labels7Ngay = BuildLabelsNgayGanNhat(7);               // ["26/08",...,"01/09"]
            var hoSo7Ngay = new List<double> { 170, 160, 185, 210, 195, 205, 180 };
            var noiTru7Ngay = new List<double> { 60, 55, 70, 75, 68, 72, 65 };

            var labels12Thang = BuildLabelsThangGanNhat(12);           // ["10/24",...,"09/25"]
            var chiPhi12Thang = new List<double> { 820, 830, 910, 870, 895, 920, 950, 980, 960, 1005, 990, 1020 };

            var slices = new List<(string Ten, double GiaTri)> {
                ("Cúm", 26), ("Viêm phổi", 18), ("Tăng huyết áp", 22), ("ĐTĐ", 16), ("Viêm dạ dày", 18)
            };

            // Lập model lần đầu
            KcbPlot = BuildKcbBarPlot(hoSo7Ngay, noiTru7Ngay, labels7Ngay);
            ChiPhiPlot = BuildChiPhiLinePlot(chiPhi12Thang, labels12Thang);
            BenhPhoBienPlot = BuildBenhPhoBienPie(slices);
        }

       

        public void UpdateKpis(
            int tongNgay, int tongThang,
            int noiTruNgay, int noiTruThang,
            int raVienNgay, int raVienThang,
            double tiLeNgay, double tiLeThang)
        {
            // TODO: GỌI HÀM NÀY với data thật từ service.
            // Giải thích: thay vì gán Random,  truyền đúng các KPI cần hiển thị.
            TongHoSoTrongNgay = tongNgay;
            TongHoSoTrongThang = tongThang;
            DieuTriNoiTruNgay = noiTruNgay;
            DieuTriNoiTruThang = noiTruThang;
            RaVienNgay = raVienNgay;
            RaVienThang = raVienThang;
            TiLeBHYT = tiLeNgay;
            TiLeBHYTThang = tiLeThang;
        }

        public void UpdateKcbData(IList<double> hoSo, IList<double> noiTru, IList<string> labels)
        {
            // TODO: TRUYỀN DỮ LIỆU THẬT:
            // - hoSo: số hồ sơ từng ngày (cùng số phần tử với labels)
            // - noiTru: số nội trú từng ngày (cùng số phần tử với labels)
            // - labels: chuỗi hiển thị trên trục (thường là "dd/MM")
            KcbPlot = BuildKcbBarPlot(hoSo, noiTru, labels);
        }

        public void UpdateChiPhiData(IList<double> values, IList<string> labels)
        {
            // TODO: TRUYỀN DỮ LIỆU THẬT:
            // - values: chi phí từng tháng (đơn vị tùy bạn, ở demo là "triệu")
            // - labels: nhãn trục X cho từng điểm (thường "MM/yy")
            ChiPhiPlot = BuildChiPhiLinePlot(values, labels);
        }

        public void UpdateBenhPhoBienData(IList<(string Ten, double GiaTri)> slices)
        {
            // TODO: TRUYỀN DỮ LIỆU THẬT:
            // - Danh sách (Tên bệnh, Giá trị). Giá trị có thể là số ca hoặc tỷ lệ (%).
            BenhPhoBienPlot = BuildBenhPhoBienPie(slices);
        }

        // ======= Builders: NHẬN DATA từ tham số, KHÔNG Random/Hard-code =======

        private PlotModel BuildKcbBarPlot(IList<double> hoSo, IList<double> noiTru, IList<string> labels)
        {
            var model = new PlotModel { Title = "KCB 7 ngày gần nhất" };

            // TODO: CÓ THỂ THAY: format nhãn trục theo yêu cầu (dd/MM, ddd dd/MM ...)
            var categoryAxis = new CategoryAxis { Position = AxisPosition.Left };
            foreach (var lb in labels) categoryAxis.Labels.Add(lb);

            var valueAxis = new LinearAxis
            {
                Position = AxisPosition.Bottom,
                Minimum = 0,
                MajorGridlineStyle = LineStyle.Solid
                // TODO: CÓ THỂ THAY: đặt Maximum nếu muốn cố định trần hiển thị
            };

            var hs = new BarSeriesAlias { Title = "Hồ sơ" };
            var nt = new BarSeriesAlias { Title = "Nội trú" };

            // TODO: THAY DỮ LIỆU Ở ĐÂY bằng dữ liệu thật đã truyền vào tham số.
            // Giải thích: mỗi chỉ số tương ứng 1 cột cùng vị trí label.
            for (int i = 0; i < labels.Count; i++)
            {
                hs.Items.Add(new BarItemAlias(hoSo[i]));
                nt.Items.Add(new BarItemAlias(noiTru[i]));
            }

            model.Axes.Add(categoryAxis);
            model.Axes.Add(valueAxis);
            model.Series.Add(hs);
            model.Series.Add(nt);
            return model;
        }

        private PlotModel BuildChiPhiLinePlot(IList<double> values, IList<string> labels)
        {
            var model = new PlotModel { Title = "Chi phí 12 tháng gần nhất" };

            // TODO: CÓ THỂ THAY: kiểu trục X (CategoryAxis cho nhãn rời rạc; DateTimeAxis nếu có DateTime).
            var cat = new CategoryAxis { Position = AxisPosition.Bottom };
            foreach (var lb in labels) cat.Labels.Add(lb);

            var val = new LinearAxis
            {
                Position = AxisPosition.Left,
                Minimum = 0,
                MajorGridlineStyle = LineStyle.Solid
                // TODO: CÓ THỂ THAY: đặt MajorStep/MinorStep, StringFormat, đơn vị…
            };

            var line = new LineSeries
            {
                Title = "Chi phí (triệu)",          // TODO: THAY tiêu đề/đơn vị theo data thật
                MarkerType = MarkerType.Circle,
                MarkerSize = 3
                // TODO: CÓ THỂ THAY: màu sắc/Thickness nếu cần
            };

            // TODO: THAY DỮ LIỆU Ở ĐÂY bằng values thật (độ dài = số nhãn)
            for (int i = 0; i < values.Count; i++)
                line.Points.Add(new DataPoint(i, values[i]));

            model.Axes.Add(cat);
            model.Axes.Add(val);
            model.Series.Add(line);
            return model;
        }

        private PlotModel BuildBenhPhoBienPie(IList<(string Ten, double GiaTri)> slices)
        {
            var model = new PlotModel { Title = "Bệnh phổ biến" };

            var pie = new PieSeries
            {
                StrokeThickness = 0,
                InsideLabelPosition = 0.6,
                AngleSpan = 360,
                StartAngle = 0
                // TODO: CÓ THỂ THAY: OutsideLabelFormat, InsideLabelFormat (ví dụ "{1}: {0:0}%")
            };

            // TODO: THAY DỮ LIỆU Ở ĐÂY bằng slices thật (Tên bệnh, Số ca hoặc %).
            foreach (var s in slices)
                pie.Slices.Add(new PieSlice(s.Ten, s.GiaTri));

            model.Series.Add(pie);
            return model;
        }

        // ======= Helpers tạo labels demo (có thể bỏ khi dùng API) =======
        private static List<string> BuildLabelsNgayGanNhat(int soNgay)
        {
            // TODO: BỎ hoặc THAY bằng nhãn từ data thật (ví dụ ngày có dữ liệu).
            var labels = new List<string>();
            var today = DateTime.Today;
            for (int i = soNgay - 1; i >= 0; i--)
                labels.Add(today.AddDays(-i).ToString("dd/MM"));
            return labels;
        }

        private static List<string> BuildLabelsThangGanNhat(int soThang)
        {
            // TODO: BỎ hoặc THAY bằng nhãn từ data thật (ví dụ những tháng có phát sinh).
            var labels = new List<string>();
            var now = DateTime.Today;
            for (int i = soThang - 1; i >= 0; i--)
                labels.Add(now.AddMonths(-i).ToString("MM/yy"));
            return labels;
        }

        // ======= INotifyPropertyChanged =======
        protected void OnPropertyChanged([CallerMemberName] string name = null)
            => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
