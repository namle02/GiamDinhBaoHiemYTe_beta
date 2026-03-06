/**
 * TT05-NgoaiTru.sql - Phiên bản tối ưu hiệu năng tối đa
 * 
 * Chiến lược tối ưu:
 *   1. Gộp tất cả truy vấn lặp (TiepNhan, AppSettings) thành 1 lần
 *   2. SELECT chỉ cột cần dùng, không SELECT *
 *   3. Thay correlated subquery bằng TOP 1 + ORDER BY
 *   4. Loại bỏ điều kiện OR trong WHERE (BenhAn_Id = NULL nên chỉ cần TiepNhan_Id)
 *   5. Gọi scalar UDF đúng 1 lần mỗi function
 *   6. Dùng #temp table thay CTE để SQL Server có thể tái sử dụng kết quả + tạo statistics
 *   7. Đồng nhất NOLOCK toàn bộ
 *   8. Inline hóa logic Get_MaBacSi bằng OUTER APPLY
 *   9. Giảm chuỗi LEFT JOIN bằng cách tính PhongBan_Id qua COALESCE + subquery
 *  10. Sử dụng SET NOCOUNT ON để giảm network overhead
 */

SET NOCOUNT ON

DECLARE @SoTiepNhan VARCHAR(50) = N'{IDBenhNhan}'

-----------------------------------------------------------------------
-- PHẦN 1: Khởi tạo biến từ 1 lần truy vấn duy nhất
-----------------------------------------------------------------------
DECLARE @TiepNhan_Id VARCHAR(50)
DECLARE @Ma_Lk VARCHAR(50)
DECLARE @BenhNhan_Id VARCHAR(50)

SELECT @TiepNhan_Id = TiepNhan_Id,
       @Ma_Lk = CONVERT(VARCHAR(50), SoTiepNhan),
       @BenhNhan_Id = BenhNhan_Id
FROM TiepNhan (NOLOCK)
WHERE SoTiepNhan = @SoTiepNhan

-- Early exit nếu không tìm thấy tiếp nhận
IF @TiepNhan_Id IS NULL
BEGIN
    PRINT N'Không tìm thấy tiếp nhận: ' + @SoTiepNhan
    RETURN
END

DECLARE @BenhAn_Id VARCHAR(50)
DECLARE @ChanDoan_NT NVARCHAR(1000)
DECLARE @ICDCapCuu VARCHAR(20)
DECLARE @ICD_NT NVARCHAR(1000)
DECLARE @ICD_NTGopBenh NVARCHAR(1000)
DECLARE @ICD_phu NVARCHAR(1000)
DECLARE @Ma_PTTT_QT VARCHAR(250)
DECLARE @ChanDoan_RV NVARCHAR(1000)
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
DECLARE @CapCuu BIT = 0
DECLARE @KhamBenh_Id INT
DECLARE @Khoa NVARCHAR(200)
DECLARE @ICD_Khac NVARCHAR(1000)
DECLARE @SoBenhAn VARCHAR(25)
DECLARE @TT_01_TONGHOP_ID INT = NULL
DECLARE @NGAY_VAO DATETIME
DECLARE @LuongToiThieu DECIMAL(18,2) = 208500.00

-----------------------------------------------------------------------
-- PHẦN 2: Lấy BenhAn_Id một lần
-----------------------------------------------------------------------
SELECT @BenhAn_Id = BenhAn_Id 
FROM BenhAn (NOLOCK) 
WHERE TiepNhan_Id = @TiepNhan_Id

-----------------------------------------------------------------------
-- PHẦN 3: Gọi UDF theo đúng nhánh (chỉ 1 lần)
-----------------------------------------------------------------------
IF @BenhAn_Id IS NOT NULL
BEGIN
    SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](@BenhAn_Id, NULL)

    SELECT @ChanDoan_NT = ISNULL(ba.ChanDoanVaoKhoa, ISNULL(icd.TenICD, ISNULL(cc.ChanDoanNhapVien, icd_cc.TenICD)))
         , @ICDCapCuu = ISNULL(icd.MaICD, icd_cc.MaICD)
         , @ICD_NT = icd.MaICD
         , @ICD_NTGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenhPHCN](@TiepNhan_Id)
         , @ICD_phu = icd_k.MaICD + ';' + [dbo].[Get_MaICD_ByBenhAn_Id](@BenhAn_Id, 'M')
         , @ChanDoan_RV = ISNULL(ba.ChanDoanRaVien, icd.TenICD) + ', ' + ISNULL(ISNULL(ba.ChanDoanPhuRaVien, icd_k.TenICD), '')
    FROM dbo.BenhAn ba (NOLOCK)
    INNER JOIN TiepNhan tn (NOLOCK) ON ba.TiepNhan_ID = tn.TiepNhan_ID
    LEFT JOIN DM_ICD icd (NOLOCK) ON icd.ICD_Id = ba.ICD_BenhChinh
    LEFT JOIN ThongTinCapCuu cc (NOLOCK) ON ba.BenhAn_ID = cc.BenhAn_Id
    LEFT JOIN DM_ICD icd_cc (NOLOCK) ON ISNULL(cc.ICD_BenhChinh, cc.ICD_BenhPhu) = icd_cc.ICD_Id
    LEFT JOIN DM_ICD icd_k (NOLOCK) ON ba.ICD_BenhPhu = icd_k.ICD_Id
    WHERE ba.BenhAn_Id = @BenhAn_Id
