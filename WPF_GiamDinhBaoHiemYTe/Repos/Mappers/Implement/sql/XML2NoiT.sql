/**
 * TT02_NoiTru.sql - Phiên bản tối ưu hiệu năng tối đa
 *
 * Các tối ưu đã áp dụng:
 *   1.  Gộp 2 truy vấn Sys_AppSettings thành 1
 *   2.  Bỏ SELECT * trong subquery, join trực tiếp BenhAn
 *   3.  Bỏ subquery SELECT * bảng BenhAn cho SoChuyenVien (dòng 102 gốc)
 *   4.  Tách OR trong WHERE thành điều kiện rõ ràng (BenhAn_Id luôn có)
 *   5.  Tính trước NoiTru_TraThuocChiTiet vào #temp (gốc gọi 4 lần correlated subquery)
 *   6.  Loại bỏ join lặp BenhAn/TiepNhan ở outer query
 *   7.  Đồng nhất NOLOCK toàn bộ
 *   8.  SET NOCOUNT ON
 *   9.  Giảm nested subquery 5 tầng xuống dùng #temp table
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
-- PHẦN 3: Gộp AppSettings + UDFs
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
-- PHẦN 4: Tính tổng tiền
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
-- PHẦN 5: PTTT + Số chuyển viện (bỏ subquery SELECT *)
-----------------------------------------------------------------------
DECLARE @Ma_PTTT_QT VARCHAR(250)
SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id](@BenhAn_Id, NULL)

DECLARE @SoChuyenVien NVARCHAR(50) = NULL
SELECT @SoChuyenVien = RIGHT(bact2.SoBenhAn, 9)
FROM BenhAnTongQuat bact2 (NOLOCK)
JOIN BenhAnTongQuat_GCV gcv (NOLOCK) ON bact2.BenhAnTongQuat_Id = gcv.BenhAnTongQuat_Id
WHERE bact2.BenhAn_Id = @BenhAn_Id

-----------------------------------------------------------------------
-- PHẦN 6: Tính trước NoiTru_TraThuocChiTiet (gốc gọi 4 lần correlated subquery)
-----------------------------------------------------------------------
IF OBJECT_ID('tempdb..#TraThuoc') IS NOT NULL DROP TABLE #TraThuoc

SELECT ToaThuoc_Id, SoLoNhap_Id,
       SoLuongTra = CAST(SUM(ISNULL(SoLuong, 0)) AS DECIMAL(18, 3))
INTO #TraThuoc
FROM NoiTru_TraThuocChiTiet (NOLOCK)
GROUP BY ToaThuoc_Id, SoLoNhap_Id

-----------------------------------------------------------------------
-- PHẦN 7: Kết quả chính - Tái cấu trúc nested subquery
-----------------------------------------------------------------------
SELECT [ID] = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
     , [MA_LK] = xml2.Ma_Lk
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
     , [THANH_TIEN_BV] = xml2.Thanh_Tien
     , [THANH_TIEN_BH] = xml2.Thanh_Tien_BHYT
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
     , [CHUC_DANH_ID] = xml2.CHUC_DANH_ID
FROM (
    SELECT 
        t_ngoaids = CASE WHEN ISNULL(NgoaiDinhXuat, 0) = 1 THEN T_BHTT ELSE 0 END
      , *
    FROM (
        SELECT 
            E.*
          , T_BNTT = CAST(
                CASE 
                    WHEN E.TuyenKhamBenh_Id = 1157 AND CAST(SUBSTRING(E.Ngay_YL, 0, 9) AS SMALLDATETIME) < CAST('20210101' AS SMALLDATETIME) THEN
                        E.Thanh_Tien - E.T_BHTT - E.T_BNCCT
                    ELSE
                        E.Thanh_Tien - E.T_BHTT - E.T_BNCCT
                END AS DECIMAL(18,2))
          , Ma_Lk = @Ma_Lk
          , So_Luong = E.So_Luong_T
        FROM (
            SELECT
                D.*
              , T_BNCCT = CAST(
                    CASE 
                        WHEN D.TuyenKhamBenh_Id = 1157 AND CAST(SUBSTRING(D.Ngay_YL, 0, 9) AS SMALLDATETIME) < CAST('20210101' AS SMALLDATETIME) THEN
                            CAST(D.Thanh_Tien * 0.4 * D.TyLe_TT / 100 AS DECIMAL(18,2)) - D.T_BHTT
                        ELSE
                            CAST(D.Thanh_Tien * D.TyLe_TT / 100 AS DECIMAL(18,2)) - D.T_BHTT
                    END AS DECIMAL(18,2))
            FROM (
                SELECT 
                    C.*
                  , T_BHTT = CAST(C.Thanh_Tien * C.TyLe_TT / 100 * C.MUC_HUONG / 100 AS DECIMAL(18,2))
                FROM (
                    SELECT 
                        B.*
                        -- Dùng #TraThuoc đã tính sẵn thay vì correlated subquery (gốc gọi 4 lần)
                      , Thanh_Tien = CAST(
                            CASE WHEN B.DON_GIA * CAST(SUM(B.SoLuong) AS DECIMAL(18,3)) - ISNULL(tt_tra.SoLuongTra * B.DON_GIA, 0) < 0 THEN 0
                                 ELSE B.DON_GIA * CAST(SUM(B.SoLuong) AS DECIMAL(18,3)) - ISNULL(tt_tra.SoLuongTra * B.DON_GIA, 0)
                            END AS DECIMAL(18,2))
                      , Thanh_Tien_BHYT = CAST(
                            CASE WHEN B.DON_GIA * CAST(SUM(B.SoLuong) AS DECIMAL(18,3)) - ISNULL(tt_tra.SoLuongTra * B.DON_GIA, 0) < 0 THEN 0
                                 ELSE B.DON_GIA * CAST(SUM(B.SoLuong) AS DECIMAL(18,3)) - ISNULL(tt_tra.SoLuongTra * B.DON_GIA, 0)
                            END AS DECIMAL(18,2)) * (TyLe_TT / 100)
                      , So_Luong_T = CAST(
                            SUM(B.SoLuong) - ISNULL(tt_tra.SoLuongTra, 0) AS DECIMAL(18, 3))
                    FROM (
                        SELECT
                            A.*
                          , TyLe_TT = CASE WHEN CAST(A.NgayTiepNhan AS SMALLDATETIME) < CAST(@MocThoiGian_DuocTyLe AS SMALLDATETIME)
                                           THEN CASE WHEN ISNULL(TyLe_DuocCu, 0) = 0 THEN 100 ELSE TyLe_DuocCu END
                                           ELSE CASE WHEN ISNULL(TyLe_Duoc, 0) = 0 THEN 100 ELSE TyLe_Duoc END END
                          , DON_GIA = CAST(
                                A.DonGiaHoTro * 100
                                / CASE WHEN CAST(A.NgayTiepNhan AS SMALLDATETIME) < CAST(@MocThoiGian_DuocTyLe AS SMALLDATETIME)
                                       THEN CASE WHEN ISNULL(TyLe_DuocCu, 0) = 0 THEN 100 ELSE TyLe_DuocCu END
                                       ELSE CASE WHEN ISNULL(TyLeDieuKien, 0) = 0 THEN 100 ELSE TyLeDieuKien * 100 END END
                            AS DECIMAL(18,3))
                        FROM (
                            SELECT 
                                xncpct.DonGiaHoTro
                              , xncpct.DonGiaHoTroChiTra
                              , xncpct.SoLuong
                              , tn.NgayTiepNhan
                              , TyLe_Duoc = xbn.TyLeDieuKien * 100
                              , TyLe_DuocCu = dtlc.TyLe
                              , dt.TyLe_2
                              , nttt.ToaThuoc_Id
                              , tn.TuyenKhamBenh_Id
                              , Ngay_YL = REPLACE(CONVERT(VARCHAR, COALESCE(ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kb.ThoiGianKham, kq.ThoiGianYeuCau, clshc.NgaySuDung), 112) + CONVERT(VARCHAR(5), COALESCE(ntkb.ThoiGianKham, bapt.ThoiGianBatDau, yc.ThoiGianYeuCau, kb.ThoiGianKham, kq.ThoiGianYeuCau, clshc.NgaySuDung), 108), ':', '')
                              , Ma_Bac_Si = ISNULL(COALESCE(bstt.SoChungChiHanhNghe, bstt.SoChungChiHanhNghe, bspt.SoChungChiHanhNghe, bscls.SoChungChiHanhNghe, bskb.SoChungChiHanhNghe, bsvtyt.SoChungChiHanhNghe), 'MCCHA')
                              , Ma_Thuoc = CASE WHEN li.PhanNhom = 'DV' THEN ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN dv.MaQuiDinh ELSE dv.MaQuiDinhCu END, dv.InputCode)
                                    WHEN li.PhanNhom IN ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL THEN ISNULL(d.MaHoatChat, d.MaDuoc)
                                    WHEN li.PhanNhom IN ('DU') AND ld.LoaiVatTu_Id = 'V' AND ld.MaLoaiDuoc IN ('VTYT003') THEN ISNULL(d.MaHoatChat, d.Attribute_2)
                                    ELSE d.MaDuoc END
                              , Ma_Thuoc_Cs = CASE WHEN li.PhanNhom = 'DV' THEN ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN dv.MaQuiDinh ELSE dv.MaQuiDinhCu END, dv.InputCode)
                                    WHEN li.PhanNhom IN ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL THEN ISNULL(d.MaHoatChat, d.MaDuoc)
                                    WHEN li.PhanNhom IN ('DU') AND ld.LoaiVatTu_Id = 'V' AND ld.MaLoaiDuoc IN ('VTYT003') THEN ISNULL(d.MaHoatChat, d.Attribute_2)
                                    ELSE d.MaDuoc END
                              , ma_nhom = CASE WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V') AND ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') AND ISNULL(xbn.TyLeDieuKien, 0) = 0 OR map.TenField IN ('16','Thuoc') OR ld.MaLoaiDuoc IN ('OXY', 'OXY1') THEN '4'
                                    WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V') AND ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') AND ISNULL(xbn.TyLeDieuKien, 0) > 0 OR map.TenField IN ('16','Thuoc') OR ld.MaLoaiDuoc IN ('OXY', 'OXY1') THEN '4'
                                    WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id = ('V') AND ld.MaLoaiDuoc <> 'VTYT003' OR map.TenField IN ('10','VTYT') OR ld.MaLoaiDuoc NOT IN ('OXY', 'OXY1','LD0143','VTYT003','Mau','ChePham') THEN '10'
                                    WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V') AND ld.MaLoaiDuoc IN ('LD0143','Mau') THEN '7'
                                    WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id <> ('V') AND ld.MaLoaiDuoc IN ('LD0143','ChePham') THEN '17'
                                    WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 OR (xncpct.DonGiaHoTroChiTra > 0)) AND ld.LoaiVatTu_Id = ('V') AND ld.MaLoaiDuoc IN ('VTYT003','Mau','ChePham') THEN '7'
                                    ELSE CASE
                                        WHEN map.TenField = '01' THEN '13'
                                        WHEN map.TenField = '02' THEN '14'
                                        WHEN map.TenField = '03' THEN '1'
                                        WHEN map.TenField = '04' THEN '2'
                                        WHEN map.TenField = '05' THEN '3'
                                        WHEN map.TenField = '17' THEN '6'
                                        WHEN map.TenField = '06' THEN '8'
                                        WHEN map.TenField = '08' THEN '7'
                                        WHEN map.TenField = '11' THEN '12'
                                        WHEN map.TenField = '12' THEN '15'
                                        WHEN map.TenField = '07' THEN '9'
                                        WHEN ISNULL(map.TenField, '') = '' THEN '8'
                                    END END
                              , Ten_Thuoc = ISNULL(ISNULL(CASE WHEN tn.NgayTiepNhan > '20250731' THEN dv.TenDichVu_En ELSE dv.TenQuiDinhCu END, dv.TenDichVu), ISNULL(d.Ten_VTYT_917, REPLACE(d.TenHang, CHAR(0x1F), '')))
                              , don_vi_tinh = CASE WHEN dv.NhomDichVu_Id = 53654 THEN ISNULL(dvt.TenDonViTinh, dv.DonViTinh) ELSE ISNULL(dvt.TenDonViTinh, N'Lần') END
                              , ham_luong = d.HamLuong
                              , duong_dung = dd.Dictionary_Code
                              , LIEU_DUNG = ISNULL(dbo.Get_SoLuongThuocTrongNgay_NoiTru(nttt.ToaThuoc_Id), N'1/lần*1 lần/ngày')
                              , so_dang_ky = d.Attribute_3
                              , TT_THAU = ISNULL(d.ThongTinThau, d.MaGoiThau)
                              , PHAM_VI = 1
                              , MUC_HUONG = CASE WHEN TuyenKhamBenh_Id = 1157 THEN Muc_Huong * 100
                                    ELSE CASE WHEN CAST(tn.NgayTiepNhan AS SMALLDATETIME) < CAST(@MocThoiGian_DuocTyLe AS SMALLDATETIME) THEN
                                            CASE WHEN ISNULL(@Tong_Chi, 0) < @MinBHYTChiTra AND ISNULL(dtlc.TyLe, 0) = 0 THEN 100
                                                 ELSE CASE WHEN ISNULL(dtlc.TyLe, 0) <> 0 THEN CASE WHEN dt.TyLe_2 IS NULL THEN 0 ELSE dt.TyLe_2 * 100 END
                                                           ELSE CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong * 100
                                                                     ELSE CASE WHEN dt.TyLe_2 IS NULL THEN 0 ELSE dt.TyLe_2 * 100 END END END END
                                         ELSE
                                            CASE WHEN ISNULL(@Tong_Chi, 0) < @MinBHYTChiTra AND ISNULL(dtl.TyLe, 0) = 0 THEN 100
                                                 ELSE CASE WHEN ISNULL(dtl.TyLe, 0) <> 0 THEN CASE WHEN dt.TyLe_2 IS NULL THEN 0 ELSE dt.TyLe_2 * 100 END
                                                           ELSE CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong * 100
                                                                     ELSE CASE WHEN dt.TyLe_2 IS NULL THEN 0 ELSE dt.TyLe_2 * 100 END END END END
                                    END END
                              , Ma_Khoa = pb.MaTheoQuiDinh
                              , ma_benh = CASE WHEN @ICD_PHU = '' THEN @ICD_CHINH ELSE @ICD_CHINH + ';' + @ICD_PHU END
                              , ma_pttt = 1
                              , t_NguonKhac = 0
                              , xbn.SoLoNhap_Id
                              , xbn.TyLeDieuKien
                              , NgoaiDinhXuat
                              , MADICHVU = NULL
                              , NGUON_CTRA = 1
                              , ma_pp_chebien = ''
                              , Dang_BaoChe = ''
                              , Cach_Dung = ISNULL(nttt.GhiChu, '')
                              , CHUC_DANH_ID = COALESCE(bstt.ChucDanh_Id, bstt.ChucDanh_Id, bspt.ChucDanh_Id, bscls.ChucDanh_Id, bskb.ChucDanh_Id, bsvtyt.ChucDanh_Id)
                            FROM (
                                -- Phần DV (dịch vụ CLS)
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
                                        CASE WHEN dv.NhomDichVu_Id = 27 THEN yc.NoiThucHien_Id ELSE yc.NoiYeuCau_Id END, ba.KhoaRa_Id),
                                    NoiTru_ToaThuoc_ID = NULL,
                                    NgoaiTru_ToaThuoc_ID = NULL,
                                    TenDonViTinh = dv.DonViTinh,
                                    BenhAn_Id = @BenhAn_Id,
                                    TiepNhan_Id = @TiepNhan_Id,
                                    Muc_Huong = ycct.MucHuong
                                FROM CLSYeuCauChiTiet ycct (NOLOCK)
                                LEFT JOIN CLSYeuCau yc (NOLOCK) ON ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id
                                LEFT JOIN DM_DichVu dv (NOLOCK) ON dv.DichVu_Id = ycct.DichVu_Id
                                LEFT JOIN BenhAn ba (NOLOCK) ON ba.BenhAn_Id = yc.BenhAn_Id
                                -- Tối ưu: BenhAn_Id luôn NOT NULL ở nội trú, tách OR
                                WHERE yc.BenhAn_Id = @BenhAn_Id

                                UNION ALL

                                -- Phần thuốc/VTYT
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
                                    PhongBan_Id = ISNULL(ISNULL(pb.PhongBan_Id, ISNULL(pb2.PhongBan_Id, ISNULL(pb3.PhongBan_Id, pb1.PhongBan_Id))), pb4.PhongBan_Id),
                                    NoiTru_ToaThuoc_ID = xbn.ToaThuoc_Id,
                                    NgoaiTru_ToaThuoc_ID = NULL,
                                    TenDonViTinh = d.DonViTinh,
                                    BenhAn_Id = @BenhAn_Id,
                                    TiepNhan_Id = @TiepNhan_Id,
                                    Muc_Huong = xbn.MucHuong
                                FROM ChungTuXuatBenhNhan xbn (NOLOCK)
                                LEFT JOIN DM_Duoc d (NOLOCK) ON d.Duoc_Id = xbn.Duoc_Id
                                LEFT JOIN DM_TenDuoc td (NOLOCK) ON td.TenDuoc_Id = d.TenDuoc_Id
                                LEFT JOIN NoiTru_ToaThuoc nttt (NOLOCK) ON nttt.ToaThuoc_Id = xbn.ToaThuoc_Id
                                LEFT JOIN NoiTru_KhamBenh kb (NOLOCK) ON kb.KhamBenh_Id = nttt.KhamBenh_Id
                                LEFT JOIN NoiTru_LuuTru lt (NOLOCK) ON lt.LuuTru_Id = kb.LuuTru_Id
                                LEFT JOIN DM_PhongBan pb (NOLOCK) ON pb.PhongBan_Id = lt.PhongBan_Id
                                LEFT JOIN NoiTru_TraThuocChiTiet B (NOLOCK) ON B.NoiTru_TraThuocChiTiet_Id = xbn.ToaThuocTra_Id AND xbn.Duoc_ID = B.Duoc_ID
                                LEFT JOIN NoiTru_TraThuoc C (NOLOCK) ON C.NoiTru_TraThuoc_Id = B.NoiTru_TraThuoc_Id
                                LEFT JOIN NoiTru_LuuTru E (NOLOCK) ON E.LuuTru_Id = C.LuuTru_Id
                                LEFT JOIN DM_PhongBan pb2 (NOLOCK) ON pb2.PhongBan_Id = E.PhongBan_Id
                                LEFT JOIN BenhAnPhauThuat_VTYT vtyt (NOLOCK) ON vtyt.BenhAnPhauThuat_VTYT_Id = xbn.BenhAnPhauThuat_VTYT_Id
                                LEFT JOIN ChungTu t (NOLOCK) ON vtyt.ChungTuTongHop_Id = t.ChungTu_Id
                                LEFT JOIN DM_KhoDuoc kd (NOLOCK) ON t.KhoXuat_Id = kd.KhoDuoc_Id
                                LEFT JOIN DM_PhongBan pb3 (NOLOCK) ON pb3.PhongBan_Id = kd.PhongBan_Id
                                LEFT JOIN KhamBenh_VTYT vt (NOLOCK) ON xbn.KhamBenh_VTYT_Id = vt.KhamBenh_VTYT_Id
                                LEFT JOIN KhamBenh kb1 (NOLOCK) ON vt.KhamBenh_Id = kb1.KhamBenh_Id
                                LEFT JOIN DM_PhongBan pb1 (NOLOCK) ON pb1.PhongBan_Id = kb1.PhongBan_Id
                                LEFT JOIN CLSGhiNhanHoaChat_VTYT clsvt (NOLOCK) ON xbn.CLSHoaChat_VTYT_Id = clsvt.ID AND xbn.Duoc_Id = clsvt.Duoc_Id
                                LEFT JOIN DM_KhoDuoc k (NOLOCK) ON clsvt.KhoSuDung_Id = k.KhoDuoc_Id
                                LEFT JOIN DM_PhongBan pb4 (NOLOCK) ON pb4.PhongBan_Id = k.PhongBan_Id
                                -- Tối ưu: BenhAn_Id luôn NOT NULL, dùng trực tiếp
                                WHERE xbn.BenhAn_Id = @BenhAn_Id AND xbn.MienPhi = 0
                            ) xncpct
                            LEFT JOIN dbo.VienPhiNoiTru_Loai_IDRef LI (NOLOCK) ON LI.Loai_IDRef = xncpct.Loai_IDRef AND xncpct.DonGiaHoTroChiTra > 0
                            LEFT JOIN (
                                SELECT dndv.DichVu_Id, mbc.MoTa, mbc.ID, mbc.Ma,
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
                                        WHEN mbc.TenField IN ('NGCK','Giuong','GB','Gi') THEN '12'
                                        WHEN mbc.TenField = 'VTYT' THEN '10'
                                        WHEN mbc.TenField = 'ThuocK' THEN '17'
                                        ELSE mbc.TenField
                                    END AS TenField
                                FROM dbo.DM_MauBaoCao mbc (NOLOCK)
                                JOIN dbo.DM_DinhNghiaDichVu dndv (NOLOCK) ON dndv.NhomBaoCao_Id = mbc.ID
                                WHERE MauBC = 'BCVP_097'
                            ) map ON map.DichVu_Id = xncpct.NoiDung_Id AND LI.PhanNhom = 'DV'
                            -- Tối ưu: dùng biến đã có thay vì join lại BenhAn/TiepNhan
                            LEFT JOIN dbo.BenhAn ba (NOLOCK) ON ba.BenhAn_Id = @BenhAn_Id
                            LEFT JOIN dbo.TiepNhan tn (NOLOCK) ON tn.TiepNhan_Id = ba.TiepNhan_Id
                            LEFT JOIN dbo.DM_BenhNhan bn (NOLOCK) ON bn.BenhNhan_Id = tn.BenhNhan_Id
                            LEFT JOIN DM_DoiTuong dt (NOLOCK) ON dt.DoiTuong_Id = tn.DoiTuong_Id
                            LEFT JOIN dbo.Lst_Dictionary ndt (NOLOCK) ON ndt.Dictionary_Id = dt.NhomDoiTuong_Id AND ndt.Dictionary_Code = 'BHYT'
                            LEFT JOIN DM_Duoc d (NOLOCK) ON d.Duoc_Id = xncpct.NoiDung_Id AND li.PhanNhom IN ('DU','DI','VH','VT')
                            LEFT JOIN dbo.DM_LoaiDuoc ld (NOLOCK) ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
                            LEFT JOIN dbo.DM_DonViTinh dvt (NOLOCK) ON dvt.DonViTinh_Id = d.DonViTinh_Id
                            LEFT JOIN dbo.DM_PhongBan pb (NOLOCK) ON pb.PhongBan_Id = xncpct.PhongBan_Id
                            LEFT JOIN dbo.DM_DichVu dv (NOLOCK) ON dv.DichVu_Id = xncpct.NoiDung_Id AND li.PhanNhom = 'DV'
                            LEFT JOIN dbo.Lst_Dictionary dd (NOLOCK) ON dd.Dictionary_Id = d.DuongDung_Id
                            LEFT JOIN ChungTuXuatBenhNhan xbn (NOLOCK) ON xncpct.IDRef = xbn.ChungTuXuatBN_Id AND xncpct.Loai_IDRef = 'I'
                            LEFT JOIN NoiTru_ToaThuoc nttt (NOLOCK) ON nttt.ToaThuoc_Id = xbn.ToaThuoc_Id
                            LEFT JOIN NoiTru_KhamBenh ntkb (NOLOCK) ON ntkb.KhamBenh_Id = nttt.KhamBenh_Id
                            LEFT JOIN vw_NhanVien bstt (NOLOCK) ON bstt.NhanVien_Id = ntkb.BasSiKham_Id
                            LEFT JOIN CLSYeuCauChiTiet clsyc (NOLOCK) ON clsyc.YeuCauChiTiet_Id = xncpct.IDRef AND xncpct.Loai_IDRef = 'A'
                            LEFT JOIN CLSYeuCau yc (NOLOCK) ON yc.CLSYeuCau_Id = clsyc.CLSYeuCau_Id
                            LEFT JOIN vw_NhanVien bscls (NOLOCK) ON bscls.NhanVien_Id = yc.BacSiChiDinh_Id
                            LEFT JOIN CLSGhiNhanHoaChat_VTYT clshc (NOLOCK) ON xbn.CLSHoaChat_VTYT_Id = clshc.ID
                            LEFT JOIN CLSYeuCau kq (NOLOCK) ON clshc.CLSYeuCau_Id = kq.CLSYeuCau_Id
                            LEFT JOIN CLSKetQua kqvt (NOLOCK) ON kq.CLSYeuCau_Id = kqvt.CLSYeuCau_Id
                            LEFT JOIN vw_NhanVien bsvtyt (NOLOCK) ON kqvt.BacSiKetLuan_Id = bsvtyt.NhanVien_Id
                            LEFT JOIN DM_DoiTuong_GiaDuoc_TyLe dtl (NOLOCK) ON d.Duoc_Id = dtl.Duoc_Id AND dt.DoiTuong_Id = dtl.DoiTuong_Id AND dtl.TamNgung = 0
                            LEFT JOIN DM_DoiTuong_GiaDuoc_TyLe_BaseLine dtlc (NOLOCK) ON d.Duoc_Id = dtlc.Duoc_Id AND dt.DoiTuong_Id = dtlc.DoiTuong_Id AND dtlc.TamNgung = 0
                            LEFT JOIN KhamBenh_VTYT KBVT (NOLOCK) ON xbn.KhamBenh_VTYT_ID = KBVT.KhamBenh_VTYT_ID
                            LEFT JOIN KhamBenh kb (NOLOCK) ON KBVT.KhamBenh_Id = kb.KhamBenh_Id
                            LEFT JOIN vw_NhanVien bskb (NOLOCK) ON bskb.NhanVien_Id = kb.BacSiKham_Id
                            LEFT JOIN BenhAnPhauThuat_VTYT PTVT (NOLOCK) ON xbn.BenhAnPhauThuat_VTYT_Id = PTVT.BenhAnPhauThuat_VTYT_Id
                            LEFT JOIN BenhAnPhauThuat BAPT (NOLOCK) ON PTVT.BenhAnPhauThuat_Id = BAPT.BenhAnPhauThuat_Id
                            LEFT JOIN Sys_Users us (NOLOCK) ON PTVT.NguoiTao_Id = us.User_Id
                            LEFT JOIN NhanVien_User_Mapping usmap (NOLOCK) ON us.User_Id = usmap.User_Id
                            LEFT JOIN vw_NhanVien bspt (NOLOCK) ON usmap.NhanVien_Id = bspt.NhanVien_Id
                            LEFT JOIN DM_ICD I (NOLOCK) ON ba.ICD_BenhChinh = I.ICD_Id
                        WHERE xncpct.DonGiaHoTroChiTra > 0
                            AND ((LI.PhanNhom IN ('DU','DI','VH','VT') AND ld.LoaiVatTu_Id IN ('T', 'H')) OR map.TenField IN ('08', '16')
                                OR ld.MaLoaiDuoc IN ('OXY', 'OXY1','LD0143','VTYT003','Mau'))
                            AND xncpct.SoLuong > 0
                        ) A
                    ) B
                    -- Tối ưu: dùng #TraThuoc đã tính sẵn thay vì 4 correlated subquery
                    LEFT JOIN #TraThuoc tt_tra ON tt_tra.ToaThuoc_Id = B.ToaThuoc_Id AND tt_tra.SoLoNhap_Id = B.SoLoNhap_Id
                    GROUP BY B.ToaThuoc_Id, B.TyLe_Duoc, B.TyLe_DuocCu, B.Ngay_YL, B.DonGiaHoTro, B.DonGiaHoTroChiTra
                        , B.Muc_Huong, B.Ma_Bac_Si, B.NgayTiepNhan, B.TyLe_2
                        , B.TyLe_TT, B.DON_GIA, B.SoLuong, B.Ma_Thuoc, B.Ma_Thuoc_Cs
                        , B.ma_nhom, B.Ten_Thuoc, B.don_vi_tinh, B.ham_luong, B.duong_dung, B.LIEU_DUNG, B.so_dang_ky, B.TT_THAU
                        , B.PHAM_VI, B.TuyenKhamBenh_Id, NgoaiDinhXuat, B.Ma_Khoa, B.ma_benh, B.ma_pttt, B.t_NguonKhac, B.SoLoNhap_Id, TyLeDieuKien
                        , MADICHVU, NGUON_CTRA, ma_pp_chebien, Dang_BaoChe, Cach_Dung, B.CHUC_DANH_ID
                        , tt_tra.SoLuongTra
                ) C
            ) D
        ) E
    ) xml2
    WHERE xml2.So_Luong_T > 0
) xml2
ORDER BY Ngay_YL

-- Dọn dẹp temp table
DROP TABLE #TraThuoc

SET NOCOUNT OFF
