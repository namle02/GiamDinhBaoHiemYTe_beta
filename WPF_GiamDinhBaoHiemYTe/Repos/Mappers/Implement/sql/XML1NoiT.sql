/**
 * TT01-NoiTru.sql - Phiên bản tối ưu hiệu năng tối đa
 *
 * Các tối ưu đã áp dụng:
 *   1.  Gộp 2 truy vấn Sys_AppSettings thành 1
 *   2.  Bỏ SELECT * trong subquery, join trực tiếp
 *   3.  Bỏ subquery lặp bảng BenhAn (dòng 102 gốc)
 *   4.  Gộp 4 subquery lặp TiepNhan_DoiTuongThayDoi thành 1 biến tạm
 *   5.  Thay correlated subquery KhamBenh_VaoVien bằng OUTER APPLY TOP 1
 *   6.  Loại bỏ join lặp TiepNhan, BenhAn ở outer query (dùng biến đã có)
 *   7.  Loại bỏ join lặp Lst_Dictionary loaiBA (join 2 lần cùng bảng)
 *   8.  Đồng nhất NOLOCK toàn bộ
 *   9.  SET NOCOUNT ON giảm network overhead
 *  10.  Tính trước thông tin đổi thẻ BHYT vào biến, tránh subquery lặp
 */

SET NOCOUNT ON

DECLARE @SoBenhAn NVARCHAR(20) = N'{IDBenhNhan}'

-----------------------------------------------------------------------
-- PHẦN 1: Lấy BenhAn_Id
-----------------------------------------------------------------------
DECLARE @BenhAn_Id NVARCHAR(20)
SELECT @BenhAn_Id = ba.BenhAn_Id
FROM dbo.BenhAn ba (NOLOCK)
WHERE ba.SoBenhAn = @SoBenhAn

-- Early exit
IF @BenhAn_Id IS NULL
BEGIN
    PRINT N'Không tìm thấy bệnh án: ' + @SoBenhAn
    RETURN
END

-----------------------------------------------------------------------
-- PHẦN 2: Lấy thông tin BenhAn + ICD (bỏ SELECT *, join trực tiếp)
-----------------------------------------------------------------------
DECLARE @Ma_Lk VARCHAR(20) = NULL
DECLARE @TiepNhan_Id INT
DECLARE @ChanDoan_RV NVARCHAR(2000)
DECLARE @ICD_CHINH NVARCHAR(2000)
DECLARE @ICD_CHINH_YHCT NVARCHAR(2000)
DECLARE @ChanDoan NVARCHAR(2000)

SELECT @ChanDoan = ISNULL(ba.ChanDoanVaoKhoa, ISNULL(icd.TenICD, ISNULL(cc.ChanDoanNhapVien, icd_cc.TenICD)))
     , @ICD_CHINH = icd.MaICD
     , @ICD_CHINH_YHCT = icd.MaICD_YHCT
     , @ChanDoan_RV = ISNULL(ba.ChanDoanRaVien, icd.TenICD) + ', ' + ISNULL(ISNULL(ba.ChanDoanPhuRaVien, icd_k.TenICD), '')
     , @SoBenhAn = ba.SoBenhAn
     , @Ma_Lk = REPLACE(ba.SoBenhAn, '/', '_')
     , @TiepNhan_Id = ba.TiepNhan_Id
FROM dbo.BenhAn ba (NOLOCK)
INNER JOIN TiepNhan tn (NOLOCK) ON ba.TiepNhan_ID = tn.TiepNhan_ID
LEFT JOIN DM_ICD icd (NOLOCK) ON icd.ICD_Id = ba.ICD_BenhChinh
LEFT JOIN ThongTinCapCuu cc (NOLOCK) ON ba.BenhAn_ID = cc.BenhAn_Id
LEFT JOIN DM_ICD icd_cc (NOLOCK) ON ISNULL(cc.ICD_BenhChinh, cc.ICD_BenhPhu) = icd_cc.ICD_Id
LEFT JOIN DM_ICD icd_k (NOLOCK) ON ba.ICD_BenhPhu = icd_k.ICD_Id
WHERE ba.BenhAn_Id = @BenhAn_Id

