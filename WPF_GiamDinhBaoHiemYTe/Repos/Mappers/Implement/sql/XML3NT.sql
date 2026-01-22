DECLARE @SoTiepNhan VARCHAR(50)  = N'{IDBenhNhan}'
DECLARE @TiepNhan_Id VARCHAR(50)
SELECT @TiepNhan_Id = TiepNhan_Id FROM TiepNhan WHERE SoTiepNhan = @SoTiepNhan
DECLARE @BenhAn_Id VARCHAR(50)
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
      ,[DON_GIA_BV] = XML3.DON_GIA
      ,[DON_GIA_BH] = XML3.DON_GIA
      ,[TT_THAU] = XML3.TT_THAU
      ,[TYLE_TT_DV] = XML3.tyle_tt
      ,[TYLE_TT_BH] = 100  
      ,[THANH_TIEN_BV] = XML3.Thanh_Tien
      ,[THANH_TIEN_BH] = XML3.Thanh_Tien
      ,[T_TRANTT] = XML3.T_TRANTT
      ,[MUC_HUONG] = XML3.MUC_HUONG
      ,[T_NGUONKHAC_NSNN] = 0
      ,[T_NGUONKHAC_VTNN] = 0
      ,[T_NGUONKHAC_VTTN] = 0
      ,[T_NGUONKHAC_CL] = 0
      ,[T_NGUONKHAC] = 0
      ,[T_BNTT] = XML3.t_bntt
      ,[T_BNCCT] = XML3.[T_BNCCT]
      ,[T_BHTT] = XML3.[T_BHTT]
      ,[MA_KHOA] = XML3.[MA_KHOA]
      ,[MA_GIUONG] = XML3.[MA_GIUONG]
      ,[MA_BAC_SI] = XML3.[MA_BAC_SI]
      ,[NGUOI_THUC_HIEN] = Nguoi_TH
      ,[MA_BENH] = XML3.[MA_BENH]
      ,[MA_BENH_YHCT] = NULL
      ,[NGAY_YL] = XML3.[NGAY_YL]
      ,[NGAY_TH_YL] = XML3.[NGAY_THUCHIEN_YL]
      ,[NGAY_KQ] = XML3.[NGAY_KQ]
      ,[MA_PTTT] = XML3.[MA_PTTT]
      ,[VET_THUONG_TP] = NULL
      ,[PP_VO_CAM] = PPVC
      ,[VI_TRI_TH_DVKT] = VITRI
      ,[MA_MAY] = ma_may
      ,[MA_HIEU_SP] = XML3.MAHIEU
      ,[TAI_SU_DUNG] = XML3.TSD
      ,[DU_PHONG] = NULL
	  ,[LoaiBenhPham_Id] = 
			CASE 
				WHEN MA_DICH_VU IN (N'24.0017.1714', N'24.0005.1716', N'24.0003.1715', N'24.0001.1714') THEN LoaiBenhPham_Id
				ELSE NULL
			END
	  ,[ChucDanh_id] = chuc_danh
	  ,[MoTa_Text] = MoTa_Text
	  ,[KET_LUAN] = ketluan
	  ,[TrinhTuThucHien] = TrinhTuThucHien
	  ,[PhuTang] = PhuTang
	   FROM (
			SELECT		 MA_LK = @Ma_Lk	
						, STT = row_number () over (order by (select 1))--xnct.XacNhanChiPhiChiTiet_Id
						,ma_dich_vu = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end --+ CASE WHEN ISNULL(clsyc.ViTri, '') <> '' THEN '.' + ISNULL(clsyc.ViTri, '') ELSE '' END
										   when LI.PhanNhom = 'DV' and map.TenField = '11' then 'VC.' + bvct.MaBenhVien
										   else null end
						,ma_dich_vu_cs = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end-- + CASE WHEN ISNULL(clsyc.ViTri, '') <> '' THEN '.' + ISNULL(clsyc.ViTri, '') ELSE '' END
											  when li.PhanNhom = 'DV' And map.TenField = '11' then 'VC.' + bvct.MaBenhVien
											  else null 
										 end
						,ma_vat_tu =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.madichvu))  else null end
						,ma_vat_tu_cs  =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then	isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end, dv.madichvu))  else null end
						, MA_NHOM = CASE -- Ma_Nhom
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') OR  map.TenField in ('16','Thuoc') THEN '4'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V')	 OR  map.TenField in ('10','VTYT')  THEN '10' 
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
										when MAP.TenField = '18' then 18
										WHEN ISNULL(map.TenField, '') = '' THEN '12'
										END
									END
						, GOI_VTYT = ''
						, TEN_VAT_TU = CASE WHEN xnct.Loai_IDRef <> 'A' THEN  ISNULL(D.Ten_VTYT_917, d.TenHang)
											ELSE ''
									   END
						-- TrucTC	phân nhóm để tách thẻ thuốc & vật tư y tế
							--  map.TenField = '08' nếu map máu trong DM dịch vụ
						--, Phan_loai= CASE	WHEN (LI.PhanNhom = 'DU' AND  ld.LoaiVatTu_Id IN ('T', 'H')) OR  map.TenField = '08' OR  map.TenField = '16' THEN 'T' ELSE 'D' END
						--, TEN_DICH_VU = REPLACE(isnull(ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end, dv.TenDichVu),''), CHAR(0x1F), '') 
						, TEN_DICH_VU = case when tn.NgayTiepNhan <= '20241215' then REPLACE(isnull(ISNULL(isnull(dv.Attribute3,case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end), dv.TenDichVu),''), CHAR(0x1F), '')
						else REPLACE(isnull(ISNULL(case when tn.NgayTiepNhan > '20250731' then DV.TenDichVu_En else dv.TenQuiDinhCu end, dv.TenDichVu),''), CHAR(0x1F), '') 	
						end
						-- ten_thuoc
						, DON_VI_TINH = isnull(dvt.TenDonViTinh,N'Lần')								 --	Don_Vi_Tinh
						, PHAM_VI = 1 --isnull(phamvi.Dictionary_Code,1) --fix tạm test với dv vì dv chưa map
						--, SO_LUONG  = CAST((xnct.SoLuong) as decimal(18, 2))												--	so_luong
						, SO_LUONG = CAST(CASE WHEN map.TenField = '12' And clsyc.PT50 = 1 THEN 0.5		--Nếu dịch vụ thuộc nhóm ngày giường và được tích PT50, SO_LUONG = 0.5
										ELSE CAST((xnct.SoLuong) as decimal(18, 2))
									 END
									 - 
									 ISNULL((SELECT SUM(SOLUONG) FROM NoiTru_TraThuocChiTiet where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id), 0)
									 as decimal(18,2))
						--, DON_GIA = CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))					--don_gia
						, DON_GIA = case when clsyc.TyLeThanhToan is not null							--don_gia
											then CAST((isnull(xnct.DonGiaHoTro,0)/clsyc.TyLeThanhToan)* CASE WHEN (clsyc.PT80 = 1 or clsyc.PT50 = 1) THEN isnull(clsyc.TyleThanhToan,1) ELSE 1 END as decimal(18,2)) 
										else CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,2)) 
									end	
						--, DON_GIA = case when clsyc.TyLeThanhToan is not null then CAST(isnull(xnct.DonGiaHoTro,0)/clsyc.TyLeThanhToan as decimal(18,3)) else CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3)) end					--don_gia
						, TT_Thau = case when d.Duoc_Id is not null  then isnull(d.ThongTinThau,d.MaGoiThau)	 else   ISNULL(dv.ReportCode,'') end
						--, TYLE_TT = case when clsyc.TyLeThanhToan is not null then clsyc.TyLeThanhToan*100 else 100 end --case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end										--	muc_huong
						, TYLE_TT = CASE WHEN clsyc.TyLeThanhToan IS NOT NULL										--Trường hợp có tỷ lệ thanh toán trong clsyeucauchitiet
												THEN CASE WHEN map.TenField = '01' THEN clsyc.TyLeThanhToan*100         --Nếu dịch vụ là công khám
														  WHEN map.TenField IN ('06', '18') And clsyc.PT80 = 1 THEN 80			--Nếu dịch vụ thuộc nhóm PTTT và được tích PT80
														  WHEN map.TenField IN ('06', '18') And clsyc.PT50 = 1 THEN 50			--Nếu dịch vụ thuộc nhóm PTTT và được tích PT50
														  WHEN map.TenField = '12' And clsyc.PT50 = 1 THEN 100			--Nếu dịch vụ thuộc nhóm ngày giường và được tích PT50, SO_LUONG = 0.5
														  WHEN map.TenField = '12' And clsyc.Ghep2 = 1 THEN 50			--Nếu dịch vụ thuộc nhóm ngày giường và được tích nằm ghép 2
														  WHEN map.TenField = '12' And clsyc.Ghep3 = 1 THEN 30			--Nếu dịch vụ thuộc nhóm ngày giường và được tích nằm ghép 3
														  ELSE clsyc.TyLeThanhToan*100									--Ngoài các trường hợp trên
													 END
										 ELSE 100																	--Không có tỷ lệnh thanh toán trong clsyeucauchitiet
									END
						
						----, THANH_TIEN = CAST((xnct.DonGiaHoTro*xnct.SoLuong) as decimal(18,2))-- t_TongChi	
						, THANH_TIEN = CAST(
										CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		
										
																													
						, T_TRANTT = NULL
						, muc_huong = CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
						, t_bhtt = CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
						, t_bntt= 0 
						, t_bncct = CAST(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)) as decimal(18,2))
									-
									CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
						, t_nguonkhac = 0 

						, t_ngoaids = case when isnull(bc.ngoaidinhxuat,0)=1 or isnull(icd_nt.NgoaiDinhXuat,0)=1 then
												CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
										else 0 end	
						, MA_KHOA = CASE WHEN ba.BenhAn_Id IS NULL THEN 'K01' --'K01' -- mặc định bằng kê 01 khoa khám bệnh là 01
									ELSE ISNULL(pbsd.MaTheoQuiDinh, pbRa.MaTheoQuiDinh) END
						, MA_GIUONG =''
	
						, chuc_danh =  case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null and map.TenField <> '01' then bscls.ChucDanh_Id
											when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then isnull(nguoitaokb.ChucDanh_Id,bscls.ChucDanh_Id) --bskb.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.ChucDanh_Id
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.ChucDanh_Id
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.ChucDanh_Id
										else null end
						
						, Ma_Bac_Si = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null and map.TenField <> '01' then bscls.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then isnull(nguoitaokb.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe) --bskb.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
										else null end
								
						, MA_BENH  = isnull(@ICD_NTGopBenh,@ICD_PKGopBenh)
					    , NGAY_YL =  case when xnct.Loai_IDRef = 'A' then format( yc.ThoiGianYeuCau,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then  format( ptvt.NgayTao,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( kbvt.NgayTao,'yyyyMMddHHmm')
									else NULL
									end
						, NGAY_THUCHIEN_YL = CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':','')
										WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') --Xét nghiệm
											THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 108), ':','')
										WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') --CĐHA
											THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 108), ':','')
									ELSE
										replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham), 108), ':','')  				-- ngay_yl	
									END
							-- datpt29
						--, NGAY_THUCHIEN_YL = case when  xnct.Loai_IDRef = 'A' and kq.CLSKetQua_Id is not null then format( kq.ThoiGianBatDauThucHien,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then format( PTVT.NgayTao,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( kbvt.NgayTao,'yyyyMMddHHmm')
						--					else NULL
						--					end 
						
						--, NGAY_KQ =   case when  xnct.Loai_IDRef = 'A' and kq.CLSKetQua_Id is not null then format( kq.ThoiGianThucHien,'yyyyMMddHHmm')
						--				else NULL
						--					end 
						----end 
						, NGAY_KQ = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then 
											REPLACE(CONVERT(varchar, KB.KetThucKham, 112) + CONVERT(varchar(5), KB.KetThucKham, 108),  ':','')
										else
							
								REPLACE(CONVERT(varchar, COALESCE(kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, bapt.ThoiGianKetThuc), 112) + CONVERT(varchar(5), COALESCE(kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, bapt.ThoiGianKetThuc), 108),  ':','')
									end
						, MA_PTTT =  1 
				
						, MA_PTTT_QT = case when  li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then icd9.MaICD9_CM else null end
						, MAHIEU = D.mahieusp
						, TSD = null--case when d.TaiSuDung = 1 then '1' else '' end
						, PPVC = case 
								WHEN map.TenField in ('06','18') THEN isnull(isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code),'4') 
								else isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code) end
						--isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code)
						, VITRI = ''--left(clsyc.VITRI,3)
						, ma_may = 
						--case when ndv.CapTren_Id = 1 then REPLACE(isnull(kqct.MaMay_Lis,''), ' ', '')
						--			when mamay.Dictionary_Code = 'KXD' Then null
						--			else isnull(mamay.Dictionary_Code, mamaypttt.Dictionary_Code) end
						case 
								when ndv.CapTren_Id = 1 and (mamay.Dictionary_Code is null or mamay.Dictionary_Code != 'KXD') 
									then REPLACE(COALESCE(ma_may.MaMay_Lis, mamay.Dictionary_Code, ''), ' ', '')
								when mamay.Dictionary_Code = 'KXD' then null
								when mamaypttt.Dictionary_Code = 'KXD' then null
								else isnull(mamay.Dictionary_Code, mamaypttt.Dictionary_Code) 
							end
						, Nguoi_TH = -- a Thanh VNTD IT YC null người TH lấy người chỉ định 01/07/2024
									isnull(case when li.PhanNhom = 'DV' and map.TenField = '01'  then nguoitaokb.SoChungChiHanhNghe--bskb.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(bapt.BenhAnPhauThuat_Id)
											when li.PhanNhom = 'DV' and kq.CLSKetQua_Id is not null then bskq.SoChungChiHanhNghe
											else NULL end
											,
											case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null then bscls.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
										else null end
										)
						, kq.MoTa_Text
						, kq.KetLuan
						, yc.LoaiBenhPham_Id
						, bapt.TrinhTuThucHien
						, kq.PhuTang
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
								xn.TiepNhan_Id, xn.BenhAn_Id

							From	XacNhanChiPhi xn (nolock) 
								JOIN XacNhanChiPhiChiTiet  (nolock) xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
							Where	TiepNhan_Id = @TiepNhan_Id
								And SoXacNhan IS NOT NULL		
						
						) xnct
				left JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI (nolock)  ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
				LEFT JOIN	(	SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
										CASE 
											 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
											 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
											 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
											 --WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
											 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND (ldv.MaLoaiDichVu = 'ThuThuat' Or ndv.MaNhomDichVu IN ('0307', '0304', '2101') or dndv.DichVu_Id in (19601,19618,19619,20531,21998,28915)) THEN '18' --Thủ thuật
											 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND ldv.MaLoaiDichVu <> 'ThuThuat' And ndv.MaNhomDichVu NOT IN ('0307', '0304', '2101') and dndv.DichVu_Id not in (19601,19618,19619,20531,21998,28915) THEN '06' --Phẫu thuật
											 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
											 WHEN mbc.TenField = 'VC' THEN '11'
											 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	--Máu
											 WHEN mbc.TenField in  ('CPMau') THEN '09'	--Chế phẩm máu
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
								LEFT JOIN DM_DichVu dv on dndv.DichVu_Id = dv.DichVu_Id
								LEFT JOIN DM_NhomDichVu ndv on dv.NhomDichVu_Id = ndv.NhomDichVu_Id
								LEFT JOIN DM_LoaiDichVu ldv on ndv.LoaiDichVu_Id = ldv.LoaiDichVu_Id
								WHERE	mbc.MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id 
				left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id
				left join CLSYeuCauChiTiet (nolock)  clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
				left join ChungTuXuatBenhNhan  (nolock) xbn on ( xnct.IDRef = xbn.ChungTuXuatBN_Id and xnct.Loai_IDRef = 'I')
				LEFT JOIN (SELECT CLSYeuCauChiTiet_Id, SIDIssueDateTime = MAX(SIDIssueDateTime) 
							FROM Lab_SIDStatus (nolock)
							GROUP BY CLSYeuCauChiTiet_Id) lab  on clsyc.YeuCauChiTiet_Id = lab.CLSYeuCauChiTiet_Id
				LEFT JOIN BenhAn ba (nolock) on xnct.BenhAn_Id = ba.BenhAn_Id
				left join DM_ICD icd_nt on icd_nt.ICD_Id=ba.ICD_BenhChinh
				left join KhamBenh kb on kb.YeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
				left join DM_ICD bc on BC.ICD_ID=kb.ChanDoanICD_Id
				left join DM_BenhVien bvct (Nolock) on kb.ChuyenDenBenhVien_Id = bvct.BenhVien_Id						   			
				left join dm_phongban (nolock)  pb on pb.PhongBan_Id = kb.PhongBan_Id
				LEFT JOIN	dbo.Lst_Dictionary (nolock)  lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
				LEFT JOIN	dbo.DM_BenhVien (nolock)  ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
				LEFT JOIN	DM_Duoc (nolock)  d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
				LEFT JOIN	dbo.DM_LoaiDuoc (nolock)  ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
				LEFT JOIN	dbo.DM_DonViTinh (nolock)  dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
				left join dbo.DM_DichVu (nolock)  dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
				left join dbo.Lst_Dictionary (nolock)  dd ON dd.Dictionary_Id = d.DuongDung_Id
				left join CLSYeuCau yc (nolock)  on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
				left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
				/*left join CLSKetQuaChiTiet kqct(nolock) on kq.CLSKetQua_Id=kqct.CLSKetQua_Id 
													and kqct.CLSKetQuaChiTiet_Id=(select max(CLSKetQuaChiTiet_Id) from CLSKetQuaChiTiet cc where cc.CLSKetQua_Id=kq.CLSKetQua_Id)
				*/
				left join ( select DichVu_Id =  isnull(d.CapTren_Id,d.DichVu_Id), CLSKetQua_Id, MaMay_Lis from  CLSKetQuaChiTiet (nolock) kqct
											join DM_DichVu(nolock) d on d.DichVu_Id = kqct.DichVu_Id
									where MaMay_Lis <> '' and MaMay_Lis is not null
									group by isnull(d.CapTren_Id,d.DichVu_Id),CLSKetQua_Id,MaMay_Lis
							) kqct on kqct.CLSKetQua_Id = kq.CLSKetQua_Id and kqct.DichVu_Id = clsyc.DichVu_Id
				left join BenhAnPhauThuat_YeuCau ptyc (nolock) on ptyc.CLSYeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
				left join BenhAnPhauThuat_VTYT  (nolock) PTVT on xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
				left join BenhAnPhauThuat bapt (nolock) on bapt.BenhAnPhauThuat_Id = isNULL(PTVT.BenhAnPhauThuat_Id	,PTYC.BenhAnPhauThuat_Id)				
				--left join ToaThuoc tthuoc on tthuoc.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
				--left join KhamBenh_ToaThuoc kbtt on kbtt.KhamBenh_ToaThuoc_Id = tthuoc.KhamBenh_ToaThuoc_Id
				left join KhamBenh_VTYT kbvt (nolock)  on  xnct.IDRef = kbvt.KhamBenh_VTYT_Id and li.PhanNhom = 'DU' and kbvt.Duoc_Id = d.Duoc_Id
				left join KhamBenh kb1  (nolock) on  kb1.KhamBenh_Id = kbvt.KhamBenh_Id

				---- Thuốc ty lệ 
				left join DM_DoiTuong_GiaDuoc_TyLe (nolock)  tyle on tyle.DoiTuong_Id = XBN.DoiTuong_Id and tyle.Duoc_Id = d.Duoc_Id
				--Lấy ra ngày y lệnh
				left join NoiTru_ToaThuoc nttt (nolock)  on xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
				left join NoiTru_KhamBenh ntkb  (nolock) on nttt.khambenh_id = ntkb.khambenh_id
			-- ngày kê VTTT
				
				
				--Lấy ra Ma_Bac_Si
				left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
				LEFT JOIN vw_NhanVien  (nolock) bskb on bskb.NhanVien_Id=kb.BacSiKham_Id
				--lấy người tạo công khám
				left join NhanVien_User_Mapping (nolock)  usmapkb on kb.NguoiTao_Id = usmapkb.User_Id
				left join vw_NhanVien (nolock) nguoitaokb on nguoitaokb.NhanVien_Id = usmapkb.nhanvien_id


				LEFT JOIN vw_NhanVien  (nolock) bskb_vt on bskb_vt.NhanVien_Id=kb1.BacSiKham_Id
				left join vw_NhanVien bscls (nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
				left join vw_NhanVien  (nolock) bskq on bskq.nhanvien_Id = kq.BacSiKetLuan_Id	
				left join NhanVien_User_Mapping (nolock)  usmap on PTVT.NguoiTao_Id = usmap.User_Id
				left join vw_NhanVien bspt_VT (nolock)  on usmap.NhanVien_Id = bspt_VT.NhanVien_Id
				left join DM_ICD9_CM icd9 on icd9.ICD9_CM_Id = dv.ICD9_CM_Id
				left join Lst_Dictionary ppvc on ppvc.Dictionary_Id = bapt.PhuongPhapVoCam_Id 
				left join Lst_Dictionary mamay on mamay.Dictionary_Id = kq.ThietBi_Id
				left join Lst_Dictionary  ( nolock)  mamaypttt on mamaypttt.Dictionary_Id = bapt.ThietBi_ID
				LEFT JOIN DM_NhomDichVu ndv (nolock) on yc.NhomDichVu_Id = ndv.NhomDichVu_Id

				LEFT JOIN DM_PhongBan pbsd (Nolock) on xnct.PhongBan_Id = pbsd.PhongBan_Id
				LEFT JOIN DM_PhongBan pbRa (Nolock) on ba.KhoaRa_Id = pbRa.PhongBan_Id
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


				WHERE	xnct.DonGiaHoTroChiTra > 0
			
				AND (		(LI.PhanNhom  in  ('DU') and  ld.LoaiVatTu_Id IN ('V'))
							or  ( isnull(map.TenField,'') not in  ('08' ,'16') and LI.PhanNhom  in  ('DV'))
					)
				and isnull(ld.MaLoaiDuoc,'') not in ('OXY', 'OXY1','LD0143','VTYT003')
	   ) XML3 where XML3.So_Luong > 0 

end