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
        /// Lấy danh sách MA_LK theo MA_BN và khoảng thời gian
        /// </summary>
        /// <param name="maBn">Mã bệnh nhân</param>
        /// <param name="ngayVaoFrom">Ngày vào từ (format: yyyyMMddHHmm hoặc yyyyMMdd)</param>
        /// <param name="ngayRaTo">Ngày ra đến (format: yyyyMMddHHmm hoặc yyyyMMdd)</param>
        /// <returns>Danh sách MA_LK</returns>
        Task<List<MaLkSearchResult>> GetMaLkByMaBnAndDate(string maBn, string ngayVaoFrom, string ngayRaTo);

    }
}
