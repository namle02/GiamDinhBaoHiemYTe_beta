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
    ,[STT] = row_number () over (order by (select 1))
    ,[MA_DICH_VU] = left (isnull(con.MaQuiDinh,case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end) ,15)
    ,[MA_CHI_SO] = isnull(isnull(con.MaChiSo,dv.MaChiSo),'0')
    ,[TEN_CHI_SO] = REPLACE(isnull(con.TenDichVu,dv.TenDichVu), CHAR(0x1F), '') 	
    ,[GIA_TRI] = REPLACE(REPLACE(REPLACE(REPLACE(isnull(ct.ketqua, ''), CHAR(0x1F), ''),'.','.'),'',''),'','')
	,[MUC_BINH_THUONG] = ct.MucBinhThuong
    ,[DON_VI_DO] =  isnull(con.DonViTinh,dv.DonViTinh)
    ,[MO_TA] = MoTa_Text
    ,[KET_LUAN]= kq.ketluaN		
    ,[NGAY_KQ] = ISNULL(replace(convert(varchar , kq.ThoiGianThucHien, 112)+convert(varchar(5), kq.ThoiGianThucHien, 108), ':',''), replace(convert(varchar , yc.NgayGioYeuCau, 112)+convert(varchar(5), yc.NgayGioYeuCau, 108), ':',''))	
    ,[MA_BS_DOC_KQ] =  bsi.SoChungChiHanhNghe
    ,[DU_PHONG] = NULL
	From	(
				Select	*
				From	XacNhanChiPhi  (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id
					And SoXacNhan IS NOT NULL
				--AND		Loai = 'NgoaiTru'
				--	and Ngayxacnhan is not null
						
			) xn
	left Join	XacNhanChiPhiChiTiet (nolock)  xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
	left JOIN	dbo.VienPhiNoiTru_Loai_IDRef (nolock)  LI ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
	LEFT JOIN	(	SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
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
									WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
									WHEN mbc.TenField = 'VTYT' THEN '10'
							ELSE mbc.TenField
					END  as TenField
					,mbc.Ma 
					FROM	dbo.DM_MauBaoCao mbc
					JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
					WHERE	mbc.MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id 
	left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xn.TiepNhan_Id
	left join (
					select  PhongBan_Id = max(PhongBan_Id)
							, kb.TiepNhan_Id
							,kb.BacSiKham_Id
							, kb.ThoiGianKham
					from KhamBenh kb (nolock) 
					left join TiepNhan  (nolock) tn on tn.TiepNhan_Id = kb.TiepNhan_Id 
					group by kb.BenhNhan_Id, kb.TiepNhan_Id, NgayKham,kb.BacSiKham_Id,kb.ThoiGianKham
					) KB on 	kb.TiepNhan_Id = xn.TiepNhan_Id	 and kb.ThoiGianKham IN (SELECT TOP 1 ThoigianKham FROM KhamBenh k1
																					WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )	
				   			
	left join dm_phongban  (nolock) pb on pb.PhongBan_Id = kb.PhongBan_Id
	left JOIN dbo.DM_BenhNhan (nolock)  bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
	left JOIN DM_DoiTuong (nolock)  dt on dt.DoiTuong_Id = tn.DoiTuong_Id
	left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
	left join DM_NhomDichVu  (nolock) ndv on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
	left join DM_DIchVU (nolock)  con on con.CapTren_Id = dv.DichVu_ID
	left join CLSYeuCauChiTiet  (nolock) clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
	left join CLSYeuCau yc  (nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
	left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
	left join clsketquachitiet ct (nolock) on ct.clsketqua_id = kq.clsketqua_id and ct.DichVU_Id = isnull(con.DichVU_ID,dv.DichVU_ID)
	left join Lst_Dictionary mm (nolock) on mm.Dictionary_Id = kq.ThietBi_Id and mm.Dictionary_Type_Code = 'NhomThietBi'
	left join vw_NhanVien bsi on bsi.NhanVien_Id = isnull(kq.BacSiKetLuan_Id,kq.BacSiThucHien_Id)
	WHERE xnct.DonGiaHoTroChiTra > 0 AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0 and ndv.LoaiDichVu_Id = 2
	and ct.ketqua is not null
	and bsi.SoChungChiHanhNghe is not null


end