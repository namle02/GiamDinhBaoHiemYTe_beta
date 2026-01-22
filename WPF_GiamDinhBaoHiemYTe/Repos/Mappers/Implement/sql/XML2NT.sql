DECLARE @SoTiepNhan VARCHAR(50) = N'{IDBenhNhan}'

DECLARE @BenhAn_id VARCHAR(50)
DECLARE @TiepNhan_Id VARCHAR(50)
SELECT @TiepNhan_Id = TiepNhan_Id FROM TiepNhan WHERE SoTiepNhan = @SoTiepNhan

DECLARE @Ma_Lk VARCHAR(50)
DECLARE @ChanDoan_NT NVARCHAR(1000)
SELECT @Ma_Lk = convert(varchar (50),SoTiepNhan ) FROM TiepNhan WHERE TiepNhan_Id = @TiepNhan_Id
DECLARE @ICDCapCuu VARCHAR(20)
DECLARE @ICD_NT NVARCHAR(1000)
DECLARE @ICD_NTGopBenh NVARCHAR(1000)
DECLARE @ICD_phu NVARCHAR(1000)
DECLARE @Ma_PTTT_QT varchar(250)
declare @ChanDoan_RV  NVARCHAR(1000)



SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id] (NULL, @TiepNhan_Id)

if @BenhAn_Id is null 

set @BenhAn_Id  = (select BenhAn_Id from BenhAn where TiepNhan_Id = @TiepNhan_Id)

