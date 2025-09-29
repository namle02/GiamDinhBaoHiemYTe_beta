
using Microsoft.Data.SqlClient;
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
        //Task GetXMLData(XMLDataType type, string query, PatientData patient, SqlConnection connection);
    
        // Method để lấy danh sách lỗi từ GoogleSheet
        Task<List<ErrorItem>> GetErrorListFromGoogleSheetAsync();
      
        Task<Thuoc?> GetThuocByDuocIdAsync(string duocId);

        Task<List<NhanVien>> SearchNhanVienAsync(string? keyword);

        Task<DichVu?> GetDichVuByIdOrCodeAsync(string keyword);
        Task<List<DichVu>> SearchDichVuAsync(string? keyword);

    }
}
