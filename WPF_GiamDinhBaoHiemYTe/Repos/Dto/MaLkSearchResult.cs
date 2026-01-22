namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    /// <summary>
    /// DTO chứa kết quả tìm kiếm MA_LK theo MA_BN và khoảng thời gian
    /// </summary>
    public class MaLkSearchResult
    {
        public string? Ma_Bn { get; set; }
        public string? Ma_Lk { get; set; }
        public string? Ngay_Vao { get; set; }
        public string? Ngay_Ra { get; set; }
        public int? LoaiBenhAn_Id { get; set; }
        
        /// <summary>
        /// Hiển thị thông tin dạng: MA_LK - Ngày vào: ...
        /// </summary>
        public string DisplayText => $"{Ma_Lk} - Vào: {FormatDate(Ngay_Vao)}";

        private string FormatDate(string? date)
        {
            if (string.IsNullOrWhiteSpace(date) || date.Length < 8)
                return date ?? "";
            
            // Format từ yyyyMMddHHmm sang dd/MM/yyyy HH:mm
            if (date.Length >= 12)
            {
                return $"{date.Substring(6, 2)}/{date.Substring(4, 2)}/{date.Substring(0, 4)} {date.Substring(8, 2)}:{date.Substring(10, 2)}";
            }
            // Format từ yyyyMMdd sang dd/MM/yyyy
            else if (date.Length >= 8)
            {
                return $"{date.Substring(6, 2)}/{date.Substring(4, 2)}/{date.Substring(0, 4)}";
            }
            
            return date;
        }
    }
}