if @BenhAn_Id is not null
	begin
		SELECT	@ChanDoan_NT = isnull(ba.ChanDoanVaoKhoa, isnull(icd.TenICD, isnull( cc.ChanDoanNhapVien,icd_cc.TenICD) ) )
			, @ICDCapCuu = isnull(icd.MaICD, icd_cc.MaICD)
			, @ICD_NT = icd.MaICD
			, @ICD_NTGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenhPHCN] (@Tiepnhan_id)
			, @ICD_phu = icd_k.MaICD + ';' + [dbo].[Get_MaICD_ByBenhAn_Id] (@BenhAn_Id,'M')--, @SoBenhAn = ba.SoBenhAn,
			--, @Ma_Lk =  REPLACE(ba.SoBenhAn,'/','_')
			, @ChanDoan_RV = isnull(ba.ChanDoanRaVien,icd.TenICD)+ ', ' + isnull(isnull(ba.chandoanphuravien,icd_k.tenicd),'')
		FROM	(
					SELECT	*
					FROM	dbo.BenhAn
					WHERE	BenhAn_Id = @BenhAn_Id
				) ba
		INNER JOIN TiepNhan tn  (nolock)  ON ba.TiepNhan_ID= tn.TiepNhan_ID
		LEFT JOIN DM_ICD icd  (nolock) ON icd.ICD_Id = ba.ICD_BenhChinh
		left join ThongTinCapCuu cc (nolock)  on ba.BenhAn_ID = cc.BenhAn_Id 
		left join DM_ICD icd_cc (nolock)  on isnull(cc.ICD_BenhChinh, cc.ICD_BenhPhu) = icd_cc.ICD_Id
		LEFT JOIN DM_ICD icd_k (nolock)  ON ba.ICD_BenhPhu  = icd_k.ICD_Id	

		SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id] (@BenhAn_Id, NULL)
	end
	DECLARE @MaCSKCB  NVARCHAR(1000)
	
	DECLARE @ChanDoan_PK NVARCHAR(1000)
	DECLARE @ICD_PK NVARCHAR(1000)
	DECLARE @ICDKB NVARCHAR(1000)
	DECLARE @ICD_PHUPK NVARCHAR(1000)
	
	DECLARE @ICD_PNT NVARCHAR(1000)
	
	DECLARE @ICD_PKBenhChinh NVARCHAR(1000)
	DECLARE @ICD_PKGopBenh NVARCHAR(1000)
	DECLARE	@ThoiGianKham DATETIME
	
	DECLARE @ChanDoanCapCuu NVARCHAR(1000)
	
	declare @CapCuu bit
	
	DECLARE @KhamBenh_Id int
	Declare @Khoa NVARCHAR(200)
	declare @ICD_Khac NVARCHAR(1000)
	declare @SoBenhAn varchar(25)

	
	DECLARE @TT_01_TONGHOP_ID int = null
	DECLARE @NGAY_VAO DATETIME
	
	set @CapCuu = 0
	----Phòng Khám
	set @ICD_PK = [dbo].[Get_MaICDPhuByTiepNhan_ID](@TiepNhan_Id)
	set @ChanDoan_PK = [dbo].[Get_DSChanDoanKB_ByTiepNhan_ID](@TiepNhan_Id)
	set @ICD_PHUPK = [dbo].[Get_MaICD_ByTiepNhan_ID](@TiepNhan_Id)
	set @ICD_PKBenhChinh = [dbo].[Get_MaICDByTiepNhan_ID_benhchinh](@TiepNhan_Id)
	set @ICD_PKGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenh](@TiepNhan_Id)
	----end Phòng Khám
	---Bệnh án Ngoại trú--
	set @ICD_PNT = [dbo].[Get_MaICD_Phu_ByBenhAn_Id] (@BenhAn_Id,'M') --- icd bệnh phụ


	select @MaCSKCB=Value 
	from Sys_AppSettings  where Code = N'MaBenhVien_BHYT'

	-- Dùng để test
	--SET @MaCSKCB = '80005'

	Declare @LuongToiThieu Decimal(18,2) = 208500.00
	SELECT @LuongToiThieu = VALUE from sys_appsettings where code = 'LuongToiThieu'

	

	--lấy chẩn đoán của bệnh án ngoại trú
	select @ChanDoanCapCuu = icd.TenICD ,@ICDCapCuu = icd.MaICD, @CapCuu = 1			
	from BenhAn ba
	left join DM_ICD icd   (Nolock)  on icd.ICD_Id = ba.ICD_BenhChinh
	where TiepNhan_Id = @TiepNhan_Id
	and ba.SoCapCuu is not null

	--lấy mã bệnh chính của phòng khám đầu tiên
	SELECT @ICDKB = icd.MaICD	
	FROM TiepNhan tn (nolock)
	join	KhamBenh kb (nolock) ON tn.TiepNhan_Id = kb.TiepNhan_Id
	and kb.ThoiGianKham IN (SELECT min(ThoiGianKham) FROM KhamBenh k1 WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )
	LEFT JOIN	DM_ICD icd  (Nolock)  ON  icd.ICD_Id = kb.ChanDoanICD_Id
	where tn.tiepnhan_id = @TiepNhan_Id
	
	------------------
	
	------DungDV11
	
	
	------End
	SET @BenhAn_Id = NULL   --Tránh trường hợp bệnh án ngoại trú vẫn có benhan_id
-- DUNGDV Tinh TOng Tien Thuoc
	Declare @Tong_Tien_Thuoc Decimal(18, 2) = 0
	Declare @Tong_Chi decimal(18,2) = 0
	Declare @XacNhanChiPhi_ID int = null
	Declare @T_BHTT decimal(18,2) = 0
	Declare @T_BNCCT decimal(18,2) = 0
	Declare @T_BNTT decimal(18,2) = 0
	Declare @T_NguonKhac decimal(18,2) = 0
	Declare @Tong_Chi_BH decimal(18,2) = 0

	--SET @T_BHTT = dbo.Tong_t_bhtt_ngoaitru (@TiepNhan_Id)

	SELECT 
		@Tong_Chi = T_TongChi,
		@T_BHTT = T_BHTT,
		@T_BNCCT = T_BNCCT,
		@Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
		@T_BNTT=T_BNTT,
		@T_NguonKhac=T_NguonKhac,
		@Tong_Chi_BH = T_TONGCHI_BH
	FROM dbo.Tong_Tien_XML_BangKe01_130 (@TiepNhan_Id)



