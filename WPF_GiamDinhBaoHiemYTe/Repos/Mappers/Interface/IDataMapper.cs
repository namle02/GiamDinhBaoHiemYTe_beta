using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Interface
{
    public enum XMLDataType
    {
        XML0, XML1, XML2, XML3, XML4, XML5, XML6, XML7, XML8, XML9, XML10, XML11, XML13, XML14, XML15
    }
    public interface IDataMapper
    {
        Task<PatientData> GetDataFromDB(string IDBenhNhan);
        
        /// <summary>
        /// Lấy danh sách MA_LK theo MA_BN và ngày vào từ (Tình huống 1)
        /// </summary>
        /// <param name="maBn">Mã bệnh nhân</param>
        /// <param name="ngayVaoFrom">Ngày vào từ (format: yyyyMMddHHmm hoặc yyyyMMdd)</param>
        /// <returns>Danh sách MA_LK</returns>
        Task<List<MaLkSearchResult>> GetMaLkByMaBnAndDate(string maBn, string ngayVaoFrom);

        /// <summary>
        /// Lấy danh sách MA_LK theo input - xử lý 3 tình huống:
        /// Tình huống 1: MA_BN + Ngày vào
        /// Tình huống 2: Mã có "TN" ở đầu (SoTiepNhan)
        /// Tình huống 3: Mã không có "TN" ở đầu (SoBenhAn)
        /// </summary>
        /// <param name="maBn">Mã bệnh nhân (cho tình huống 1)</param>
        /// <param name="ngayVaoFrom">Ngày vào từ (cho tình huống 1, format: yyyyMMddHHmm hoặc yyyyMMdd)</param>
        /// <param name="inputCode">Mã input (cho tình huống 2 hoặc 3 - tự động detect)</param>
        /// <returns>Danh sách MA_LK</returns>
        Task<List<MaLkSearchResult>> GetMaLkByInput(string? maBn = null, string? ngayVaoFrom = null, string? inputCode = null);

        /// <summary>
        /// Lấy danh sách bệnh nhân lỗi mã máy (cùng thiết bị và thời gian thực hiện)
        /// </summary>
        /// <returns>Danh sách bệnh nhân lỗi mã máy</returns>
        Task<List<BenhNhanLoiMaMayResult>> GetDsBenhNhanLoiMaMay();

    }
}
