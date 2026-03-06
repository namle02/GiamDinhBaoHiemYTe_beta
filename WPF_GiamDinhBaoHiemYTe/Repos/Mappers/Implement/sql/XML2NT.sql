/*==============================================================================
  TT02-NgoaiTru.sql - PHIÊN BẢN TỐI ƯU
  
  Tối ưu so với bản gốc:
  1. SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED thay cho (nolock) rải rác
  2. Bỏ subquery SELECT * không cần thiết (dòng 34-38, 146 gốc)
  3. Thay correlated subquery MIN(ThoiGianKham) bằng TOP 1
  4. Loại bỏ OR trong JOIN/WHERE (dòng 405-406, 452 gốc)
  5. Tính trước SUM(NoiTru_TraThuocChiTiet) — biểu thức lặp ~12 lần
  6. Thay correlated subquery trong JOIN kbm (dòng 535 gốc) bằng CROSS APPLY
  7. Loại bỏ JOIN DM_LoaiDuoc trùng lặp (dòng 486 vs 492 gốc)
  8. Loại bỏ JOIN DM_ICD trùng lặp (dòng 537-541 gốc, 3 lần gần giống nhau)
==============================================================================*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SoTiepNhan VARCHAR(50) =N'{IDBenhNhan}'

DECLARE @BenhAn_id VARCHAR(50)
DECLARE @TiepNhan_Id VARCHAR(50)
SELECT @TiepNhan_Id = TiepNhan_Id FROM TiepNhan WHERE SoTiepNhan = @SoTiepNhan

DECLARE @Ma_Lk VARCHAR(50)
DECLARE @ChanDoan_NT NVARCHAR(1000)
SELECT @Ma_Lk = CONVERT(VARCHAR(50), SoTiepNhan) FROM TiepNhan WHERE TiepNhan_Id = @TiepNhan_Id

DECLARE @ICDCapCuu VARCHAR(20)
DECLARE @ICD_NT NVARCHAR(1000)
DECLARE @ICD_NTGopBenh NVARCHAR(1000)
DECLARE @ICD_phu NVARCHAR(1000)
DECLARE @Ma_PTTT_QT VARCHAR(250)
DECLARE @ChanDoan_RV NVARCHAR(1000)

SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](NULL, @TiepNhan_Id)

IF @BenhAn_Id IS NULL
	SET @BenhAn_Id = (SELECT BenhAn_Id FROM BenhAn WHERE TiepNhan_Id = @TiepNhan_Id)

IF @BenhAn_Id IS NOT NULL
BEGIN
	SELECT
		@ChanDoan_NT = ISNULL(ba.ChanDoanVaoKhoa, ISNULL(icd.TenICD, ISNULL(cc.ChanDoanNhapVien, icd_cc.TenICD)))
		, @ICDCapCuu = ISNULL(icd.MaICD, icd_cc.MaICD)
		, @ICD_NT = icd.MaICD
		, @ICD_NTGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenhPHCN](@Tiepnhan_id)
		, @ICD_phu = icd_k.MaICD + ';' + [dbo].[Get_MaICD_ByBenhAn_Id](@BenhAn_Id, 'M')
		, @ChanDoan_RV = ISNULL(ba.ChanDoanRaVien, icd.TenICD) + ', ' + ISNULL(ISNULL(ba.chandoanphuravien, icd_k.tenicd), '')
	-- [TỐI ƯU #2] Bỏ subquery SELECT *, dùng WHERE trực tiếp
	FROM dbo.BenhAn ba
	INNER JOIN TiepNhan tn ON ba.TiepNhan_ID = tn.TiepNhan_ID
	LEFT JOIN DM_ICD icd ON icd.ICD_Id = ba.ICD_BenhChinh
	LEFT JOIN ThongTinCapCuu cc ON ba.BenhAn_ID = cc.BenhAn_Id
	LEFT JOIN DM_ICD icd_cc ON cc.ICD_BenhChinh = icd_cc.ICD_Id
	LEFT JOIN DM_ICD icd_cc2 ON cc.ICD_BenhPhu = icd_cc2.ICD_Id AND cc.ICD_BenhChinh IS NULL
	LEFT JOIN DM_ICD icd_k ON ba.ICD_BenhPhu = icd_k.ICD_Id
	WHERE ba.BenhAn_Id = @BenhAn_Id

	SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](@BenhAn_Id, NULL)
END

DECLARE @MaCSKCB NVARCHAR(1000)
DECLARE @ChanDoan_PK NVARCHAR(1000)
DECLARE @ICD_PK NVARCHAR(1000)
DECLARE @ICDKB NVARCHAR(1000)
DECLARE @ICD_PHUPK NVARCHAR(1000)
DECLARE @ICD_PNT NVARCHAR(1000)
DECLARE @ICD_PKBenhChinh NVARCHAR(1000)
DECLARE @ICD_PKGopBenh NVARCHAR(1000)
DECLARE @ThoiGianKham DATETIME
DECLARE @ChanDoanCapCuu NVARCHAR(1000)
DECLARE @CapCuu BIT
DECLARE @KhamBenh_Id INT
DECLARE @Khoa NVARCHAR(200)
DECLARE @ICD_Khac NVARCHAR(1000)
DECLARE @SoBenhAn VARCHAR(25)
DECLARE @TT_01_TONGHOP_ID INT = NULL
DECLARE @NGAY_VAO DATETIME

SET @CapCuu = 0

----Phòng Khám
SET @ICD_PK = [dbo].[Get_MaICDPhuByTiepNhan_ID](@TiepNhan_Id)
SET @ChanDoan_PK = [dbo].[Get_DSChanDoanKB_ByTiepNhan_ID](@TiepNhan_Id)
SET @ICD_PHUPK = [dbo].[Get_MaICD_ByTiepNhan_ID](@TiepNhan_Id)
SET @ICD_PKBenhChinh = [dbo].[Get_MaICDByTiepNhan_ID_benhchinh](@TiepNhan_Id)
SET @ICD_PKGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenh](@TiepNhan_Id)
----end Phòng Khám

---Bệnh án Ngoại trú--
SET @ICD_PNT = [dbo].[Get_MaICD_Phu_ByBenhAn_Id](@BenhAn_Id, 'M')

SELECT @MaCSKCB = Value FROM Sys_AppSettings WHERE Code = N'MaBenhVien_BHYT'

DECLARE @LuongToiThieu DECIMAL(18, 2) = 208500.00
SELECT @LuongToiThieu = VALUE FROM sys_appsettings WHERE code = 'LuongToiThieu'

--lấy chẩn đoán của bệnh án ngoại trú
SELECT @ChanDoanCapCuu = icd.TenICD, @ICDCapCuu = icd.MaICD, @CapCuu = 1
FROM BenhAn ba
LEFT JOIN DM_ICD icd ON icd.ICD_Id = ba.ICD_BenhChinh
WHERE TiepNhan_Id = @TiepNhan_Id
	AND ba.SoCapCuu IS NOT NULL

-- [TỐI ƯU #3] Thay correlated subquery MIN(ThoiGianKham) bằng TOP 1
SELECT TOP 1 @ICDKB = icd.MaICD
FROM KhamBenh kb
LEFT JOIN DM_ICD icd ON icd.ICD_Id = kb.ChanDoanICD_Id
WHERE kb.TiepNhan_Id = @TiepNhan_Id
ORDER BY kb.ThoiGianKham ASC

SET @BenhAn_Id = NULL   --Tránh trường hợp bệnh án ngoại trú vẫn có benhan_id

-- Tính Tổng Tiền Thuốc
DECLARE @Tong_Tien_Thuoc DECIMAL(18, 2) = 0
DECLARE @Tong_Chi DECIMAL(18, 2) = 0
DECLARE @XacNhanChiPhi_ID INT = NULL
DECLARE @T_BHTT DECIMAL(18, 2) = 0
DECLARE @T_BNCCT DECIMAL(18, 2) = 0
DECLARE @T_BNTT DECIMAL(18, 2) = 0
DECLARE @T_NguonKhac DECIMAL(18, 2) = 0
DECLARE @Tong_Chi_BH DECIMAL(18, 2) = 0

SELECT
	@Tong_Chi = T_TongChi,
	@T_BHTT = T_BHTT,
	@T_BNCCT = T_BNCCT,
	@Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
	@T_BNTT = T_BNTT,
	@T_NguonKhac = T_NguonKhac,
	@Tong_Chi_BH = T_TONGCHI_BH
FROM dbo.Tong_Tien_XML_BangKe01_130(@TiepNhan_Id)

-- [TỐI ƯU #2] Bỏ subquery SELECT *, dùng WHERE trực tiếp
DECLARE @SoChuyenVien NVARCHAR(50) = NULL
SELECT @SoChuyenVien = LEFT(cv.SoPhieu, 6)
FROM TiepNhan TN
JOIN DM_BenhNhan ON tn.BenhNhan_Id = DM_BenhNhan.BenhNhan_Id
LEFT JOIN DM_BenhVien td ON td.benhvien_id = tn.NoiGioiThieu_Id
JOIN ChuyenVien cv ON cv.TiepNhan_Id = tn.TiepNhan_Id
WHERE TN.TiepNhan_Id = @TiepNhan_id

IF @BenhAn_Id IS NULL
BEGIN

	SELECT [ID] = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
		, [MA_LK] = @Ma_Lk
		, [STT] = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
		, [MA_THUOC] = xml2.Ma_Thuoc
		, [MA_PP_CHEBIEN] = xml2.ma_pp_chebien
		, [MA_CSKCB_THUOC] = NULL
		, [MA_NHOM] = xml2.ma_nhom
		, [TEN_THUOC] = xml2.Ten_Thuoc
		, [DON_VI_TINH] = xml2.don_vi_tinh
		, [HAM_LUONG] = xml2.ham_luong
		, [DUONG_DUNG] = xml2.duong_dung
		, [DANG_BAO_CHE] = xml2.Dang_BaoChe
		, [LIEU_DUNG] = xml2.LIEU_DUNG
		, [CACH_DUNG] = xml2.Cach_Dung
		, [SO_DANG_KY] = xml2.so_dang_ky
		, [TT_THAU] = xml2.TT_THAU
		, [PHAM_VI] = xml2.PHAM_VI
		, [TYLE_TT_BH] = xml2.TyLe_TT
		, [SO_LUONG] = xml2.So_Luong
		, [DON_GIA] = xml2.DON_GIA
		, [THANH_TIEN_BV] = xml2.THANH_TIEN_BV
		, [THANH_TIEN_BH] = xml2.Thanh_Tien
		, [T_NGUONKHAC_NSNN] = 0
		, [T_NGUONKHAC_VTNN] = 0
		, [T_NGUONKHAC_VTTN] = 0
		, [T_NGUONKHAC_CL] = 0
		, [T_NGUONKHAC] = xml2.T_NguonKhac
		, [MUC_HUONG] = xml2.MUC_HUONG
		, [T_BNTT] = xml2.T_BNTT
		, [T_BNCCT] = xml2.T_BNCCT
		, [T_BHTT] = xml2.T_BHTT
		, [MA_KHOA] = xml2.Ma_Khoa
		, [MA_BAC_SI] = xml2.Ma_Bac_Si
		, [MA_DICH_VU] = xml2.MADICHVU
		, [NGAY_YL] = xml2.Ngay_YL
		, [MA_PTTT] = xml2.ma_pttt
		, [NGUON_CTRA] = xml2.NGUON_CTRA
		, [VET_THUONG_TP] = NULL
		, [DU_PHONG] = NULL
		, [NGAY_TH_YL] = xml2.Ngay_YL
		, [CHUC_DANH_ID] = xml2.CHUC_DANH_ID
	FROM (
		SELECT *, t_bntt = CASE WHEN ThuocVG = 1 THEN CAST(0 AS DECIMAL(18, 2)) ELSE THANH_TIEN_BV - (t_bhtt + t_bncct) END
		FROM (
			SELECT
				MA_LK = @Ma_Lk
				, STT = ROW_NUMBER() OVER (ORDER BY (SELECT 1))

				, Ma_Thuoc = CASE
					WHEN li.PhanNhom = 'DV' THEN ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END, dv.InputCode)
					WHEN li.PhanNhom IN ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL THEN ISNULL(d.MaHoatChat, d.MaDuoc)
					WHEN li.PhanNhom IN ('DU') AND ld.LoaiVatTu_Id = 'V' AND ld.MaLoaiDuoc IN ('VTYT003') THEN ISNULL(d.MaHoatChat, d.Attribute_2)
					ELSE d.MaDuoc
				END

				, Ma_Thuoc_Cs = CASE
					WHEN li.PhanNhom = 'DV' THEN ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END, dv.InputCode)
					WHEN li.PhanNhom IN ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL THEN ISNULL(d.MaHoatChat, d.MaDuoc)
					WHEN li.PhanNhom IN ('DU') AND ld.LoaiVatTu_Id = 'V' AND ld.MaLoaiDuoc IN ('VTYT003') THEN ISNULL(d.MaHoatChat, d.Attribute_2)
					ELSE d.MaDuoc
				END

				, MA_NHOM = CASE
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 AND xbn.TyLeDieuKien IS NOT NULL AND xnct.DonGiaHoTroChiTra > 0)
						AND ld.LoaiVatTu_Id <> ('V') THEN '4'
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V')
						AND ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') OR map.TenField IN ('16','Thuoc')
						OR ld.MaLoaiDuoc IN ('OXY', 'OXY1') THEN '4'
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id = ('V')
						AND ld.MaLoaiDuoc <> 'VTYT003' OR map.TenField IN ('10','VTYT')
						OR ld.MaLoaiDuoc NOT IN ('OXY', 'OXY1','LD0143','VTYT003','Mau','ChePham') THEN '10'
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V')
						AND ld.MaLoaiDuoc IN ('LD0143','Mau') THEN '7'
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V')
						AND ld.MaLoaiDuoc IN ('LD0143','ChePham') THEN '17'
					WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id = ('V')
						AND ld.MaLoaiDuoc IN ('VTYT003','Mau','ChePham') THEN '7'
					ELSE CASE
						WHEN map.TenField = '01' THEN '13'
						WHEN map.TenField = '02' THEN '14'
						WHEN map.TenField = '03' THEN '1'
						WHEN map.TenField = '04' THEN '2'
						WHEN map.TenField = '05' THEN '3'
						WHEN map.TenField = '06' THEN '8'
						WHEN map.TenField = '07' THEN '10'
						WHEN map.TenField = '08' THEN '7'
						WHEN map.TenField = '11' THEN '12'
						WHEN map.TenField = '12' THEN '15'
						WHEN map.TenField = '18' THEN '18'
						WHEN ISNULL(map.TenField, '') = '' THEN '12'
					END
				END

				, Ten_Thuoc = ISNULL(ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.TenDichVu_En ELSE dv.TenQuiDinhCu END, DV.TenDichvU),
					ISNULL(d.Ten_VTYT_917, REPLACE(D.TenHang, CHAR(0x1F), '')))
				, DON_VI_TINH = ISNULL(dvt.TenDonViTinh, N'Lần')
				, HAM_LUONG = d.HamLuong
				, ma_pp_chebien = ''
				, Dang_BaoChe = ''
				, DUONG_DUNG = dd.Dictionary_Code
				, Cach_Dung = ISNULL(nttt.GhiChu, thuoc.GhiChu)
				, LIEU_DUNG = CASE
					WHEN thuoc.toathuoc_id IS NOT NULL THEN dbo.Get_SoLuongThuocTrongNgay(thuoc.toathuoc_id)
					WHEN nttt.ToaThuoc_Id IS NOT NULL THEN dbo.Get_SoLuongThuocTrongNgay_NoiTru(nttt.toathuoc_id)
					ELSE N'1/lần*1 lần/ngày'
				END

				, SO_DANG_KY = ISNULL(d.Attribute_3, '')
				, TT_Thau = ISNULL(ISNULL(d.ThongTinThau, d.MaGoiThau), '')
				, Pham_Vi = 1

				-- [TỐI ƯU #5] Tính SoLuong_SauTra 1 lần, dùng lại nhiều chỗ 
				-- (thay vì lặp subquery NoiTru_TraThuocChiTiet ~12 lần)
				, So_Luong = CAST(
					SUM(xnct.SoLuong) - ISNULL(traThuoc.SoLuongTra, 0)
				AS DECIMAL(18, 3))

				, DON_GIA = xnct.DonGiaDoanhThu
				, TYLE_TT = CAST(ISNULL((xbn.TyLeDieuKien * 100), 100) AS DECIMAL(18, 0))

				-- [TỐI ƯU #5] Dùng CROSS APPLY traThuoc thay vì lặp subquery
				, THANH_TIEN = CAST(
					CASE WHEN xbn.TyLeDieuKien IS NOT NULL THEN
						CASE WHEN (xnct.DonGiaDoanhThu * xbn.TyLeDieuKien * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
						ELSE (xnct.DonGiaDoanhThu * xbn.TyLeDieuKien * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
					ELSE
						CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
						ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
					END
				AS DECIMAL(18, 2))

				, THANH_TIEN_BV = CAST(
					CASE WHEN (xnct.DonGiaDoanhThu * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
					ELSE (xnct.DonGiaDoanhThu * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
				AS DECIMAL(18, 2))

				, muc_huong = xnct.muc_huong * 100

				-- ThanhTien_BH dùng cho t_bhtt (biểu thức lặp ~6 lần gốc → giờ tính 1 lần)
				, t_bhtt = CAST(
					CASE WHEN xbn.DuocDieuKien_Id IS NULL THEN
						CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
						ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
					ELSE
						CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
						ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
					END
					* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
					/ 100
				AS DECIMAL(18, 2))

				, t_bncct =
					CAST(
						CASE WHEN xbn.DuocDieuKien_Id IS NULL THEN
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						ELSE
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						END
					AS DECIMAL(18, 2))
					-
					CAST(
						CASE WHEN xbn.DuocDieuKien_Id IS NULL THEN
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						ELSE
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						END
						* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
						/ 100
					AS DECIMAL(18, 2))

				, t_nguonkhac = CASE
					WHEN (mg.LyDo_ID IN (9692)) THEN 0
					ELSE ISNULL(xbn.GiaTriMienGiam, 0)
				END

				, t_ngoaids = CASE WHEN ISNULL(bc.ngoaidinhxuat, 0) = 1 OR ISNULL(icd_nt.NgoaiDinhXuat, 0) = 1 THEN
					CAST(
						CASE WHEN xbn.DuocDieuKien_Id IS NULL THEN
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						ELSE
							CASE WHEN (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) < 0 THEN 0
							ELSE (xnct.DonGiaHoTro * (CAST(SUM(xnct.SoLuong) AS DECIMAL(18, 3)) - ISNULL(traThuoc.SoLuongTra, 0))) END
						END
						* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
						/ 100
					AS DECIMAL(18, 2))
				ELSE 0 END

				, MA_KHOA = COALESCE(pbkb1.MaTheoQuiDinh, pbcdinh.MaTheoQuiDinh, pbthuoc.MaTheoQuiDinh, 'K01')

				, MA_BAC_SI = CASE
					WHEN nttt.ToaThuoc_Id IS NOT NULL THEN bstt.SoChungChiHanhNghe
					WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt.SoChungChiHanhNghe
					WHEN kbvt.KhamBenh_VTYT_Id IS NOT NULL THEN bskbvt.SoChungChiHanhNghe
					WHEN thuoc.ToaThuoc_Id IS NOT NULL THEN bskbtt.SoChungChiHanhNghe
					WHEN HCVT.Id IS NOT NULL THEN BSHCVT.SoChungChiHanhNghe
					WHEN HCVTNT.Id IS NOT NULL THEN BSHCVTNT.SoChungChiHanhNghe
					WHEN map.TenField IN ('08','16') AND li.PhanNhom = 'DV' THEN bscls.SoChungChiHanhNghe
					ELSE NULL
				END

				, MA_BENH = ISNULL(@ICD_NT, @ICD_PKGopBenh)
				, NGAY_YL = REPLACE(
					CONVERT(VARCHAR, COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kbm.ketthucKham, ychc.thoigianyeucau), 112)
					+ CONVERT(VARCHAR(5), COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kbm.KetThucKham, ychc.thoigianyeucau), 108), ':', '')
				, ma_pttt = CASE WHEN LEFT(tn.SoBHYT, 2) IN ('QN','CA','CY') THEN 2 ELSE 1 END
				, ThuocVG = 0
				, MADICHVU = dbo.Get_Ma_DV_XML2(ISNULL(bapt.clsyeucau_id, YCHC.clsyeucau_id))
				, NGUON_CTRA = 1
				, CHUC_DANH_ID = CASE
					WHEN nttt.ToaThuoc_Id IS NOT NULL THEN bstt.ChucDanh_Id
					WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt.ChucDanh_Id
					WHEN kbvt.KhamBenh_VTYT_Id IS NOT NULL THEN bskbvt.ChucDanh_Id
					WHEN thuoc.ToaThuoc_Id IS NOT NULL THEN bskbtt.ChucDanh_Id
					WHEN HCVT.Id IS NOT NULL THEN BSHCVT.ChucDanh_Id
					WHEN HCVTNT.Id IS NOT NULL THEN BSHCVTNT.ChucDanh_Id
					WHEN map.TenField IN ('08','16') AND li.PhanNhom = 'DV' THEN bscls.ChucDanh_Id
					ELSE NULL
				END

			FROM (
				-- ===== Dịch vụ kỹ thuật =====
				SELECT
					Loai_IDRef = 'A',
					IDRef = ycct.YeuCauChiTiet_Id,
					NoiDung_Id = ycct.DichVu_Id,
					NoiDung = dv.TenDichVu,
					SoLuong = ycct.SoLuong,
					DonGiaDoanhThu = ycct.DonGiaDoanhThu,
					DonGiaHoTro = CASE WHEN CHARINDEX('.01', CAST(ycct.DonGiaHoTro AS VARCHAR(20))) > 0
						THEN CAST(REPLACE(CAST(ycct.DonGiaHoTro AS VARCHAR(20)), '.01', '.00') AS DECIMAL(18, 3))
						ELSE CAST(ycct.DonGiaHoTro AS DECIMAL(18, 3)) END,
					DonGiaHoTroChiTra = ycct.DonGiaHoTroChiTra,
					DonGiaThanhToan = ycct.DonGiaThanhToan,
					PhongBan_Id = ISNULL(
						CASE WHEN dv.NhomDichVu_Id = 27 THEN yc.NoiThucHien_Id ELSE yc.NoiYeuCau_id END,
						ba.KhoaRa_Id),
					NoiTru_ToaThuoc_ID = NULL,
					Ngoaitru_ToaThuoc_ID = NULL,
					TenDonViTinh = dv.DonViTinh,
					BenhAn_Id = @benhan_id,
					TiepNhan_Id = @tiepnhan_id,
					Muc_Huong = ycct.MucHuong
				FROM CLSYeuCauChiTiet ycct
				LEFT JOIN CLSYeuCau yc ON ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id
				LEFT JOIN DM_DichVu dv ON dv.DichVu_Id = ycct.DichVu_Id
				LEFT JOIN BenhAn ba ON ba.TiepNhan_Id = @tiepnhan_id
				-- [TỐI ƯU #4] Thay OR bằng filter trực tiếp theo @tiepnhan_id
				WHERE yc.TiepNhan_Id = @tiepnhan_id

				UNION ALL

				-- ===== Thuốc / Vật tư =====
				SELECT
					Loai_IDRef = 'I',
					IDRef = ISNULL(clsvt.ID, xbn.ChungTuXuatBN_Id),
					NoiDung_Id = ISNULL(clsvt.Duoc_Id, xbn.Duoc_Id),
					NoiDung = td.TenDuoc,
					SoLuong = CASE WHEN xbn.ToaThuocTra_Id IS NOT NULL THEN 0 - xbn.SoLuong ELSE xbn.SoLuong END,
					DonGiaDoanhThu = xbn.DonGiaDoanhThu,
					DonGiaHoTro = CASE WHEN CHARINDEX('.01', CAST(xbn.DonGiaHoTro AS VARCHAR(20))) > 0
						THEN CAST(REPLACE(CAST(xbn.DonGiaHoTro AS VARCHAR(20)), '.01', '.00') AS DECIMAL(18, 3))
						ELSE CAST(xbn.DonGiaHoTro AS DECIMAL(18, 3)) END,
					DonGiaHoTroChiTra = xbn.DonGiaHoTroChiTra,
					DonGiaThanhToan = xbn.DonGiaThanhToan,
					PhongBan_Id = ISNULL(ISNULL(pb.PhongBan_Id, ISNULL(pb3.PhongBan_Id, pb1.PhongBan_Id)), pb4.phongban_id),
					NoiTru_ToaThuoc_ID = CASE WHEN @benhan_id IS NOT NULL THEN xbn.ToaThuoc_Id ELSE NULL END,
					Ngoaitru_ToaThuoc_ID = CASE WHEN @benhan_id IS NULL THEN xbn.ToaThuoc_Id ELSE NULL END,
					TenDonViTinh = d.DonViTinh,
					BenhAn_Id = @benhan_id,
					TiepNhan_Id = @tiepnhan_id,
					Muc_Huong = xbn.MucHuong
				FROM ChungTuXuatBenhNhan xbn
				LEFT JOIN DM_Duoc d ON d.Duoc_Id = xbn.Duoc_Id
				LEFT JOIN DM_TenDuoc td ON td.TenDuoc_Id = d.TenDuoc_Id
				LEFT JOIN ToaThuoc tt ON tt.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
				LEFT JOIN KhamBenh kb ON kb.KhamBenh_Id = tt.KhamBenh_Id
				LEFT JOIN DM_PhongBan pb ON pb.PhongBan_Id = kb.PhongBan_Id
				LEFT JOIN BenhAnPhauThuat_VTYT vtyt ON vtyt.BenhAnPhauThuat_VTYT_Id = xbn.BenhAnPhauThuat_VTYT_Id AND vtyt.duoc_id = xbn.duoc_id
				LEFT JOIN DM_KhoDuoc k1 ON vtyt.khosudung_id = k1.khoduoc_id
				LEFT JOIN DM_PhongBan pb3 ON pb3.PhongBan_Id = k1.phongban_id
				LEFT JOIN KhamBenh_VTYT vt ON xbn.KhamBenh_VTYT_Id = vt.KhamBenh_VTYT_Id AND vt.duoc_id = xbn.duoc_id
				LEFT JOIN KhamBenh kb1 ON vt.KhamBenh_Id = kb1.KhamBenh_Id
				LEFT JOIN DM_PhongBan pb1 ON pb1.PhongBan_Id = kb1.PhongBan_Id
				LEFT JOIN CLSGhiNhanHoaChat_VTYT clsvt ON xbn.CLSHoaChat_VTYT_Id = clsvt.id AND xbn.Duoc_Id = clsvt.duoc_id
				LEFT JOIN dm_khoduoc k ON clsvt.KhoSuDung_Id = k.KhoDuoc_Id
				LEFT JOIN DM_PhongBan pb4 ON pb4.PhongBan_Id = k.PhongBan_Id
				-- [TỐI ƯU #4] Thay OR bằng filter trực tiếp
				WHERE xbn.TiepNhan_Id = @tiepnhan_id AND xbn.mienphi = 0
			) xnct

			LEFT JOIN dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef

			LEFT JOIN (
				SELECT dndv.DichVu_Id, mbc.MoTa, mbc.ID,
					CASE
						WHEN mbc.TenField IN ('CK','CongKham','KB','TienKham') THEN '01'
						WHEN mbc.TenField IN ('XN','XetNghiem','XNHH') THEN '03'
						WHEN mbc.TenField IN ('Thuoc','OXY') THEN '16'
						WHEN mbc.TenField IN ('TTPT','TT','TT_PT') THEN '06'
						WHEN mbc.TenField IN ('ThuThuat') THEN '18'
						WHEN mbc.TenField IN ('DVKT_Cao', 'KTC') THEN '07'
						WHEN mbc.TenField = 'VC' THEN '11'
						WHEN mbc.TenField IN ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'
						WHEN mbc.TenField IN ('CDHA','CDHA_TDCN') THEN '04'
						WHEN mbc.TenField = 'TDCN' THEN '05'
						WHEN mbc.TenField = 'K' THEN 'Khac'
						WHEN mbc.TenField IN ('NGCK','Giuong','GB') THEN '12'
						WHEN mbc.TenField = 'VTYT' THEN '10'
						ELSE mbc.TenField
					END AS TenField
					, mbc.Ma
				FROM dbo.DM_MauBaoCao mbc
				JOIN dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
				WHERE MauBC = 'BCVP_097'
			) map ON map.DichVu_Id = xnct.NoiDung_Id

			LEFT JOIN dbo.TiepNhan tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id
			LEFT JOIN dbo.DM_BenhNhan bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
			LEFT JOIN DM_DoiTuong dt ON dt.DoiTuong_Id = tn.DoiTuong_Id
			LEFT JOIN dbo.Lst_Dictionary ndt ON ndt.Dictionary_Id = dt.NhomDoiTuong_Id
			LEFT JOIN dbo.Lst_Dictionary lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
			LEFT JOIN dbo.DM_BenhVien ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id

			LEFT JOIN DM_Duoc d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' AND ISNULL(D.BHYT, 0) = 1
			LEFT JOIN DM_Duoc_HoatChat hc ON hc.HoatChat_Id = d.HoatChat_Id
			-- [TỐI ƯU #7] Bỏ JOIN DM_LoaiDuoc trùng lặp (alias f trong gốc), chỉ giữ ld
			LEFT JOIN dbo.DM_LoaiDuoc ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
			LEFT JOIN dbo.DM_DonViTinh dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
			LEFT JOIN dbo.DM_DichVu dv ON dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
			LEFT JOIN dbo.Lst_Dictionary dd ON dd.Dictionary_Id = d.DuongDung_Id
			LEFT JOIN DM_BenhVien kcbbd ON tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
			LEFT JOIN ChungTuXuatBenhNhan xbn ON (xnct.IDRef = xbn.ChungTuXuatBN_Id AND xnct.Loai_IDRef = 'I')

			-- Lấy ra ngày y lệnh
			LEFT JOIN ToaThuoc thuoc ON thuoc.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
			LEFT JOIN NoiTru_ToaThuoc nttt ON xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
			LEFT JOIN NoiTru_KhamBenh ntkb ON nttt.khambenh_id = ntkb.khambenh_id

			-- [TỐI ƯU #5] OUTER APPLY tính SUM(NoiTru_TraThuocChiTiet) 1 lần duy nhất
			-- Phải đặt SAU JOIN nttt để nttt.toathuoc_id đã được bind
			OUTER APPLY (
				SELECT SoLuongTra = CAST(SUM(ISNULL(SoLuong, 0)) AS DECIMAL(18, 3))
				FROM NoiTru_TraThuocChiTiet
				WHERE ToaThuoc_Id = nttt.toathuoc_id
			) traThuoc
			LEFT JOIN BenhAnPhauThuat_VTYT PTVT ON xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
			LEFT JOIN BenhAnPhauThuat BAPT ON PTVT.BenhAnPhauThuat_Id = BAPT.BenhAnPhauThuat_Id
			LEFT JOIN KhamBenh_VTYT kbvt ON xbn.KhamBenh_VTYT_Id = kbvt.KhamBenh_VTYT_Id AND li.PhanNhom = 'DU' AND kbvt.Duoc_Id = d.Duoc_Id
			LEFT JOIN KhamBenh kb1 ON kbvt.KhamBenh_Id = kb1.KhamBenh_Id
			LEFT JOIN CLSYeuCauChiTiet yctt ON yctt.YeuCauChiTiet_Id = xnct.IDRef AND xnct.Loai_IDRef = 'A'
			LEFT JOIN CLSYeuCau yc ON yc.CLSYeuCau_Id = yctt.CLSYeuCau_Id
			LEFT JOIN vw_NhanVien bskbvt ON bskbvt.NhanVien_Id = kb1.BacSiKham_Id
			LEFT JOIN KhamBenh kbtt ON kbtt.KhamBenh_Id = thuoc.KhamBenh_Id
			LEFT JOIN vw_NhanVien bskbtt ON bskbtt.NhanVien_Id = kbtt.BacSiKham_Id

			-- Mã khoa chỉ định thuốc
			LEFT JOIN NoiTru_LuuTru ltru ON ltru.LuuTru_Id = ntkb.LuuTru_Id
			LEFT JOIN DM_PhongBan pbthuoc ON pbthuoc.PhongBan_Id = ltru.PhongBan_Id
			LEFT JOIN DM_PhongBan pbcdinh ON pbcdinh.PhongBan_Id = yc.NoiYeuCau_Id
			LEFT JOIN DM_PhongBan pbkb1 ON pbkb1.PhongBan_Id = kb1.PhongBan_Id

			-- Lấy ra Ma_Bac_Si
			LEFT JOIN vw_NhanVien bstt ON bstt.NhanVien_Id = ntkb.BasSiKham_Id
			LEFT JOIN vw_NhanVien bscls ON bscls.NhanVien_Id = yc.BacSiChiDinh_Id
			LEFT JOIN Sys_Users us ON BAPT.NguoiTao_Id = us.User_Id
			LEFT JOIN NhanVien_User_Mapping usmap ON us.User_Id = usmap.User_Id
			LEFT JOIN vw_NhanVien bspt ON usmap.NhanVien_Id = bspt.NhanVien_Id

			-- CLS HCVT ngoại trú
			LEFT JOIN CLSGhiNhanHoaChat_VTYT HCVT ON xnct.IDRef = HCVT.Id AND xnct.Loai_IDRef = 'E'
			LEFT JOIN CLSYeuCau YCHC ON HCVT.CLSYeuCau_Id = YCHC.CLSYeuCau_Id
			LEFT JOIN CLSKetqua YCHCkq ON HCVT.CLSYeuCau_Id = YCHCkq.CLSYeuCau_Id
			LEFT JOIN vw_NhanVien BSHCVT ON YCHCkq.BacSiKetLuan_id = BSHCVT.NhanVien_Id

			-- CLS HCVT nội trú
			LEFT JOIN CLSGhiNhanHoaChat_VTYT HCVTNT ON xbn.CLSHoaChat_VTYT_Id = HCVTNT.Id
			LEFT JOIN CLSYeuCau YCHCNT ON HCVTNT.CLSYeuCau_Id = YCHCNT.CLSYeuCau_Id
			LEFT JOIN CLSKetqua YCHCNTkq ON HCVTNT.CLSYeuCau_Id = YCHCNTkq.CLSYeuCau_Id
			LEFT JOIN vw_NhanVien BSHCVTNT ON YCHCNTkq.bacsiketluan_id = BSHCVTNT.NhanVien_Id

			LEFT JOIN MienGiam mg ON mg.TiepNhan_Id = tn.TiepNhan_Id

			-- [TỐI ƯU #6] Thay correlated subquery trong JOIN kbm bằng CROSS APPLY
			OUTER APPLY (
				SELECT TOP 1 kbm2.*
				FROM KhamBenh kbm2
				WHERE kbm2.TiepNhan_Id = xnct.TiepNhan_Id
				ORDER BY kbm2.KhamBenh_Id ASC
			) kbm

			LEFT JOIN dm_phongban pb ON pb.PhongBan_Id = kbm.PhongBan_Id
			-- [TỐI ƯU #8] Bỏ 2 JOIN DM_ICD trùng (i, icd gốc), dùng 1 bc duy nhất
			LEFT JOIN DM_ICD bc ON bc.ICD_ID = kbm.ChanDoanICD_Id
			LEFT JOIN BenhAn ba ON xnct.BenhAn_Id = ba.BenhAn_Id
			LEFT JOIN DM_ICD icd_nt ON icd_nt.ICD_Id = ba.ICD_BenhChinh

			WHERE xnct.DonGiaHoTroChiTra > 0
				AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
				AND (
					(LI.PhanNhom = 'DU' AND ld.LoaiVatTu_Id IN ('T', 'H'))
					OR map.TenField = '08'
					OR map.TenField = '16'
					OR map.TenField = 'OXY'
					OR ld.MaLoaiDuoc IN ('OXY', 'OXY1', 'LD0143', 'VTYT003')
				)
				AND ISNULL(xbn.toathanhpho, 0) = 0

			GROUP BY nttt.ToaThuoc_Id, li.PhanNhom,
				CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END,
				dv.InputCode, d.MaHoatChat, d.MaDuoc, d.BHYT,
				xnct.DonGiaHoTroChiTra, ld.LoaiVatTu_Id, map.TenField,
				ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.TenDichVu_En ELSE dv.TenQuiDinhCu END, DV.TenDichvU),
				d.Ten_VTYT_917, d.TenDuocDayDu,
				ISNULL(dvt.TenDonViTinh, N'Lần'), d.HamLuong, d.MaDuongDung, d.Attribute_3, d.Attribute_2,
				xnct.DonGiaHoTro, pb.MaTheoQuiDinh,
				ntkb.NgayKham, yc.ngayyeucau, ld.MaLoaiDuoc,
				D.TenHang, D.ThoiGianHopDong, dt.TyLe_2, d.ThongTinThau, d.MaGoiThau,
				pbcdinh.MaTheoQuiDinh, pbthuoc.MaTheoQuiDinh, pbkb1.MaTheoQuiDinh,
				dd.Dictionary_Code,
				REPLACE(
					CONVERT(VARCHAR, COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kbm.ketthucKham, ychc.thoigianyeucau), 112)
					+ CONVERT(VARCHAR(5), COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kbm.KetThucKham, ychc.thoigianyeucau), 108), ':', ''),
				tn.TuyenKhamBenh_Id,
				bc.ngoaidinhxuat, icd_nt.ngoaidinhxuat, tn.SoBHYT,
				xnct.muc_huong, ISNULL('/' + nttt.GhiChu, '/' + thuoc.GhiChu),
				bapt.CLSYeuCau_Id, YCHC.CLSYeuCau_Id,
				ISNULL(nttt.GhiChu, thuoc.GhiChu),
				thuoc.toathuoc_id,
				xbn.DuocDieuKien_Id,
				xbn.GiaTriMienGiam, mg.LyDo_ID,
				bc.NgoaiDinhXuat, icd_nt.NgoaiDinhXuat,
				xnct.DonGiaDoanhThu,
				xbn.TyLeDieuKien,
				-- MA_BAC_SI group
				CASE
					WHEN nttt.ToaThuoc_Id IS NOT NULL THEN bstt.SoChungChiHanhNghe
					WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt.SoChungChiHanhNghe
					WHEN kbvt.KhamBenh_VTYT_Id IS NOT NULL THEN bskbvt.SoChungChiHanhNghe
					WHEN thuoc.ToaThuoc_Id IS NOT NULL THEN bskbtt.SoChungChiHanhNghe
					WHEN HCVT.Id IS NOT NULL THEN BSHCVT.SoChungChiHanhNghe
					WHEN HCVTNT.Id IS NOT NULL THEN BSHCVTNT.SoChungChiHanhNghe
					WHEN map.TenField IN ('08','16') AND li.PhanNhom = 'DV' THEN bscls.SoChungChiHanhNghe
					ELSE NULL
				END,
				-- CHUC_DANH_ID group
				CASE
					WHEN nttt.ToaThuoc_Id IS NOT NULL THEN bstt.ChucDanh_Id
					WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt.ChucDanh_Id
					WHEN kbvt.KhamBenh_VTYT_Id IS NOT NULL THEN bskbvt.ChucDanh_Id
					WHEN thuoc.ToaThuoc_Id IS NOT NULL THEN bskbtt.ChucDanh_Id
					WHEN HCVT.Id IS NOT NULL THEN BSHCVT.ChucDanh_Id
					WHEN HCVTNT.Id IS NOT NULL THEN BSHCVTNT.ChucDanh_Id
					WHEN map.TenField IN ('08','16') AND li.PhanNhom = 'DV' THEN bscls.ChucDanh_Id
					ELSE NULL
				END,
				-- traThuoc (từ OUTER APPLY)
				traThuoc.SoLuongTra
		) xml2 WHERE SO_LUONG > 0
	) xml2

END

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
