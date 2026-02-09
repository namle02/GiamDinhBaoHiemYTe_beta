DECLARE @Sobenhan NVARCHAR(20) = N'{IDBenhNhan}'




DECLARE @benhan_id NVARCHAR(20)
SELECT	@BenhAn_Id = ba.BenhAn_Id
FROM	dbo.BenhAn ba (nolock) 
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



	SELECT [ID] = row_number () OVER (ORDER BY (SELECT 1))
	  ,[MA_LK] = XML3.Ma_Lk
      ,[STT] = row_number () OVER (ORDER BY (SELECT 1))
      ,[MA_DICH_VU] = XML3.ma_dich_vu
      ,[MA_PTTT_QT] = XML3.MA_PTTT_QT
      ,[MA_VAT_TU] = XML3.ma_vat_tu
      ,[MA_NHOM] = XML3.MA_NHOM
      ,[GOI_VTYT] = XML3.GOI_VTYT
      ,[TEN_VAT_TU] = XML3.TEN_VAT_TU
      ,[TEN_DICH_VU] = XML3.ten_dich_vu
      ,[MA_XANG_DAU] = NULL
      ,[DON_VI_TINH] = XML3.don_vi_tinh
      ,[PHAM_VI] = XML3.PHAM_VI
      ,[SO_LUONG] = XML3.SO_LUONG
      ,[DON_GIA_BV] = XML3.Don_Gia_BV
      ,[DON_GIA_BH] = XML3.Don_Gia
      ,[TT_THAU] = XML3.TT_THAU
      ,[TYLE_TT_DV] = XML3.tyle_tt
      ,[TYLE_TT_BH] = case when isnull(xml3.T_TRANTT,0) <> 0 then 100 else XML3.tyle_thanhtoanBH  end
      ,[THANH_TIEN_BV] = XML3.Thanh_Tien
      ,[THANH_TIEN_BH] =  case when isnull(xml3.T_TRANTT,0) <> 0 then XML3.Don_Gia*SO_LUONG else  XML3.Thanh_Tien_BH*(XML3.tyle_thanhtoanBH/100) end
      ,[T_TRANTT] = XML3.T_TRANTT
      ,[MUC_HUONG] = XML3.MUC_HUONG
      ,[T_NGUONKHAC_NSNN] = 0
      ,[T_NGUONKHAC_VTNN] = 0
      ,[T_NGUONKHAC_VTTN] = 0
      ,[T_NGUONKHAC_CL] = 0
      ,[T_NGUONKHAC] = 0
	  ,[T_BNTT] = xml3.Thanh_Tien -  case when isnull(xml3.T_TRANTT,0) <> 0 then XML3.Don_Gia*SO_LUONG else  XML3.Thanh_Tien_BH*(XML3.tyle_thanhtoanBH/100) end
      ,[T_BNCCT] = XML3.[T_BNCCT]
      ,[T_BHTT] = XML3.[T_BHTT]
      ,[MA_KHOA] = XML3.[MA_KHOA]
      ,[MA_GIUONG] = XML3.[MA_GIUONG]
      ,[MA_BAC_SI] = XML3.[MA_BAC_SI]
      ,[NGUOI_THUC_HIEN] = Nguoi_TH
      ,[MA_BENH] = XML3.[MA_BENH]
      ,[MA_BENH_YHCT] = case when xml3.ten_dich_vu = N'Khám YHCT' then @ICD_CHINH_YHCT + ';' + @ICD_PHU_YHCT else '' end
      ,[NGAY_YL] = XML3.[NGAY_YL]
      ,[NGAY_TH_YL] = XML3.[NGAY_THUCHIEN_YL]
      ,[NGAY_KQ] = XML3.[NGAY_KQ]
      ,[MA_PTTT] = XML3.[MA_PTTT]
      ,[VET_THUONG_TP] = NULL
      ,[PP_VO_CAM] = PPVC
      ,[VI_TRI_TH_DVKT] = null
      ,[MA_MAY] = ma_may
      ,[MA_HIEU_SP] = XML3.MAHIEU
      ,[TAI_SU_DUNG] = null
      ,[DU_PHONG] = NULL
	  ,[LoaiBenhPham_Id] = 
			CASE 
				WHEN MA_DICH_VU IN (N'24.0017.1714',N'24.0001.1714', N'24.0005.1716', N'24.0003.1715') THEN LoaiBenhPham_Id
				ELSE NULL
			END
	  ,[ChucDanh_id] = chuc_danh
	  ,[MoTa_Text] = MoTa_Text
	  ,[KET_LUAN] = ketluan
	  ,[TrinhTuThucHien] = TrinhTuThucHien
	  ,[PhuTang] = PhuTang

	   FROM (

	SELECT xml34.* , t_ngoaids= case when isnull(NgoaiDinhXuat,0)=1 then t_bhtt else 0 end, TrinhTuThucHien
	FROM (
	SELECT
			Ma_Lk = @Ma_Lk
			,ma_dich_vu = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end 
							   when LI.PhanNhom = 'DV' And map.TenField = '11' Then 'VC.' + bvct.TenBenhVien_Ru
							   else 
									case when PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL And TT04.VATTU_TT04_ID IS NOT NULL then  dvktc.MaQuiDinh
									else null end
							   end
			,ma_dich_vu_cs  = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end 
								   when LI.PhanNhom = 'DV' And map.TenField = '11' then 'VC.' + bvct.TenBenhVien_Ru
								   else  
									case when PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL And TT04.VATTU_TT04_ID IS NOT NULL then  dvktc.MaQuiDinh
									else null end
							   end
			, mahieu = d.mahieusp
			,ma_vat_tu =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.madichvu))  else null end
			,ma_vat_tu_cs  =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then	isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.madichvu))    else null end
			, ma_nhom = CASE --Ma_Nhom
							WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') and ld.MaLoaiDuoc not in ('LD0143','VTYT003') OR  map.TenField in ('16','Thuoc') THEN '4'
							WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') and ld.MaLoaiDuoc not in ('LD0143','VTYT003') And ISNULL(dtl.TyLe,0) = 0 And TT04.VATTU_TT04_ID IS NULL OR  map.TenField in ('10','VTYT')  THEN '10' 
							WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') and ld.MaLoaiDuoc not in ('LD0143','VTYT003') And (ISNULL(dtl.TyLe,0) > 0 OR TT04.VATTU_TT04_ID IS NOT NULL) OR  map.TenField in ('10','VTYT')  THEN '10'  --sua VTTT ti le  cu 11 
							WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xncpct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') And ld.MaLoaiDuoc in ('LD0143','VTYT003') THEN '7'
						ELSE 
							CASE
							WHEN map.TenField = '01' THEN '13' 
							WHEN map.TenField = '02' THEN '14' 
							WHEN map.TenField = '03' THEN '1' 
							WHEN map.TenField = '04' THEN '2' 
							WHEN map.TenField = '05' THEN '3'
							WHEN map.TenField = '17' THEN '6'  
							WHEN map.TenField = '18' THEN '18' ---18
							WHEN map.TenField = '06' THEN '8' 
							WHEN map.TenField = '08' THEN '7' 
							WHEN map.TenField = '09' THEN '17' 
							WHEN map.TenField = '11' THEN '12' 
							WHEN map.TenField = '12' THEN '15' 
							WHEN map.TenField = '07' THEN '9'
							WHEN ISNULL(map.TenField, '') = '' THEN '8'
							END
						END
			--, GOI_VTYT = ''
			, GOI_VTYT = CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL And TT04.VATTU_TT04_ID IS NOT NULL THEN 'G1'
							ELSE '' END
			, TEN_VAT_TU = CASE WHEN li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10'  THEN ISNULL(isnull(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,dv.TenDichVu), isnull(d.Ten_VTYT_917,d.TenHang))
								ELSE NULL
						   END
			, ten_dich_vu = case when tn.NgayTiepNhan <= '20241215' then CASE WHEN li.PhanNhom not in ('DU','DI','VH','VT') and map.TenField <> '10' then REPLACE(isnull(isnull(dv.Attribute3,case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end),dv.TenDichVu), CHAR(0x1F), '') end
			else CASE WHEN li.PhanNhom not in ('DU','DI','VH','VT') and map.TenField <> '10' then REPLACE(isnull(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,dv.TenDichVu), CHAR(0x1F), '') end
			end
			, don_vi_tinh = case when dv.NhomDichVu_Id = 53654 then isnull(dvt.TenDonViTinh,dv.DonViTinh)
							else isnull(dvt.TenDonViTinh,N'Lần') end
			, PHAM_VI = 1
			, So_Luong = CAST(CASE WHEN clsyc.PT50 = 1 and (map.TenField = '12' Or map.TenField = '07') THEN 0.5		--N?u d?ch v? thu?c nhóm ngày gi??ng và ???c tích PT50, SO_LUONG = 0.5
									WHEN clsyc.PT80 = 1 And ( map.TenField = '07') THEN 0.8
								ELSE CAST((sum(xncpct.SoLuong)) as decimal(18, 2))
						 END
						 - 
						 ISNULL((SELECT SUM(SOLUONG) FROM NoiTru_TraThuocChiTiet where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id), 0)
						 as decimal(18,2))
			, Don_Gia_BV =   isnull(xbn.DonGiaDoanhThu,xncpct.DonGiaHoTro)
			, Don_Gia = CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL 
								And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN 
								--thêm theo yêu c?u s?a ??n giá còn 1 n?a ??i v?i stent th? 2 24/11/2025
								case when ISNULL(PTVT.STT_Stent, 0) = 2  then CAST(TT04.DONGIA_TT04 as Decimal(18, 3)) * 1/2 --and d.MaHoatChat like N'%N06.02.020%' 
								when ISNULL(PTVT.STT_Stent, 0) = 3 then CAST(TT04.DONGIA_TT04 as Decimal(18, 3)) * 1/3 -- thanhnn thêm 12/01/2026
								when ISNULL(PTVT.STT_Stent, 0) = 4 then CAST(TT04.DONGIA_TT04 as Decimal(18, 3)) * 1/3 -- thanhnn thêm 12/01/2026
								else
								CAST(TT04.DONGIA_TT04 as Decimal(18, 3))
								end 
							ELSE 
								CASE WHEN map.TenField = '12' And clsyc.Ghep2 = 1 THEN CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) 
									 WHEN map.TenField = '12' And clsyc.Ghep3 = 1 THEN CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) 
								ELSE CAST(xncpct.DonGiaHoTro/isnull(clsyc.TyLeThanhToan,1) as Decimal(18, 3)) END
							END -- Don_Gia
			, tyle_tt = CASE WHEN clsyc.TyLeThanhToan IS NOT NULL										--Tr??ng h?p có t? l? thanh toán trong clsyeucauchitiet
								THEN CASE WHEN map.TenField = '01' THEN clsyc.TyLeThanhToan*100         --N?u d?ch v? là công khám
											WHEN map.TenField = '12' And clsyc.PT50 = 1 THEN 100			--N?u d?ch v? thu?c nhóm ngày gi??ng và ???c tích PT50, SO_LUONG = 0.5
											WHEN map.TenField = '12' And clsyc.Ghep2 = 1 THEN 50			--N?u d?ch v? thu?c nhóm ngày gi??ng và ???c tích n?m ghép 2
											WHEN map.TenField = '12' And clsyc.Ghep3 = 1 THEN 30			--N?u d?ch v? thu?c nhóm ngày gi??ng và ???c tích n?m ghép 3
											when map.TenField IN ('06', '18') and clsyc.pt50=1 then 50
											when map.TenField IN ('06', '18') and clsyc.pt80=1 then 80
											ELSE clsyc.TyLeThanhToan*100									--Ngoài các tr??ng h?p trên
										END
							ELSE 
								
								 100 END																	--Không có t? l?nh thanh toán trong clsyeucauchitiet
						
			, tyle_thanhtoanBH = CAST( CASE WHEN ISNULL(dtl.TyLe,0) > 0 THEN dtl.TyLe 
									WHEN ISNULL(PTVT.STT_STENT,0) = 2 and d.MaHoatChat like N'%N06.02.020%' THEN 50 --100 -- c? 50
									WHEN ISNULL(PTVT.STT_STENT,0) = 3 and d.MaHoatChat like N'%N06.02.020%' THEN 33 -- c? 0
									WHEN ISNULL(PTVT.STT_STENT,0) = 4 and d.MaHoatChat like N'%N06.02.020%' THEN 33 -- c? 0
								ELSE 100 END as decimal(18,0))
			, TT_THAU = case when d.Duoc_Id is not null  then isnull(d.ThongTinThau,d.MaGoiThau)	 else   ISNULL(dv.ReportCode,'') end
			, Thanh_Tien = CAST(
							CAST(
								CASE WHEN clsyc.PT50 = 1 THEN sum(xncpct.SoLuong) * 0.5 
									WHEN clsyc.PT80 = 1 THEN sum(xncpct.SoLuong) * 0.8 
									WHEN clsyc.Ghep2 = 1 THEN sum(xncpct.SoLuong) * 0.5
									WHEN clsyc.Ghep3 = 1 THEN sum(xncpct.SoLuong) * 0.3 
								ELSE sum(xncpct.SoLuong)  END
								*
								CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
									And TT04.VATTU_TT04_ID IS NOT NULL 
									And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
								ELSE CAST(isnull(xbn.DonGiaDoanhThu,xncpct.DonGiaHoTro) as Decimal(18, 3)) END
							as decimal(18,2))
							-
							CAST((CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
										And TT04.VATTU_TT04_ID IS NOT NULL 
										And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
									ELSE CAST(isnull(xbn.DonGiaDoanhThu,xncpct.DonGiaHoTro) as Decimal(18, 3)) END
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))
			,  Thanh_Tien_BH = CAST(
							CAST(
								CASE WHEN clsyc.PT50 = 1 THEN sum(xncpct.SoLuong) * 0.5 
									WHEN clsyc.PT80 = 1 THEN sum(xncpct.SoLuong) * 0.8 
									WHEN clsyc.Ghep2 = 1 THEN sum(xncpct.SoLuong) * 0.5
									WHEN clsyc.Ghep3 = 1 THEN sum(xncpct.SoLuong) * 0.3 
								ELSE sum(xncpct.SoLuong)  END
								*
								CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
									And TT04.VATTU_TT04_ID IS NOT NULL 
									And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
								ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
							as decimal(18,2))
							-
							CAST((CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
										And TT04.VATTU_TT04_ID IS NOT NULL 
										And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
									ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))
			
			, T_TRANTT = CASE	
								--Thanhnn s?a 12/01/2026
								WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL
								--and d.MaHoatChat like N'%N06.02.020%'
								And ISNULL(PTVT.STT_Stent, 0) = 2
								THEN 18000000
								WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL
								and d.MaHoatChat like N'%N06.02.020%'
								And ISNULL(PTVT.STT_Stent, 0) = 3
								THEN 12000000
								WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL
								and d.MaHoatChat like N'%N06.02.020%'
								And ISNULL(PTVT.STT_Stent, 0) = 4
								THEN 12000000
							WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL 
								And ISNULL(PTVT.STT_Stent, 0) = 1
								THEN CAST(TT04.DONGIA_TT04 as Decimal(18, 0))
							WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
								And TT04.VATTU_TT04_ID IS NOT NULL 
								And ISNULL(PTVT.STT_Stent, 0) = 0
								THEN CAST(TT04.DONGIA_TT04 as Decimal(18, 0))
							ELSE NULL END
			, MUC_HUONG = case 
							when ISNULL(PTVT.STT_STENT,0) = 2 then 100
							when ISNULL(PTVT.STT_STENT,0) = 3 then 100 -- 30
							when ISNULL(PTVT.STT_STENT,0) = 4 then 100 -- 30
							else
							case when tn.TuyenKhamBenh_Id = 1157 
								then CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN xncpct.Muc_Huong*100 ELSE dt.TyLe_2 * 100 END
							else
								CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra THEN 100 
								ELSE  
									CASE WHEN TT04.VATTU_TT04_ID IS NULL 
											THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
													ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
									ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
								END 
							end
							end
								-- t_tongchi	
			, t_NguonKhac = 0 --t_nguonkhac	
			
			, t_bntt =CAST(
							CAST(
								CASE WHEN clsyc.PT50 = 1 THEN sum(xncpct.SoLuong) * 0.5 
									WHEN clsyc.PT80 = 1 THEN sum(xncpct.SoLuong) * 0.8 
									WHEN clsyc.Ghep2 = 1 THEN sum(xncpct.SoLuong) * 0.5
									WHEN clsyc.Ghep3 = 1 THEN sum(xncpct.SoLuong) * 0.3 
								ELSE sum(xncpct.SoLuong)  END
								*
								CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
									And TT04.VATTU_TT04_ID IS NOT NULL 
									And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
								ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
							as decimal(18,2))
							-
							CAST((CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
										And TT04.VATTU_TT04_ID IS NOT NULL 
										And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaDoanhThu as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
									ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))
							-
							 CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
						CAST(
						CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
								WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
								WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
								WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
							ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
							-
							CAST((xncpct.DonGiaHoTro
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))		---Thanh_Tien						
						*
						CASE WHEN  ISNULL(@Tong_Chi,0) < 1 THEN 100 
							ELSE  
								CASE WHEN TT04.VATTU_TT04_ID IS NULL 
										THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
												ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
								ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
							END	----Muc_Huong
						/100
						as decimal(18,2))
					ELSE
						CAST(
						CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
								WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
								WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
								WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
							ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
							-
							CAST((xncpct.DonGiaHoTroChiTra
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))		---Thanh_Tien						
						as decimal(18,2))
					END 
					-
					case when tn.TuyenKhamBenh_Id = 1157 --and TyLe_2<>0.4
								And CAST(SUBSTRING(CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':', '')
														WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') 
															THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
														WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') 
															THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
													ELSE
														replace(convert(varchar , COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 112)+convert(varchar(5), COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 108), ':','')  
													END, 0, 9) as smalldatetime) < CAST('20210101' as smalldatetime)
							THEN 
								CASE WHEN ISNULL(@Tong_Chi,0) < 1 THEN 0
								ELSE
									CAST(
										(CAST(
											CASE WHEN clsyc.PT50 = 1 THEN sum(xncpct.SoLuong) * 0.5 
												WHEN clsyc.PT80 = 1 THEN sum(xncpct.SoLuong) * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN sum(xncpct.SoLuong) * 0.5
												WHEN clsyc.Ghep3 = 1 THEN sum(xncpct.SoLuong) * 0.3 
											ELSE sum(xncpct.SoLuong)  END
											*
											CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
												And TT04.VATTU_TT04_ID IS NOT NULL 
												And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
											ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
										as decimal(18,2))
										-
										CAST((CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
													And TT04.VATTU_TT04_ID IS NOT NULL 
													And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))
												ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
											 )*0.4
										as decimal(18,2)) --Thanh_Tien
									-
									CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
										CAST(
										CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
												WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
												WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
											ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
											-
											CAST((xncpct.DonGiaHoTro
												  *
												  ISNULL((SELECT SUM(SOLUONG) 
														  FROM NoiTru_TraThuocChiTiet 
														  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
														 ), 0)
												 ) as Decimal(18, 2))
											as decimal(18,2))		---Thanh_Tien						
										*
										case when TuyenKhamBenh_Id =1157 then Muc_Huong*100
										else
										CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra THEN 100 
											ELSE  
												CASE WHEN TT04.VATTU_TT04_ID IS NULL 
														THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
																ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
												ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
											END end	----Muc_Huong
										/100
										as decimal(18,2))
									ELSE
										CAST(
										CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
												WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
												WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
											ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
											-
											CAST((xncpct.DonGiaHoTroChiTra
												  *
												  ISNULL((SELECT SUM(SOLUONG) 
														  FROM NoiTru_TraThuocChiTiet 
														  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
														 ), 0)
												 ) as Decimal(18, 2))
											as decimal(18,2))		---Thanh_Tien						
										as decimal(18,2))
									END --T_BHTT
								END
						else
								CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
										WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8
										WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
										WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3  
									ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
									-
									CAST((xncpct.DonGiaHoTro
										  *
										  ISNULL((SELECT SUM(SOLUONG) 
												  FROM NoiTru_TraThuocChiTiet 
												  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
												 ), 0)
										 ) as Decimal(18, 2))
								as decimal(18,2))		--Thanh_Tien
								-
								CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
									CAST(
									CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
											WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
											WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
											WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
										ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
										-
										CAST((xncpct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		---Thanh_Tien						
									*
									CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra THEN 100 
									ELSE  
										CASE WHEN TT04.VATTU_TT04_ID IS NULL 
												THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
														ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
										ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
									END	----Muc_Huong
									/100
									as decimal(18,2))
								ELSE
									CAST(
									CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
											WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
											WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
											WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
										ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
										-
										CAST((xncpct.DonGiaHoTroChiTra
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		---Thanh_Tien						
									as decimal(18,2))
								END 		--T_BHTT
							--END
						end
			, t_bhtt = CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
						CAST(
						CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
								WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
								WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
								WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
							ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
							-
							CAST((xncpct.DonGiaHoTro
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))		---Thanh_Tien						
						*
						CASE WHEN  ISNULL(@Tong_Chi,0) < 1 THEN 100 
							ELSE  
								CASE WHEN TT04.VATTU_TT04_ID IS NULL 
										THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
												ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
								ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
							END	----Muc_Huong
						/100
						as decimal(18,2))
					ELSE
						CAST(
						CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
								WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
								WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
								WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
							ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
							-
							CAST((xncpct.DonGiaHoTroChiTra
								  *
								  ISNULL((SELECT SUM(SOLUONG) 
										  FROM NoiTru_TraThuocChiTiet 
										  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
										 ), 0)
								 ) as Decimal(18, 2))
							as decimal(18,2))		---Thanh_Tien						
						as decimal(18,2))
					END 
			, t_bncct = case when tn.TuyenKhamBenh_Id = 1157 --and TyLe_2<>0.4
								And CAST(SUBSTRING(CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':', '')
													WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') 
														THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
													WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') 
														THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
												ELSE
													replace(convert(varchar , COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 112)+convert(varchar(5), COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 108), ':','')  
												END, 0, 9) as smalldatetime) < CAST('20210101' as smalldatetime)
							THEN 
								CASE WHEN ISNULL(@Tong_Chi,0) < 1 THEN 0
								ELSE
									CAST(
										(CAST(
											CASE WHEN clsyc.PT50 = 1 THEN sum(xncpct.SoLuong) * 0.5 
												WHEN clsyc.PT80 = 1 THEN sum(xncpct.SoLuong) * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN sum(xncpct.SoLuong) * 0.5
												WHEN clsyc.Ghep3 = 1 THEN sum(xncpct.SoLuong) * 0.3 
											ELSE sum(xncpct.SoLuong)  END
											*
											CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
												And TT04.VATTU_TT04_ID IS NOT NULL 
												And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))---And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaHoTro as Decimal(18, 3))
											ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
										as decimal(18,2))
										-
										CAST((CASE WHEN PTVT.BenhAnPhauThuat_VTYT_Id IS NOT NULL 
													And TT04.VATTU_TT04_ID IS NOT NULL 
													And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(tt04.DONGIA_TT04 as Decimal(18, 3))--And ISNULL(xncpct.DonGiaDoanhThu,0) >= ISNULL(xncpct.DonGiaHoTro,0) THEN CAST(xncpct.DonGiaHoTro as Decimal(18, 3))
												ELSE CAST(xncpct.DonGiaHoTro as Decimal(18, 3)) END
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
											 )*0.4
										as decimal(18,2)) --Thanh_Tien
									-
									CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
										CAST(
										CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
												WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
												WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
											ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
											-
											CAST((xncpct.DonGiaHoTro
												  *
												  ISNULL((SELECT SUM(SOLUONG) 
														  FROM NoiTru_TraThuocChiTiet 
														  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
														 ), 0)
												 ) as Decimal(18, 2))
											as decimal(18,2))		---Thanh_Tien						
										*
										case when TuyenKhamBenh_Id =1157 then Muc_Huong*100
										else
										CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra THEN 100 
											ELSE  
												CASE WHEN TT04.VATTU_TT04_ID IS NULL 
														THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
																ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
												ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
											END end	----Muc_Huong
										/100
										as decimal(18,2))
									ELSE
										CAST(
										CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
												WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
												WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
												WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
											ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
											-
											CAST((xncpct.DonGiaHoTroChiTra
												  *
												  ISNULL((SELECT SUM(SOLUONG) 
														  FROM NoiTru_TraThuocChiTiet 
														  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
														 ), 0)
												 ) as Decimal(18, 2))
											as decimal(18,2))		---Thanh_Tien						
										as decimal(18,2))
									END --T_BHTT
								END
						else
								CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
										WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8
										WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
										WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3  
									ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
									-
									CAST((xncpct.DonGiaHoTro
										  *
										  ISNULL((SELECT SUM(SOLUONG) 
												  FROM NoiTru_TraThuocChiTiet 
												  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
												 ), 0)
										 ) as Decimal(18, 2))
								as decimal(18,2))		--Thanh_Tien
								-
								CASE WHEN TT04.VATTU_TT04_ID IS NULL THEN
									CAST(
									CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
											WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
											WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
											WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
										ELSE CAST((xncpct.DonGiaHoTro*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
										-
										CAST((xncpct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		---Thanh_Tien						
									*
									CASE WHEN  ISNULL(@Tong_Chi,0) < @MinBHYTChiTra THEN 100 
									ELSE  
										CASE WHEN TT04.VATTU_TT04_ID IS NULL 
												THEN CASE WHEN xncpct.Muc_Huong <> dt.TyLe_2 THEN xncpct.Muc_Huong*100 
														ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end  END
										ELSE case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end END
								
									END	----Muc_Huong
									/100
									as decimal(18,2))
								ELSE
									CAST(
									CAST(CASE WHEN clsyc.PT50 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5 
											WHEN clsyc.PT80 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.8 
											WHEN clsyc.Ghep2 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.5
											WHEN clsyc.Ghep3 = 1 THEN CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  * 0.3 
										ELSE CAST((xncpct.DonGiaHoTroChiTra*sum(xncpct.SoLuong)) as Decimal(18, 2))  END
										-
										CAST((xncpct.DonGiaHoTroChiTra
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xncpct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		---Thanh_Tien						
									
									as decimal(18,2))
								END 		--T_BHTT
							END
					--	end
			
			, Ma_Khoa =  isnull(pb.MaTheoQuiDinh,pbRa.MaTheoQuiDinh) -- Ma_khoa
			, Ma_Giuong = left (case when map.TenField in ('12','02') then  isnull(gb.MoTa ,case 
										when map.TenField='12' then 
											case 
											when  [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id)<> '' then 
											LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14)
											else 'H001' 
											end
										when map.TenField='02' then 
											case 
											when  [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id)<> '' then 
											LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14)
											else 'H001' 
											end
										else LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14) 
										end)
							else 
								null	
							end,4)
			
			, ma_bac_si = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null AND map.TenField <> '01' then bscls.SoChungChiHanhNghe
								when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null AND map.TenField = '01' then isnull(nguoitaokb.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe)--bskb.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and CLSGhiNhan_VTYT.id is not null then bskb2.SoChungChiHanhNghe
										else null end
			, chuc_danh =  case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null and map.TenField <> '01' then bscls.ChucDanh_Id
					when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then isnull(nguoitaokb.ChucDanh_Id,bscls.ChucDanh_Id) --bskb.SoChungChiHanhNghe
					when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.ChucDanh_Id
					when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.ChucDanh_Id
					when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.ChucDanh_Id
				else null end
			, ma_benh = case when @ICD_PHU='' then @ICD_CHINH else  @ICD_CHINH + ';' + @ICD_PHU end
			 , NGAY_YL =  case when xncpct.Loai_IDRef = 'A' then format( yc.ThoiGianYeuCau,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then format( bapt.ThoiGianBatDau,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( KBVT.NgayTao,'yyyyMMddHHmm')
										when  xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.id is not null then format( clsVTYT.ThoiGianYeuCau,'yyyyMMddHHmm')
									else NULL
									end

			, NGAY_THUCHIEN_YL =	CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':', '')
							WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') 
								THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.thoigiannhan,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.thoigiannhan,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
							WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') 
								THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
							WHEN ndv.MaNhomDichVu IN ('0801','0802','0803') 
								THEN NULL
							when  xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.id is not null then  format( kq.ThoiGianBatDauThucHien,'yyyyMMddHHmm')				
						
						ELSE
							replace(convert(varchar , COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 112)+convert(varchar(5), COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 108), ':','')  
						END
			, NGAY_KQ = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then 
									REPLACE(CONVERT(varchar,  COALESCE(KB.ketthuckham,yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(KB.ketthuckham,yc.ThoiGianYeuCau), 108),  ':','')
							when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '12' then 
									case when yc.NgayYeuCau != ba.NgayRaVien then
										REPLACE(CONVERT(varchar,  yc.NgayYeuCau, 112) + '2359',  ':','')
										else
										REPLACE(CONVERT(varchar,  ba.ThoiGianRaVien, 112) + CONVERT(varchar(5), ba.ThoiGianRaVien, 108),  ':','')
										end
							when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '02' then 
							REPLACE(CONVERT(varchar,  DATEADD(HOUR, 4, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), DATEADD(HOUR, 4, yc.ThoiGianYeuCau), 108),  ':','')
						else
						replace(convert(varchar , COALESCE(kq.ngaykhoadulieu,kq.ThoiGianThucHien, bapt.ThoiGianKetThuc, baptth.ThoiGianKetThuc,yc.ThoiGianYeuCau), 112) + convert(varchar(5), COALESCE(kq.ngaykhoadulieu,kq.ThoiGianThucHien,bapt.ThoiGianKetThuc, baptth.ThoiGianKetThuc,yc.ThoiGianYeuCau), 108), ':','')	-- ngay_kq
						end
			, ma_pttt=1	
			, NgoaiDinhXuat
			, MA_PTTT_QT = case when  li.PhanNhom = 'DV' and baptth.BenhAnPhauThuat_Id is not null then icd9.MaICD9_CM else null end

			, Nguoi_TH =  
						isnull(case when li.PhanNhom = 'DV' and map.TenField = '01'  then nguoitaokb.SoChungChiHanhNghe--bskb.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(BAPTTH.BenhAnPhauThuat_Id)
											when li.PhanNhom = 'DV' and kq.CLSKetQua_Id is not null then bskq.SoChungChiHanhNghe
											else NULL end
								,
								case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null then bscls.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
											when xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.Id is not null then bskq.SoChungChiHanhNghe
											
										else null end
								)

			, PPVC = case 
						WHEN map.TenField in ('06','18') THEN isnull(isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code),'4') 
						else isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code) end
						--isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code)
			, Ma_May = 
			case 
				when ndv.CapTren_Id = 1 and (mamay.Dictionary_Code is null or mamay.Dictionary_Code != 'KXD') 
					then REPLACE(COALESCE(ma_may.MaMay_Lis, mamay.Dictionary_Code, ''), ' ', '')
				when mamay.Dictionary_Code = 'KXD' then null
				when mamaypttt.Dictionary_Code = 'KXD' then null
				else isnull(mamay.Dictionary_Code, mamaypttt.Dictionary_Code) 
			end
			, CAST(kq.MoTa_Text AS NVARCHAR(MAX)) AS MoTa_Text
			, CAST(kq.KetLuan AS NVARCHAR(MAX)) AS KetLuan
			, yc.LoaiBenhPham_Id
			, CAST(kq.PhuTang  AS NVARCHAR(MAX)) AS PhuTang
			, PTVT.BenhAnPhauThuat_Id as ba1
			, ptyc.BenhAnPhauThuat_Id as ba2
	From	(
									SELECT 
										Loai_IDRef = 'A',
										IDRef = ycct.YeuCauChiTiet_Id,
										NoiDung_Id = ycct.DichVu_Id,
										NoiDung = dv.TenDichVu, --ko quan trong
										SoLuong = ycct.SoLuong,
										DonGiaDoanhThu = ycct.DonGiaDoanhThu,
										DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(ycct.DonGiaHoTro as varchar(20))) > 0 
															THEN CAST(REPLACE(CAST(ycct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
													ELSE CAST(ycct.DonGiaHoTro as Decimal(18, 3)) END,
										DonGiaHoTroChiTra = ycct.DonGiaHoTroChiTra,
										DonGiaThanhToan = ycct.DonGiaThanhToan,
										PhongBan_Id = isnull(		
											CASE
												WHEN dv.NhomDichVu_Id = 27 THEN yc.NoiThucHien_Id
												ELSE yc.NoiYeuCau_id
											END,ba.KhoaRa_Id),
										NoiTru_ToaThuoc_ID = NULL,
										NgoaiTru_ToaThuoc_ID = null,
										TenDonViTinh = dv.DonViTinh,
										BenhAn_Id = @benhan_id,
										TiepNhan_Id = @tiepnhan_id,
										Muc_Huong = ycct.MucHuong

									FROM CLSYeuCauChiTiet ycct (Nolock)
									LEFT JOIN CLSYeuCau yc (Nolock) ON ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id
									LEFT JOIN DM_DichVu dv (Nolock) ON dv.DichVu_Id = ycct.DichVu_Id
									LEFT JOIN BenhAn ba (Nolock) ON ba.BenhAn_Id = yc.BenhAn_Id or yc.TiepNhan_Id = ba.TiepNhan_Id
									Where @benhan_id = yc.BenhAn_Id or @tiepnhan_id = yc.TiepNhan_Id

									UNION ALL

									SELECT
										Loai_IDRef = 'I',
										IDRef = isnull(clsvt.ID,xbn.ChungTuXuatBN_Id),
										NoiDung_Id = isnull(clsvt.Duoc_Id,xbn.Duoc_Id),
										NoiDung = td.TenDuoc, --ko quan trong
										SoLuong = 
											CASE 
												WHEN xbn.ToaThuocTra_Id is not null then 0 - xbn.SoLuong
												else xbn.SoLuong
											END,
										DonGiaDoanhThu =xbn.DonGiaDoanhThu,
										DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(xbn.DonGiaHoTro as varchar(20))) > 0 
															THEN CAST(REPLACE(CAST(xbn.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
													ELSE CAST(xbn.DonGiaHoTro as Decimal(18, 3)) END,
										DonGiaHoTroChiTra =xbn.DonGiaHoTroChiTra,
										DonGiaThanhToan =xbn.DonGiaThanhToan,
										PhongBan_Id = isnull(isnull(pb.PhongBan_Id, isnull(pb2.PhongBan_Id, isnull(pb3.PhongBan_Id,pb1.PhongBan_Id))),pb4.phongban_id),
										NoiTru_ToaThuoc_ID = CASE WHEN @benhan_id is not null THEN xbn.ToaThuoc_Id ELSE NULL END,
										NgoaiTru_ToaThuoc_ID = CASE WHEN @benhan_id is null THEN xbn.ToaThuoc_Id ELSE NULL END,
										TenDonViTinh = d.DonViTinh,
										BenhAn_Id = @benhan_id,
										TiepNhan_Id = @tiepnhan_id,
										Muc_Huong = xbn.MucHuong
									FROM ChungTuXuatBenhNhan xbn (Nolock)
									left join DM_Duoc d (Nolock) on d.Duoc_Id = xbn.Duoc_Id
									left join DM_TenDuoc td (Nolock) on td.TenDuoc_Id = d.TenDuoc_Id
									/* Toa thuoc noi tru*/
									left join NoiTru_ToaThuoc nttt (Nolock) on nttt.ToaThuoc_Id  = xbn.ToaThuoc_Id 			-- IDREF bang chung tu xuat benh nhan la Toathuoc Id, toathuoctra_Id bang toa thuoc
									left join NoiTru_KhamBenh kb (Nolock)  on kb.KhamBenh_Id = nttt.KhamBenh_Id
									left join Noitru_LuuTru lt (Nolock)  on lt.LuuTru_Id = kb.LuuTru_Id
									left join DM_PhongBan pb (Nolock)  on pb.PhongBan_Id = lt.PhongBan_Id

									/*Tra thuoc noi tru*/
									left JOin NoiTru_TraThuocChiTiet B (Nolock) on B.NoiTru_TraThuocChiTiet_Id = xbn.ToaThuocTra_Id and xbn.duoc_ID = b.duoc_ID
									left join NoiTru_TraThuoc C (Nolock) on C.NoiTru_TraThuoc_Id = B.NoiTru_TraThuoc_Id 
									left join NoiTru_LuuTru E (Nolock) on E.LuuTru_Id = C.LuuTru_Id
									left join DM_PhongBan pb2 (Nolock) on pb2.PhongBan_Id = E.PhongBan_Id

									/*bệnh án phẫu thuật VTYT*/
									left join  BenhAnPhauThuat_VTYT vtyt (Nolock)  on vtyt.BenhAnPhauThuat_VTYT_Id = xbn.BenhAnPhauThuat_VTYT_Id
									left join ChungTu t (Nolock) on vtyt.ChungTuTongHop_Id=t.ChungTu_Id
									left join DM_KhoDuoc kd (Nolock) on t.KhoXuat_Id=kd.KhoDuoc_Id
									left join  DM_PhongBan pb3 (Nolock) on pb3.PhongBan_Id  = kd.PhongBan_Id

									/*cận lâm sàng ghi nhận VTYT - hóa chất*/
									left join KhamBenh_VTYT vt (Nolock) on xbn.KhamBenh_VTYT_Id=vt.KhamBenh_VTYT_Id
									left join KhamBenh kb1 (Nolock) on vt.KhamBenh_Id=kb1.KhamBenh_Id
									left join DM_PhongBan pb1 (Nolock) on pb1.PhongBan_Id = kb1.PhongBan_Id
									/*ClsHC-VT*/
									left join CLSGhiNhanHoaChat_VTYT (Nolock) clsvt on xbn.CLSHoaChat_VTYT_Id=clsvt.id and xbn.Duoc_Id=clsvt.duoc_id
									left join dm_khoduoc  k (Nolock) on  clsvt.KhoSuDung_Id=k.KhoDuoc_Id
									left join DM_PhongBan pb4 (Nolock) on pb4.PhongBan_Id = k.PhongBan_Id
									Where( @benhan_id = xbn.BenhAn_Id or @tiepnhan_id = xbn.TiepNhan_Id) and xbn.mienphi = 0
			) xncpct
	JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI (nolock) ON LI.Loai_IDRef = xncpct.Loai_IDRef
	LEFT JOIN	(
					SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID, mbc.Ma,
					CASE 
								 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
								 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
								 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
								 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND (ldv.MaLoaiDichVu = 'ThuThuat' Or ndv.MaNhomDichVu IN ('0307', '0304', '2101') or dndv.DichVu_Id in (19601,19618,19619,20531,21998,28915)) THEN '18' 
								 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND ldv.MaLoaiDichVu <> 'ThuThuat' And ndv.MaNhomDichVu NOT IN ('0307', '0304', '2101') and dndv.DichVu_Id not in (19601,19618,19619,20531,21998,28915) THEN '06' 
								 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
								 WHEN mbc.TenField = 'VC' THEN '11'
								 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	--Máu
								 WHEN mbc.TenField in  ('CPMau') THEN '09'	
								 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
								 WHEN mbc.TenField = 'TDCN' THEN '05'
								 WHEN mbc.TenField = 'K' THEN 'Khac'
								 WHEN mbc.TenField in  ('NGCK','Giuong','GB','GI') THEN '12'--,'GiuongDTBN'
								 WHEN mbc.TenField = 'VTYT' THEN '10'
								 WHEN mbc.TenField = 'ThuocK' THEN '17'
								 WHEN mbc.TenField = 'GiuongDTBN' THEN '02'
							ELSE mbc.TenField
					END  as TenField
					FROM	dbo.DM_MauBaoCao mbc
					JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
					LEFT JOIN DM_DichVu dv on dndv.DichVu_Id = dv.DichVu_Id
					LEFT JOIN DM_NhomDichVu ndv on dv.NhomDichVu_Id = ndv.NhomDichVu_Id
					LEFT JOIN DM_LoaiDichVu ldv on ndv.LoaiDichVu_Id = ldv.LoaiDichVu_Id
					WHERE	MauBC = 'BCVP_097'
				) map  ON map.DichVu_Id = xncpct.NoiDung_Id AND LI.PhanNhom = 'DV'
	LEFT JOIN	dbo.BenhAn ba (Nolock) ON ba.BenhAn_Id = @BenhAn_Id
	LEFT JOIN	dbo.TiepNhan tn (Nolock)  ON tn.TiepNhan_Id = ba.TiepNhan_Id
	LEFT JOIN	dbo.DM_BenhNhan bn (Nolock)  ON bn.BenhNhan_Id = tn.BenhNhan_Id
	LEFT JOIN	DM_DoiTuong dt  (Nolock)  on dt.DoiTuong_Id = tn.DoiTuong_Id
	LEFT JOIN	DM_Duoc d  (Nolock)  ON d.Duoc_Id = xncpct.NoiDung_Id AND li.PhanNhom in ('DU','DI','VH','VT')
	LEFT JOIN	dbo.DM_LoaiDuoc ld  (Nolock)  ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
	LEFT JOIN	dbo.DM_DonViTinh dvt (Nolock)  ON dvt.DonViTinh_Id = d.DonViTinh_Id
	LEFT JOIN	dbo.DM_PhongBan pb (Nolock)  ON pb.PhongBan_Id = xncpct.PhongBan_Id--ba.KhoaRa_Id
	
	left join ChungTuXuatBenhNhan xbn (Nolock)  on ( xncpct.IDRef = xbn.ChungTuXuatBN_Id and xncpct.Loai_IDRef = 'I')
	
	--- Lay NgayKham
	left join NoiTru_ToaThuoc nttt (nolock) on nttt.toathuoc_id=xbn.toathuoc_id
	left join NoiTru_KhamBenh ntkb (nolock) on ntkb.KhamBenh_Id=nttt.KhamBenh_Id
	left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
	
	left join CLSGhiNhanHoaChat_VTYT CLSGhiNhan_VTYT (nolock) ON CLSGhiNhan_VTYT.Id = xbn.IDRef and xbn.Loai_IDRef= 'E'
	left join CLSYeuCau clsVTYT (nolock) on clsVTYT.CLSYeuCau_Id = CLSGhiNhan_VTYT.CLSYeuCau_Id

	left join CLSYeuCauChiTiet clsyc  (Nolock) on clsyc.YeuCauChiTiet_Id=xncpct.IDRef and xncpct.Loai_IDRef = 'A'

	LEFT JOIN   dbo.DM_DichVu dv (Nolock)  on dv.DichVu_Id = clsyc.DichVu_Id
	 left join CLSYeuCau yc  (Nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
	 LEFT JOIN DM_NhomDichVu ndv (nolock) on yc.NhomDichVu_Id = ndv.NhomDichVu_Id
	 left join (
		Select * from KhamBenh where TiepNhan_Id = @TiepNhan_ID
		) kb on kb.YeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
	 left join vw_NhanVien bskb  (Nolock) on bskb.NhanVien_Id=kb.BacSiKham_Id

	left join NhanVien_User_Mapping (nolock)  usmapkb on kb.NguoiTao_Id = usmapkb.User_Id
	left join vw_NhanVien (nolock) nguoitaokb on nguoitaokb.NhanVien_Id = usmapkb.nhanvien_id


	 left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=isnull(yc.CLSYeuCau_Id,clsVTYT.CLSYeuCau_Id)
	 left join vw_NhanVien bskq  (Nolock) on bskq.NhanVien_Id=kq.BacSiKetLuan_Id

	left join ( 
					select 
					DichVu_Id = isnull(d.CapTren_Id, d.DichVu_Id), 
					CLSKetQua_Id, 
					MIN(MaMay_Lis) as MaMay_Lis 
				from CLSKetQuaChiTiet (nolock) kqct
				join DM_DichVu(nolock) d on d.DichVu_Id = kqct.DichVu_Id
				where MaMay_Lis <> '' and MaMay_Lis is not null
				group by isnull(d.CapTren_Id, d.DichVu_Id), CLSKetQua_Id
							) ma_may on ma_may.CLSKetQua_Id = kq.CLSKetQua_Id and ma_may.DichVu_Id = clsyc.DichVu_Id

	left join vw_NhanVien bscls  (Nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
	left join DM_BenhVien bvct (nolock) on ba.ChuyenDenBenhVien_Id = bvct.BenhVien_Id
	left join DM_DoiTuong_GiaDuoc_TyLe dtl (Nolock) on d.Duoc_Id = dtl.Duoc_Id And dt.DoiTuong_Id = dtl.DoiTuong_Id
	left join BenhAnPhauThuat_VTYT PTVT (nolock) on xbn.BenhAnPhauThuat_VTYT_Id = PTVT.BenhAnPhauThuat_VTYT_Id
	left join BenhAnPhauThuat BAPT (nolock) on BAPT.BenhAnPhauThuat_Id = PTVT.BenhAnPhauThuat_Id
	left join NhanVien_User_Mapping usmap on PTVT.NguoiTao_Id = usmap.User_Id
	left join vw_NhanVien bspt_vt on usmap.NhanVien_Id = bspt_vt.NhanVien_Id
	left join KhamBenh_VTYT KBVT (nolock) ON xbn.KhamBenh_VTYT_ID = KBVT.KhamBenh_VTYT_ID
	left join KhamBenh kb1 (nolock) on KBVT.KhamBenh_Id = kb1.KhamBenh_Id
	left join vw_NhanVien bskb_vt (nolock) on bskb_vt.NhanVien_Id=kb1.BacSiKham_Id
	left join DM_VATTU_TT04 TT04 ON D.Duoc_Id = TT04.Duoc_ID
	left join CLSYeuCau yc1 (Nolock) on BAPT.Clsyeucau_Id = yc1.CLSYeuCau_Id
	left join CLSYeuCauChiTiet ycct (Nolock) on yc1.CLSYeuCau_Id = ycct.CLSYeuCau_Id
	left join DM_DichVu dvktc (Nolock) on ycct.DichVu_Id = dvktc.DichVu_Id
	--HUNGVV13
	left join vw_NhanVien bskb2 (nolock) on bskb2.NhanVien_Id=clsVTYT.BacSiChiDinh_Id
	left join DM_ICD I on ba.ICD_BenhChinh=I.ICD_Id
	left join DM_PhongBan pbRa on ba.KhoaRa_Id=pbRa.PhongBan_Id

	--END HUNGVV13
	left join BenhAnPhauThuat_YeuCau ptyc (nolock) on ptyc.CLSYeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
	left join BenhAnPhauThuat BAPTTH (Nolock) on ptyc.BenhAnPhauThuat_Id = BAPTTH.BenhAnPhauThuat_Id
	LEFT JOIN (SELECT CLSYeuCauChiTiet_Id, SIDIssueDateTime = MAX(SIDIssueDateTime) 
				FROM Lab_SIDStatus (nolock)
				GROUP BY CLSYeuCauChiTiet_Id) lab on clsyc.YeuCauChiTiet_Id = lab.CLSYeuCauChiTiet_Id
	left join Lst_Dictionary  ( nolock)  ppvc on ppvc.Dictionary_Id = BAPTTH.PhuongPhapVoCam_Id
	left join Lst_Dictionary  ( nolock)  mamay on mamay.Dictionary_Id = kq.ThietBi_Id
	left join Lst_Dictionary  ( nolock)  mamaypttt on mamaypttt.Dictionary_Id = bapt.ThietBi_ID
	left join DM_ICD9_CM icd9  ( nolock)  on icd9.ICD9_CM_Id = dv.ICD9_CM_Id
	left join NoiTru_LuuTruChiTiet ltct  ( nolock)  on ltct.LuuTruChiTiet_Id = yc.LuuTruChiTiet_Id
	left join DM_GiuongBenh gb  ( nolock)  on gb.GiuongBenh_Id = ltct.GiuongBenh_Id
	where 
		-- cast(xncpct.Loai as varchar(20)) = 'NoiTru' 
		
		--AND
		xncpct.DonGiaHoTroChiTra > 0

		--and ba.NgayRaVien is not null	
 
		AND ((LI.PhanNhom  in  ('DU') and  ld.LoaiVatTu_Id IN ('V')) 

				or  ( isnull(map.TenField,'') not in  ('08' ,'16') and LI.PhanNhom  in  ('DV'))
		) and isnull(ld.MaLoaiDuoc,'') not in ('OXY', 'OXY1','LD0143','VTYT003')
		AND xncpct.SoLuong > 0
		and  ISNULL(d.BHYT,1) = 1	

group by xncpct.NoiTru_ToaThuoc_ID, CAST(kq.MoTa_Text AS NVARCHAR(MAX)), li.PhanNhom, case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.InputCode, d.MaDuoc, d.BHYT
		, pbRa.MaTheoQuiDinh
		,case when d.Duoc_Id is not null  then isnull(d.thongtinthau, N'9999.22030;G0;N6;2024') else   ISNULL(dv.ReportCode,'') end
		, xncpct.DonGiaHoTroChiTra, ld.LoaiVatTu_Id, map.TenField
		, COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau,baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau)
		, isnull(dvt.TenDonViTinh,N'Lần'),isnull(dvt.TenDonViTinh,dv.DonViTinh), xncpct.DonGiaHoTro
		,d.mahieusp
		, CASE WHEN li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10'  THEN ISNULL(isnull(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,dv.TenDichVu), isnull(d.Ten_VTYT_917,d.TenHang))
								ELSE NULL
						   END
		, case when tn.NgayTiepNhan <= '20241215' then CASE WHEN li.PhanNhom not in ('DU','DI','VH','VT') and map.TenField <> '10' then REPLACE(isnull(isnull(dv.Attribute3,case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end),dv.TenDichVu), CHAR(0x1F), '') end
			else CASE WHEN li.PhanNhom not in ('DU','DI','VH','VT') and map.TenField <> '10' then REPLACE(isnull(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,dv.TenDichVu), CHAR(0x1F), '') end
			end
		, ntkb.ThoiGianKham, yc.ThoiGianYeuCau, ld.MaLoaiDuoc, clsyc.PT50,clsyc.PT80,clsyc.Ghep2,clsyc.Ghep3
		, D.TenHang,dt.TyLe_2,d.MaGoiThau,PTVT.BenhAnPhauThuat_VTYT_Id,xncpct.DonGiaDoanhThu,xncpct.phongban_id,dv.TenDichVu
		,dtl.TyLe,case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end,clsyc.TyLeThanhToan,PTVT.STT_STENT,pb.MaTheoQuiDinh,pb.TenPhongBan_En
		, tn.TuyenKhamBenh_Id, xncpct.Muc_Huong,TT04.VATTU_TT04_ID,TT04.DONGIA_TT04, dv.MaDichVu,xncpct.Loai_IDRef,xncpct.NoiDung
		, xncpct.NoiDung_Id,bvct.TenBenhVien_Ru,dvktc.MaQuiDinh, d.MaHoatChat,d.Attribute_2,d.Attribute_3
		, dv.ReportCode,NgoaiDinhXuat
		, COALESCE(kq.ngaykhoadulieu,kq.ThoiGianThucHien, bapt.ThoiGianKetThuc, baptth.ThoiGianKetThuc), BAPTTH.BenhAnPhauThuat_Id
		, dv.NhomDichVu_Id, kb.ThoiGianKham, ndv.MaNhomDichVu
		, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau)
		, COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau)
		, case when  li.PhanNhom = 'DV' and baptth.BenhAnPhauThuat_Id is not null then icd9.MaICD9_CM else null end
		,isnull(xbn.DonGiaDoanhThu,xncpct.DonGiaHoTro)
		, isnull( isnull(FORMAT(kq.ThoiGianBatDauThucHien,'yyyyMMddHHmm'),ISNULL(FORMAT(kq.thoigiannhan,'yyyyMMddHHmm'),ISNULL(FORMAT(kq.ngaytao,'yyyyMMddHHmm'), FORMAT(baptth.thoigianbatdau,'yyyyMMddHHmm')))) ,FORMAT(yc.ThoiGianYeuCau,'yyyyMMddHHmm') )
		,isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code)
		, case 
				when ndv.CapTren_Id = 1 and (mamay.Dictionary_Code is null or mamay.Dictionary_Code != 'KXD') 
					then REPLACE(COALESCE(ma_may.MaMay_Lis, mamay.Dictionary_Code, ''), ' ', '')
				when mamay.Dictionary_Code = 'KXD' then null
				when mamaypttt.Dictionary_Code = 'KXD' then null
				else isnull(mamay.Dictionary_Code, mamaypttt.Dictionary_Code) 
			end
		, case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null AND map.TenField <> '01' then bscls.SoChungChiHanhNghe
								when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null AND map.TenField = '01' then isnull(nguoitaokb.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe)--bskb.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and CLSGhiNhan_VTYT.id is not null then bskb2.SoChungChiHanhNghe
										else null end

			, case when xncpct.Loai_IDRef = 'A' then format( yc.ThoiGianYeuCau,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then format( bapt.ThoiGianBatDau,'yyyyMMddHHmm')
										when xncpct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( KBVT.NgayTao,'yyyyMMddHHmm')
										when  xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.id is not null then format( clsVTYT.ThoiGianYeuCau,'yyyyMMddHHmm')
									else NULL
									end
		 
			,CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':', '')
							WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') 
								THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.thoigiannhan,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.thoigiannhan,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
							WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') 
								THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, kq.ThoiGianThucHien, yc.ThoiGianYeuCau), 108), ':','')
							WHEN ndv.MaNhomDichVu IN ('0801','0802','0803') 
								THEN NULL
							when  xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.id is not null then  format( kq.ThoiGianBatDauThucHien,'yyyyMMddHHmm')
							
						
						
						ELSE
							replace(convert(varchar , COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 112)+convert(varchar(5), COALESCE(ntkb.ThoiGianKham,bapt.ThoiGianBatDau, baptth.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham,kb1.ThoiGianKham, clsVTYT.ThoiGianYeuCau), 108), ':','')  
						END
			, case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then 
									REPLACE(CONVERT(varchar,  COALESCE(KB.ketthuckham,yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(KB.ketthuckham,yc.ThoiGianYeuCau), 108),  ':','')
							when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '12' then 
									case when yc.NgayYeuCau != ba.NgayRaVien then
										REPLACE(CONVERT(varchar,  yc.NgayYeuCau, 112) + '2359',  ':','')
										else
										REPLACE(CONVERT(varchar,  ba.ThoiGianRaVien, 112) + CONVERT(varchar(5), ba.ThoiGianRaVien, 108),  ':','')
										end
							when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '02' then 
									REPLACE(CONVERT(varchar,  DATEADD(HOUR, 4, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), DATEADD(HOUR, 4, yc.ThoiGianYeuCau), 108),  ':','')
						else
						replace(convert(varchar , COALESCE(kq.ngaykhoadulieu,kq.ThoiGianThucHien, bapt.ThoiGianKetThuc, baptth.ThoiGianKetThuc,yc.ThoiGianYeuCau), 112) + convert(varchar(5), COALESCE(kq.ngaykhoadulieu,kq.ThoiGianThucHien,bapt.ThoiGianKetThuc, baptth.ThoiGianKetThuc,yc.ThoiGianYeuCau), 108), ':','')	-- ngay_kq
						end
			, case when li.PhanNhom = 'DV' and map.TenField = '01'  then bskb.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(BAPTTH.BenhAnPhauThuat_Id)
											when li.PhanNhom = 'DV' and kq.CLSKetQua_Id is not null then bskq.SoChungChiHanhNghe
											else NULL end
			, left (case when map.TenField in ('12','02') then  isnull(gb.MoTa ,case 
										when map.TenField='12' then 
											case 
											when  [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id)<> '' then 
											LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14)
											else 'H001' 
											end
										when map.TenField='02' then 
											case 
											when  [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id)<> '' then 
											LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14)
											else 'H001' 
											end
										else LEFT( [dbo].[get_ma_giuong](@BenhAn_Id,xncpct.phongban_id),14) 
										end)
							else 
								null	
							end,4)
				, case when d.Duoc_Id is not null  then isnull(d.ThongTinThau,d.MaGoiThau)	 else   ISNULL(dv.ReportCode,'') end
				, isnull(case when li.PhanNhom = 'DV' and map.TenField = '01'  then nguoitaokb.SoChungChiHanhNghe--bskb.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(BAPTTH.BenhAnPhauThuat_Id)
											when li.PhanNhom = 'DV' and kq.CLSKetQua_Id is not null then bskq.SoChungChiHanhNghe
											else NULL end
								,
								case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null then bscls.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
											when xncpct.Loai_IDRef <> 'A' and CLSGhiNhan_VTYT.Id is not null then bskq.SoChungChiHanhNghe
											
										else null end
								)
				, yc.LoaiBenhPham_Id , CAST(kq.PhuTang  AS NVARCHAR(MAX)) ,PTVT.BenhAnPhauThuat_Id	,PTYC.BenhAnPhauThuat_Id,CAST(kq.ketluan AS NVARCHAR(MAX))
				, clsyc.YeuCauChiTiet_Id,nguoitaokb.ChucDanh_Id, bscls.ChucDanh_Id,bstt.ChucDanh_Id,bskb_vt.ChucDanh_Id,bspt_vt.ChucDanh_Id,PTVT.BenhAnPhauThuat_VTYT_Id,kbvt.KhamBenh_Id,ntkb.KhamBenh_Id
		) XML34 
		Left join benhanphauthuat bapt on bapt.BenhAnPhauThuat_Id = isNULL(XML34.ba1,XML34.ba2)	
		where XML34.So_Luong > 0
) xml3
