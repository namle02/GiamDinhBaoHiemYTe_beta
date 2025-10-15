namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service để đọc dữ liệu từ file Excel
    /// </summary>
    public interface IExcelReaderService
    {
        /// <summary>
        /// Đọc danh sách mã liên kết (ma_lk) từ file Excel
        /// </summary>
        /// <param name="filePath">Đường dẫn đến file Excel</param>
        /// <param name="sheetName">Tên sheet cần đọc (mặc định là sheet đầu tiên)</param>
        /// <param name="columnName">Tên cột chứa mã liên kết (mặc định là "ma_lk")</param>
        /// <returns>Danh sách mã liên kết</returns>
        Task<List<string>> ReadMaLkFromExcelAsync(string filePath, string? sheetName = null, string columnName = "ma_lk");

        /// <summary>
        /// Lấy danh sách tên các sheet trong file Excel
        /// </summary>
        /// <param name="filePath">Đường dẫn đến file Excel</param>
        /// <returns>Danh sách tên các sheet</returns>
        Task<List<string>> GetSheetNamesAsync(string filePath);
    }
}

