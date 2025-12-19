using Dapper;
using Microsoft.Data.SqlClient;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Dto;
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
                {XMLDataType.XML2,@$"SELECT t.* ,  nv.chucdanh_id
FROM XML130.dbo.TT_02_THUOC AS t
LEFT JOIN eHospital_ThuyDienUB.dbo.vw_nhanvien AS nv
	ON nv.SoChungChiHanhNghe = t.MA_BAC_SI
where MA_LK = N'{IDBenhNhan}' ORDER BY ID" },
                {XMLDataType.XML3,@$"SELECT t.*, q.LoaiBenhPham_Id, nv.chucdanh_id,
    CASE 
        WHEN t.MA_DICH_VU IN (N'02.0295.0498', N'02.0286.0497', N'02.0296.0500') THEN
            (SELECT TOP 1 kq.MoTa_Text
             FROM XML130.dbo.TT_01_TONGHOP AS th 
             LEFT JOIN eHospital_ThuyDienUB.dbo.TiepNhan AS tn ON tn.SoTiepNhan = t.MA_LK 
             LEFT JOIN eHospital_ThuyDienUB.dbo.CLSYeuCau AS yc ON yc.TiepNhan_Id = tn.TiepNhan_Id
             LEFT JOIN eHospital_ThuyDienUB.dbo.CLSKetQua AS kq ON kq.CLSYeuCau_Id = yc.CLSYeuCau_Id 
             LEFT JOIN eHospital_ThuyDienUB.dbo.CLSYeuCauChiTiet AS ycct ON ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id 
             JOIN eHospital_ThuyDienUB.ehosdict.DM_DichVu AS dv ON dv.DichVu_Id = ycct.DichVu_Id AND dv.MaQuiDinh = t.MA_DICH_VU
             WHERE th.ma_lk = t.MA_LK)
        ELSE NULL
    END AS Mo_Ta_Text
	,
    TT.TrinhTuThucHien AS trinhTuThucHien,
    XNMD.MucBinhThuong AS mucBinhThuong,
    XNMD.KetQua AS ketQua
FROM XML130.dbo.TT_03_DVKT_VTYT AS t
--thời gian y lệnh đổi thành thời gian yêu cầu trong CLS yêu cầu
LEFT JOIN (
	SELECT	distinct
				ma_dich_vu = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end
									when LI.PhanNhom = 'DV' and map.TenField = '11' then 'VC.' + bvct.MaBenhVien
									else null end
				,ma_vat_tu =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.madichvu))  else null end
				, NGAY_YL =  case when xnct.Loai_IDRef = 'A' then format( yc.ThoiGianYeuCau,'yyyyMMddHHmm')
								when xnct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
								when xnct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then  format( ptvt.NgayTao,'yyyyMMddHHmm')
								when xnct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( kbvt.NgayTao,'yyyyMMddHHmm')
							else NULL
							end
				, SoBenhAn
				, yc.ThoiGianYeuCau
		From	(
					Select	
						xnct.XacNhanChiPhi_Id,
						xnct.Loai_IDRef,
						xnct.IDRef,
						xnct.NoiDung_Id,
						xnct.DonGiaHoTroChiTra,
						xn.TiepNhan_Id, xn.BenhAn_Id

					From	eHospital_ThuyDienUB.dbo.XacNhanChiPhi xn (nolock) 
						JOIN eHospital_ThuyDienUB.dbo.XacNhanChiPhiChiTiet  (nolock) xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
					Where SoXacNhan IS NOT NULL		
						
				) xnct
		left JOIN	eHospital_ThuyDienUB.dbo.VienPhiNoiTru_Loai_IDRef LI (nolock)  ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
		LEFT JOIN	(	SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
								CASE 
										WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
										WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
										WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
										--WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
										WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND (ldv.MaLoaiDichVu = 'ThuThuat' Or ndv.MaNhomDichVu IN ('0307', '0304', '2101') or dndv.DichVu_Id in (19601,19618,19619,20531,21998,28915)) THEN '18' --Thủ thuật
										WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND ldv.MaLoaiDichVu <> 'ThuThuat' And ndv.MaNhomDichVu NOT IN ('0307', '0304', '2101') and dndv.DichVu_Id not in (19601,19618,19619,20531,21998,28915) THEN '06' --Phẫu thuật
										WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
										WHEN mbc.TenField = 'VC' THEN '11'
										WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	--Máu
										WHEN mbc.TenField in  ('CPMau') THEN '09'	--Chế phẩm máu
										WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
										WHEN mbc.TenField = 'TDCN' THEN '05'
										WHEN mbc.TenField = 'K' THEN 'Khac'
										WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
										WHEN mbc.TenField = 'VTYT' THEN '10'
								ELSE mbc.TenField
						END  as TenField
						,mbc.Ma 
						FROM	eHospital_ThuyDienUB.ehosdict.DM_MauBaoCao mbc
						JOIN	eHospital_ThuyDienUB.ehosdict.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
						LEFT JOIN eHospital_ThuyDienUB.ehosdict.DM_DichVu dv on dndv.DichVu_Id = dv.DichVu_Id
						LEFT JOIN eHospital_ThuyDienUB.ehosdict.DM_NhomDichVu ndv on dv.NhomDichVu_Id = ndv.NhomDichVu_Id
						LEFT JOIN eHospital_ThuyDienUB.ehosdict.DM_LoaiDichVu ldv on ndv.LoaiDichVu_Id = ldv.LoaiDichVu_Id
						WHERE	mbc.MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id 
		left JOIN	eHospital_ThuyDienUB.dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id
		left join eHospital_ThuyDienUB.dbo.CLSYeuCauChiTiet (nolock)  clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
		left join eHospital_ThuyDienUB.dbo.ChungTuXuatBenhNhan  (nolock) xbn on ( xnct.IDRef = xbn.ChungTuXuatBN_Id and xnct.Loai_IDRef = 'I')
		LEFT JOIN eHospital_ThuyDienUB.dbo.BenhAn ba (nolock) on xnct.BenhAn_Id = ba.BenhAn_Id
		left join eHospital_ThuyDienUB.dbo.KhamBenh kb on kb.YeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
		left join eHospital_ThuyDienUB.ehosdict.DM_BenhVien bvct (Nolock) on kb.ChuyenDenBenhVien_Id = bvct.BenhVien_Id						   			
		LEFT JOIN	eHospital_ThuyDienUB.ehosdict.DM_Duoc (nolock)  d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
		LEFT JOIN	eHospital_ThuyDienUB.ehosdict.DM_LoaiDuoc (nolock)  ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
		left join eHospital_ThuyDienUB.ehosdict.DM_DichVu (nolock)  dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
		left join eHospital_ThuyDienUB.dbo.CLSYeuCau yc (nolock)  on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
		left join eHospital_ThuyDienUB.dbo.CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
		left join eHospital_ThuyDienUB.dbo.BenhAnPhauThuat_VTYT  (nolock) PTVT on xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
		left join eHospital_ThuyDienUB.dbo.KhamBenh_VTYT kbvt (nolock)  on  xnct.IDRef = kbvt.KhamBenh_VTYT_Id and li.PhanNhom = 'DU' and kbvt.Duoc_Id = d.Duoc_Id
		left join eHospital_ThuyDienUB.dbo.NoiTru_ToaThuoc nttt (nolock)  on xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
		left join eHospital_ThuyDienUB.dbo.NoiTru_KhamBenh ntkb  (nolock) on nttt.khambenh_id = ntkb.khambenh_id
		WHERE xnct.DonGiaHoTroChiTra > 0
			
		AND (		(LI.PhanNhom  in  ('DU') and  ld.LoaiVatTu_Id IN ('V'))
					or  ( isnull(map.TenField,'') not in  ('08' ,'16') and LI.PhanNhom  in  ('DV'))
			)
		and isnull(ld.MaLoaiDuoc,'') not in ('OXY', 'OXY1','LD0143','VTYT003')
) tg on tg.SoBenhAn = t.MA_LK
		AND tg.MA_DICH_VU = t.MA_DICH_VU
		AND tg.NGAY_YL = t.NGAY_YL

LEFT JOIN (
    SELECT distinct
        dv.MaQuiDinh,
        cls.ThoiGianYeuCau,
        cls.LoaiBenhPham_Id
    FROM eHospital_ThuyDienUB.dbo.clsyeucauchitiet AS clsct
    LEFT JOIN eHospital_ThuyDienUB.dbo.clsyeucau AS cls
        ON clsct.CLSYeuCau_Id = cls.CLSYeuCau_Id
    LEFT JOIN eHospital_ThuyDienUB.dbo.BenhAn AS ba
        ON cls.benhan_id = ba.benhan_id
    LEFT JOIN eHospital_ThuyDienUB.ehosdict.dm_dichvu AS dv
        ON clsct.DichVu_Id = dv.DichVu_Id
    WHERE dv.MaQuiDinh IN (N'24.0001.1714', N'24.0005.1716', N'24.0003.1715')
) AS q
    ON t.MA_DICH_VU = q.MaQuiDinh
    AND q.ThoiGianYeuCau = tg.ThoiGianYeuCau

LEFT JOIN eHospital_ThuyDienUB.dbo.vw_nhanvien AS nv
	ON nv.SoChungChiHanhNghe = t.MA_BAC_SI
LEFT JOIN (
    SELECT 
        pt.TrinhTuThucHien, 
        dv.MaQuiDinh,
        ba.SoBenhAn,
        cls.ThoiGianYeuCau
    FROM eHospital_ThuyDienUB.dbo.BenhAnPhauThuat AS pt
    LEFT JOIN eHospital_ThuyDienUB.dbo.BenhAn AS ba 
        ON ba.BenhAn_Id = pt.BenhAn_Id
    LEFT JOIN eHospital_ThuyDienUB.dbo.CLSYeuCau AS cls 
        ON cls.CLSYeuCau_Id = pt.CLSYeuCau_Id
    LEFT JOIN eHospital_ThuyDienUB.dbo.CLSYeuCauChiTiet AS ct 
        ON cls.CLSYeuCau_Id = ct.CLSYeuCau_Id
    LEFT JOIN eHospital_ThuyDienUB.ehosdict.DM_DichVu AS dv 
        ON dv.dichvu_id = ct.DichVu_Id
) AS TT ON TT.MaQuiDinh = t.MA_DICH_VU 
   AND tt.thoigianyeucau = tg.ThoiGianYeuCau
    AND TT.SoBenhAn = Ma_LK 

LEFT JOIN (
    select ct.MucBinhThuong, ba.SoBenhAn, yc.ThoiGianYeuCau, dv.MaQuiDinh, ct.KetQua
    from eHospital_ThuyDienUB.dbo.CLSKetQua kq
    left join eHospital_ThuyDienUB.dbo.CLSYeuCau yc 
        on yc.clsyeucau_id = kq.CLSYeuCau_Id
    left join eHospital_ThuyDienUB.dbo.clsketquachitiet ct 
        on kq.CLSKetQua_Id = ct.CLSKetQua_Id
    left join eHospital_ThuyDienUB.dbo.BenhAn ba 
        on ba.BenhAn_Id = yc.BenhAn_Id
    left join eHospital_ThuyDienUB.ehosdict.DM_DichVu dv 
        on dv.DichVu_Id = ct.DichVu_Id
    where yc.NhomDichVu_Id = N'73'
)XNMD on XNMD.SoBenhAn = Ma_LK 
        AND XNMD.thoigianyeucau = tg.ThoiGianYeuCau
        AND XNMD.MaQuiDinh = t.MA_DICH_VU
WHERE t.Ma_LK = N'{IDBenhNhan}'
order by  STT;" },
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

        /// <summary>
        /// Lấy danh sách MA_LK theo MA_BN và khoảng thời gian
        /// </summary>
        public async Task<List<MaLkSearchResult>> GetMaLkByMaBnAndDate(string maBn, string ngayVaoFrom, string ngayRaTo)
        {
            try
            {
                string connectionString = _configReader.Config["DB_string"];

                // Query để lấy danh sách MA_LK
                string query = @"
                    SELECT MA_BN, MA_LK, NGAY_VAO, NGAY_RA
                    FROM TT_01_TONGHOP
                    WHERE MA_BN = @maBn
                      AND NGAY_VAO >= @ngayVaoFrom 
                      AND NGAY_RA <= @ngayRaTo
                    ORDER BY NGAY_VAO DESC";

                // Debug log
                System.Diagnostics.Debug.WriteLine($"=== DataMapper Query ===");
                System.Diagnostics.Debug.WriteLine($"MA_BN: {maBn}");
                System.Diagnostics.Debug.WriteLine($"NGAY_VAO >= {ngayVaoFrom}");
                System.Diagnostics.Debug.WriteLine($"NGAY_RA <= {ngayRaTo}");

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    var results = await connection.QueryAsync<MaLkSearchResult>(query, new 
                    { 
                        maBn, 
                        ngayVaoFrom, 
                        ngayRaTo 
                    });
                    
                    System.Diagnostics.Debug.WriteLine($"Kết quả: Tìm thấy {results.Count()} MA_LK");
                    foreach (var r in results)
                    {
                        System.Diagnostics.Debug.WriteLine($"  → MA_LK: {r.Ma_Lk}, NGAY_VAO: {r.Ngay_Vao}, NGAY_RA: {r.Ngay_Ra}");
                    }
                    System.Diagnostics.Debug.WriteLine($"=======================");
                    
                    return results.ToList();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi khi tìm kiếm MA_LK: {ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return new List<MaLkSearchResult>();
            }
        }

    }
}