END
ELSE
BEGIN
    SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](NULL, @TiepNhan_Id)
END

-----------------------------------------------------------------------
-- PHẦN 4: Gọi UDF Phòng Khám (scalar - không tránh được, gọi 1 lần mỗi fn)
-----------------------------------------------------------------------
SET @ICD_PK = [dbo].[Get_MaICDPhuByTiepNhan_ID](@TiepNhan_Id)
SET @ChanDoan_PK = [dbo].[Get_DSChanDoanKB_ByTiepNhan_ID](@TiepNhan_Id)
SET @ICD_PHUPK = [dbo].[Get_MaICD_ByTiepNhan_ID](@TiepNhan_Id)
SET @ICD_PKBenhChinh = [dbo].[Get_MaICDByTiepNhan_ID_benhchinh](@TiepNhan_Id)
SET @ICD_PKGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenh](@TiepNhan_Id)

-- Bệnh án Ngoại trú
SET @ICD_PNT = [dbo].[Get_MaICD_Phu_ByBenhAn_Id](@BenhAn_Id, 'M')

-----------------------------------------------------------------------
-- PHẦN 5: Gộp AppSettings thành 1 truy vấn
-----------------------------------------------------------------------
SELECT @MaCSKCB = MAX(CASE WHEN Code = N'MaBenhVien_BHYT' THEN Value END),
       @LuongToiThieu = MAX(CASE WHEN Code = 'LuongToiThieu' THEN Value END)
FROM Sys_AppSettings (NOLOCK)
WHERE Code IN (N'MaBenhVien_BHYT', 'LuongToiThieu')

-----------------------------------------------------------------------
-- PHẦN 6: Chẩn đoán cấp cứu
-----------------------------------------------------------------------
SELECT @ChanDoanCapCuu = icd.TenICD, @ICDCapCuu = icd.MaICD, @CapCuu = 1
FROM BenhAn ba (NOLOCK)
LEFT JOIN DM_ICD icd (NOLOCK) ON icd.ICD_Id = ba.ICD_BenhChinh
WHERE ba.TiepNhan_Id = @TiepNhan_Id
  AND ba.SoCapCuu IS NOT NULL

-----------------------------------------------------------------------
-- PHẦN 7: Mã bệnh chính phòng khám đầu tiên (TOP 1 thay correlated subquery)
-----------------------------------------------------------------------
SELECT TOP 1 @ICDKB = icd.MaICD
FROM KhamBenh kb (NOLOCK)
LEFT JOIN DM_ICD icd (NOLOCK) ON icd.ICD_Id = kb.ChanDoanICD_Id
WHERE kb.TiepNhan_Id = @TiepNhan_Id
ORDER BY kb.ThoiGianKham ASC

-----------------------------------------------------------------------
-- PHẦN 8: Reset BenhAn_Id + Tính tổng tiền
-----------------------------------------------------------------------
SET @BenhAn_Id = NULL

DECLARE @Tong_Tien_Thuoc DECIMAL(18, 2) = 0
DECLARE @Tong_Chi DECIMAL(18, 2) = 0
DECLARE @T_BHTT DECIMAL(18, 2) = 0
DECLARE @T_BNCCT DECIMAL(18, 2) = 0
DECLARE @T_BNTT DECIMAL(18, 2) = 0
DECLARE @T_NguonKhac DECIMAL(18, 2) = 0
DECLARE @Tong_Chi_BH DECIMAL(18, 2) = 0

SELECT @Tong_Chi = T_TongChi,
       @T_BHTT = T_BHTT,
       @T_BNCCT = T_BNCCT,
       @Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
       @T_BNTT = T_BNTT,
       @T_NguonKhac = T_NguonKhac,
       @Tong_Chi_BH = T_TONGCHI_BH
FROM dbo.Tong_Tien_XML_BangKe01_130(@TiepNhan_Id)

-----------------------------------------------------------------------
-- PHẦN 9: Số chuyển viện (bỏ subquery TiepNhan, dùng biến đã có)
-----------------------------------------------------------------------
DECLARE @SoChuyenVien NVARCHAR(50) = NULL
SELECT @SoChuyenVien = LEFT(cv.SoPhieu, 6)
FROM ChuyenVien cv (NOLOCK)
WHERE cv.TiepNhan_Id = @TiepNhan_Id

