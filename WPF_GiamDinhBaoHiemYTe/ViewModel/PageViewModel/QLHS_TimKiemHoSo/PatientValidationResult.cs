using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    /// <summary>
    /// Model kết hợp để hiển thị validation result trong DataGrid
    /// </summary>
    public partial class PatientValidationResult : ObservableObject
    {
        [ObservableProperty]
        private string ma_Lk = string.Empty;

        [ObservableProperty]
        private string ho_Ten = string.Empty;

        [ObservableProperty]
        private string gioi_Tinh = string.Empty;

        [ObservableProperty]
        private string nam_Sinh = string.Empty;

        [ObservableProperty]
        private string noi_Dung_Loi = string.Empty;

        [ObservableProperty]
        private bool isError = false;

        // Lưu danh sách ValidationRule để dùng cho overlay chi tiết
        public List<ValidationRule>? ValidationRules { get; set; }
    }
}

