
DECLARE @Sobenhan NVARCHAR(20) = N'{IDBenhNhan}'
DECLARE @benhan_id NVARCHAR(20)
SELECT	@BenhAn_Id = ba.BenhAn_Id
FROM	dbo.BenhAn ba (nolock) 
INNER jOIN XacNhanChiPhi (nolock)   xn on xn.xacnhanchiphi_id=ba.xacnhanchiphi_id
WHERE	ba.SoBenhAn = @SoBenhAn 


declare @Ma_Lk varchar (20) = null
DECLARE @TiepNhan_Id int
DECLARE @ChanDoan_RV NVARCHAR(2000)
DECLARE @ICD_CHINH NVARCHAR(2000)
DECLARE @ICD_CHINH_YHCT NVARCHAR(2000)
DECLARE @ChanDoan NVARCHAR(2000)
SELECT	@ChanDoan = isnull(ba.ChanDoanVaoKhoa, isnull(icd.TenICD, isnull( cc.ChanDoanNhapVien,icd_cc.TenICD) ) )
			
			, @ICD_CHINH = icd.MaICD
			, @ICD_CHINH_YHCT = icd.MaICD_YHCT
			, @ChanDoan_RV = isnull(ba.ChanDoanRaVien,icd.TenICD)+ ', ' + isnull(isnull(ba.chandoanphuravien,icd_k.tenicd),'')
			, @SoBenhAn = ba.SoBenhAn
			, @Ma_Lk =  REPLACE(ba.SoBenhAn,'/','_')
			, @TiepNhan_Id = ba.TiepNhan_Id
	FROM	(
				SELECT	*
				FROM	dbo.BenhAn
				WHERE	BenhAn_Id = @BenhAn_Id
			) ba
	INNER JOIN TiepNhan tn  (nolock)  ON ba.TiepNhan_ID= tn.TiepNhan_ID
	LEFT JOIN	DM_ICD icd  (nolock) ON icd.ICD_Id =ba.ICD_BenhChinh
	left join ThongTinCapCuu cc (nolock)  on ba.BenhAn_ID = cc.BenhAn_Id 
	left join DM_ICD icd_cc (nolock)  on isnull(cc.ICD_BenhChinh, cc.ICD_BenhPhu) = icd_cc.ICD_Id
	LEFT JOIN DM_ICD icd_k (nolock)  ON ba.ICD_BenhPhu  = icd_k.ICD_Id
	
	DECLARE @MaCSKCB  NVARCHAR(2000)
	
	DECLARE @Ma_TheBHYT VARCHAR(500)
	
	DECLARE @ICD NVARCHAR(2000)
	DECLARE @ICD_Khac NVARCHAR(2000)


	DECLARE @ICD_PHU NVARCHAR(2000)
	DECLARE @ICD_PHU_YHCT NVARCHAR(2000)
	
	DECLARE	@NGAY_VAO DATETIME
	DECLARE	@NGAY_RA DATETIME
	DECLARE @TT_01_TONGHOP_ID int = null
	
	
	select @MaCSKCB=Value 
	from Sys_AppSettings  where Code = N'MaBenhVien_BHYT'
	-- Dùng ?? test
	--SET @MaCSKCB = '80005'
	Declare @MocThoiGian_DuocTyLe varchar(10) = '20190101'

	Declare @MinBHYTChiTra decimal(18,2) = 208500.00
	SELECT @MinBHYTChiTra = VALUE from sys_appsettings where code = 'LuongToiThieu'
	SET @ICD_PHU = [dbo].[Get_MaICD_Phu_ByBenhAn_Id] (@BenhAn_Id,'M')
	SET @ICD_PHU_YHCT = [dbo].[Get_MaICDYHCT_Phu_ByBenhAn_Id_YHCT] (@BenhAn_Id ,'Y3')
	SET @MocThoiGian_DuocTyLe = dbo.sp_SysGetAppSettingValue('BHYT_NgayTiepNhan_DuocTyLe','VI')

		
	
	

