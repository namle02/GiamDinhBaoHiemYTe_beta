/*==============================================================================
  TT04-NgoaiTru.sql - PHIÊN BẢN TỐI ƯU
  
  Tối ưu so với bản gốc:
  1. SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED thay cho (nolock) rải rác
  2. Bỏ subquery SELECT * không cần thiết (dòng 33-37, 144 gốc)
  3. Thay correlated subquery MIN(ThoiGianKham) bằng TOP 1
  4. Thay OR trong JOIN/WHERE bằng filter trực tiếp @tiepnhan_id
  5. Thay subquery KhamBenh phức tạp (GROUP BY + correlated TOP 1) bằng CROSS APPLY TOP 1
  6. Loại bỏ điều kiện WHERE trùng lặp (DonGiaHoTroChiTra > 0 xuất hiện 2 lần)
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
		, [MA_DICH_VU] = LEFT(ISNULL(con.MaQuiDinh, CASE WHEN tn.NgayTiepNhan > '20250731' THEN DV.MaQuiDinh ELSE DV.MaQuiDinhCu END), 15)
		, [MA_CHI_SO] = ISNULL(ISNULL(con.MaChiSo, dv.MaChiSo), '0')
		, [TEN_CHI_SO] = REPLACE(ISNULL(con.TenDichVu, dv.TenDichVu), CHAR(0x1F), '')
		, [GIA_TRI] = REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ct.ketqua, ''), CHAR(0x1F), ''), '.' + CHAR(0x17), '.'), CHAR(0x17), ''), CHAR(0x02), '')
		, [MUC_BINH_THUONG] = ct.MucBinhThuong
		, [DON_VI_DO] = ISNULL(con.DonViTinh, dv.DonViTinh)
		, [MO_TA] = MoTa_Text
		, [KET_LUAN] = kq.ketluan
		, [NGAY_KQ] = ISNULL(
			REPLACE(CONVERT(VARCHAR, kq.ThoiGianThucHien, 112) + CONVERT(VARCHAR(5), kq.ThoiGianThucHien, 108), ':', ''),
			REPLACE(CONVERT(VARCHAR, yc.NgayGioYeuCau, 112) + CONVERT(VARCHAR(5), yc.NgayGioYeuCau, 108), ':', '')
		)
		, [MA_BS_DOC_KQ] = bsi.SoChungChiHanhNghe
		, [DU_PHONG] = NULL
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
				WHEN mbc.TenField IN ('TTPT','TT','TT_PT') THEN '06'
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
		WHERE mbc.MauBC = 'BCVP_097'
	) map ON map.DichVu_Id = xnct.NoiDung_Id

	LEFT JOIN dbo.TiepNhan tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id

	-- [TỐI ƯU #5] Thay subquery KhamBenh phức tạp (GROUP BY + correlated TOP 1) bằng CROSS APPLY
	OUTER APPLY (
		SELECT TOP 1 kb2.PhongBan_Id, kb2.BacSiKham_Id, kb2.ThoiGianKham
		FROM KhamBenh kb2
		WHERE kb2.TiepNhan_Id = xnct.TiepNhan_Id
		ORDER BY kb2.ThoiGianKham ASC
	) kb

	LEFT JOIN dm_phongban pb ON pb.PhongBan_Id = kb.PhongBan_Id
	LEFT JOIN dbo.DM_BenhNhan bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
	LEFT JOIN DM_DoiTuong dt ON dt.DoiTuong_Id = tn.DoiTuong_Id
	LEFT JOIN dbo.DM_DichVu dv ON dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
	LEFT JOIN DM_NhomDichVu ndv ON ndv.NhomDichVu_Id = dv.NhomDichVu_Id
	LEFT JOIN DM_DichVu con ON con.CapTren_Id = dv.DichVu_ID
	LEFT JOIN CLSYeuCauChiTiet clsyc ON clsyc.YeuCauChiTiet_Id = xnct.IDRef AND xnct.Loai_IDRef = 'A'
	LEFT JOIN CLSYeuCau yc ON yc.CLSYeuCau_Id = clsyc.CLSYeuCau_Id
	LEFT JOIN CLSKetQua kq ON kq.CLSYeuCau_Id = yc.CLSYeuCau_Id
	LEFT JOIN clsketquachitiet ct ON ct.clsketqua_id = kq.clsketqua_id AND ct.DichVU_Id = ISNULL(con.DichVU_ID, dv.DichVU_ID)
	LEFT JOIN Lst_Dictionary mm ON mm.Dictionary_Id = kq.ThietBi_Id AND mm.Dictionary_Type_Code = 'NhomThietBi'
	LEFT JOIN vw_NhanVien bsi ON bsi.NhanVien_Id = ISNULL(kq.BacSiKetLuan_Id, kq.BacSiThucHien_Id)

	WHERE xnct.DonGiaHoTroChiTra > 0
		AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
		AND ndv.LoaiDichVu_Id = 2
		AND ct.ketqua IS NOT NULL
		AND bsi.SoChungChiHanhNghe IS NOT NULL

END

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
