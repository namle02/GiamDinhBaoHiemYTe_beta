namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    /// <summary>
    /// DTO chứa dữ liệu từ 1 dòng Excel - có thể là MA_LK hoặc MA_BN + dates
    /// </summary>
    public class ExcelRowData
    {
        /// <summary>
        /// Mã liên kết (nếu có cột MA_LK)
        /// </summary>
        public string? MaLk { get; set; }
        
        /// <summary>
        /// Mã bệnh nhân (nếu có cột MA_BN)
        /// </summary>
        public string? MaBn { get; set; }
        
        /// <summary>
        /// Ngày vào (nếu có cột NGAY_VAO)
        /// </summary>
        public string? NgayVao { get; set; }
        
        /// <summary>
        /// Ngày ra (nếu có cột NGAY_RA)
        /// </summary>
        public string? NgayRa { get; set; }
        
        /// <summary>
        /// Loại dữ liệu: "MA_LK" hoặc "MA_BN"
        /// </summary>
        public string DataType { get; set; } = "MA_LK";
        
        /// <summary>
        /// Kiểm tra xem có đủ thông tin để tra cứu không
        /// </summary>
        public bool IsValid()
        {
            if (DataType == "MA_LK")
            {
                return !string.IsNullOrWhiteSpace(MaLk);
            }
            else // MA_BN
            {
                return !string.IsNullOrWhiteSpace(MaBn) 
                    && !string.IsNullOrWhiteSpace(NgayVao) 
                    && !string.IsNullOrWhiteSpace(NgayRa);
            }
        }
    }
}