-----------------------------------------------------------------------
-- PHẦN 3: Gộp AppSettings thành 1 truy vấn + UDFs
-----------------------------------------------------------------------
DECLARE @MaCSKCB NVARCHAR(2000)
DECLARE @MinBHYTChiTra DECIMAL(18,2) = 208500.00
DECLARE @MocThoiGian_DuocTyLe VARCHAR(10) = '20190101'

SELECT @MaCSKCB = MAX(CASE WHEN Code = N'MaBenhVien_BHYT' THEN Value END),
       @MinBHYTChiTra = MAX(CASE WHEN Code = 'LuongToiThieu' THEN Value END)
FROM Sys_AppSettings (NOLOCK)
WHERE Code IN (N'MaBenhVien_BHYT', 'LuongToiThieu')

DECLARE @ICD_PHU NVARCHAR(2000)
DECLARE @ICD_PHU_YHCT NVARCHAR(2000)
SET @ICD_PHU = [dbo].[Get_MaICD_Phu_ByBenhAn_Id](@BenhAn_Id, 'M')
SET @ICD_PHU_YHCT = [dbo].[Get_MaICDYHCT_Phu_ByBenhAn_Id_YHCT](@BenhAn_Id, 'Y3')
SET @MocThoiGian_DuocTyLe = dbo.sp_SysGetAppSettingValue('BHYT_NgayTiepNhan_DuocTyLe', 'VI')

-----------------------------------------------------------------------
-- PHẦN 4: Tính tổng tiền (TVF - giữ nguyên)
-----------------------------------------------------------------------
DECLARE @Tong_Tien_Thuoc DECIMAL(18, 2) = 0
DECLARE @T_BHTT DECIMAL(18, 2) = 0
DECLARE @Tong_Chi DECIMAL(18, 2) = 0
DECLARE @T_BNCCT DECIMAL(18, 2) = 0
DECLARE @T_BNTT DECIMAL(18, 2) = 0
DECLARE @T_VTYT DECIMAL(18, 2) = 0
DECLARE @T_KTC DECIMAL(18, 2) = 0
DECLARE @T_ThanhTienBH DECIMAL(18, 2) = 0
DECLARE @MocThoiGian_BHYT VARCHAR(10) = '20180715'

SELECT @Tong_Chi = T_TongChi,
       @T_BHTT = T_BHTT,
       @T_BNCCT = T_BNCCT,
       @T_BNTT = T_BNTT,
       @Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
       @T_VTYT = T_Tong_Tien_VTYT,
       @T_KTC = T_Tong_Tien_KTC,
       @T_ThanhTienBH = T_ThanhTienBH
FROM dbo.Tong_Tien_XML_BangKe02_130(@BenhAn_Id)

-----------------------------------------------------------------------
-- PHẦN 5: PTTT + Số chuyển viện
-----------------------------------------------------------------------
DECLARE @Ma_PTTT_QT VARCHAR(250)
SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](@BenhAn_Id, NULL)

DECLARE @SoChuyenVien NVARCHAR(50) = NULL
SELECT @SoChuyenVien = RIGHT(bact2.SoBenhAn, 9)
FROM BenhAnTongQuat bact2 (NOLOCK)
JOIN BenhAnTongQuat_GCV gcv (NOLOCK) ON bact2.BenhAnTongQuat_Id = gcv.BenhAnTongQuat_Id
WHERE bact2.BenhAn_Id = @BenhAn_Id

-----------------------------------------------------------------------
-- PHẦN 6: Tính trước thông tin đổi thẻ BHYT (tránh 4 subquery lặp)
-----------------------------------------------------------------------
DECLARE @DoiThe_SoBHYT VARCHAR(500) = NULL
DECLARE @DoiThe_MaKCBBD VARCHAR(500) = NULL
DECLARE @DoiThe_TuNgay VARCHAR(100) = NULL
DECLARE @DoiThe_DenNgay VARCHAR(100) = NULL