-- TUvq2 Tinh TOng Tien Thuoc
Declare @Tong_Tien_Thuoc Decimal(18, 2) = 0
Declare @T_BHTT decimal(18,2) = 0
Declare @Tong_Chi decimal(18,2) = 0
--Declare @Thanh_Tien decimal(18,2) = 0
Declare @T_BNCCT decimal(18,2) = 0
Declare @T_BNTT decimal(18,2) = 0
Declare @T_VTYT Decimal(18,2) = 0
Declare @T_KTC Decimal(18,2) = 0
declare @T_ThanhTienBH decimal(18,2) = 0
Declare @MocThoiGian_BHYT varchar(10) = '20180715'


SELECT 
	@Tong_Chi = T_TongChi,
	@T_BHTT = T_BHTT,
	@T_BNCCT = T_BNCCT,
	@T_BNTT = T_BNTT,
	@Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
	@T_VTYT = T_Tong_Tien_VTYT,
	@T_KTC = T_Tong_Tien_KTC,
	@T_ThanhTienBH  = T_ThanhTienBH 
FROM dbo.Tong_Tien_XML_BangKe02_130 (@BenhAn_Id)

DECLARE @Ma_PTTT_QT varchar(250)
SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id] (@BenhAn_Id, NULL)



DECLARE @SoChuyenVien nvarchar (50) = null
SELECT		
			@SoChuyenVien = right (BenhAnTongQuat.SoBenhAn,9)--tùy ch?nh theo d? án
			--GIAY_CHUYEN_TUYEN = left (BenhAnTongQuat.SoBenhAn,6),--tùy ch?nh theo d? án
	FROM (select * from BenhAn where BenhAn.BenhAn_Id = @BenhAn_Id and XacNhanChiPhi_Id is not null) BenhAn
	JOIN BenhAnTongQuat (nolock)   ON BenhAnTongQuat.BenhAn_Id = BenhAn.BenhAn_Id
	JOIN BenhAnTongQuat_GCV (nolock)   ON BenhAnTongQuat.BenhAnTongQuat_Id = BenhAnTongQuat_GCV.BenhAnTongQuat_Id




