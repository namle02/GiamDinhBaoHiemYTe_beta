using Dapper;
using Microsoft.Data.SqlClient;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Implement
{
    public class DataMapper : IDataMapper
    {
       
        private readonly IConfigReader _configReader;

      
        private readonly IGoogleSheetService _googleSheetService;
        private readonly IDynamicValidationService _dynamicValidationService;
        
        // Biến để lưu kết quả từ GoogleSheetService
        private object? _googleSheetData;
        
        // Property để truy cập dữ liệu GoogleSheet từ bên ngoài
        public object? GoogleSheetData => _googleSheetData;

        // Method để lấy danh sách lỗi từ GoogleSheet
        public async Task<List<ErrorItem>> GetErrorListFromGoogleSheetAsync()
        {
            try
            {
                var errorList = await _googleSheetService.GetErrorListAsync();
                _googleSheetData = errorList; // Lưu vào biến để sử dụng sau
                return errorList;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"GetErrorListFromGoogleSheetAsync error: {ex.Message}");
                return new List<ErrorItem>();
            }
        }

        public DataMapper(IConfigReader configReader, IGoogleSheetService googleSheetService, IDynamicValidationService dynamicValidationService)
        {
            _configReader = configReader;
            _googleSheetService = googleSheetService;
            _dynamicValidationService = dynamicValidationService;
        }





        public async Task<PatientData> GetDataFromDB(string IDBenhNhan)
        {
            PatientData patient = new() { PatientID = IDBenhNhan };

            Dictionary<XMLDataType, string> XML_Query_List = new Dictionary<XMLDataType, string>
            {
                {XMLDataType.XML0,$"select * from TT_00_CHECKIN where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML1,$"select * from TT_01_TONGHOP where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML2,$"select * from TT_02_THUOC where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML3,$"select * from TT_03_DVKT_VTYT where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML4,$"select * from TT_04_CLS where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML5,$"select * from TT_05_LAMSANG where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML6,$"select * from TT_06_HIV where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML7,$"select * from TT_07_GIAY_RAVIEN where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML8,$"select * from TT_08_HSBA where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML9,$"select * from TT_09_CHUNGSINH where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML10,$"select * from TT_10_DUONGTHAI where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML11,$"select * from TT_11_NGHI_BHXH where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML13,$"select * from TT_13_GIAYCHUYENTUYEN where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML14,$"select * from TT_14_GIAYHENKHAMLAI where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" },
                {XMLDataType.XML15,$"select * from TT_15_DIEUTRILAO where MA_LK like N'%{IDBenhNhan}%' ORDER BY ID" }
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
                var errorList = await _googleSheetService.GetErrorListAsync();
                _googleSheetData = errorList; // Lưu vào biến
                _dynamicValidationService.ApplyDynamicValidation(patient, errorList);
            }
            catch (Exception ex)
            {
                // Log lỗi nếu cần, nhưng không làm gián đoạn flow chính
                System.Diagnostics.Debug.WriteLine($"DynamicValidationService error: {ex.Message}");
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

        // ===== Tra cứu DM Dược theo Duoc_Id
        public async Task<Thuoc?> GetThuocByDuocIdAsync(string duocId)
        {
            if (string.IsNullOrWhiteSpace(duocId)) return null;
            string connectionString = _configReader.Config["DB_string"];

            if (_configReader.Config.TryGetValue("VW_DUOC_SQL", out var custom))
            {
                // Dùng SQL tùy chỉnh nếu đã cấu hình
                await using var connectionCustom = new SqlConnection(connectionString);
                await connectionCustom.OpenAsync();
                var rowCustom = await connectionCustom.QueryFirstOrDefaultAsync(custom, new { duocId });
                if (rowCustom == null) return null;

                var thuocCustom = new Thuoc
                {
                    Duoc_Id = rowCustom.Duoc_Id?.ToString() ?? string.Empty,
                    MaDuoc = rowCustom.Ma_Duoc?.ToString() ?? string.Empty,
                    TenDuocDayDu = rowCustom.Ten_Duoc_Day_Du?.ToString() ?? string.Empty,
                    DonViTinh = rowCustom.Don_Vi_Tinh?.ToString() ?? string.Empty,
                    TenKhongDau = rowCustom.Ten_Khong_Dau?.ToString() ?? string.Empty,
                    TenLoaiVatTu = rowCustom.Ten_Loai_Vat_Tu?.ToString() ?? string.Empty,
                    TaiSuDung = rowCustom.Tai_Su_Dung?.ToString() ?? string.Empty,
                    DangBaoChe_Id = rowCustom.Dang_Bao_Che_Id?.ToString() ?? string.Empty,
                    NguonChiTra_Id = rowCustom.Nguoi_Tri_Tra_Id?.ToString() ?? string.Empty,
                    PhuongPhapCheBien_Id = rowCustom.Phuong_Phap_Che_Bien_Id?.ToString() ?? string.Empty,
                    PhamViThanhToan_Id = rowCustom.Pham_Vi_Thanh_Toan_Id?.ToString() ?? string.Empty,
                    ThongTinThau = rowCustom.Thong_Tin_Thau?.ToString() ?? string.Empty,
                };
                return thuocCustom;
            }

            // Nếu không có cấu hình tùy chỉnh: cho phép chỉ định DB chứa view
            if (!_configReader.Config.TryGetValue("VW_DUOC_DB", out var dmDb) || string.IsNullOrWhiteSpace(dmDb))
            {
                // Default theo môi trường hiện tại của bạn
                dmDb = "eHospital_ThuyDienUB";
            }
            var sql = $"SELECT TOP 1 * FROM [{dmDb}].dbo.vw_DM_Duoc WHERE Duoc_Id = @duocId";
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();
            var row = await connection.QueryFirstOrDefaultAsync(sql, new { duocId });
            if (row == null) return null;


            var thuoc = new Thuoc
            {
                Duoc_Id = row.Duoc_Id?.ToString() ?? string.Empty,
                MaDuoc = row.MaDuoc?.ToString() ?? row.Ma_Duoc?.ToString() ?? string.Empty,
                TenDuocDayDu = row.TenDuocDayDu?.ToString() ?? row.Ten_Duoc_Day_Du?.ToString() ?? string.Empty,
                DonViTinh = row.DonViTinh?.ToString() ?? row.Don_Vi_Tinh?.ToString() ?? string.Empty,
                TenKhongDau = row.TenKhongDau?.ToString() ?? row.Ten_Khong_Dau?.ToString() ?? string.Empty,
                TenLoaiVatTu = row.TenLoaiVatTu?.ToString() ?? row.Ten_Loai_Vat_Tu?.ToString() ?? string.Empty,
                TaiSuDung = row.TaiSuDung?.ToString() ?? row.Tai_Su_Dung?.ToString() ?? string.Empty,
                DangBaoChe_Id = row.DangBaoChe_ID?.ToString() ?? row.Dang_Bao_Che_Id?.ToString() ?? string.Empty,
                NguonChiTra_Id = row.NguonChiTra_ID?.ToString() ?? row.Nguoi_Tri_Tra_Id?.ToString() ?? string.Empty,
                PhuongPhapCheBien_Id = row.PhuongPhapCheBien_ID?.ToString() ?? row.Phuong_Phap_Che_Bien_Id?.ToString() ?? string.Empty,
                PhamViThanhToan_Id = row.PhamViThanhToan_ID?.ToString() ?? row.Pham_Vi_Thanh_Toan_Id?.ToString() ?? string.Empty,
                ThongTinThau = row.ThongTinThau?.ToString() ?? row.Thong_Tin_Thau?.ToString() ?? string.Empty,
            };
            return thuoc;
        }

        // ===== Tra cứu nhân viên theo NhanVien_Id hoặc tên
        public async Task<List<NhanVien>> SearchNhanVienAsync(string? keyword)
        {
            string connectionString = _configReader.Config["DB_string"];
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            // Nếu keyword là số -> ưu tiên tìm theo Id, ngược lại tìm theo tên/mã
            var sql = @"SELECT TOP 100 * FROM [eHospital_ThuyDienUB].dbo.vw_NhanVien
                        WHERE (@isNum = 1 AND NhanVien_Id = @id)
                           OR (@isNum = 0 AND (MaNhanVien LIKE N'%' + @kw + '%' OR TenNhanVien LIKE N'%' + @kw + '%' OR TenKhongDau LIKE N'%' + @kw + '%'))
                        ORDER BY TenNhanVien";

            bool isNum = int.TryParse(keyword, out int id);
            var rows = (await connection.QueryAsync(sql, new { isNum, id, kw = keyword ?? string.Empty })).ToList();

            var list = new List<NhanVien>(rows.Count);
            foreach (var r in rows)
            {
                list.Add(new NhanVien
                {
                    NhanVien_Id = Convert.ToInt32(r.NhanVien_Id),
                    MaNhanVien = r.MaNhanVien?.ToString() ?? string.Empty,
                    Ho = r.Ho?.ToString() ?? string.Empty,
                    Ten = r.Ten?.ToString() ?? string.Empty,
                    TenNhanVien = r.TenNhanVien?.ToString() ?? string.Empty,
                    TenNhanVien_RU = r.TenNhanVien_RU?.ToString() ?? string.Empty,
                    TenNhanVien_EN = r.TenNhanVien_EN?.ToString() ?? string.Empty,
                    TenTat = r.TenTat?.ToString() ?? string.Empty,
                    NgaySinh = r.NgaySinh as DateTime? ?? r.Ngay_Sinh as DateTime?,
                    GioiTinh = r.GioiTinh?.ToString() ?? string.Empty,
                    DiaChi = r.DiaChi?.ToString() ?? string.Empty,
                    PhongBan_Id = r.PhongBan_Id as int?,
                    DonViCongTac_Id = r.DonViCongTac_Id as int?,
                    ChucDanh_Id = r.ChucDanh_Id as int?,
                    ChucVu_Id = r.ChucVu_Id as int?,
                    TrinhDoChuyenMon_Id = r.TrinhDoChuyenMon_Id as int?,
                    QuocTich_Id = r.QuocTich_Id as int?,
                    TinhThanh_Id = r.TinhThanh_Id as int?,
                    QuanHuyen_Id = r.QuanHuyen_Id as int?,
                    XaPhuong_Id = r.XaPhuong_Id as int?,
                    DanToc_Id = r.DanToc_Id as int?,
                    NgheNghiep_Id = r.NgheNghiep_Id as int?,
                    Cmnd = r.CMND?.ToString() ?? string.Empty,
                    HoChieu = r.HoChieu?.ToString() ?? string.Empty,
                    TrucTiepSX = r.TrucTiepSX as bool?,
                    TiepXucDocHai = r.TiepXucDocHai as bool?,
                    TamNgung = r.TamNgung as bool?,
                    TenKhongDau = r.TenKhongDau?.ToString() ?? string.Empty,
                    NgayTao = r.NgayTao as DateTime?,
                    NguoiTao_Id = r.NguoiTao_Id as int?,
                    NgayCapNhat = r.NgayCapNhat as DateTime?,
                    NguoiCapNhat_Id = r.NguoiCapNhat_Id as int?,
                    MaDonVi = r.MaDonVi?.ToString() ?? string.Empty,
                    NgayVao = r.NgayVao as DateTime?,
                    MaNhanVienNSTL = r.MaNhanVienNSTL?.ToString() ?? string.Empty,
                    Ngay_Sinh = r.Ngay_Sinh as DateTime?,
                    SoChungChiHanhNghe = r.SoChungChiHanhNghe?.ToString() ?? string.Empty,
                    ChungChiHanhNghe = r.ChungChiHanhNghe?.ToString() ?? string.Empty,
                    MaLienThongBS = r.MaLienThongBS?.ToString() ?? string.Empty,
                    SeriCKS = r.SeriCKS?.ToString() ?? string.Empty,
                    MatKhauLienThongBS = r.MatKhauLienThongBS?.ToString() ?? string.Empty,
                    SoBHXH = r.SoBHXH?.ToString() ?? string.Empty,
                    UserName = r.UserName?.ToString() ?? string.Empty,
                    PassSign = r.PassSign?.ToString() ?? string.Empty,
                    Email = r.Email?.ToString() ?? string.Empty,
                    NgayCKS = r.NgayCKS as DateTime?,
                    ClientIDSmartCA = r.ClientIDSmartCA?.ToString() ?? string.Empty,
                    ClientSecretSmartCA = r.ClientSecretSmartCA?.ToString() ?? string.Empty,
                    Dutru1 = r.Dutru1?.ToString() ?? string.Empty,
                });
            }

            return list;
        }

        // ===== Tra cứu DichVu theo DichVu_Id hoặc MaDichVu
        public async Task<DichVu?> GetDichVuByIdOrCodeAsync(string keyword)
        {
            if (string.IsNullOrWhiteSpace(keyword)) return null;
            string connectionString = _configReader.Config["DB_string"];
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            // Cho phép override DB/schema qua cấu hình nếu cần
            var dmDb = _configReader.Config.TryGetValue("DM_DICHVU_DB", out var db) && !string.IsNullOrWhiteSpace(db)
                ? db
                : "eHospital_ThuyDienUB";

            var sql = $@"SELECT TOP 1 * FROM [{dmDb}].dbo.DM_DichVu WITH (NOLOCK)
                         WHERE (ISNUMERIC(@kw)=1 AND DichVu_Id = TRY_CONVERT(int, @kw))
                            OR (MaDichVu = @kw)";

            var row = await connection.QueryFirstOrDefaultAsync(sql, new { kw = keyword.Trim() });
            if (row == null) return null;

            return MapDichVu(row);
        }

        public async Task<List<DichVu>> SearchDichVuAsync(string? keyword)
        {
            string connectionString = _configReader.Config["DB_string"];
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            var dmDb = _configReader.Config.TryGetValue("DM_DICHVU_DB", out var db) && !string.IsNullOrWhiteSpace(db)
                ? db
                : "eHospital_ThuyDienUB";

            var sql = $@"SELECT TOP 100 * FROM [{dmDb}].dbo.DM_DichVu WITH (NOLOCK)
                         WHERE (@kw='' OR MaDichVu LIKE N'%' + @kw + '%' OR TenDichVu LIKE N'%' + @kw + '%' OR TenKhongDau LIKE N'%' + @kw + '%')
                         ORDER BY TenDichVu";

            var rows = (await connection.QueryAsync(sql, new { kw = keyword?.Trim() ?? string.Empty })).ToList();
            var list = new List<DichVu>(rows.Count);
            foreach (var r in rows)
            {
                list.Add(MapDichVu(r));
            }
            return list;
        }

        private static DichVu MapDichVu(dynamic r)
        {
            var o = new DichVu
            {
                DichVu_Id = r.DichVu_Id as int? ?? Convert.ToInt32(r.DichVu_Id),
                NhomDichVu_Id = r.NhomDichVu_Id as int? ?? 0,
                MaDichVu = r.MaDichVu?.ToString() ?? string.Empty,
                MaDichVu_Seg01 = r.MaDichVu_Seg01?.ToString(),
                MaDichVu_Seg02 = r.MaDichVu_Seg02?.ToString(),
                MaDichVu_Seg03 = r.MaDichVu_Seg03?.ToString(),
                MaDichVu_Seg04 = r.MaDichVu_Seg04?.ToString(),
                TenDichVu = r.TenDichVu?.ToString() ?? string.Empty,
                TenDichVu_En = r.TenDichVu_En?.ToString(),
                TenDichVu_Ru = r.TenDichVu_Ru?.ToString(),
                Cap = r.Cap as int? ?? 0,
                CapTren_Id = r.CapTren_Id as int?,
                DonViTinh = r.DonViTinh?.ToString(),
                Idx = r.Idx as int? ?? 0,
                ChonHetCapDuoi = r.ChonHetCapDuoi as int? ?? 0,
                CoGiaDichVu = r.CoGiaDichVu as int? ?? 0,
                GiaCoDinh = r.GiaCoDinh as int? ?? 0,
                ThucHienBenNgoai = r.ThucHienBenNgoai as int? ?? 0,
                SoPhim = r.SoPhim?.ToString(),
                MaQuiDinh = r.MaQuiDinh?.ToString(),
                TamNgung = r.TamNgung as int? ?? 0,
                TenKhongDau = r.TenKhongDau?.ToString(),
                NgayTao = r.NgayTao as DateTime?,
                NguoiTao_Id = r.NguoiTao_Id as int? ?? 0,
                NgayCapNhat = r.NgayCapNhat as DateTime?,
                NguoiCapNhat_Id = r.NguoiCapNhat_Id as int?,
                CoGiaTriChuan = r.CoGiaTriChuan as int? ?? 0,
                Test = r.Test as int? ?? 0,
                Attribute1 = r.Attribute1?.ToString(),
                Attribute2 = r.Attribute2?.ToString(),
                Attribute3 = r.Attribute3?.ToString(),
                Attribute4 = r.Attribute4?.ToString(),
                Attribute5 = r.Attribute5?.ToString(),
                NhomDichVu_Report_Local_Id = r.NhomDichVu_Report_Local_Id?.ToString(),
                NhomDichVu_Report_Global_Id = r.NhomDichVu_Report_Global_Id?.ToString(),
                ShortName = r.ShortName?.ToString(),
                InputCode = r.InputCode?.ToString(),
                NoResult = r.NoResult as int? ?? 0,
                ApplyFor = r.ApplyFor?.ToString(),
                PrintWhenNull = r.PrintWhenNull as int? ?? 0,
                ReportCode = r.ReportCode?.ToString(),
                ReportTitle = r.ReportTitle?.ToString(),
                DoUuTienDichVu = r.DoUuTienDichVu as int? ?? 0,
                MaMay = r.MaMay?.ToString(),
                BHYT = r.BHYT as int? ?? 0,
                IsThongSo = r.IsThongSo as int? ?? 0,
                CostCenter_Id = r.CostCenter_Id?.ToString(),
                Ma37 = r.Ma37?.ToString(),
                Ma50 = r.Ma50?.ToString(),
                TenDVTheoTT37 = r.TenDVTheoTT37?.ToString(),
                GhiChuTT37 = r.GhiChuTT37?.ToString(),
                MaDichVu_BenhVien = r.MaDichVu_BenhVien?.ToString(),
                LoaiPTTT = r.LoaiPTTT?.ToString(),
                ID_CODE = r.ID_CODE?.ToString(),
                PSXN = r.PSXN?.ToString(),
                SLDV = r.SLDV?.ToString(),
                SoNgayDichVu = r.SoNgayDichVu as int? ?? 0,
                ICD9_CM_Id = r.ICD9_CM_Id as int? ?? 0,
                MaXangDau = r.MaXangDau?.ToString(),
                MaChiSo = r.MaChiSo?.ToString(),
                PhamViTT_ID = r.PhamViTT_ID as int?,
                ICD9_ID = r.ICD9_ID as int?,
                DDchidinh = r.DDchidinh as int? ?? 0,
                MaQuiDinhCu = r.MaQuiDinhCu as int?,
                TenQuiDinhCu = r.TenQuiDinhCu?.ToString(),
                TGTHMin = r.TGTHMin?.ToString()
            };
            return o;
        }

    }
}
