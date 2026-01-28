using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Animation;

namespace WPF_GiamDinhBaoHiem.View.ControlView
{
    public partial class AILoadingControl : UserControl
    {
        public static readonly DependencyProperty StatusTextProperty =
            DependencyProperty.Register(
                nameof(StatusText),
                typeof(string),
                typeof(AILoadingControl),
                new PropertyMetadata("Đang xử lý dữ liệu..."));

        public static readonly DependencyProperty SubStatusTextProperty =
            DependencyProperty.Register(
                nameof(SubStatusText),
                typeof(string),
                typeof(AILoadingControl),
                new PropertyMetadata("Vui lòng đợi trong giây lát"));

        public string StatusText
        {
            get => (string)GetValue(StatusTextProperty);
            set => SetValue(StatusTextProperty, value);
        }

        public string SubStatusText
        {
            get => (string)GetValue(SubStatusTextProperty);
            set => SetValue(SubStatusTextProperty, value);
        }

        public AILoadingControl()
        {
            InitializeComponent();
            Loaded += AILoadingControl_Loaded;
            Unloaded += AILoadingControl_Unloaded;
        }

        private void AILoadingControl_Loaded(object sender, RoutedEventArgs e)
        {
            // Start all animations
            var rotateAnimation = (Storyboard)Resources["RotateAnimation"];
            var pulseAnimation = (Storyboard)Resources["PulseAnimation"];
            var particleAnimation = (Storyboard)Resources["ParticleAnimation"];
            var textFadeAnimation = (Storyboard)Resources["TextFadeAnimation"];

            rotateAnimation?.Begin();
            pulseAnimation?.Begin();
            particleAnimation?.Begin();
            textFadeAnimation?.Begin();
        }

        private void AILoadingControl_Unloaded(object sender, RoutedEventArgs e)
        {
            // Stop all animations
            var rotateAnimation = (Storyboard)Resources["RotateAnimation"];
            var pulseAnimation = (Storyboard)Resources["PulseAnimation"];
            var particleAnimation = (Storyboard)Resources["ParticleAnimation"];
            var textFadeAnimation = (Storyboard)Resources["TextFadeAnimation"];

            rotateAnimation?.Stop();
            pulseAnimation?.Stop();
            particleAnimation?.Stop();
            textFadeAnimation?.Stop();
        }
    }
}