SELECT  [Id] = row_number () OVER (ORDER BY (SELECT 1))
		,[MA_LK] = xml2.Ma_Lk
      ,[STT] = row_number () OVER (ORDER BY (SELECT 1))
      ,[MA_THUOC] = xml2.Ma_Thuoc
      ,[MA_PP_CHEBIEN] = xml2.ma_pp_chebien
      ,[MA_CSKCB_THUOC] = null
      ,[MA_NHOM] = xml2.ma_nhom
      ,[TEN_THUOC] = xml2.Ten_Thuoc
      ,[DON_VI_TINH] = xml2.don_vi_tinh
      ,[HAM_LUONG] = xml2.ham_luong
      ,[DUONG_DUNG] = xml2.duong_dung
      ,[DANG_BAO_CHE] = XML2.Dang_BaoChe
      ,[LIEU_DUNG] = xml2.LIEU_DUNG
      ,[CACH_DUNG] = xml2.Cach_Dung
      ,[SO_DANG_KY] = xml2.so_dang_ky
      ,[TT_THAU] = xml2.TT_THAU
      ,[PHAM_VI] = xml2.PHAM_VI
      ,[TYLE_TT_BH] = xml2.TyLe_TT
      ,[SO_LUONG] = xml2.So_Luong
      ,[DON_GIA] = xml2.DON_GIA
      ,[THANH_TIEN_BV] = xml2.Thanh_Tien
      ,[THANH_TIEN_BH] = xml2.Thanh_Tien_BHYT
      ,[T_NGUONKHAC_NSNN] = 0
      ,[T_NGUONKHAC_VTNN] = 0
      ,[T_NGUONKHAC_VTTN] = 0
      ,[T_NGUONKHAC_CL] = 0
      ,[T_NGUONKHAC] = xml2.T_NguonKhac
      ,[MUC_HUONG] = xml2.MUC_HUONG
      ,[T_BNTT] = xml2.T_BNTT
      ,[T_BNCCT] = xml2.T_BNCCT
      ,[T_BHTT] = xml2.T_BHTT
      ,[MA_KHOA] = xml2.Ma_Khoa
      ,[MA_BAC_SI] = xml2.Ma_Bac_Si
      ,[MA_DICH_VU] = xml2.MADICHVU
      ,[NGAY_YL] = xml2.Ngay_YL
      ,[MA_PTTT] = xml2.ma_pttt
      ,[NGUON_CTRA] = XML2.NGUON_CTRA
      ,[VET_THUONG_TP] = null
      ,[DU_PHONG] = null
	  ,[CHUC_DANH_ID] = xml2.CHUC_DANH_ID
	FROM (
	SELECT 
		 t_ngoaids= case when isnull(ngoaidinhxuat,0)=1 then T_BHTT else 0 end 
		, *
	FROM (
		SELECT 
			E.*
			, T_BNTT = CAST(
							CASE 
								WHEN E.TuyenKhamBenh_Id = 1157 And CAST(SUBSTRING(E.Ngay_YL, 0, 9) as smalldatetime) < CAST('20210101' as smalldatetime)    THEN
									
									E.Thanh_Tien
									-
									E.T_BHTT
									-
									E.T_BNCCT
							ELSE
								E.Thanh_Tien
								- 
								E.T_BHTT
								-
								E.T_BNCCT
								
							END
						as decimal(18,2))
			, Ma_Lk = @Ma_Lk
			, So_Luong = E.So_Luong_T
		FROM (
			SELECT
				D.*
				, T_BNCCT = CAST(
								CASE 
									WHEN D.TuyenKhamBenh_Id = 1157 And CAST(SUBSTRING(D.Ngay_YL, 0, 9) as smalldatetime) < CAST('20210101' as smalldatetime)  THEN
										CAST(D.Thanh_Tien * 0.4 * D.TyLe_TT / 100 as decimal(18,2))
											-
											D.T_BHTT
										--END
								ELSE
									CAST(D.Thanh_Tien * D.TyLe_TT/ 100 as decimal(18,2))
									- 
									D.T_BHTT
								
								END 
							as decimal(18,2))
			FROM
			(
				SELECT 
					C.*
					, T_BHTT = CAST(C.Thanh_Tien * C.TyLe_TT/100 * C.MUC_HUONG / 100 as decimal(18,2))
				FROM (
					SELECT 
						B.*
						, Thanh_Tien = CAST(
											CASE WHEN B.DON_GIA*CAST(SUM(B.SoLuong) as decimal(18,3)) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = B.ToaThuoc_Id and SoLoNhap_Id = B.SoLoNhap_Id ) * B.DON_GIA), 0) < 0 THEN 0--and SoLoNhap_Id = B.SoLoNhap_Id
											ELSE 
												B.DON_GIA*CAST(SUM(B.SoLuong) as decimal(18,3)) 
												- ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = B.ToaThuoc_Id and SoLoNhap_Id = B.SoLoNhap_Id ) * B.DON_GIA), 0) --and SoLoNhap_Id = B.SoLoNhap_Id
											END
										as decimal(18,2))
						, Thanh_Tien_BHYT = CAST(
											CASE WHEN B.DON_GIA*CAST(SUM(B.SoLuong) as decimal(18,3)) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = B.ToaThuoc_Id and SoLoNhap_Id = B.SoLoNhap_Id ) * B.DON_GIA), 0) < 0 THEN 0--and SoLoNhap_Id = B.SoLoNhap_Id
											ELSE 
												B.DON_GIA*CAST(SUM(B.SoLuong) as decimal(18,3)) 
												- ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = B.ToaThuoc_Id and SoLoNhap_Id = B.SoLoNhap_Id ) * B.DON_GIA), 0) --and SoLoNhap_Id = B.SoLoNhap_Id
											END
											
										as decimal(18,2)) * (TyLe_TT/100)
						, So_Luong_T = CAST(
											SUM(B.SoLuong)  
											- 
											isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = B.ToaThuoc_Id and SoLoNhap_Id = B.SoLoNhap_Id),0) --and SoLoNhap_Id = B.SoLoNhap_Id
										as Decimal(18, 3))
					FROM (
						SELECT
							A.*			
							, TyLe_TT = CASE WHEN CAST(A.NgayTiepNhan as smalldatetime) < CAST(@MocThoiGian_DuocTyLe as smalldatetime)
												THEN CASE WHEN ISNULL(TyLe_DuocCu,0) = 0 THEN 100 ELSE TyLe_DuocCu END
										ELSE CASE WHEN ISNULL(TyLe_Duoc,0) = 0 THEN 100 ELSE TyLe_Duoc END END
							, DON_GIA = CAST(
											A.DonGiaHoTro*100
										/
											CASE WHEN CAST(A.NgayTiepNhan as smalldatetime) < CAST(@MocThoiGian_DuocTyLe as smalldatetime)
													THEN CASE WHEN ISNULL(TyLe_DuocCu,0) = 0 THEN 100 ELSE TyLe_DuocCu END
											ELSE CASE WHEN ISNULL(TyLeDieuKien,0) = 0 THEN 100 ELSE TyLeDieuKien*100 END END
										as decimal(18,3))
						FROM (
							SELECT 
								xncpct.DonGiaHoTro
								, xncpct.DonGiaHoTroChiTra
								, xncpct.SoLuong
								, tn.NgayTiepNhan
								, TyLe_Duoc = xbn.TyLeDieuKien*100
								, TyLe_DuocCu = dtlc.TyLe
								, dt.TyLe_2
								, nttt.ToaThuoc_Id
								, tn.TuyenKhamBenh_Id
								, Ngay_YL = replace(convert(varchar , COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kq.ThoiGianYeuCau,clshc.ngaysudung), 112)+convert(varchar(5), COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kq.ThoiGianYeuCau,clshc.ngaysudung), 108), ':','')  
								, Ma_Bac_Si = isnull(COALESCE(bstt.SoChungChiHanhNghe,bstt.SoChungChiHanhNghe,bspt.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe,bskb.SoChungChiHanhNghe,bsvtyt.SoChungChiHanhNghe),'MCCHA')
								--, Ma_Lk = @Ma_Lk			
								, Ma_Thuoc = case when li.PhanNhom = 'DV' then  ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode)
														when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL then 
														ISNULL(d.MaHoatChat, d.MaDuoc)
														WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') THEN
															ISNULL(d.MaHoatChat, d.Attribute_2)
														else d.MaDuoc
														 end
								, Ma_Thuoc_Cs = case when li.PhanNhom = 'DV' then ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode)
														when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL then 
														ISNULL(d.MaHoatChat, d.MaDuoc)
														WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') THEN
															ISNULL(d.MaHoatChat, d.Attribute_2)
														else d.MaDuoc
														 end
			
								, ma_nhom = CASE WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') and ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') And ISNULL(xbn.TyLeDieuKien,0) = 0 OR  map.TenField in ('16','Thuoc') or ld.MaLoaiDuoc in ('OXY', 'OXY1')  THEN '4'
												WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') and ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') And ISNULL(xbn.TyLeDieuKien,0) > 0 OR  map.TenField in ('16','Thuoc') or ld.MaLoaiDuoc in ('OXY', 'OXY1')THEN '4'  --- sua thuoc cu 6
												WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') And ld.MaLoaiDuoc <> 'VTYT003'	 OR  map.TenField in ('10','VTYT') or ld.MaLoaiDuoc not in ('OXY', 'OXY1','LD0143','VTYT003','Mau','ChePham') THEN '10' 
												WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') And ld.MaLoaiDuoc in ('LD0143','Mau') THEN '7'
												WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') And ld.MaLoaiDuoc in ('LD0143','ChePham') THEN '17'
												WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') And ld.MaLoaiDuoc in ('VTYT003','Mau','ChePham') THEN '7'
											ELSE 
												CASE
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
												END
											END
								, Ten_Thuoc = ISNULL(ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,DV.TenDichVu), ISNULL(d.Ten_VTYT_917, REPLACE(D.TenHang, CHAR(0x1F), '')))  -- Ten_Thuoc
								--, don_vi_tinh = isnull(dvt.TenDonViTinh,N'L?n') 
								, don_vi_tinh =
								case when dv.NhomDichVu_Id = 53654 then isnull(dvt.TenDonViTinh,dv.DonViTinh)
								else isnull(dvt.TenDonViTinh,N'Lần')
								end
								, ham_luong = d.HamLuong
								, duong_dung = dd.Dictionary_Code		
								, LIEU_DUNG = isnull(dbo.Get_SoLuongThuocTrongNgay_NoiTru(nttt.toathuoc_id),N'1/lần*1 lần/ngày') -- N'1/l?n*1 l?n/ngày'	
								, so_dang_ky = d.Attribute_3
								, TT_THAU = isnull(d.ThongTinThau,d.MaGoiThau)											-- TT_THAU
								, PHAM_VI = 1
								, MUC_HUONG =  case when TuyenKhamBenh_Id=1157 then Muc_Huong*100
									else
									CASE WHEN CAST(tn.NgayTiepNhan as smalldatetime) < CAST(@MocThoiGian_DuocTyLe as smalldatetime) 
														THEN
															CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra And ISNULL(dtlc.TyLe,0) = 0 THEN 100 
															ELSE  
																CASE WHEN  ISNULL(dtlc.TyLe,0) <> 0 THEN case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end
																ELSE CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
																	ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
																END
															END
												ELSE 
													CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra And ISNULL(dtl.TyLe,0) = 0 THEN 100 
													ELSE  
														CASE WHEN  ISNULL(dtl.TyLe,0) <> 0 THEN case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end
														ELSE CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
															ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
														END
													END
												END end
								--, t_ngoaids = 0			
								, Ma_Khoa =  pb.MaTheoQuiDinh -- Ma_khoa
								, ma_benh = case when @ICD_PHU='' then @ICD_CHINH else  @ICD_CHINH + ';' + @ICD_PHU end	-- ma_benh
								, ma_pttt=1	
								, t_NguonKhac = 0 
								, xbn.SoLoNhap_Id
								, xbn.TyLeDieuKien
								, NgoaiDinhXuat
								, MADICHVU = null--dbo.Get_Ma_DV_XML2(isnull(bapt.clsyeucau_id,YCHC.clsyeucau_id))
								, NGUON_CTRA = 1
								, ma_pp_chebien = '' --PPCB.Dictionary_Name_En
								, Dang_BaoChe =  '' 
								, Cach_Dung = isnull(nttt.GhiChu, '')
						        , CHUC_DANH_ID = COALESCE(bstt.ChucDanh_Id,bstt.ChucDanh_Id,bspt.ChucDanh_Id,bscls.ChucDanh_Id,bskb.ChucDanh_Id,bsvtyt.ChucDanh_Id)

							FROM	(
										Select	
											xncpct.XacNhanChiPhiChiTiet_Id,
											xncpct.XacNhanChiPhi_Id,
											xncpct.Loai_IDRef,
											xncpct.IDRef,
											xncpct.NoiDung_Id,
											xncpct.NoiDung,
											xncpct.SoLuong,
											xncpct.DonGiaDoanhThu,
											DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(xncpct.DonGiaHoTro as varchar(20))) > 0 
																	THEN CAST(REPLACE(CAST(xncpct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
															ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END,
											xncpct.DonGiaHoTroChiTra,
											xncpct.DonGiaThanhToan,
											xncpct.SoLuong_New,
											xncpct.DonGiaHoTroChiTra_New,
											--xncpct.Loai,
											xncpct.NgayCapNhat,
											xncpct.NguoiCapNhat_Id,
											xncpct.PhongBan_Id,
											xncpct.NgoaiTru_ToaThuoc_ID,
											xncpct.NoiTru_ToaThuoc_ID,
											--xncpct.TenDonViTinh,
											xncpct.XN_DonGiaVon,
											xncpct.XN_DonGiaMua,
											xncpct.DonGiaHoTroChiTra_4210,
											xncpct.Muc_Huong,
											xn.Loai
										From	XacNhanChiPhi xn
										 JOIN XacNhanChiPhiChiTiet xncpct On xncpct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xncpct.DonGiaHoTroChiTra>0
										Where	BenhAn_Id = @BenhAn_Id
											and Ngayxacnhan is not null 
									) xncpct
								LEFT JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xncpct.Loai_IDRef and xncpct.DonGiaHoTroChiTra>0
								LEFT JOIN	(
												SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID, mbc.Ma,
												CASE 
															 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
															 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
															WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
															 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
															 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
															 WHEN mbc.TenField = 'VC' THEN '11'
															 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	
															 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
															 WHEN mbc.TenField = 'TDCN' THEN '05'
															 WHEN mbc.TenField = 'K' THEN 'Khac'
															 WHEN mbc.TenField in  ('NGCK','Giuong','GB','Gi') THEN '12'
															 WHEN mbc.TenField = 'VTYT' THEN '10'
															 WHEN mbc.TenField = 'ThuocK' THEN '17'
														ELSE mbc.TenField
												END  as TenField
												FROM	dbo.DM_MauBaoCao mbc
												JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
												WHERE	MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xncpct.NoiDung_Id AND LI.PhanNhom = 'DV'
								LEFT JOIN	dbo.BenhAn ba  (nolock)  ON ba.BenhAn_Id = @BenhAn_Id
								LEFT JOIN	dbo.TiepNhan tn (nolock) ON tn.TiepNhan_Id = ba.TiepNhan_Id
								LEFT JOIN	dbo.DM_BenhNhan bn (nolock)ON bn.BenhNhan_Id = tn.BenhNhan_Id
								LEFT JOIN	DM_DoiTuong dt (nolock) on dt.DoiTuong_Id = tn.DoiTuong_Id
								left join dbo.Lst_Dictionary ndt  (Nolock) on ndt.Dictionary_Id=dt.NhomDoiTuong_Id	and ndt.Dictionary_Code='BHYT'
						
								LEFT JOIN	DM_Duoc d (nolock) ON d.Duoc_Id = xncpct.NoiDung_Id AND li.PhanNhom in ('DU','DI','VH','VT')
								--LEFT JOIN	DM_Duoc_HoatChat hc (nolock) on hc.HoatChat_Id = d.HoatChat_Id
								LEFT JOIN	dbo.DM_LoaiDuoc ld (nolock) ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
								LEFT JOIN	dbo.DM_DonViTinh dvt (nolock) ON dvt.DonViTinh_Id = d.DonViTinh_Id
								LEFT JOIN	dbo.DM_PhongBan pb (nolock) ON pb.PhongBan_Id = xncpct.phongban_id
								left join dbo.DM_DichVu dv (nolock) on dv.DichVu_Id = xncpct.NoiDung_Id AND li.PhanNhom = 'DV'
								left join dbo.Lst_Dictionary dd (nolock) ON dd.Dictionary_Id = d.DuongDung_Id
									-- L?y them mã thu?c BHYT, s? ?k,s? lô nh?p, ngày y lênh
								left join ChungTuXuatBenhNhan xbn (nolock) on ( xncpct.IDRef = xbn.ChungTuXuatBN_Id and xncpct.Loai_IDRef = 'I')

								left join NoiTru_ToaThuoc nttt (nolock) on nttt.toathuoc_id=xbn.toathuoc_id
								left join NoiTru_KhamBenh ntkb (nolock) on ntkb.KhamBenh_Id=nttt.KhamBenh_Id
								--left join NoiTru_TraThuocChiTiet ttct (nolock) on ttct.ToaThuoc_Id = nttt.ToaThuoc_Id
								left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
								-- l?y thêm ngày yêu c?u CLS
								left join CLSYeuCauChiTiet clsyc (nolock) on clsyc.YeuCauChiTiet_Id=xncpct.IDRef AND xncpct.Loai_IDRef = 'A'
								left join CLSYeuCau yc (nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
								left join vw_NhanVien bscls (nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
								left join CLSGhiNhanHoaChat_VTYT clshc (nolock) on xbn.CLSHoaChat_VTYT_Id=clshc.id
								left join CLSYeuCau kq (nolock) on clshc.CLSYeuCau_Id=kq.CLSYeuCau_Id
								left join CLSKetQua kqvt (nolock) on kq.CLSYeuCau_Id = kqvt.CLSYeuCau_Id
								left join vw_NhanVien bsvtyt (nolock) on kqvt.BacSiKetLuan_Id = bsvtyt.NhanVien_Id
								left join DM_DoiTuong_GiaDuoc_TyLe dtl (nolock) on d.Duoc_Id = dtl.Duoc_Id 
														And dt.DoiTuong_Id = dtl.DoiTuong_Id
														And dtl.TamNgung = 0
								left join DM_DoiTuong_GiaDuoc_TyLe_BaseLine dtlc (nolock) on d.Duoc_Id = dtlc.Duoc_Id 
														And dt.DoiTuong_Id = dtlc.DoiTuong_Id
														And dtlc.TamNgung = 0

								--bác s? kê VTYT ? phòng khám
								left join KhamBenh_VTYT KBVT (nolock) ON xbn.KhamBenh_VTYT_ID = KBVT.KhamBenh_VTYT_ID
								left join KhamBenh kb (nolock) on KBVT.KhamBenh_Id = kb.KhamBenh_Id
								left join vw_NhanVien bskb (nolock) on bskb.NhanVien_Id=kb.BacSiKham_Id
								--bác s? kê vtyt ph?u thu?t th? thu?t
								left join BenhAnPhauThuat_VTYT PTVT (nolock) on xbn.BenhAnPhauThuat_VTYT_Id = PTVT.BenhAnPhauThuat_VTYT_Id
								left join BenhAnPhauThuat BAPT (nolock) on PTVT.BenhAnPhauThuat_Id = BAPT.BenhAnPhauThuat_Id
								left join Sys_Users us on PTVT.NguoiTao_Id = us.User_Id
								left join NhanVien_User_Mapping usmap on us.User_Id = usmap.User_Id
								left join vw_NhanVien bspt on usmap.NhanVien_Id = bspt.NhanVien_Id
								left join DM_ICD I on ba.ICD_BenhChinh=I.ICD_Id
							WHERE  cast(xncpct.Loai as varchar(20)) = 'NoiTru' 
								AND xncpct.DonGiaHoTroChiTra > 0
								
								AND ((LI.PhanNhom in ('DU','DI','VH','VT') AND  ld.LoaiVatTu_Id IN ('T', 'H')) OR  map.TenField in( '08' , '16')
										or ld.MaLoaiDuoc in ('OXY', 'OXY1','LD0143','VTYT003','Mau')
										)
								AND xncpct.SoLuong > 0
							) A
						) B
						GROUP BY B.ToaThuoc_Id, B.TyLe_Duoc, B.TyLe_DuocCu, B.Ngay_YL, B.DonGiaHoTro, B.DonGiaHoTroChiTra
							, B.Muc_Huong, B.Ma_Bac_Si, B.NgayTiepNhan, B.TyLe_2
							, B.TyLe_TT, B.DON_GIA, B.SoLuong, B.Ma_Thuoc, B.Ma_Thuoc_Cs
							, B.ma_nhom, B.Ten_Thuoc, B.don_vi_tinh, B.ham_luong, B.duong_dung, B.LIEU_DUNG, B.so_dang_ky, B.TT_THAU
							, B.PHAM_VI, B.TuyenKhamBenh_Id, NgoaiDinhXuat, B.Ma_Khoa, B.ma_benh , B.ma_pttt, B.t_NguonKhac,B.SoLoNhap_Id,TyLeDieuKien	
							, MADICHVU
							, NGUON_CTRA, ma_pp_chebien, Dang_BaoChe, Cach_Dung, B.CHUC_DANH_ID
					
					
					) C
				) D
			) E
	) xml2
	where xml2.So_Luong_T > 0
	) xml2
	

