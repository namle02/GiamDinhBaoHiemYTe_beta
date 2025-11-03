using System.Collections.Generic;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service để xử lý các UI dialogs (MessageBox, file dialogs, custom dialogs)
    /// </summary>
    public interface IDialogService
    {
        /// <summary>
        /// Hiển thị thông báo lỗi
        /// </summary>
        void ShowError(string message, string title = "Lỗi");

        /// <summary>
        /// Hiển thị thông báo cảnh báo
        /// </summary>
        void ShowWarning(string message, string title = "Cảnh báo");

        /// <summary>
        /// Hiển thị thông báo thông tin
        /// </summary>
        void ShowInformation(string message, string title = "Thông báo");

        /// <summary>
        /// Hiển thị dialog chọn file Excel để mở
        /// </summary>
        string? ShowOpenExcelFileDialog(string title = "Chọn file Excel");

        /// <summary>
        /// Hiển thị dialog chọn nơi lưu file Excel
        /// </summary>
        string? ShowSaveExcelFileDialog(string defaultFileName, string title = "Lưu file Excel");

        /// <summary>
        /// Hiển thị dialog chọn sheet từ danh sách
        /// </summary>
        string? ShowSheetSelectionDialog(List<string> sheetNames, string title = "Chọn Sheet");

        /// <summary>
        /// Hiển thị dialog xác nhận Yes/No
        /// </summary>
        bool ShowConfirmation(string message, string title = "Xác nhận");
    }
}


