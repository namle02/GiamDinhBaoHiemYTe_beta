/*==============================================================================
  TT03-NgoaiTru.sql - PHIÊN BẢN TỐI ƯU
  
  Tối ưu so với bản gốc:
  1. SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED thay cho (nolock) rải rác
  2. Bỏ subquery SELECT * không cần thiết (dòng 33-37, 143 gốc)
  3. Thay correlated subquery MIN(ThoiGianKham) bằng TOP 1
  4. Thay OR trong JOIN/WHERE bằng filter trực tiếp @tiepnhan_id
  5. OUTER APPLY tính SUM(NoiTru_TraThuocChiTiet) 1 lần (thay ~5 lần lặp)
  6. Gộp 2 JOIN CLSKetQuaChiTiet trùng lặp thành 1
  7. Tách ISNULL ra khỏi WHERE condition
==============================================================================*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SoTiepNhan VARCHAR(50) = N'{IDBenhNhan}'

DECLARE @TiepNhan_Id VARCHAR(50)
SELECT @TiepNhan_Id = TiepNhan_Id FROM TiepNhan WHERE SoTiepNhan = @SoTiepNhan

DECLARE @BenhAn_Id VARCHAR(50)
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
	-- [TỐI ƯU #2] Bỏ subquery SELECT *
	FROM dbo.BenhAn ba
	INNER JOIN TiepNhan tn ON ba.TiepNhan_ID = tn.TiepNhan_ID
	LEFT JOIN DM_ICD icd ON icd.ICD_Id = ba.ICD_BenhChinh
	LEFT JOIN ThongTinCapCuu cc ON ba.BenhAn_ID = cc.BenhAn_Id
	LEFT JOIN DM_ICD icd_cc ON cc.ICD_BenhChinh = icd_cc.ICD_Id
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

---Bệnh án Ngoại trú
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
		, [MA_DICH_VU] = XML3.ma_dich_vu
		, [MA_PTTT_QT] = XML3.MA_PTTT_QT
		, [MA_VAT_TU] = XML3.ma_vat_tu
		, [MA_NHOM] = XML3.MA_NHOM
		, [GOI_VTYT] = XML3.GOI_VTYT
		, [TEN_VAT_TU] = XML3.TEN_VAT_TU
		, [TEN_DICH_VU] = XML3.ten_dich_vu
		, [MA_XANG_DAU] = NULL
		, [DON_VI_TINH] = XML3.don_vi_tinh
		, [PHAM_VI] = XML3.PHAM_VI
		, [SO_LUONG] = XML3.SO_LUONG
		, [DON_GIA_BV] = XML3.DON_GIA
		, [DON_GIA_BH] = XML3.DON_GIA
		, [TT_THAU] = XML3.TT_THAU
		, [TYLE_TT_DV] = XML3.tyle_tt
		, [TYLE_TT_BH] = 100
		, [THANH_TIEN_BV] = XML3.Thanh_Tien
		, [THANH_TIEN_BH] = XML3.Thanh_Tien
		, [T_TRANTT] = XML3.T_TRANTT
		, [MUC_HUONG] = XML3.MUC_HUONG
		, [T_NGUONKHAC_NSNN] = 0
		, [T_NGUONKHAC_VTNN] = 0
		, [T_NGUONKHAC_VTTN] = 0
		, [T_NGUONKHAC_CL] = 0
		, [T_NGUONKHAC] = 0
		, [T_BNTT] = XML3.t_bntt
		, [T_BNCCT] = XML3.[T_BNCCT]
		, [T_BHTT] = XML3.[T_BHTT]
		, [MA_KHOA] = XML3.[MA_KHOA]
		, [MA_GIUONG] = XML3.[MA_GIUONG]
		, [MA_BAC_SI] = XML3.[MA_BAC_SI]
		, [NGUOI_THUC_HIEN] = Nguoi_TH
		, [MA_BENH] = XML3.[MA_BENH]
		, [MA_BENH_YHCT] = NULL
		, [NGAY_YL] = XML3.[NGAY_YL]
		, [NGAY_TH_YL] = XML3.[NGAY_THUCHIEN_YL]
		, [NGAY_KQ] = XML3.[NGAY_KQ]
		, [MA_PTTT] = XML3.[MA_PTTT]
		, [VET_THUONG_TP] = NULL
		, [PP_VO_CAM] = PPVC
		, [VI_TRI_TH_DVKT] = VITRI
		, [MA_MAY] = ma_may
		, [MA_HIEU_SP] = XML3.MAHIEU
		, [TAI_SU_DUNG] = XML3.TSD
		, [DU_PHONG] = NULL
		, [LoaiBenhPham_Id] =
			CASE
				WHEN MA_DICH_VU IN (N'24.0017.1714', N'24.0005.1716', N'24.0003.1715', N'24.0001.1714') THEN LoaiBenhPham_Id
				ELSE NULL
			END
		, [ChucDanh_id] = chuc_danh
		, [MoTa_Text] = MoTa_Text
		, [KET_LUAN] = ketluan
		, [TrinhTuThucHien] = TrinhTuThucHien
		, [PhuTang] = PhuTang
	FROM (
		SELECT
			MA_LK = @Ma_Lk
			, STT = ROW_NUMBER() OVER (ORDER BY (SELECT 1))

			, ma_dich_vu = CASE
				WHEN li.PhanNhom = 'DV' AND map.TenField != '10' AND map.TenField != '11'
					THEN CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END
				WHEN LI.PhanNhom = 'DV' AND map.TenField = '11' THEN 'VC.' + bvct.MaBenhVien
				ELSE NULL
			END

			, ma_dich_vu_cs = CASE
				WHEN li.PhanNhom = 'DV' AND map.TenField != '10' AND map.TenField != '11'
					THEN CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END
				WHEN li.PhanNhom = 'DV' AND map.TenField = '11' THEN 'VC.' + bvct.MaBenhVien
				ELSE NULL
			END

			, ma_vat_tu = CASE WHEN li.PhanNhom IN ('DU','DI','VH','VT') OR map.TenField = '10'
				THEN ISNULL(ISNULL(LTRIM(RTRIM(d.MaHoatChat)), ISNULL(d.Attribute_2, d.Attribute_3)),
					ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END, dv.madichvu))
				ELSE NULL
			END

			, ma_vat_tu_cs = CASE WHEN li.PhanNhom IN ('DU','DI','VH','VT') OR map.TenField = '10'
				THEN ISNULL(ISNULL(LTRIM(RTRIM(d.MaHoatChat)), ISNULL(d.Attribute_2, d.Attribute_3)),
					ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END, dv.madichvu))
				ELSE NULL
			END

			, MA_NHOM = CASE
				WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V') OR map.TenField IN ('16','Thuoc') THEN '4'
				WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xnct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id = ('V') OR map.TenField IN ('10','VTYT') THEN '10'
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

			, GOI_VTYT = ''
			, TEN_VAT_TU = CASE WHEN xnct.Loai_IDRef <> 'A' THEN ISNULL(D.Ten_VTYT_917, d.TenHang) ELSE '' END

			, TEN_DICH_VU = CASE WHEN tn.NgayTiepNhan <= '20241215'
				THEN REPLACE(ISNULL(ISNULL(ISNULL(dv.Attribute3, CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.TenDichVu_En ELSE dv.TenQuiDinhCu END), dv.TenDichVu), ''), CHAR(0x1F), '')
				ELSE REPLACE(ISNULL(ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.TenDichVu_En ELSE dv.TenQuiDinhCu END, dv.TenDichVu), ''), CHAR(0x1F), '')
			END

			, DON_VI_TINH = ISNULL(dvt.TenDonViTinh, N'Lần')
			, PHAM_VI = 1

			-- [TỐI ƯU #5] Dùng traThuoc.SoLuongTra thay vì subquery lặp
			, SO_LUONG = CAST(
				CASE WHEN map.TenField = '12' AND clsyc.PT50 = 1 THEN 0.5
				ELSE CAST(xnct.SoLuong AS DECIMAL(18, 2))
				END
				- ISNULL(traThuoc.SoLuongTra, 0)
			AS DECIMAL(18, 2))

			, DON_GIA = CASE WHEN clsyc.TyLeThanhToan IS NOT NULL
				THEN CAST((ISNULL(xnct.DonGiaHoTro, 0) / clsyc.TyLeThanhToan) * CASE WHEN (clsyc.PT80 = 1 OR clsyc.PT50 = 1) THEN ISNULL(clsyc.TyleThanhToan, 1) ELSE 1 END AS DECIMAL(18, 2))
				ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 2))
			END

			, TT_Thau = CASE WHEN d.Duoc_Id IS NOT NULL THEN ISNULL(d.ThongTinThau, d.MaGoiThau) ELSE ISNULL(dv.ReportCode, '') END

			, TYLE_TT = CASE WHEN clsyc.TyLeThanhToan IS NOT NULL THEN
				CASE
					WHEN map.TenField = '01' THEN clsyc.TyLeThanhToan * 100
					WHEN map.TenField IN ('06', '18') AND clsyc.PT80 = 1 THEN 80
					WHEN map.TenField IN ('06', '18') AND clsyc.PT50 = 1 THEN 50
					WHEN map.TenField = '12' AND clsyc.PT50 = 1 THEN 100
					WHEN map.TenField = '12' AND clsyc.Ghep2 = 1 THEN 50
					WHEN map.TenField = '12' AND clsyc.Ghep3 = 1 THEN 30
					ELSE clsyc.TyLeThanhToan * 100
				END
				ELSE 100
			END

			-- [TỐI ƯU #5] Dùng traThuoc.SoLuongTra thay vì lặp subquery
			, THANH_TIEN = CAST(
				CAST((CASE WHEN ISNULL(tyle.TyLe, 0) = 0 THEN CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 3))
				ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) / tyle.TyLe * 100 AS DECIMAL(18, 3)) END)
				* CAST(xnct.SoLuong AS DECIMAL(18, 2)) AS DECIMAL(18, 2))
				-
				CAST(xnct.DonGiaHoTro * ISNULL(traThuoc.SoLuongTra, 0) AS DECIMAL(18, 2))
			AS DECIMAL(18, 2))

			, T_TRANTT = NULL

			, muc_huong = CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END

			, t_bhtt = CAST(
				(CAST((CASE WHEN ISNULL(tyle.TyLe, 0) = 0 THEN CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 3))
				ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) / tyle.TyLe * 100 AS DECIMAL(18, 3)) END)
				* CAST(xnct.SoLuong AS DECIMAL(18, 2)) AS DECIMAL(18, 2))
				-
				CAST(xnct.DonGiaHoTro * ISNULL(traThuoc.SoLuongTra, 0) AS DECIMAL(18, 2)))
				* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
				/ 100
			AS DECIMAL(18, 2))

			, t_bntt = 0

			, t_bncct = CAST(
				CAST((CASE WHEN ISNULL(tyle.TyLe, 0) = 0 THEN CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 3))
				ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) / tyle.TyLe * 100 AS DECIMAL(18, 3)) END)
				* CAST(xnct.SoLuong AS DECIMAL(18, 2)) AS DECIMAL(18, 2))
				-
				CAST(xnct.DonGiaHoTro * ISNULL(traThuoc.SoLuongTra, 0) AS DECIMAL(18, 2))
			AS DECIMAL(18, 2))
			-
			CAST(
				(CAST((CASE WHEN ISNULL(tyle.TyLe, 0) = 0 THEN CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 3))
				ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) / tyle.TyLe * 100 AS DECIMAL(18, 3)) END)
				* CAST(xnct.SoLuong AS DECIMAL(18, 2)) AS DECIMAL(18, 2))
				-
				CAST(xnct.DonGiaHoTro * ISNULL(traThuoc.SoLuongTra, 0) AS DECIMAL(18, 2)))
				* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
				/ 100
			AS DECIMAL(18, 2))

			, t_nguonkhac = 0

			, t_ngoaids = CASE WHEN ISNULL(bc.ngoaidinhxuat, 0) = 1 OR ISNULL(icd_nt.NgoaiDinhXuat, 0) = 1 THEN
				CAST(
					(CAST((CASE WHEN ISNULL(tyle.TyLe, 0) = 0 THEN CAST(ISNULL(xnct.DonGiaHoTro, 0) AS DECIMAL(18, 3))
					ELSE CAST(ISNULL(xnct.DonGiaHoTro, 0) / tyle.TyLe * 100 AS DECIMAL(18, 3)) END)
					* CAST(xnct.SoLuong AS DECIMAL(18, 2)) AS DECIMAL(18, 2))
					-
					CAST(xnct.DonGiaHoTro * ISNULL(traThuoc.SoLuongTra, 0) AS DECIMAL(18, 2)))
					* CASE WHEN ISNULL(@Tong_Chi, 0) < @LuongToiThieu THEN 100 ELSE Muc_Huong * 100 END
					/ 100
				AS DECIMAL(18, 2))
			ELSE 0 END

			, MA_KHOA = CASE WHEN ba.BenhAn_Id IS NULL THEN 'K01'
				ELSE ISNULL(pbsd.MaTheoQuiDinh, pbRa.MaTheoQuiDinh)
			END

			, MA_GIUONG = ''

			, chuc_danh = CASE
				WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL AND map.TenField <> '01' THEN bscls.ChucDanh_Id
				WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL AND map.TenField = '01' THEN ISNULL(nguoitaokb.ChucDanh_Id, bscls.ChucDanh_Id)
				WHEN li.PhanNhom <> 'DV' AND ntkb.KhamBenh_Id IS NOT NULL THEN bstt.ChucDanh_Id
				WHEN li.PhanNhom <> 'DV' AND kbvt.KhamBenh_Id IS NOT NULL THEN bskb_vt.ChucDanh_Id
				WHEN li.PhanNhom <> 'DV' AND PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt_vt.ChucDanh_Id
				ELSE NULL
			END

			, Ma_Bac_Si = CASE
				WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL AND map.TenField <> '01' THEN bscls.SoChungChiHanhNghe
				WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL AND map.TenField = '01' THEN ISNULL(nguoitaokb.SoChungChiHanhNghe, bscls.SoChungChiHanhNghe)
				WHEN li.PhanNhom <> 'DV' AND ntkb.KhamBenh_Id IS NOT NULL THEN bstt.SoChungChiHanhNghe
				WHEN li.PhanNhom <> 'DV' AND kbvt.KhamBenh_Id IS NOT NULL THEN bskb_vt.SoChungChiHanhNghe
				WHEN li.PhanNhom <> 'DV' AND PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt_vt.SoChungChiHanhNghe
				ELSE NULL
			END

			, MA_BENH = ISNULL(@ICD_NTGopBenh, @ICD_PKGopBenh)

			, NGAY_YL = CASE
				WHEN xnct.Loai_IDRef = 'A' THEN FORMAT(yc.ThoiGianYeuCau, 'yyyyMMddHHmm')
				WHEN xnct.Loai_IDRef <> 'A' AND xbn.ToaThuoc_Id IS NOT NULL THEN FORMAT(ntkb.ThoiGianKham, 'yyyyMMddHHmm')
				WHEN xnct.Loai_IDRef <> 'A' AND xbn.BenhAnPhauThuat_VTYT_ID IS NOT NULL THEN FORMAT(ptvt.NgayTao, 'yyyyMMddHHmm')
				WHEN xnct.Loai_IDRef <> 'A' AND kbvt.KhamBenh_VTYT_Id IS NOT NULL THEN FORMAT(kbvt.NgayTao, 'yyyyMMddHHmm')
				ELSE NULL
			END

			, NGAY_THUCHIEN_YL = CASE
				WHEN ndv.MaNhomDichVu = '04' THEN
					REPLACE(CONVERT(VARCHAR, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(VARCHAR(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':', '')
				WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') THEN
					REPLACE(CONVERT(VARCHAR, COALESCE(lab.SIDIssueDateTime, kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, yc.ThoiGianYeuCau), 112) + CONVERT(VARCHAR(5), COALESCE(lab.SIDIssueDateTime, kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, yc.ThoiGianYeuCau), 108), ':', '')
				WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') THEN
					REPLACE(CONVERT(VARCHAR, COALESCE(kq.ThoiGianBatDauThucHien, kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, yc.ThoiGianYeuCau), 112) + CONVERT(VARCHAR(5), COALESCE(kq.ThoiGianBatDauThucHien, kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, yc.ThoiGianYeuCau), 108), ':', '')
				ELSE
					REPLACE(CONVERT(VARCHAR, COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kb.ThoiGianKham), 112) + CONVERT(VARCHAR(5), COALESCE(kb1.ThoiGianKham, ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kb.ThoiGianKham), 108), ':', '')
			END

			, NGAY_KQ = CASE WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL AND map.TenField = '01' THEN
				REPLACE(CONVERT(VARCHAR, KB.KetThucKham, 112) + CONVERT(VARCHAR(5), KB.KetThucKham, 108), ':', '')
			ELSE
				REPLACE(CONVERT(VARCHAR, COALESCE(kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, bapt.ThoiGianKetThuc), 112) + CONVERT(VARCHAR(5), COALESCE(kq.NgayKhoaDuLieu, CASE WHEN kq.NgayTao > kq.ThoiGianThucHien THEN kq.NgayTao ELSE kq.ThoiGianThucHien END, bapt.ThoiGianKetThuc), 108), ':', '')
			END

			, MA_PTTT = 1
			, MA_PTTT_QT = CASE WHEN li.PhanNhom = 'DV' AND ptyc.BenhAnPhauThuat_YeuCau_Id IS NOT NULL THEN icd9.MaICD9_CM ELSE NULL END
			, MAHIEU = D.mahieusp
			, TSD = NULL
			, PPVC = CASE
				WHEN map.TenField IN ('06','18') THEN ISNULL(ISNULL(ppvc.Dictionary_Name_en, ppvc.Dictionary_Code), '4')
				ELSE ISNULL(ppvc.Dictionary_Name_en, ppvc.Dictionary_Code)
			END
			, VITRI = ''
			, ma_may = CASE
				WHEN ndv.CapTren_Id = 1 AND (mamay.Dictionary_Code IS NULL OR mamay.Dictionary_Code != 'KXD')
					THEN REPLACE(COALESCE(ma_may.MaMay_Lis, mamay.Dictionary_Code, ''), ' ', '')
				WHEN mamay.Dictionary_Code = 'KXD' THEN NULL
				WHEN mamaypttt.Dictionary_Code = 'KXD' THEN NULL
				ELSE ISNULL(mamay.Dictionary_Code, mamaypttt.Dictionary_Code)
			END

			, Nguoi_TH =
				ISNULL(
					CASE
						WHEN li.PhanNhom = 'DV' AND map.TenField = '01' THEN nguoitaokb.SoChungChiHanhNghe
						WHEN li.PhanNhom = 'DV' AND ptyc.BenhAnPhauThuat_YeuCau_Id IS NOT NULL THEN dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(bapt.BenhAnPhauThuat_Id)
						WHEN li.PhanNhom = 'DV' AND kq.CLSKetQua_Id IS NOT NULL THEN bskq.SoChungChiHanhNghe
						ELSE NULL
					END
					,
					CASE
						WHEN li.PhanNhom = 'DV' AND clsyc.YeuCauChiTiet_Id IS NOT NULL THEN bscls.SoChungChiHanhNghe
						WHEN li.PhanNhom <> 'DV' AND ntkb.KhamBenh_Id IS NOT NULL THEN bstt.SoChungChiHanhNghe
						WHEN li.PhanNhom <> 'DV' AND kbvt.KhamBenh_Id IS NOT NULL THEN bskb_vt.SoChungChiHanhNghe
						WHEN li.PhanNhom <> 'DV' AND PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL THEN bspt_vt.SoChungChiHanhNghe
						ELSE NULL
					END
				)
			, kq.MoTa_Text
			, kq.KetLuan
			, yc.LoaiBenhPham_Id
			, bapt.TrinhTuThucHien
			, kq.PhuTang

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
			-- [TỐI ƯU #4] Thay OR bằng filter trực tiếp
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

		LEFT JOIN dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef AND xnct.DonGiaHoTroChiTra > 0

		LEFT JOIN (
			SELECT dndv.DichVu_Id, mbc.MoTa, mbc.ID,
				CASE
					WHEN mbc.TenField IN ('CK','CongKham','KB','TienKham') THEN '01'
					WHEN mbc.TenField IN ('XN','XetNghiem','XNHH') THEN '03'
					WHEN mbc.TenField IN ('Thuoc','OXY') THEN '16'
					WHEN mbc.TenField IN ('TTPT','TT','TT_PT') AND (ldv.MaLoaiDichVu = 'ThuThuat' OR ndv.MaNhomDichVu IN ('0307', '0304', '2101') OR dndv.DichVu_Id IN (19601,19618,19619,20531,21998,28915)) THEN '18'
					WHEN mbc.TenField IN ('TTPT','TT','TT_PT') AND ldv.MaLoaiDichVu <> 'ThuThuat' AND ndv.MaNhomDichVu NOT IN ('0307', '0304', '2101') AND dndv.DichVu_Id NOT IN (19601,19618,19619,20531,21998,28915) THEN '06'
					WHEN mbc.TenField IN ('DVKT_Cao', 'KTC') THEN '07'
					WHEN mbc.TenField = 'VC' THEN '11'
					WHEN mbc.TenField IN ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'
					WHEN mbc.TenField IN ('CPMau') THEN '09'
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
			LEFT JOIN DM_DichVu dv ON dndv.DichVu_Id = dv.DichVu_Id
			LEFT JOIN DM_NhomDichVu ndv ON dv.NhomDichVu_Id = ndv.NhomDichVu_Id
			LEFT JOIN DM_LoaiDichVu ldv ON ndv.LoaiDichVu_Id = ldv.LoaiDichVu_Id
			WHERE mbc.MauBC = 'BCVP_097'
		) map ON map.DichVu_Id = xnct.NoiDung_Id

		LEFT JOIN dbo.TiepNhan tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id
		LEFT JOIN CLSYeuCauChiTiet clsyc ON clsyc.YeuCauChiTiet_Id = xnct.IDRef AND xnct.Loai_IDRef = 'A'
		LEFT JOIN ChungTuXuatBenhNhan xbn ON (xnct.IDRef = xbn.ChungTuXuatBN_Id AND xnct.Loai_IDRef = 'I')
		LEFT JOIN (
			SELECT CLSYeuCauChiTiet_Id, SIDIssueDateTime = MAX(SIDIssueDateTime)
			FROM Lab_SIDStatus
			GROUP BY CLSYeuCauChiTiet_Id
		) lab ON clsyc.YeuCauChiTiet_Id = lab.CLSYeuCauChiTiet_Id

		LEFT JOIN BenhAn ba ON xnct.BenhAn_Id = ba.BenhAn_Id
		LEFT JOIN DM_ICD icd_nt ON icd_nt.ICD_Id = ba.ICD_BenhChinh
		LEFT JOIN KhamBenh kb ON kb.YeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
		LEFT JOIN DM_ICD bc ON bc.ICD_ID = kb.ChanDoanICD_Id
		LEFT JOIN DM_BenhVien bvct ON kb.ChuyenDenBenhVien_Id = bvct.BenhVien_Id
		LEFT JOIN dm_phongban pb ON pb.PhongBan_Id = kb.PhongBan_Id
		LEFT JOIN dbo.Lst_Dictionary lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
		LEFT JOIN dbo.DM_BenhVien ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
		LEFT JOIN DM_Duoc d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' AND ISNULL(D.BHYT, 0) = 1
		LEFT JOIN dbo.DM_LoaiDuoc ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
		LEFT JOIN dbo.DM_DonViTinh dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
		LEFT JOIN dbo.DM_DichVu dv ON dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
		LEFT JOIN dbo.Lst_Dictionary dd ON dd.Dictionary_Id = d.DuongDung_Id
		LEFT JOIN CLSYeuCau yc ON yc.CLSYeuCau_Id = clsyc.CLSYeuCau_Id
		LEFT JOIN CLSKetQua kq ON kq.CLSYeuCau_Id = yc.CLSYeuCau_Id

		-- [TỐI ƯU #6] Gộp 2 JOIN CLSKetQuaChiTiet thành 1
		LEFT JOIN (
			SELECT
				DichVu_Id = ISNULL(d.CapTren_Id, d.DichVu_Id),
				CLSKetQua_Id,
				MaMay_Lis = MIN(MaMay_Lis)
			FROM CLSKetQuaChiTiet kqct
			JOIN DM_DichVu d ON d.DichVu_Id = kqct.DichVu_Id
			WHERE MaMay_Lis <> '' AND MaMay_Lis IS NOT NULL
			GROUP BY ISNULL(d.CapTren_Id, d.DichVu_Id), CLSKetQua_Id
		) ma_may ON ma_may.CLSKetQua_Id = kq.CLSKetQua_Id AND ma_may.DichVu_Id = clsyc.DichVu_Id

		LEFT JOIN BenhAnPhauThuat_YeuCau ptyc ON ptyc.CLSYeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
		LEFT JOIN BenhAnPhauThuat_VTYT PTVT ON xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
		LEFT JOIN BenhAnPhauThuat bapt ON bapt.BenhAnPhauThuat_Id = ISNULL(PTVT.BenhAnPhauThuat_Id, PTYC.BenhAnPhauThuat_Id)
		LEFT JOIN KhamBenh_VTYT kbvt ON xnct.IDRef = kbvt.KhamBenh_VTYT_Id AND li.PhanNhom = 'DU' AND kbvt.Duoc_Id = d.Duoc_Id
		LEFT JOIN KhamBenh kb1 ON kb1.KhamBenh_Id = kbvt.KhamBenh_Id

		-- Thuốc tỷ lệ
		LEFT JOIN DM_DoiTuong_GiaDuoc_TyLe tyle ON tyle.DoiTuong_Id = XBN.DoiTuong_Id AND tyle.Duoc_Id = d.Duoc_Id

		-- Lấy ra ngày y lệnh
		LEFT JOIN NoiTru_ToaThuoc nttt ON xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
		LEFT JOIN NoiTru_KhamBenh ntkb ON nttt.khambenh_id = ntkb.khambenh_id

		-- [TỐI ƯU #5] OUTER APPLY tính SUM(NoiTru_TraThuocChiTiet) 1 lần duy nhất
		-- Phải đặt SAU JOIN nttt
		OUTER APPLY (
			SELECT SoLuongTra = CAST(SUM(ISNULL(SoLuong, 0)) AS DECIMAL(18, 2))
			FROM NoiTru_TraThuocChiTiet
			WHERE ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
		) traThuoc

		-- Lấy ra Ma_Bac_Si
		LEFT JOIN vw_NhanVien bstt ON bstt.NhanVien_Id = ntkb.BasSiKham_Id
		LEFT JOIN vw_NhanVien bskb ON bskb.NhanVien_Id = kb.BacSiKham_Id
		-- Lấy người tạo công khám
		LEFT JOIN NhanVien_User_Mapping usmapkb ON kb.NguoiTao_Id = usmapkb.User_Id
		LEFT JOIN vw_NhanVien nguoitaokb ON nguoitaokb.NhanVien_Id = usmapkb.nhanvien_id

		LEFT JOIN vw_NhanVien bskb_vt ON bskb_vt.NhanVien_Id = kb1.BacSiKham_Id
		LEFT JOIN vw_NhanVien bscls ON bscls.NhanVien_Id = yc.BacSiChiDinh_Id
		LEFT JOIN vw_NhanVien bskq ON bskq.nhanvien_Id = kq.BacSiKetLuan_Id
		LEFT JOIN NhanVien_User_Mapping usmap ON PTVT.NguoiTao_Id = usmap.User_Id
		LEFT JOIN vw_NhanVien bspt_VT ON usmap.NhanVien_Id = bspt_VT.NhanVien_Id
		LEFT JOIN DM_ICD9_CM icd9 ON icd9.ICD9_CM_Id = dv.ICD9_CM_Id
		LEFT JOIN Lst_Dictionary ppvc ON ppvc.Dictionary_Id = bapt.PhuongPhapVoCam_Id
		LEFT JOIN Lst_Dictionary mamay ON mamay.Dictionary_Id = kq.ThietBi_Id
		LEFT JOIN Lst_Dictionary mamaypttt ON mamaypttt.Dictionary_Id = bapt.ThietBi_ID
		LEFT JOIN DM_NhomDichVu ndv ON yc.NhomDichVu_Id = ndv.NhomDichVu_Id

		LEFT JOIN DM_PhongBan pbsd ON xnct.PhongBan_Id = pbsd.PhongBan_Id
		LEFT JOIN DM_PhongBan pbRa ON ba.KhoaRa_Id = pbRa.PhongBan_Id

		WHERE xnct.DonGiaHoTroChiTra > 0
			AND (
				(LI.PhanNhom IN ('DU') AND ld.LoaiVatTu_Id IN ('V'))
				OR (ISNULL(map.TenField, '') NOT IN ('08', '16') AND LI.PhanNhom IN ('DV'))
			)
			-- [TỐI ƯU #7] Tách ISNULL: thêm điều kiện rõ ràng hơn
			AND (ld.MaLoaiDuoc IS NULL OR ld.MaLoaiDuoc NOT IN ('OXY', 'OXY1', 'LD0143', 'VTYT003'))
	) XML3 WHERE XML3.So_Luong > 0

END

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