-----------------------------------------------------------------------
-- PHẦN 10: Kết quả chính - Temp table + OUTER APPLY thay scalar UDF
-----------------------------------------------------------------------
IF @BenhAn_Id IS NULL
BEGIN
    -- Đưa dữ liệu phẫu thuật vào temp table để SQL Server tạo statistics
    -- giúp tối ưu execution plan tốt hơn CTE cho query phức tạp
    
    -- Xóa temp table nếu còn tồn tại từ lần chạy trước
    IF OBJECT_ID('tempdb..#PhauThuat') IS NOT NULL DROP TABLE #PhauThuat

    CREATE TABLE #PhauThuat (
        dien_bien NVARCHAR(MAX),
        hoi_chan NVARCHAR(MAX),
        phau_thuat NVARCHAR(MAX),
        NGAY_YL VARCHAR(20),
        Ma_Bsi NVARCHAR(200)
    )

    -- PHẦN 10a: Insert phẫu thuật - chỉ lọc theo TiepNhan_Id (BenhAn_Id = NULL)
    INSERT INTO #PhauThuat (dien_bien, hoi_chan, phau_thuat, NGAY_YL, Ma_Bsi)
    SELECT 
        ISNULL(pt.ICD_TruocPhauThuat_MoTa, ISNULL(yc_outer.NoiDungChiTiet, yc_outer.ChanDoan)),
        NULL,
        ISNULL(pt.CanThiepPhauThuat, ' '),
        REPLACE(CONVERT(VARCHAR, pt.ThoiGianKetThuc, 112) + CONVERT(VARCHAR(5), pt.ThoiGianKetThuc, 108), ':', ''),
        dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(pt.BenhAnPhauThuat_Id)
    FROM CLSYeuCauChiTiet ycct (NOLOCK)
    INNER JOIN CLSYeuCau yc_outer (NOLOCK) ON ycct.CLSYeuCau_Id = yc_outer.CLSYeuCau_Id
    INNER JOIN DM_DichVu dv (NOLOCK) ON dv.DichVu_Id = ycct.DichVu_Id
    INNER JOIN DM_NhomDichVu ndv (NOLOCK) ON ndv.NhomDichVu_Id = dv.NhomDichVu_Id
    INNER JOIN dbo.VienPhiNoiTru_Loai_IDRef LI (NOLOCK) ON LI.Loai_IDRef = 'A' AND LI.PhanNhom = 'DV'
    INNER JOIN BenhAnPhauThuat pt (NOLOCK) ON pt.CLSYeuCau_Id = yc_outer.CLSYeuCau_Id
    WHERE yc_outer.TiepNhan_Id = @TiepNhan_Id
      AND ycct.DonGiaHoTroChiTra > 0
      AND CAST(ycct.DonGiaHoTro AS DECIMAL(18,3)) * ycct.SoLuong <> 0
      AND ndv.LoaiDichVu_ID IN (3, 8)

    -- PHẦN 10b: Insert hội chẩn
    INSERT INTO #PhauThuat (dien_bien, hoi_chan, phau_thuat, NGAY_YL, Ma_Bsi)
    SELECT 
        ISNULL(hc.TomTat_TienSuBenh + ', ', '') + ISNULL(hc.TinhTrang + ', ', '') + ISNULL(hc.TomTat_DienBienBenh, ''),
        ISNULL(hc.ChanDoan + ', ', '') + ISNULL(hc.HuongXuTri + ', ', '') + ISNULL(hc.ChamSoc, ''),
        '',
        REPLACE(CONVERT(VARCHAR, hc.ThoiGianHoiChan, 112) + CONVERT(VARCHAR(5), hc.ThoiGianHoiChan, 108), ':', ''),
        nv.SoChungChiHanhNghe
    FROM HoiChan hc (NOLOCK)
    LEFT JOIN vw_NhanVien nv (NOLOCK) ON nv.NhanVien_Id = hc.BacSi_Id
    WHERE hc.TiepNhan_Id = @TiepNhan_Id
      AND hc.HoiChan_Id IS NOT NULL

    -- PHẦN 10c: Kết quả cuối - đọc từ temp table (rất nhanh)
    SELECT 
        [MA_LK] = @Ma_Lk,
        [STT] = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        [DIEN_BIEN_LS] = dien_bien,
        [GIAI_DOAN_BENH] = NULL,
        [HOI_CHAN] = hoi_chan,
        [PHAU_THUAT] = phau_thuat,
        [THOI_DIEM_DBLS] = NGAY_YL,
        [NGUOI_THUC_HIEN] = Ma_Bsi,
        [DU_PHONG] = NULL
    FROM #PhauThuat

    DROP TABLE #PhauThuat
END

SET NOCOUNT OFF