SELECT TOP 1
    @DoiThe_SoBHYT = UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(Attribute1)), 0, 16), '')) + ';',
    @DoiThe_MaKCBBD = UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(Attribute1)), 16, 20), '')) + ';',
    @DoiThe_TuNgay = CONVERT(VARCHAR, Attribute5, 112) + ';',
    @DoiThe_DenNgay = CONVERT(VARCHAR, Attribute6, 112) + ';'
FROM TiepNhan_DoiTuongThayDoi (NOLOCK)
WHERE TiepNhan_Id = @TiepNhan_Id
  AND ISNULL(Attribute1, '') <> ''
  AND IS2The = 1
ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC

-----------------------------------------------------------------------
-- PHẦN 7: Kết quả chính - Đơn giản hóa chuỗi JOIN
-----------------------------------------------------------------------
SELECT * FROM
(
    SELECT 
        [MA_LK] = @Ma_Lk
      , [STT] = 1
      , [MA_BN] = RIGHT(bn.MaYTe, 8)
      , [HO_TEN] = bn.TenBenhNhan
      , [SO_CCCD] = CASE WHEN LEN(bn.CMND) < 10 THEN '' ELSE LEFT(bn.CMND, 12) END
      , [NGAY_SINH] = CASE 
            WHEN bn.NgaySinh IS NULL THEN CONVERT(VARCHAR, bn.NamSinh) + '01010000'
            ELSE CONVERT(VARCHAR, bn.NgaySinh, 112) + '0000'
        END
      , [GIOI_TINH] = CASE WHEN bn.GioiTinh = 'T' THEN 1 WHEN bn.GioiTinh = 'G' THEN 2 END
      , [MA_QUOCTICH] = ISNULL(quoctich.Dictionary_Code, '000')
      , [MA_DANTOC] = ISNULL(dantoc.Dictionary_Code, '01')
      , [MA_NGHE_NGHIEP] = ISNULL(nghenghiep.Dictionary_Name_En, '00000')
      , [DIA_CHI] = bn.DiaChi
      , [MATINH_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL THEN tinhmoi.Ma_TheoChuan ELSE tinh.Ma_TheoChuan END
      , [MAHUYEN_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL THEN NULL ELSE huyen.Ma_TheoChuan END
      , [MAXA_CU_TRU] = CASE WHEN bn.DonViHanhChinhMoi = 1 AND bn.TinhThanhMoi_Id IS NOT NULL THEN xamoi.Ma_TheoChuan ELSE xa.Ma_TheoChuan END
      , [DIEN_THOAI] = LEFT(bn.SoDienThoai, 10)

      -- Dùng biến đã tính sẵn thay vì 4 subquery lặp
      , [MA_THE_BHYT] = RTRIM(LTRIM(ISNULL(@DoiThe_SoBHYT, ''))) + UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(tn.SoBHYT)), 0, 16), ''))
      , [MA_DKBD] = RTRIM(LTRIM(ISNULL(@DoiThe_MaKCBBD, ''))) + UPPER(ISNULL(SUBSTRING(RTRIM(LTRIM(tn.SoBHYT)), 16, 20), ''))
      , [GT_THE_TU] = RTRIM(LTRIM(ISNULL(@DoiThe_TuNgay, ''))) + CONVERT(VARCHAR, tn.BHYTTuNgay, 112)
      , [GT_THE_DEN] = RTRIM(LTRIM(ISNULL(@DoiThe_DenNgay, ''))) + CONVERT(VARCHAR, tn.BHYTDenNgay, 112)
      , [NGAY_MIEN_CCT] = CONVERT(VARCHAR, tn.NgayHuongMienCT, 112)
      , [LY_DO_VV] = ISNULL(ISNULL(tn.LyDoVaoVien, 
            CASE WHEN lst.Dictionary_Code = '2' AND bv.TenBenhVien_En <> @MaCSKCB THEN N'Cấp cứu' ELSE N'Khám chữa bệnh' END
        ), N'Khám chữa bệnh')
      , [LY_DO_VNT] = ISNULL(kbvv.LyDoVaoVien, N'Cần nhập viện')
      , [MA_LY_DO_VNT] = 1
      , [CHAN_DOAN_VAO] = ba.ChanDoanVaoKhoa
      , [CHAN_DOAN_RV] = @ChanDoan_RV
      , [MA_BENH_CHINH] = @ICD_CHINH
      , [MA_BENH_KT] = @ICD_PHU
      , [MA_BENH_YHCT] = NULL
      , [MA_PTTT_QT] = @Ma_PTTT_QT
      , [MA_DOITUONG_KCB] = CASE WHEN tn.NgayTiepNhan > '20251017' THEN
            CASE WHEN ISNULL(tn.MaDoiTuongKCB_Id, 0) = 0 THEN
                CASE WHEN lst.Dictionary_Code = '2' AND bv.TenBenhVien_En <> @MaCSKCB THEN '2'
                     WHEN bv.TenBenhVien_En = @MaCSKCB AND TuyenKB.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1'
                     WHEN lst.Dictionary_Code <> '2' AND TuyenKB.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3'
                     ELSE '3.2'
                END
            ELSE mdt.Dictionary_Code END
        ELSE
            CASE WHEN lst.Dictionary_Code = '2' AND bv.TenBenhVien_En <> @MaCSKCB THEN '2'
                 WHEN bv.TenBenhVien_En = @MaCSKCB AND TuyenKB.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1'
                 WHEN lst.Dictionary_Code <> '2' AND TuyenKB.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3'
                 ELSE '3.3'
            END
        END
      , [MA_NOI_DI] = ISNULL(ngt.TenBenhVien_En, '')
      , [MA_NOI_DEN] = ISNULL(manoiden.TenBenhVien_En, '')
      , [MA_TAI_NAN] = NULL
      , [NGAY_VAO] = CASE 
            WHEN ba.ThoiGianRaVien < '20250219' THEN REPLACE(CONVERT(VARCHAR, ba.ThoiGianVaoVien, 112) + CONVERT(VARCHAR(5), ba.ThoiGianVaoVien, 108), ':', '')
            ELSE REPLACE(CONVERT(VARCHAR, tn.ThoiGianTiepNhan, 112) + CONVERT(VARCHAR(5), tn.ThoiGianTiepNhan, 108), ':', '')
        END
      , [NGAY_VAO_NOI_TRU] = REPLACE(CONVERT(VARCHAR, ba.ThoiGianVaoVien, 112) + CONVERT(VARCHAR(5), ba.ThoiGianVaoVien, 108), ':', '')
      , [NGAY_RA] = REPLACE(CONVERT(VARCHAR, ba.ThoiGianRaVien, 112) + CONVERT(VARCHAR(5), ba.ThoiGianRaVien, 108), ':', '')
      , [GIAY_CHUYEN_TUYEN] = @SoChuyenVien
      , [SO_NGAY_DTRI] = CASE WHEN ba.SoNgayDieuTri_New IS NOT NULL THEN ba.SoNgayDieuTri_New
            ELSE
                CASE WHEN DATEDIFF(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 240 THEN 0
                     WHEN DATEDIFF(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 1440 THEN 1
                     ELSE
                        CASE WHEN ba.ThoiGianVaoVien < CAST(@MocThoiGian_BHYT AS DATETIME) THEN
                            CASE WHEN DATEDIFF(DAY, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) = 0 THEN 1
                                 ELSE DATEDIFF(DAY, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) + 1
                            END
                        ELSE
                            CASE WHEN DATEDIFF(DAY, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) = 0 THEN 1
                                 ELSE
                                    CASE WHEN ketquadieutri.Dictionary_Code IN ('Khoi', 'Giam') THEN DATEDIFF(DAY, ba.ThoiGianVaoVien, ba.ThoiGianRaVien)
                                         ELSE DATEDIFF(DAY, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) + 1
                                    END
                            END
                        END
                END
        END
      , [PP_DIEU_TRI] = bact.PPDT
      , [KET_QUA_DTRI] = CASE WHEN ketquadieutri.Dictionary_Code = 'Khoi' THEN 1
            WHEN ketquadieutri.Dictionary_Code = 'Giam' THEN 2
            WHEN ketquadieutri.Dictionary_Code = 'KhongThayDoi' THEN 3
            WHEN ketquadieutri.Dictionary_Code IN ('NXV', 'nanghon', 'HHXV') THEN 4
            WHEN ketquadieutri.Dictionary_Code IN ('TuVong', 'TuVong24', 'TuVongCD', 'TuVongTL', 'TuVong7') THEN 5
            ELSE 1 END
      , [MA_LOAI_RV] = CASE WHEN lydoxuatvien.Dictionary_Code = 'RV' THEN 1
            WHEN lydoxuatvien.Dictionary_Code = 'CV' THEN 2
            WHEN lydoxuatvien.Dictionary_Code = 'BV' THEN 3
            WHEN lydoxuatvien.Dictionary_Code IN ('XV', 'TV', 'TV24', 'CCRV', 'DV', 'N') THEN 4
            ELSE 1 END
      , [GHI_CHU] = bact.LoiDanThayThuoc
      , [NGAY_TTOAN] = NULL
      , [T_THUOC] = @Tong_Tien_Thuoc
      , [T_VTYT] = @T_VTYT
      , [T_TONGCHI_BV] = @Tong_Chi
      , [T_TONGCHI_BH] = @T_ThanhTienBH
      , [T_BNTT] = @Tong_Chi - @T_ThanhTienBH
      , [T_BNCCT] = @T_BNCCT
      , [T_BHTT] = @T_BHTT
      , [T_NGUONKHAC] = 0
      , [T_BHTT_GDV] = 0
      , [NAM_QT] = NULL
      , [THANG_QT] = NULL
      , [MA_LOAI_KCB] = CASE WHEN DATEDIFF(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 240 THEN '09'
            WHEN loaiBA.Dictionary_Name_En = N'Nội ngày' THEN '04'
            ELSE '03'
        END
      , [MA_KHOA] = pb.MaTheoQuiDinh
      , [MA_CSKCB] = @MaCSKCB
      , [MA_KHUVUC] = ISNULL(NSS.Dictionary_Code, '')
      , [CAN_NANG] = CAST(COALESCE(
            NULLIF(
                CASE 
                    WHEN ISNUMERIC(REPLACE(bact.CanNang, '.', ',')) = 1 
                    THEN TRY_CAST(REPLACE(bact.CanNang, '.', ',') AS DECIMAL(18,2))
                    ELSE TRY_CAST(bact.CanNang AS DECIMAL(18,2))
                END, 0),
            NULLIF(kbvv.CanNang, 0), 50) AS DECIMAL(18,2))
      , [CAN_NANG_CON] = [dbo].[Get_CanNangCon_ByBenhAn_id](@BenhAn_Id)
      , [NAM_NAM_LIEN_TUC] = NULL
      , [NGAY_TAI_KHAM] = FORMAT(ba.NgayHenTaiKham, 'yyyyMMdd')
      , [MA_HSBA] = @Ma_Lk
      , [MA_TTDV] = '2096091139'
      , [DU_PHONG] = NULL

    FROM BenhAn ba (NOLOCK)
    -- TiepNhan: chỉ join 1 lần (gốc join 3 lần)
    INNER JOIN TiepNhan tn (NOLOCK) ON tn.TiepNhan_Id = ba.TiepNhan_Id

    -- Lấy thông tin lưu trú (khoa cuối cùng)
    OUTER APPLY (
        SELECT TOP 1 lt.PhongBan_Id, lt.ChanDoanRaKhoa
        FROM NoiTru_LuuTru lt (NOLOCK)
        WHERE lt.BenhAn_Id = ba.BenhAn_Id
        ORDER BY lt.LuuTru_Id DESC
    ) lt_last

    LEFT JOIN DM_BenhNhan bn (NOLOCK) ON tn.BenhNhan_Id = bn.BenhNhan_Id
    LEFT JOIN BenhAnChiTiet bact (NOLOCK) ON ba.BenhAn_Id = bact.BenhAn_Id

    -- Dictionary lookups
    LEFT JOIN Lst_Dictionary ketquadieutri (NOLOCK) ON ketquadieutri.Dictionary_Id = ba.KetQuaDieuTri_Id
    LEFT JOIN Lst_Dictionary lydoxuatvien (NOLOCK) ON lydoxuatvien.Dictionary_Id = ba.LyDoXuatVien_Id
    LEFT JOIN Lst_Dictionary loaiBA (NOLOCK) ON loaiBA.Dictionary_Id = ba.LoaiBenhAn_Id
    LEFT JOIN Lst_Dictionary lst (NOLOCK) ON lst.Dictionary_Id = tn.LyDoTiepNhan_Id
    LEFT JOIN Lst_Dictionary TuyenKB (NOLOCK) ON TuyenKB.Dictionary_Id = tn.TuyenKhamBenh_ID
    LEFT JOIN Lst_Dictionary NSS (NOLOCK) ON tn.NoiSinhSong_ID = NSS.Dictionary_Id AND NSS.Dictionary_Type_Code = 'NoiSinhSong'
    LEFT JOIN Lst_Dictionary quoctich (NOLOCK) ON quoctich.Dictionary_Id = bn.QuocTich_Id
    LEFT JOIN Lst_Dictionary dantoc (NOLOCK) ON dantoc.Dictionary_Id = bn.DanToc_Id
    LEFT JOIN Lst_Dictionary nghenghiep (NOLOCK) ON nghenghiep.Dictionary_Id = bn.NgheNghiep_Id
    LEFT JOIN Lst_Dictionary mdt (NOLOCK) ON mdt.Dictionary_Id = tn.MaDoiTuongKCB_Id

    -- PhongBan / BenhVien
    LEFT JOIN DM_PhongBan pb (NOLOCK) ON pb.PhongBan_Id = ba.KhoaRa_Id
    LEFT JOIN DM_DoiTuong dt (NOLOCK) ON dt.DoiTuong_Id = tn.DoiTuong_Id
    LEFT JOIN DM_BenhVien bv (NOLOCK) ON tn.BenhVien_KCB_Id = bv.BenhVien_Id
    LEFT JOIN DM_BenhVien ngt (NOLOCK) ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
    LEFT JOIN DM_BenhVien manoiden (NOLOCK) ON manoiden.BenhVien_Id = ba.ChuyenDenBenhVien_Id AND manoiden.TamNgung = 0

    -- Địa chính
    LEFT JOIN DM_DonViHanhChinh tinh (NOLOCK) ON tinh.DonViHanhChinh_Id = bn.TinhThanh_Id
    LEFT JOIN DM_DonViHanhChinh huyen (NOLOCK) ON huyen.DonViHanhChinh_Id = bn.QuanHuyen_Id
    LEFT JOIN DM_DonViHanhChinh xa (NOLOCK) ON xa.DonViHanhChinh_Id = bn.XaPhuong_Id
    LEFT JOIN DM_DonViHanhChinh tinhmoi (NOLOCK) ON tinhmoi.DonViHanhChinh_Id = bn.TinhThanhMoi_Id
    LEFT JOIN DM_DonViHanhChinh xamoi (NOLOCK) ON xamoi.DonViHanhChinh_Id = bn.XaPhuongMoi_Id

    -- KhamBenh_VaoVien: OUTER APPLY thay correlated subquery
    OUTER APPLY (
        SELECT TOP 1 kbvv.LyDoVaoVien, kbvv.CanNang
        FROM KhamBenh_VaoVien kbvv (NOLOCK)
        WHERE kbvv.TiepNhan_Id = ba.TiepNhan_Id
        ORDER BY kbvv.KhamBenhVaoVien_Id DESC
    ) kbvv

    LEFT JOIN BenhAn_TreCon te (NOLOCK) ON te.BenhAn_Id = ba.BenhAn_Id

    WHERE ba.BenhAn_Id = @BenhAn_Id
) AAAA

SET NOCOUNT OFF
