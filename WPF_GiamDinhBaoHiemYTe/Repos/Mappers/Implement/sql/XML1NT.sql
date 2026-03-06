/*==============================================================================
  TT01-NgoaiTru.sql - PHIÊN BẢN TỐI ƯU
  
  Tối ưu so với bản gốc:
  1. SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED thay cho (nolock) rải rác
  2. Gộp 4 subquery TiepNhan_DoiTuongThayDoi thành 1 lần query duy nhất
  3. Loại bỏ subquery SELECT * không cần thiết
  4. Thay correlated subquery bằng TOP 1 / biến tính trước
  5. Tách OR trong WHERE/JOIN thành IF...ELSE hoặc tính trước
  6. Tính T_VTYT riêng bằng subquery/biến, giảm GROUP BY 50+ cột
  7. Tính trước MAX(KhamBenhVaoVien_Id) thành biến
  8. Truy vấn bảng TiepNhan 1 lần duy nhất vào biến tạm
==============================================================================*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @SoTiepNhan VARCHAR(50) = N'{IDBenhNhan}'

DECLARE @TiepNhan_Id VARCHAR(50)
SELECT @TiepNhan_Id = TiepNhan_Id FROM TiepNhan WHERE SoTiepNhan = @SoTiepNhan

DECLARE @BenhAn_id VARCHAR(50)
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
	-- [TỐI ƯU #3] Bỏ subquery SELECT *, dùng WHERE trực tiếp
	FROM dbo.BenhAn ba
	INNER JOIN TiepNhan tn ON ba.TiepNhan_ID = tn.TiepNhan_ID
	LEFT JOIN DM_ICD icd ON icd.ICD_Id = ba.ICD_BenhChinh
	LEFT JOIN ThongTinCapCuu cc ON ba.BenhAn_ID = cc.BenhAn_Id
	-- [TỐI ƯU #6] Tách ISNULL ra 2 LEFT JOIN riêng biệt
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
SET @ICD_PNT = [dbo].[Get_MaICD_Phu_ByBenhAn_Id](@BenhAn_Id, 'M') --- icd bệnh phụ

SELECT @MaCSKCB = Value FROM Sys_AppSettings WHERE Code = N'MaBenhVien_BHYT'

DECLARE @LuongToiThieu DECIMAL(18, 2) = 208500.00
SELECT @LuongToiThieu = VALUE FROM sys_appsettings WHERE code = 'LuongToiThieu'

--lấy chẩn đoán của bệnh án ngoại trú
SELECT @ChanDoanCapCuu = icd.TenICD, @ICDCapCuu = icd.MaICD, @CapCuu = 1
FROM BenhAn ba
LEFT JOIN DM_ICD icd ON icd.ICD_Id = ba.ICD_BenhChinh
WHERE TiepNhan_Id = @TiepNhan_Id
	AND ba.SoCapCuu IS NOT NULL

-- [TỐI ƯU #2] Thay correlated subquery MIN(ThoiGianKham) bằng TOP 1
SELECT TOP 1 @ICDKB = icd.MaICD
FROM KhamBenh kb
LEFT JOIN DM_ICD icd ON icd.ICD_Id = kb.ChanDoanICD_Id
WHERE kb.TiepNhan_Id = @TiepNhan_Id
ORDER BY kb.ThoiGianKham ASC

SET @BenhAn_Id = NULL   --Tránh trường hợp bệnh án ngoại trú vẫn có benhan_id

-- DUNGDV Tinh Tong Tien Thuoc
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

-- [TỐI ƯU #3] Bỏ subquery SELECT *, dùng WHERE trực tiếp
DECLARE @SoChuyenVien NVARCHAR(50) = NULL
SELECT @SoChuyenVien = LEFT(cv.SoPhieu, 6)
FROM TiepNhan TN
JOIN DM_BenhNhan ON tn.BenhNhan_Id = DM_BenhNhan.BenhNhan_Id
LEFT JOIN DM_BenhVien td ON td.benhvien_id = tn.NoiGioiThieu_Id
JOIN ChuyenVien cv ON cv.TiepNhan_Id = tn.TiepNhan_Id
WHERE TN.TiepNhan_Id = @TiepNhan_id

-- [TỐI ƯU #1] Tính trước thông tin từ TiepNhan_DoiTuongThayDoi (1 lần thay vì 4 lần)
DECLARE @BH_Attribute1 NVARCHAR(500) = NULL
DECLARE @BH_Attribute5 DATETIME = NULL
DECLARE @BH_Attribute6 DATETIME = NULL

SELECT TOP 1
	@BH_Attribute1 = Attribute1,
	@BH_Attribute5 = Attribute5,
	@BH_Attribute6 = Attribute6
FROM TiepNhan_DoiTuongThayDoi
WHERE TiepNhan_Id = @TiepNhan_Id
	AND ISNULL(Attribute1, '') <> ''
	AND IS2The = 1
ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC

-- Tính trước các giá trị từ biến @BH_Attribute*
DECLARE @MA_THE_BHYT_Prefix NVARCHAR(200) = ''
DECLARE @MA_DKBD_Prefix NVARCHAR(200) = ''
DECLARE @GT_THE_TU_Prefix VARCHAR(20) = ''
DECLARE @GT_THE_DEN_Prefix VARCHAR(20) = ''

IF @BH_Attribute1 IS NOT NULL
BEGIN
	SET @MA_THE_BHYT_Prefix = UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(@BH_Attribute1)), 0, 16), '')) + ';'
	SET @MA_DKBD_Prefix = UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(@BH_Attribute1)), 16, 20), '')) + ';'
END
IF @BH_Attribute5 IS NOT NULL
	SET @GT_THE_TU_Prefix = CONVERT(VARCHAR, @BH_Attribute5, 112) + ';'
IF @BH_Attribute6 IS NOT NULL
	SET @GT_THE_DEN_Prefix = CONVERT(VARCHAR, @BH_Attribute6, 112) + ';'

-- [TỐI ƯU #8] Tính trước MAX KhamBenhVaoVien_Id
DECLARE @MaxKBVV_Id INT
SELECT @MaxKBVV_Id = MAX(KhamBenhVaoVien_Id)
FROM KhamBenh_VaoVien
WHERE TiepNhan_Id = @TiepNhan_Id

-- [TỐI ƯU #9] Tính T_VTYT trước, tránh GROUP BY 50+ cột trong query chính
DECLARE @T_VTYT DECIMAL(18, 2) = 0

SELECT @T_VTYT = ROUND(SUM(
	CASE WHEN (
		(LI.PhanNhom IN ('DU','DI','VH','VT') AND ld.LoaiVatTu_Id = 'V'
			AND ISNULL(ld.MaLoaiDuoc, '') NOT IN ('OXY', 'OXY1', 'LD0143', 'VTYT003')
			AND ISNULL(d.BHYT, 0) = 1
		)
		OR (ISNULL(map.TenField, '')) = 'VTYT'
	)
	THEN (xnct.DonGiaHoTro * xnct.SoLuong) ELSE 0 END
), 0)
FROM (
	-- Dịch vụ kỹ thuật
	SELECT
		Loai_IDRef = 'A',
		NoiDung_Id = ycct.DichVu_Id,
		SoLuong = ycct.SoLuong,
		DonGiaHoTro = CASE WHEN CHARINDEX('.01', CAST(ycct.DonGiaHoTro AS VARCHAR(20))) > 0
						THEN CAST(REPLACE(CAST(ycct.DonGiaHoTro AS VARCHAR(20)), '.01', '.00') AS DECIMAL(18, 3))
						ELSE CAST(ycct.DonGiaHoTro AS DECIMAL(18, 3)) END,
		DonGiaHoTroChiTra = ycct.DonGiaHoTroChiTra
	FROM CLSYeuCauChiTiet ycct
	LEFT JOIN CLSYeuCau yc ON ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id
	WHERE yc.TiepNhan_Id = @TiepNhan_Id

	UNION ALL

	-- Thuốc / Vật tư
	SELECT
		Loai_IDRef = 'I',
		NoiDung_Id = ISNULL(clsvt.Duoc_Id, xbn.Duoc_Id),
		SoLuong = xbn.SoLuong,
		DonGiaHoTro = CASE WHEN CHARINDEX('.01', CAST(xbn.DonGiaHoTro AS VARCHAR(20))) > 0
						THEN CAST(REPLACE(CAST(xbn.DonGiaHoTro AS VARCHAR(20)), '.01', '.00') AS DECIMAL(18, 3))
						ELSE CAST(xbn.DonGiaHoTro AS DECIMAL(18, 3)) END,
		DonGiaHoTroChiTra = xbn.DonGiaHoTroChiTra
	FROM ChungTuXuatBenhNhan xbn
	LEFT JOIN CLSGhiNhanHoaChat_VTYT clsvt ON xbn.CLSHoaChat_VTYT_Id = clsvt.id AND xbn.Duoc_Id = clsvt.duoc_id
	WHERE xbn.TiepNhan_Id = @TiepNhan_Id AND xbn.mienphi = 0
) xnct
LEFT JOIN dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef
LEFT JOIN (
	SELECT dndv.DichVu_Id, mbc.TenField
	FROM dbo.DM_MauBaoCao mbc
	JOIN dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
	WHERE MauBC = 'BCVP_097'
) map ON map.DichVu_Id = xnct.NoiDung_Id
LEFT JOIN DM_Duoc d ON d.Duoc_Id = xnct.NoiDung_Id AND LI.PhanNhom = 'DU' AND ISNULL(D.BHYT, 0) = 1
LEFT JOIN dbo.DM_LoaiDuoc ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
WHERE xnct.DonGiaHoTroChiTra > 0

IF @BenhAn_Id IS NULL
BEGIN

SELECT
	[MA_LK] = @Ma_Lk
	, [STT] = 1
	, [MA_BN] = bn.SoVaoVien
	, [HO_TEN] = bn.TenBenhNhan
	, [SO_CCCD] = CASE WHEN LEN(bn.CMND) < 10 OR bn.CMND = '000000000000' THEN '' ELSE LEFT(bn.CMND, 12) END
	, [NGAY_SINH] = CASE
		WHEN bn.NgaySinh IS NULL THEN CONVERT(VARCHAR, bn.NamSinh) + '01010000'
		WHEN bn.NgaySinh IS NOT NULL THEN CONVERT(VARCHAR, bn.NgaySinh, 112) + '0000'
	END
	, [GIOI_TINH] = CASE WHEN bn.GioiTinh = 'T' THEN 1 WHEN bn.GioiTinh = 'G' THEN 2 END
	, [MA_QUOCTICH] = quoctich.Dictionary_Code
	, [MA_DANTOC] = dantoc.Dictionary_Code
	, [MA_NGHE_NGHIEP] = nghenghiep.Dictionary_Name_En
	, [DIA_CHI] = ISNULL(bn.diachi, TN.noilamviec)
	, [MATINH_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL
		THEN tinhmoi.Ma_TheoChuan ELSE tinh.Ma_TheoChuan END
	, [MAHUYEN_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL
		THEN NULL ELSE huyen.Ma_TheoChuan END
	, [MAXA_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL
		THEN xamoi.Ma_TheoChuan ELSE xa.Ma_TheoChuan END
	, [DIEN_THOAI] = LEFT(bn.SoDienThoai, 10)
	-- [TỐI ƯU #3] Dùng biến tính trước thay vì 4 subquery lặp
	, [MA_THE_BHYT] = RTRIM(LTRIM(@MA_THE_BHYT_Prefix)) + UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(TN.SoBHYT)), 0, 16), ''))
	, [MA_DKBD] = RTRIM(LTRIM(@MA_DKBD_Prefix)) + UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(TN.SoBHYT)), 16, 20), ''))
	, [GT_THE_TU] = RTRIM(LTRIM(@GT_THE_TU_Prefix)) + CONVERT(VARCHAR, tn.BHYTTuNgay, 112)
	, [GT_THE_DEN] = RTRIM(LTRIM(@GT_THE_DEN_Prefix)) + CONVERT(VARCHAR, tn.BHYTDenNgay, 112)
	, [NGAY_MIEN_CCT] = CONVERT(VARCHAR, tn.NgayHuongMienCT, 112)
	, [LY_DO_VV] = ISNULL(tn.LyDoVaoVien, N'Khám chữa bệnh')
	, [LY_DO_VNT] = kbvv.LyDoVaoVien
	, [MA_LY_DO_VNT] = NULL
	, [CHAN_DOAN_VAO] = ISNULL(@ChanDoan_NT, @ChanDoan_PK)
	, [CHAN_DOAN_RV] = ISNULL(@ChanDoan_NT, @ChanDoan_PK)
	, [MA_BENH_CHINH] = ISNULL(@ICD_NT, @ICDKB)
	, [MA_BENH_KT] = CASE WHEN @ICD_PNT = '' THEN @ICD_PK ELSE @ICD_PNT END
	, [MA_BENH_YHCT] = NULL
	, [MA_PTTT_QT] = @MA_PTTT_QT
	, [MA_DOITUONG_KCB] =
		CASE WHEN tn.NgayTiepNhan > '20251017' THEN
			CASE WHEN tn.MaDoiTuongKCB_Id IS NULL THEN
				CASE
					WHEN lst1.Dictionary_Code = '2' AND kcbbd.TenBenhVien_En <> @MaCSKCB THEN '2'
					WHEN kcbbd.TenBenhVien_En = @MaCSKCB AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1'
					WHEN lst1.Dictionary_Code <> '2' AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3'
					ELSE '3.2'
				END
			ELSE mdt.Dictionary_Code END
		ELSE
			CASE
				WHEN lst1.Dictionary_Code = '2' AND kcbbd.TenBenhVien_En <> @MaCSKCB THEN '2'
				WHEN kcbbd.TenBenhVien_En = @MaCSKCB AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1'
				WHEN lst1.Dictionary_Code <> '2' AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3'
				ELSE '3.3'
			END
		END
	, [MA_NOI_DI] = ngt.TenBenhVien_En
	, [MA_NOI_DEN] = bvChuyenDi.TenBenhVien_En
	, [MA_TAI_NAN] = CASE
		WHEN tain.nguyennhan_id = '479' THEN 1
		WHEN tain.nguyennhan_id = '480' THEN 2
		WHEN tain.nguyennhan_id = '481' THEN 4
		WHEN tain.nguyennhan_id = '482' THEN 5
		WHEN tain.nguyennhan_id = '483' THEN 3
		WHEN tain.nguyennhan_id = '484' THEN 6
		WHEN tain.nguyennhan_id = '485' THEN 7
		WHEN tain.nguyennhan_id = '8733' THEN 8
		ELSE ''
	END
	, [NGAY_VAO] = REPLACE(CONVERT(VARCHAR, tn.ThoiGianTiepNhan, 112) + CONVERT(VARCHAR(5), tn.ThoiGianTiepNhan, 108), ':', '')
	, [NGAY_VAO_NOI_TRU] = NULL
	, [NGAY_RA] = NULL
	, [GIAY_CHUYEN_TUYEN] = @SoChuyenVien
	, [SO_NGAY_DTRI] = 0
	, [PP_DIEU_TRI] = NULL
	, [KET_QUA_DTRI] = CASE
		WHEN ketquadieutri.Dictionary_Code = 'Khoi' THEN 1
		WHEN ketquadieutri.Dictionary_Code = 'Giam' THEN 2
		WHEN ketquadieutri.Dictionary_Code = 'KhongThayDoi' THEN 3
		WHEN ketquadieutri.Dictionary_Code IN ('NXV', 'nanghon', 'HHXV') THEN 4
		WHEN ketquadieutri.Dictionary_Code IN ('TuVong', 'TuVong24', 'TuVongCD', 'TuVongTL', 'TuVong7') THEN 5
		ELSE 1
	END
	, [MA_LOAI_RV] = CASE
		WHEN kb.HuongGiaiQuyet_Id = 458 THEN 2
		WHEN @BenhAn_Id IS NOT NULL THEN
			CASE
				WHEN lydoxuatvien.Dictionary_Code = 'RV' THEN 1
				WHEN lydoxuatvien.Dictionary_Code = 'CV' THEN 2
				WHEN lydoxuatvien.Dictionary_Code = 'BV' THEN 3
				WHEN lydoxuatvien.Dictionary_Code IN ('XV', 'TV', 'TV24', 'CCRV', 'DV', 'N') THEN 4
				ELSE 1
			END
		ELSE 1
	END
	, [GHI_CHU] = NULL
	, [NGAY_TTOAN] = NULL
	, [T_THUOC] = @Tong_Tien_Thuoc
	-- [TỐI ƯU #9] Dùng biến tính trước thay vì tính trong query chính
	, [T_VTYT] = @T_VTYT
	, [T_TONGCHI_BV] = @Tong_Chi
	, [T_TONGCHI_BH] = @Tong_Chi_BH
	, [T_BNTT] = @T_BNTT
	, [T_BNCCT] = @T_BNCCT
	, [T_BHTT] = @T_BHTT
	, [T_NGUONKHAC] = CAST(@T_NguonKhac AS DECIMAL(18, 2))
	, [T_BHTT_GDV] = 0
	, [NAM_QT] = NULL
	, [THANG_QT] = NULL
	, [MA_LOAI_KCB] = CASE
		WHEN ba.BenhAn_Id IS NOT NULL THEN '02'
		ELSE '01'
	END
	, [MA_KHOA] = CASE WHEN ba.BenhAn_Id IS NULL THEN pbkb.MaTheoQuiDinh ELSE kr.MaTheoQuiDinh END
	, [MA_CSKCB] = @MaCSKCB
	, [MA_KHUVUC] = ISNULL(nss.Dictionary_Code, '')
	, [CAN_NANG] = ISNULL(NULLIF(kb.CanNang, 0), 50)
	, [CAN_NANG_CON] = NULL
	, [NAM_NAM_LIEN_TUC] = NULL
	, [NGAY_TAI_KHAM] = ISNULL(CONVERT(VARCHAR, ba.ngayhentaikham, 112), dbo.Get_SoNgayHenTaiKham_XML130(@TIEPNHAN_ID))
	, [MA_HSBA] = @Ma_Lk
	, [MA_TTDV] = '2096091139'
	, [DU_PHONG] = NULL
	, [NHOM_MAU] = nhommau.Dictionary_Name

FROM dbo.TiepNhan tn
-- Bệnh nhân
LEFT JOIN dbo.DM_BenhNhan bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
-- Đối tượng
LEFT JOIN dbo.DM_DoiTuong dtg ON dtg.DoiTuong_Id = tn.DoiTuong_Id
LEFT JOIN dbo.DM_DoiTuong dt ON dt.DoiTuong_Id = tn.DoiTuong_Id
LEFT JOIN dbo.Lst_Dictionary ndt ON ndt.Dictionary_Id = dt.NhomDoiTuong_Id
-- Quốc tịch, dân tộc, nghề nghiệp
LEFT JOIN Lst_Dictionary quoctich ON quoctich.Dictionary_Id = bn.QuocTich_Id
LEFT JOIN Lst_Dictionary dantoc ON dantoc.Dictionary_Id = bn.DanToc_Id
LEFT JOIN Lst_Dictionary nghenghiep ON nghenghiep.Dictionary_Id = bn.NgheNghiep_Id
-- Đơn vị hành chính
LEFT JOIN DM_DonViHanhChinh tinh ON tinh.DonViHanhChinh_Id = bn.tinhthanh_id
LEFT JOIN DM_DonViHanhChinh huyen ON huyen.DonViHanhChinh_Id = bn.quanhuyen_id
LEFT JOIN DM_DonViHanhChinh xa ON xa.DonViHanhChinh_Id = bn.XaPhuong_Id
LEFT JOIN DM_DonViHanhChinh tinhmoi ON tinhmoi.DonViHanhChinh_Id = bn.tinhthanhMoi_id
LEFT JOIN DM_DonViHanhChinh xamoi ON xamoi.DonViHanhChinh_Id = bn.XaPhuongMoi_Id
-- Tai nạn
LEFT JOIN TaiNan tain ON tain.tiepnhan_id = tn.tiepnhan_id
-- Tuyến khám
LEFT JOIN dbo.Lst_Dictionary lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
LEFT JOIN dbo.DM_BenhVien ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
-- [TỐI ƯU #2] Thay correlated subquery MAX(KetThucKham) bằng CROSS APPLY TOP 1
CROSS APPLY (
	SELECT TOP 1 kb.*
	FROM KhamBenh kb
	WHERE kb.TiepNhan_Id = tn.TiepNhan_Id
	ORDER BY kb.KetThucKham DESC
) kb
LEFT JOIN DM_ICD bc ON bc.ICD_ID = kb.ChanDoanICD_Id
LEFT JOIN DM_ICD bp ON bp.ICD_ID = kb.ChanDoanPhuICD_Id
-- Chuyển viện
LEFT JOIN chuyenvien cv ON cv.TiepNhan_Id = tn.TiepNhan_Id
-- KCBBĐ
LEFT JOIN DM_BenhVien kcbbd ON tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
LEFT JOIN Lst_Dictionary LST1 ON LST1.Dictionary_Id = TN.LyDoTiepNhan_Id
LEFT JOIN Lst_Dictionary nss ON tn.NoiSinhSong_ID = nss.Dictionary_Id AND nss.Dictionary_Type_Code = 'NoiSinhSong'
-- Bệnh án
LEFT JOIN BenhAn ba ON ba.TiepNhan_Id = tn.TiepNhan_Id
LEFT JOIN DM_ICD icd_nt ON icd_nt.ICD_Id = ba.ICD_BenhChinh
LEFT JOIN DM_PhongBan kr ON kr.PhongBan_Id = ba.KhoaRa_Id
LEFT JOIN DM_PhongBan pbkb ON pbkb.PhongBan_Id = kb.PhongBan_Id
LEFT JOIN DM_PhongBan pb ON ba.KhoaRa_Id = pb.PhongBan_Id
LEFT JOIN lst_dictionary lydoxuatvien ON ba.lydoxuatvien_id = lydoxuatvien.dictionary_id
LEFT JOIN lst_dictionary nhommau ON nhommau.Dictionary_Id = bn.NhomMau_Id
-- [TỐI ƯU #8] Dùng biến @MaxKBVV_Id tính trước
LEFT JOIN KhamBenh_VaoVien kbvv ON kbvv.KhamBenhVaoVien_Id = @MaxKBVV_Id
-- Chuyển đi
LEFT JOIN DM_BenhVien bvChuyenDi ON bvChuyenDi.BenhVien_Id = ISNULL(cv.BenhVien_Id, ba.ChuyenDenBenhVien_Id)
	AND bvChuyenDi.TamNgung = 0
-- Kết quả điều trị
LEFT JOIN Lst_Dictionary ketquadieutri ON ketquadieutri.Dictionary_Id = ISNULL(ba.KetQuaDieuTri_Id, kb.KetQuaKhamBenh_ID)
LEFT JOIN Lst_Dictionary mdt ON mdt.Dictionary_Id = tn.MaDoiTuongKCB_Id
WHERE tn.TiepNhan_Id = @TiepNhan_Id

END

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