declare @SoChuyenVien nvarchar (50) = null
SELECT		
			@SoChuyenVien = left (SoPhieu,6)  
			--GIAY_CHUYEN_TUYEN = right(SoPhieu,8)--tùy chỉnh theo dự án
	FROM ( select * from  TiepNhan where TiepNhan_Id = @TiepNhan_id and XacNhanChiPhi_Id is not null ) TN
		JOIN DM_BenhNhan (nolock) ON tn.BenhNhan_Id = DM_BenhNhan.BenhNhan_Id
		left join DM_BenhVien (nolock)  td on td.benhvien_id = tn.NoiGioiThieu_Id
		join ChuyenVien cv ( nolock ) on cv.TiepNhan_Id = tn.TiepNhan_Id

if @BenhAn_Id is null 
begin
Select	@XacNhanChiPhi_ID = min(XacNhanChiPhi_ID) From	XacNhanChiPhi Where	TiepNhan_Id = @TiepNhan_Id And SoXacNhan IS NOT NULL

	SELECT [Id] = row_number () OVER (ORDER BY (SELECT 1))
	  ,[MA_LK] = @Ma_Lk
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
      ,[THANH_TIEN_BV] = xml2.THANH_TIEN_BV
      ,[THANH_TIEN_BH] = xml2.Thanh_Tien
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
	  ,[NGAY_TH_YL] =  xml2.Ngay_YL
	  ,[CHUC_DANH_ID] = xml2.CHUC_DANH_ID
	FROM (
	SELECT *, t_bntt = CASE WHEN ThuocVG = 1  THEN CAST(0 as decimal(18,2)) ELSE THANH_TIEN_BV - (t_bhtt + t_bncct) END FROM (
			SELECT		 MA_LK = @Ma_Lk	
						, STT = row_number () over (order by (select 1))--xnct.XacNhanChiPhiChiTiet_Id
						, Ma_Thuoc = case when li.PhanNhom = 'DV' then  ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode)
										  when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL 
											then ISNULL(d.MaHoatChat, d.MaDuoc)
										  WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') 
											THEN ISNULL(d.MaHoatChat, d.Attribute_2)									
										else d.MaDuoc
									end
						, Ma_Thuoc_Cs =case when li.PhanNhom = 'DV' then ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode)
											when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL 
												then ISNULL(d.MaHoatChat, d.MaDuoc)
											WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') 
												THEN ISNULL(d.MaHoatChat, d.Attribute_2)
											else d.MaDuoc
										end
						, MA_NHOM = CASE -- Ma_Nhom
											--datpt29 thêm mã nhóm = 6 với thuốc tỷ lệ 16062020
										when LI.PhanNhom = 'DU' AND (d.BHYT = 1 and xbn.TyLeDieuKien is not null and xnct.DonGiaHoTroChiTra>0 ) 
															and ld.LoaiVatTu_Id <> ('V') then '4' --'6' QĐ 5937
										--end datpt29
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') 
													and ld.MaLoaiDuoc NOT IN ('LD0143','Mau','ChePham') OR  map.TenField in ('16','Thuoc') 
													or ld.MaLoaiDuoc in ('OXY', 'OXY1') THEN '4'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V')  
													And ld.MaLoaiDuoc <> 'VTYT003' OR  map.TenField in ('10','VTYT') 
													or ld.MaLoaiDuoc not in ('OXY', 'OXY1','LD0143','VTYT003','Mau','ChePham') THEN '10' 
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') 
													And ld.MaLoaiDuoc in ('LD0143','Mau') THEN '7'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') 
													And ld.MaLoaiDuoc in ('LD0143','ChePham') THEN '17'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') 
													And ld.MaLoaiDuoc in ('VTYT003','Mau','ChePham') THEN '7'
									ELSE
										CASE
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
										WHEN map.TenField = '07' THEN '9' 
										when map.TenField  = '18' then '18'
										WHEN ISNULL(map.TenField, '') = '' THEN '12'
										END
									END
						
						, Ten_Thuoc = ISNULL(ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,DV.TenDichvU), ISNULL(d.Ten_VTYT_917, REPLACE(D.TenHang, CHAR(0x1F), '')))  
						, DON_VI_TINH = isnull(dvt.TenDonViTinh,N'Lần')								
						, HAM_LUONG = d.HamLuong												
						, ma_pp_chebien = '' --PPCB.Dictionary_Name_En
						, Dang_BaoChe =  '' --dangbc.Dictionary_Name_En
						, DUONG_DUNG = dd.Dictionary_Code
						, Cach_Dung = isnull(nttt.GhiChu, thuoc.GhiChu)
						--, LIEU_DUNG =  isnull(dbo.Get_SoLuongThuocTrongNgay(thuoc.toathuoc_id),N'Test')
						, LIEU_DUNG =  case when thuoc.toathuoc_id is not null then dbo.Get_SoLuongThuocTrongNgay(thuoc.toathuoc_id)
											when nttt.ToaThuoc_Id is not null then dbo.Get_SoLuongThuocTrongNgay_NoiTru(nttt.toathuoc_id)
											else N'1/lần*1 lần/ngày'
											end 
										
						
									--isnull(convert (nvarchar(500), CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18,0)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 0))
									--	) + isnull( '/' + nttt.GhiChu,'/'+thuoc.GhiChu),convert (nvarchar(500), CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18,0)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 0))
									--	))
									
						, SO_DANG_KY	=ISNULL(d.Attribute_3, '')--lo.GPDK								--	so_dang_ky
						, TT_Thau = ISNULL(isnull(d.ThongTinThau,d.MaGoiThau), '')										-- TT_Thau
						--, Pham_Vi =  case when ltt.Dictionary_Code = 'VIENGAN_B' then 2 else 1 end
						, Pham_Vi =1-- phamvi.Dictionary_Code
						, So_Luong = CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 3))
				
						, DON_GIA = xnct.DonGiaDoanhThu --CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										--ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END
						
						, TYLE_TT = CAST(isnull((xbn.TyLeDieuKien*100),100)  as decimal(18,0))

						, THANH_TIEN = CAST(
											CASE WHEN xbn.TyLeDieuKien is not null THEN
												CASE WHEN (xnct.DonGiaDoanhThu*xbn.TyLeDieuKien *CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu*xbn.TyLeDieuKien), 0)		< 0 Then 0
												ELSE (xnct.DonGiaDoanhThu*xbn.TyLeDieuKien*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu*xbn.TyLeDieuKien), 0) END			-- t_tongchi		
											ELSE  
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
										
												END
										as decimal(18,2))

						, THANH_TIEN_BV = CAST( CASE WHEN (xnct.DonGiaDoanhThu*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu), 0)		< 0 Then 0
												ELSE (xnct.DonGiaDoanhThu*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu), 0) END			-- t_tongchi		
										as decimal(18,2))

						, muc_huong = xnct.muc_huong*100 --CASE WHEN ISNULL(@Tong_Chi,0) < @MaxCPKB THEN 100 ELSE dt.TyLe_2*100 END
						
						, t_bhtt =  CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
						, t_bncct = 
						--, t_bncct = 
						CAST(CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END 
										as decimal(18,2))
									-
									CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
					, t_nguonkhac = 
										case
											when (mg.LyDo_ID in (9692)) then 0  -- 0 -- t_nguonkhac --thanhnn them -- Lý do giảm là ngoại giao thì không gửi XML
											else ISNULL(xbn.GiaTriMienGiam,0)
										end
						, t_ngoaids = case when isnull(bc.ngoaidinhxuat,0)=1 or isnull(icd_nt.NgoaiDinhXuat,0)=1 then
										CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
										else 0 end	

						--,	MA_KHOA='K01' -- mặc định bằng kê 01 khoa khám bệnh là 01
						,	MA_KHOA =  COALESCE(pbkb1.MaTheoQuiDinh,pbcdinh.MaTheoQuiDinh,pbthuoc.MaTheoQuiDinh,'K01')

						,	MA_BAC_SI = case when nttt.ToaThuoc_Id is not null then bstt.SoChungChiHanhNghe
											when PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt.SoChungChiHanhNghe
											when kbvt.KhamBenh_VTYT_Id is not null then bskbvt.SoChungChiHanhNghe
											when thuoc.ToaThuoc_Id is not null then bskbtt.SoChungChiHanhNghe
											when HCVT.Id is not null then BSHCVT.SoChungChiHanhNghe
											when HCVTNT.Id is not null then BSHCVTNT.SoChungChiHanhNghe
											when map.TenField in ('08','16') and li.PhanNhom = 'DV' then bscls.SoChungChiHanhNghe

										else null end
						
						--COALESCE(BSHCVT.SoChungChiHanhNghe,bstt.SoChungChiHanhNghe,bspt.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe,bskb.SoChungChiHanhNghe)								--	ma_bac_si
					
						,  MA_BENH  =isnull(@ICD_NT,@ICD_PKGopBenh)
						,  NGAY_YL = replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kbm.ketthucKham, ychc.thoigianyeucau), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kbm.KetThucKham,ychc.thoigianyeucau), 108), ':','') 
						,  MA_PTTT = case when 
											 left(tn.SoBHYT,2) in ('QN','CA','CY')
											 then 2 else 1 end	
						, ThuocVG = 0 --- case when ltt.Dictionary_Code = 'VIENGAN_B' THEN 1 ELSE 0 END
						, MADICHVU = dbo.Get_Ma_DV_XML2(isnull(bapt.clsyeucau_id,YCHC.clsyeucau_id))
						, NGUON_CTRA = 1--NguonCT.Dictionary_Code
						, CHUC_DANH_ID = case when nttt.ToaThuoc_Id is not null then bstt.ChucDanh_Id
								when PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt.ChucDanh_Id
								when kbvt.KhamBenh_VTYT_Id is not null then bskbvt.ChucDanh_Id
								when thuoc.ToaThuoc_Id is not null then bskbtt.ChucDanh_Id
								when HCVT.Id is not null then BSHCVT.ChucDanh_Id
								when HCVTNT.Id is not null then BSHCVTNT.ChucDanh_Id
								when map.TenField in ('08','16') and li.PhanNhom = 'DV' then bscls.ChucDanh_Id
							else null end
				From	(
							Select	
								xnct.XacNhanChiPhiChiTiet_Id,
								xnct.XacNhanChiPhi_Id,
								xnct.Loai_IDRef,
								xnct.IDRef,
								xnct.NoiDung_Id,
								xnct.NoiDung,
								xnct.SoLuong,
								xnct.DonGiaDoanhThu,
								DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(xnct.DonGiaHoTro as varchar(20))) > 0 
											THEN CAST(REPLACE(CAST(xnct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
									ELSE CAST(xnct.DonGiaHoTro as Decimal(18, 3)) END,
								xnct.DonGiaHoTroChiTra,
								xnct.DonGiaThanhToan,
								xnct.SoLuong_New,
								xnct.DonGiaHoTroChiTra_New,
								xnct.Loai,
								xnct.NgayCapNhat,
								xnct.NguoiCapNhat_Id,
								xnct.PhongBan_Id,
								xnct.NgoaiTru_ToaThuoc_ID,
								xnct.NoiTru_ToaThuoc_ID,
								xnct.TenDonViTinh,
								xnct.XN_DonGiaVon,
								xnct.XN_DonGiaMua,
								xnct.DonGiaHoTroChiTra_4210,
								xnct.Muc_Huong,
								xn.TiepNhan_Id
								, xn.BenhAn_Id
							--	xn.t_ngoaids
							From	XacNhanChiPhi xn (nolock) 
								JOIN XacNhanChiPhiChiTiet xnct (nolock)  On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
							Where	xn.TiepNhan_Id = @TiepNhan_Id
								And xn.SoXacNhan IS NOT NULL
							--AND		Loai = 'NgoaiTru'
							--	and Ngayxacnhan is not null
						
						) xnct
					left JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef
					LEFT JOIN	(
								SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
									CASE 
												 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
												 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
												 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
												 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
												 WHEN mbc.TenField in( 'ThuThuat') THEN '18'
												 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
												 WHEN mbc.TenField = 'VC' THEN '11'
												 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	
												 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
												 WHEN mbc.TenField = 'TDCN' THEN '05'
												 WHEN mbc.TenField = 'K' THEN 'Khac'
												 WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
												 WHEN mbc.TenField = 'VTYT' THEN '10'
											ELSE mbc.TenField
									END  as TenField
									,mbc.Ma 
									FROM	dbo.DM_MauBaoCao mbc
									JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
									WHERE	MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id   
					left JOIN	dbo.TiepNhan tn  (nolock) ON tn.TiepNhan_Id = xnct.TiepNhan_Id
					left JOIN	dbo.DM_BenhNhan (nolock)  bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
					left JOIN	DM_DoiTuong dt (nolock)  on dt.DoiTuong_Id = tn.DoiTuong_Id
					left join dbo.Lst_Dictionary  ndt  (Nolock) on ndt.Dictionary_Id=dt.NhomDoiTuong_Id	
					LEFT JOIN	dbo.Lst_Dictionary  (nolock) lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
					LEFT JOIN	dbo.DM_BenhVien (nolock)  ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
					LEFT JOIN	DM_Duoc (nolock)  d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
					LEFT JOIN	DM_Duoc_HoatChat hc (nolock) on hc.HoatChat_Id = d.HoatChat_Id
					LEFT JOIN	dbo.DM_LoaiDuoc (nolock)  ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
					LEFT JOIN	dbo.DM_DonViTinh  (nolock) dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
					left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
					left join dbo.Lst_Dictionary (nolock)  dd ON dd.Dictionary_Id = d.DuongDung_Id
					left join DM_BenhVien kcbbd (nolock)on tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
					left join ChungTuXuatBenhNhan  (nolock) xbn on (xnct.IDRef = xbn.ChungTuXuatBN_Id and xnct.Loai_IDRef = 'I')
					left join DM_LoaiDuoc  (nolock) f on f.LoaiDuoc_Id = D.LoaiDuoc_Id
					--Lấy ra ngày y lệnh
					left join ToaThuoc thuoc (nolock) on thuoc.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
					left join NoiTru_ToaThuoc (nolock)  nttt on xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
					left join NoiTru_KhamBenh (nolock)  ntkb on nttt.khambenh_id = ntkb.khambenh_id
					left join BenhAnPhauThuat_VTYT (nolock)  PTVT on xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
					left join BenhAnPhauThuat BAPT (nolock)  on PTVT.BenhAnPhauThuat_Id = BAPT.BenhAnPhauThuat_Id
					left join KhamBenh_VTYT kbvt (nolock)  on xnct.IDRef = kbvt.KhamBenh_VTYT_Id and li.PhanNhom = 'DU' and kbvt.Duoc_Id = d.Duoc_Id
					left join KhamBenh kb1 (nolock)  on kbvt.KhamBenh_Id = kb1.KhamBenh_Id				
					left join  CLSYeuCauChiTiet yctt on yctt.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef = 'A'
					left JOIN CLSYeuCau yc on yc.CLSYeuCau_Id = yctt.CLSYeuCau_Id	
					left join vw_NhanVien   bskbvt (nolock) on bskbvt.NhanVien_Id=kb1.BacSiKham_Id
					left join KhamBenh kbtt on kbtt.KhamBenh_Id = thuoc.KhamBenh_Id
					left join vw_NhanVien   bskbtt (nolock) on bskbtt.NhanVien_Id=kbtt.BacSiKham_Id
					--left join khambenh kb on kb.YeuCauChiTiet_Id = yctt.YeuCauChiTiet_Id
							
					--left join dm_phongban pb (nolock)  on pb.PhongBan_Id = kb.PhongBan_Id
					---datpt29 lấy ra mã khoa chỉ định thuốc
					left join NoiTru_LuuTru ltru (nolock)  on ltru.LuuTru_Id = ntkb.LuuTru_Id
					left join DM_PhongBan pbthuoc (nolock)  on pbthuoc.PhongBan_Id = ltru.PhongBan_Id
					left join DM_PhongBan pbcdinh (nolock)  on pbcdinh.PhongBan_Id = yc.NoiYeuCau_Id
					left join DM_PhongBan pbkb1  (nolock) on pbkb1.PhongBan_Id = kb1.PhongBan_Id
					--end datpt29
					--Lấy ra Ma_Bac_Si
					left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
					--LEFT JOIN vw_NhanVien bskb (nolock)  on bskb.NhanVien_Id=kb.BacSiKham_Id
					left join vw_NhanVien   bscls (nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
					left join Sys_Users  (nolock) us on BAPT.NguoiTao_Id = us.User_Id
					left join NhanVien_User_Mapping (nolock)  usmap on us.User_Id = usmap.User_Id
					left join vw_NhanVien bspt (nolock)  on usmap.NhanVien_Id = bspt.NhanVien_Id
					--lay ma bac si CLS HCVT ngoai tru
					left join CLSGhiNhanHoaChat_VTYT HCVT (nolock) on xnct.IDRef = HCVT.Id and xnct.Loai_IDRef ='E'
					left join CLSYeuCau YCHC (nolock) on HCVT.CLSYeuCau_Id = YCHC.CLSYeuCau_Id
					left join CLSKetqua YCHCkq (nolock) on HCVT.CLSYeuCau_Id = YCHCkq.CLSYeuCau_Id
					left join vw_NhanVien BSHCVT (nolock) on YCHCkq.BacSiKetLuan_id = BSHCVT.NhanVien_Id
					-- lay ma bac si CLS HCVT noi tru
					left join CLSGhiNhanHoaChat_VTYT HCVTNT (nolock) on xbn.CLSHoaChat_VTYT_Id = HCVTNT.Id
					left join CLSYeuCau YCHCNT (nolock) on HCVTNT.CLSYeuCau_Id = YCHCNT.CLSYeuCau_Id 
					left join CLSKetqua YCHCNTkq (nolock) on HCVTNT.CLSYeuCau_Id = YCHCNTkq.CLSYeuCau_Id 
					left join vw_NhanVien BSHCVTNT (nolock) on YCHCNTkq.bacsiketluan_id = BSHCVTNT.NhanVien_Id
					

					left join MienGiam mg on mg.TiepNhan_Id = tn.TiepNhan_Id
					left join KhamBenh kbm on kbm.TiepNhan_Id = xnct.TiepNhan_Id and kbm.KhamBenh_Id = (select top 1 KhamBenh_Id from khambenh where TiepNhan_Id = kbm.TiepNhan_Id)
					left join dm_phongban pb (nolock)  on pb.PhongBan_Id = kbm.PhongBan_Id
					left join DM_ICD i (nolock)  on i.ICD_Id = kbm.ChanDoanICD_Id
					left join DM_ICD icd (nolock)  on icd.ICD_Id = kbm.ChanDoanPhuICD_Id
					left join DM_ICD bc on BC.ICD_ID=kbm.ChanDoanICD_Id
					LEFT JOIN BenhAn ba (nolock) on xnct.BenhAn_Id = ba.BenhAn_Id
					left join DM_ICD icd_nt on icd_nt.ICD_Id=ba.ICD_BenhChinh
				WHERE	xnct.DonGiaHoTroChiTra > 0
					AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
					AND ((LI.PhanNhom = 'DU' AND  ld.LoaiVatTu_Id IN ('T', 'H')) OR  map.TenField = '08' OR  map.TenField = '16' or map.TenField = 'OXY'
						or ld.MaLoaiDuoc in ('OXY', 'OXY1','LD0143','VTYT003')
						)
					AND ISNULL(xbn.toathanhpho, 0) = 0
			
			GROUP BY nttt.ToaThuoc_Id, li.PhanNhom, case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode, d.MaHoatChat, d.MaDuoc, d.BHYT
				, xnct.DonGiaHoTroChiTra, ld.LoaiVatTu_Id, map.TenField, ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,DV.TenDichvU), d.Ten_VTYT_917, d.TenDuocDayDu
				, isnull(dvt.TenDonViTinh,N'Lần'), d.HamLuong, d.MaDuongDung, d.Attribute_3, d.Attribute_2, xnct.DonGiaHoTro, pb.MaTheoQuiDinh
				, ntkb.NgayKham, yc.ngayyeucau, ld.MaLoaiDuoc
				, D.TenHang, D.ThoiGianHopDong,dt.TyLe_2,d.ThongTinThau,d.MaGoiThau, pbcdinh.MaTheoQuiDinh, pbthuoc.MaTheoQuiDinh, pbkb1.MaTheoQuiDinh
				, dd.Dictionary_Code,
				replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kbm.ketthucKham, ychc.thoigianyeucau), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kbm.KetThucKham,ychc.thoigianyeucau), 108), ':','') 
				, tn.TuyenKhamBenh_Id
					, I.ngoaidinhxuat,icd.ngoaidinhxuat	, tn.SoBHYT
			, xnct.muc_huong,isnull( '/' + nttt.GhiChu,'/'+thuoc.GhiChu)
				, bapt.CLSYeuCau_Id, YCHC.CLSYeuCau_Id
				,isnull(nttt.GhiChu, thuoc.GhiChu)
				, thuoc.toathuoc_id
				, xbn.DuocDieuKien_Id
				, xbn.GiaTriMienGiam, mg.LyDo_ID
				, bc.NgoaiDinhXuat, icd_nt.NgoaiDinhXuat
				, xnct.DonGiaDoanhThu
				, xbn.TyLeDieuKien
				, case when nttt.ToaThuoc_Id is not null then bstt.SoChungChiHanhNghe
											when PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt.SoChungChiHanhNghe
											when kbvt.KhamBenh_VTYT_Id is not null then bskbvt.SoChungChiHanhNghe
											when thuoc.ToaThuoc_Id is not null then bskbtt.SoChungChiHanhNghe
											when HCVT.Id is not null then BSHCVT.SoChungChiHanhNghe
											when HCVTNT.Id is not null then BSHCVTNT.SoChungChiHanhNghe
											when map.TenField in ('08','16') and li.PhanNhom = 'DV' then bscls.SoChungChiHanhNghe

										else null end
				, case 
					when nttt.ToaThuoc_Id is not null then bstt.ChucDanh_Id
					when PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt.ChucDanh_Id
					when kbvt.KhamBenh_VTYT_Id is not null then bskbvt.ChucDanh_Id
					when thuoc.ToaThuoc_Id is not null then bskbtt.ChucDanh_Id
					when HCVT.Id is not null then BSHCVT.ChucDanh_Id
					when HCVTNT.Id is not null then BSHCVTNT.ChucDanh_Id
					when map.TenField in ('08','16') and li.PhanNhom = 'DV' then bscls.ChucDanh_Id
					else null 
				end
				) xml2 WHERE SO_LUONG > 0
		) xml2


end