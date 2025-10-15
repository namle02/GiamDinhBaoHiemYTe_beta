using Dapper;
using Microsoft.Data.SqlClient;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Implement
{
    public class DataMapper : IDataMapper
    {

        private readonly IConfigReader _configReader;
        // Biến để lưu kết quả từ GoogleSheetService
        private object? _googleSheetData;

        // Property để truy cập dữ liệu GoogleSheet từ bên ngoài
        public object? GoogleSheetData => _googleSheetData;

        public DataMapper(IConfigReader configReader)
        {
            _configReader = configReader;
        }

        public async Task<PatientData> GetDataFromDB(string IDBenhNhan)
        {
            PatientData patient = new() { PatientID = IDBenhNhan };

            Dictionary<XMLDataType, string> XML_Query_List = new Dictionary<XMLDataType, string>
            {
                {XMLDataType.XML0,$"select * from TT_00_CHECKIN where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML1,$"select * from TT_01_TONGHOP where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML2,$"select * from TT_02_THUOC where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML3,@$"SELECT t.* , q.LoaiBenhPham_Id
FROM XML130.dbo.TT_03_DVKT_VTYT AS t
LEFT JOIN (
    SELECT 
        dv.MaQuiDinh,
        cls.NgayGioYeuCau,
        cls.LoaiBenhPham_Id
    FROM eHospital_ThuyDienUB.dbo.clsyeucauchitiet AS clsct
    LEFT JOIN eHospital_ThuyDienUB.dbo.clsyeucau AS cls
        ON clsct.CLSYeuCau_Id = cls.CLSYeuCau_Id
    LEFT JOIN eHospital_ThuyDienUB.dbo.BenhAn AS ba
        ON cls.benhan_id = ba.benhan_id
    LEFT JOIN eHospital_ThuyDienUB.dbo.dm_dichvu AS dv
        ON clsct.DichVu_Id = dv.DichVu_Id
    WHERE dv.MaQuiDinh IN (N'24.0001.1714', N'24.0005.1716', N'24.0003.1715')
) AS q
    ON t.MA_DICH_VU = q.MaQuiDinh
   AND DATETIMEFROMPARTS(
         TRY_CONVERT(int, SUBSTRING(LTRIM(RTRIM(t.NGAY_YL)), 1, 4)),  -- yyyy
         TRY_CONVERT(int, SUBSTRING(LTRIM(RTRIM(t.NGAY_YL)), 5, 2)),  -- mm
         TRY_CONVERT(int, SUBSTRING(LTRIM(RTRIM(t.NGAY_YL)), 7, 2)),  -- dd
         TRY_CONVERT(int, SUBSTRING(LTRIM(RTRIM(t.NGAY_YL)), 9, 2)),  -- hh
         TRY_CONVERT(int, SUBSTRING(LTRIM(RTRIM(t.NGAY_YL)),11, 2)),  -- mi
         0, 0
       ) = CAST(q.NgayGioYeuCau AS datetime2)
WHERE t.Ma_LK = N'{IDBenhNhan}';" },
                {XMLDataType.XML4,$"select * from TT_04_CLS where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML5,$"select * from TT_05_LAMSANG where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML6,$"select * from TT_06_HIV where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML7,$"select * from TT_07_GIAY_RAVIEN where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML8,$"select * from TT_08_HSBA where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML9,$"select * from TT_09_CHUNGSINH where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML10,$"select * from TT_10_DUONGTHAI where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML11,$"select * from TT_11_NGHI_BHXH where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML13,$"select * from TT_13_GIAYCHUYENTUYEN where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML14,$"select * from TT_14_GIAYHENKHAMLAI where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML15,$"select * from TT_15_DIEUTRILAO where MA_LK = N'{IDBenhNhan}' ORDER BY ID" }
            };

            string connectionString = _configReader.Config["DB_string"];


            // Apply validation rules động từ GoogleSheet (DynamicValidationService)
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    foreach (var query in XML_Query_List)
                    {
                        await GetXMLData(query.Key, query.Value, patient, connection);
                    }
                }
            }
            catch (Exception ex)
            {
                // Log lỗi nếu cần, nhưng không làm gián đoạn flow chính
                System.Diagnostics.Debug.WriteLine(ex.Message);
                _googleSheetData = null;
            }

            return patient;
        }

        private async Task GetXMLData(XMLDataType type, string query, PatientData patient, SqlConnection connection)
        {
            switch (type)
            {
                case XMLDataType.XML0:
                    patient.Xml0 = (await connection.QueryAsync<XML0>(query)).ToList();
                    break;
                case XMLDataType.XML1:
                    patient.Xml1 = (await connection.QueryAsync<XML1>(query)).ToList();
                    break;
                case XMLDataType.XML2:
                    patient.Xml2 = (await connection.QueryAsync<XML2>(query)).ToList();
                    break;
                case XMLDataType.XML3:
                    patient.Xml3 = (await connection.QueryAsync<XML3>(query)).ToList();
                    break;
                case XMLDataType.XML4:
                    patient.Xml4 = (await connection.QueryAsync<XML4>(query)).ToList();
                    break;
                case XMLDataType.XML5:
                    patient.Xml5 = (await connection.QueryAsync<XML5>(query)).ToList();
                    break;
                case XMLDataType.XML6:
                    patient.Xml6 = (await connection.QueryAsync<XML6>(query)).ToList();
                    break;
                case XMLDataType.XML7:
                    patient.Xml7 = (await connection.QueryAsync<XML7>(query)).ToList();
                    break;
                case XMLDataType.XML8:
                    patient.Xml8 = (await connection.QueryAsync<XML8>(query)).ToList();
                    break;
                case XMLDataType.XML9:
                    patient.Xml9 = (await connection.QueryAsync<XML9>(query)).ToList();
                    break;
                case XMLDataType.XML10:
                    patient.Xml10 = (await connection.QueryAsync<XML10>(query)).ToList();
                    break;
                case XMLDataType.XML11:
                    patient.Xml11 = (await connection.QueryAsync<XML11>(query)).ToList();
                    break;
                case XMLDataType.XML13:
                    patient.Xml13 = (await connection.QueryAsync<XML13>(query)).ToList();
                    break;
                case XMLDataType.XML14:
                    patient.Xml14 = (await connection.QueryAsync<XML14>(query)).ToList();
                    break;
                case XMLDataType.XML15:
                    patient.Xml15 = (await connection.QueryAsync<XML15>(query)).ToList();
                    break;
            }
        }

    }
}
