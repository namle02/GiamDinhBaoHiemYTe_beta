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



	SELECT * FROM 
(
			select [MA_LK] = @Ma_Lk
			, [STT]= 1
			, [MA_BN] = RIGHT(bn.MaYTe, 8)
			, [HO_TEN]	=	BN.TenBenhNhan
			, [SO_CCCD] = CASE 	WHEN len(bn.CMND)<10 THEN ''	ELSE left (bn.CMND,12)  END 
			, [NGAY_SINH] = CASE	WHEN bn.NgaySinh is null THEN convert(VARCHAR, bn.NamSinh) + '01010000'	
						WHEN bn.NgaySinh is not null THEN convert(VARCHAR, bn.NgaySinh, 112) + '0000'--convert(VARCHAR,bn.GioPhut)	
					END	
			, [GIOI_TINH] = CASE WHEN bn.GioiTinh = 'T' THEN 1 
							   WHEN bn.GioiTinh = 'G' THEN 2
						  END
			, [MA_QUOCTICH] =  isnull(quoctich.Dictionary_Code,'000')
			, [MA_DANTOC] =  isnull(dantoc.Dictionary_Code, '01'	)			
			, [MA_NGHE_NGHIEP] = isnull(nghenghiep.Dictionary_Name_En,'00000')
			, [DIA_CHI] = bn.DiaChi
			, [MATINH_CU_TRU] = case when bn.DonViHanhChinhMoi = 1 and bn.TinhThanhMoi_Id is not null then tinhmoi.Ma_TheoChuan
			else tinh.Ma_TheoChuan end
			, [MAHUYEN_CU_TRU] = case when bn.DonViHanhChinhMoi = 1 and bn.TinhThanhMoi_Id is not null then null
			else huyen.Ma_TheoChuan	end
			, [MAXA_CU_TRU] = case when bn.DonViHanhChinhMoi = 1 and bn.TinhThanhMoi_Id is not null then xamoi.Ma_TheoChuan
			else xa.Ma_TheoChuan end	
			, [DIEN_THOAI] = left(bn.SoDienThoai,10)


			, [MA_THE_BHYT] = CHIPHI.SoBHYT
			, [MA_DKBD] = CHIPHI.MAKCBBD 
			, [GT_THE_TU] = CHIPHI.BHYTTuNgay 
			, [GT_THE_DEN] = CHIPHI.BHYTDenNgay
			, [NGAY_MIEN_CCT] = CONVERT(Varchar, CHIPHI.NgayHuongMienCT, 112)
			, [LY_DO_VV] = isnull(isnull(chiphi.LyDoVaoVien, CASE WHEN CHIPHI.Lydo = '2' and chiphi.MaBenhVien <> @MaCSKCB THEN N'Cấp cứu' else N'Khám chữa bệnh' end ),N'Khám chữa bệnh')
			, [LY_DO_VNT] = isnull(kbvv.LyDoVaoVien,N'Cần nhập viện')
			, [MA_LY_DO_VNT] = 1
			, [CHAN_DOAN_VAO]  = ba.ChanDoanVaoKhoa
			, [CHAN_DOAN_RV] = @ChanDoan_RV
			, [MA_BENH_CHINH] = @ICD_CHINH
			, [MA_BENH_KT] = @ICD_PHU
			,[MA_BENH_YHCT] = null
			,[MA_PTTT_QT] = @Ma_PTTT_QT
			,[MA_DOITUONG_KCB] = case when tn.NgayTiepNhan > '20251017' then 
									case when ISNULL(tn.MaDoiTuongKCB_Id, 0) = 0 then
										CASE WHEN CHIPHI.Lydo = '2' and chiphi.MaBenhVien <> @MaCSKCB THEN '2' -- Cap Cuu
										WHEN chiphi.MaBenhVien = @MaCSKCB AND CHIPHI.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1' -- Dung Tuyen
										WHEN CHIPHI.Lydo <> '2' AND CHIPHI.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3' -- Dung Tuyen
										ELSE '3.2' -- Trai Tuyen XML1
										END 
									else mdt.Dictionary_Code end
								else 
									CASE WHEN CHIPHI.Lydo = '2' and chiphi.MaBenhVien <> @MaCSKCB THEN '2' -- Cap Cuu
										WHEN chiphi.MaBenhVien = @MaCSKCB AND CHIPHI.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.1' -- Dung Tuyen
										WHEN CHIPHI.Lydo <> '2' AND CHIPHI.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN '1.3' -- Dung Tuyen
										ELSE '3.3' -- Trai Tuyen
										END 
								end
			,[MA_NOI_DI] = isnull(CHIPHI.MaBenhVienGT,'')
			,[MA_NOI_DEN] = isnull(manoiden.TenBenhVien_En,'')
			,[MA_TAI_NAN] = null
			---------------------------------
			-- Thanhnn s?a thành th?i gian ti?p nh?n 19/02/2025
			, [NGAY_VAO] = 
			case when ba.thoigianravien < '20250219' then replace(convert(varchar , ba.ThoiGianVaoVien, 112)+convert(varchar(5), ba.ThoiGianVaoVien, 108), ':','')
			else replace(convert(varchar , tn.ThoiGianTiepNhan, 112)+convert(varchar(5), tn.ThoiGianTiepNhan, 108), ':','')
			end
			, [NGAY_VAO_NOI_TRU] = replace(convert(varchar , ba.ThoiGianVaoVien, 112)+convert(varchar(5), ba.ThoiGianVaoVien, 108), ':','')
			, [NGAY_RA] = replace(convert(varchar , ba.thoigianravien, 112)+convert(varchar(5), ba.thoigianravien, 108), ':','')
			,[GIAY_CHUYEN_TUYEN] = @SoChuyenVien--chiphi.sochuyenvien
			, [SO_NGAY_DTRI]	= --case when isnull(ba.SoNgayDieuTri_New,'')<>'' then ba.SoNgayDieuTri_New
							case when ba.SoNgayDieuTri_New is not null then ba.SoNgayDieuTri_New
							else
							CASE WHEN DateDiff(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 240 THEN  0
								   WHEN DateDiff(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 1440 THEN  1
								   ELSE --DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) + 1 
										CASE WHEN ba.ThoiGianVaoVien < CAST(@MocThoiGian_BHYT as datetime) THEN
											CASE WHEN DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) = 0 THEN  1 
												ELSE DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien)+1 
												END
										ELSE
											CASE WHEN DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) = 0 THEN  1 
											ELSE 
												CASE WHEN ketquadieutri.Dictionary_Code IN ('Khoi', 'Giam') THEN DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) 
												ELSE DateDiff(day, ba.ThoiGianVaoVien, ba.ThoiGianRaVien)+1 
												END
											END
										END
								   END	end

			,[PP_DIEU_TRI] = bact.PPDT


			, [KET_QUA_DTRI] = CASE WHEN ketquadieutri.Dictionary_Code = 'Khoi' THEN 1
							      WHEN ketquadieutri.Dictionary_Code = 'Giam' THEN 2
								  WHEN ketquadieutri.Dictionary_Code = 'KhongThayDoi' THEN 3
								  WHEN ketquadieutri.Dictionary_Code in ( 'NXV','nanghon','HHXV' ) THEN 4
								  WHEN ketquadieutri.Dictionary_Code in ( 'TuVong','TuVong24','TuVongCD','TuVongTL','TuVong7' ) THEN 5
							 ELSE 1 END
			, [MA_LOAI_RV] = CASE WHEN lydoxuatvien.Dictionary_Code = 'RV' THEN 1
								   WHEN lydoxuatvien.Dictionary_Code = 'CV' THEN 2
								   WHEN lydoxuatvien.Dictionary_Code = 'BV' THEN 3
								   WHEN lydoxuatvien.Dictionary_Code in ( 'XV','TV','TV24','CCRV','DV','N' ) THEN 4
							  ELSE 1 END
			,[GHI_CHU] = bact.LoiDanThayThuoc
			, [NGAY_TTOAN] = null
			, [T_THUOC] = @Tong_Tien_Thuoc 
			, [T_VTYT] = @T_VTYT
			, [T_TONGCHI_BV] = @Tong_Chi
			, [T_TONGCHI_BH] = @T_ThanhTienBH
			, [T_BNTT] = @Tong_Chi -  @T_ThanhTienBH
			, [T_BNCCT] = @T_BNCCT
			, [T_BHTT] = @T_BHTT
			, [T_NGUONKHAC] = 0
			,[T_BHTT_GDV] = 0
			, [NAM_QT] = null
			, [THANG_QT] = null
			,[MA_LOAI_KCB] =  
										CASE WHEN DATEDIFF(MINUTE, ba.ThoiGianVaoVien, ba.ThoiGianRaVien) < 240 THEN '09'
											 WHEN loaiBA.Dictionary_Name_En = N'Nội ngày' THEN '04' 
											 ELSE '03' 
										END
			, [MA_KHOA] = pb.MaTheoQuiDinh
			, [MA_CSKCB] = @MaCSKCB
			,[MA_KHUVUC] = CHIPHI.NoiSinhSong
			,[CAN_NANG] = cast(COALESCE(NULLIF(
			--bact.CanNang
			CASE 
                WHEN ISNUMERIC(REPLACE(bact.CanNang, '.', ',')) = 1 
                THEN TRY_CAST(REPLACE(bact.CanNang, '.', ',') AS DECIMAL(18,2))
                ELSE TRY_CAST(bact.CanNang AS DECIMAL(18,2))
            END
			, 0), NULLIF(kbvv.CanNang, 0), 50) as decimal(18,2)) --cast (isnull(bact.CanNang,50) as decimal(18,2)) 
			,[CAN_NANG_CON] = [dbo].[Get_CanNangCon_ByBenhAn_id] (@BenhAn_Id)
			,[NAM_NAM_LIEN_TUC] = NULL
			,[NGAY_TAI_KHAM] = FORMAT(ba.NgayHenTaiKham,'yyyyMMdd')
			,[MA_HSBA] = @Ma_Lk
			,[MA_TTDV] = '2096091139'
			,[DU_PHONG] = NULL


		from 
		(
			select	XN.TiepNhan_Id
					, XN.BenhNhan_Id
					, XN.Benhan_Id
					, SoBHYTBD =  TN.SoBHYT
					, TUNGAY = tn.BHYTTuNgay
					, DENNGAY = tn.BHYTDenNgay
					, SoBHYT = RTRIM(LTRIM(ISNULL((SELECT SoBH 
													FROM (SELECT TOP 1 UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(Attribute1)), 0, 16), '')) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = @TiepNhan_ID And ISNULL(Attribute1,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(SoBH)), '')
									)) + UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(TN.SoBHYT)), 0, 16), '')) 
					, MAKCBBD = RTRIM(LTRIM(ISNULL((SELECT SoBH 
													FROM (SELECT TOP 1 UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(Attribute1)), 16, 20), '')) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute1,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(SoBH)), '')
									)) + UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(TN.SoBHYT)), 16, 20), ''))  
					, BHYTTuNgay =  RTRIM(LTRIM(ISNULL((SELECT TuNgay 
													FROM (SELECT TOP 1 convert(VARCHAR, Attribute5, 112) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute5,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(TuNgay)), '')
									)) + convert(VARCHAR, tn.BHYTTuNgay, 112)	
					, BHYTDenNgay =RTRIM(LTRIM(ISNULL((SELECT DenNgay 
													FROM (SELECT top 1 convert(VARCHAR, Attribute6, 112) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute6,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(DenNgay)), '')
									)) + convert(VARCHAR, tn.BHYTDenNgay, 112)	
					, NgayHuongMienCT = CONVERT(Varchar, tn.NgayHuongMienCT, 112)	
					, tn.LyDoTiepNhan_Id
					, BV.TenBenhVien
					, BV.TenBenhVien_En MaBenhVien
					, TuyenKB = TuyenKB.Dictionary_Name
					, Lydo= lst.Dictionary_Code
					, LyDoMa = lst.Dictionary_Name_En
					, XN.NgayVao
					, XN.NgayRa
					, XN.NgayKham
					, MaBenh	=	@ICD_CHINH + ';' + @ICD_PHU 				
					, xn.TenPhongKham
					, TuyenKB.Dictionary_Code
					, ngt.TenBenhVien_En AS MaBenhVienGT
					, dt.TyLe_2
					, ThoiGianXacNhan = null
					, NoiSinhSong = ISNULL(NSS.Dictionary_Code, '')
				
					, tn.sochuyenvien
					, tn.LyDoVaoVien
			from	(
						select top 1
							TiepNhan_Id = ba.TiepNhan_Id,
							BenhNhan_Id = ba.BenhNhan_Id,
							BenhAn_Id = ba.BenhAn_Id,
							NgayVao = ba.NgayVaoVien,
							NgayRa = null,
							NgayKham = null,
							TenPhongKham = pb.TenPhongBan,
							ChanDoan = lt.ChanDoanRaKhoa
						from BenhAn ba 
						left join TiepNhan tn (nolock) on tn.TiepNhan_Id = ba.TiepNhan_Id
						join NoiTru_LuuTru lt (nolock) on ba.BenhAn_Id = lt.BenhAn_Id
						join DM_PhongBan pb (nolock) on lt.PhongBan_Id = pb.PhongBan_Id
						left join DM_ICD icd (nolock) on icd.ICD_Id = ba.ICD_BenhPhu
						where lt.ChanDoanRaKhoa is not null and ba.BenhAn_Id = @benhan_id
						order by lt.LuuTru_Id desc
			
					)xn
					
					left join TiepNhan TN (nolock) on TN.TiepNhan_Id = XN.TiepNhan_Id
					LEFT JOIN DM_DoiTuong dt (nolock) on  dt.DoiTuong_Id = tn.DoiTuong_Id
					left join DM_Benhvien BV (nolock) on TN.BenhVien_KCB_Id = BV.BenhVien_Id
					left join DM_BenhVien ngt (nolock) on ngt.BenhVien_Id = TN.NoiGioiThieu_Id
					left join Lst_Dictionary LST (nolock) on LST.Dictionary_Id = TN.LyDoTiepNhan_Id
					Left join Lst_Dictionary TuyenKB (nolock) on TuyenKB.Dictionary_Id = TN.TuyenKhamBenh_ID

					LEFT JOIN Lst_Dictionary NSS (nolock) ON TN.NoiSinhSong_ID = NSS.Dictionary_Id And NSS.Dictionary_Type_Code = 'NoiSinhSong'
					
			Where xn.BenhAn_id = @BenhAn_Id

			
		) CHIPHI
			
			left join DM_BenhNhan bn (nolock) ON ChiPhi.BenhNhan_Id = bn.BenhNhan_Id	
			left join BenhAn ba (nolock) on ba.BenhAn_Id = ChiPhi.BenhAn_Id
			left join BenhAnChiTiet bact (nolock) on ba.BenhAn_Id = bact.BenhAn_Id
			LEFT JOIN Lst_Dictionary  ketquadieutri  (nolock)  ON ketquadieutri.Dictionary_Id = ba.KetQuaDieuTri_Id
			LEFT JOIN	dbo.Lst_Dictionary  lydoxuatvien  (nolock)  ON lydoxuatvien.Dictionary_Id = ba.LyDoXuatVien_Id
			left join DM_PhongBan pb (nolock) on pb.PhongBan_Id = ba.KhoaRa_Id		
			---- lOAI BO BA NGOAI TRU
			LEFT join Lst_Dictionary (nolock) lba on lba.Dictionary_Id = ba.LoaiBenhAn_Id
			left join DM_ICD (nolock) I on ba.ICD_BenhChinh=I.ICD_Id

			LEFT JOIN Lst_Dictionary quoctich (nolock)  ON quoctich.Dictionary_Id = bn.QuocTich_Id
			LEFT JOIN Lst_Dictionary dantoc (nolock)  ON dantoc.Dictionary_Id = bn.DanToc_Id

			LEFT JOIN DM_DonViHanhChinh tinh (nolock) ON tinh.DonViHanhChinh_Id = bn.tinhthanh_id 
			LEFT JOIN DM_DonViHanhChinh huyen (nolock) ON huyen.DonViHanhChinh_Id = bn.quanhuyen_id
			LEFT JOIN DM_DonViHanhChinh xa (nolock) ON xa.DonViHanhChinh_Id = bn.XaPhuong_Id
			LEFT JOIN DM_DonViHanhChinh tinhmoi (nolock) ON tinhmoi.DonViHanhChinh_Id = bn.tinhthanhMoi_id 
			LEFT JOIN DM_DonViHanhChinh xamoi (nolock) ON xamoi.DonViHanhChinh_Id = bn.XaPhuongMoi_Id

			LEFT JOIN Lst_Dictionary nghenghiep (nolock)  ON nghenghiep.Dictionary_Id = bn.NgheNghiep_Id
			LEFT JOIN KhamBenh_VaoVien kbvv (nolock) on kbvv.tiepnhan_id  = ba.tiepnhan_id  and kbvv.KhamBenhVaoVien_Id = (select max(KhamBenhVaoVien_Id) from KhamBenh_VaoVien where TiepNhan_Id = ba.TiepNhan_Id)
			left join DM_BenhVien manoiden (nolock) on manoiden.BenhVien_Id = ba.ChuyenDenBenhVien_Id and manoiden.TamNgung = 0
			left join BenhAn_TreCon te on te.BenhAn_Id = ba.BenhAn_Id
			left join Lst_Dictionary loaiBA on loaiBA.Dictionary_Id = ba.LoaiBenhAn_Id
			left join TiepNhan tn on tn.TiepNhan_Id = ba.TiepNhan_Id
			left join Lst_Dictionary mdt on mdt.Dictionary_Id = tn.MaDoiTuongKCB_Id	
	
) AAAA