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

	SELECT  
	[MA_LK] = @Ma_Lk	
      ,[STT] = row_number () over (order by (select 1))
      ,[DIEN_BIEN_LS] = dien_bien
      ,[GIAI_DOAN_BENH] = NULL
      ,[HOI_CHAN] = hoi_chan
      ,[PHAU_THUAT] = phau_thuat
      ,[THOI_DIEM_DBLS] = NGAY_YL
      ,[NGUOI_THUC_HIEN] = Ma_Bsi
      ,[DU_PHONG] = NULL
	  
	From 
	( 
		SELECT	DIEN_BIEN = isnull(pt.ICD_TruocPhauThuat_MoTa,isnull(yc.NoiDungChiTiet,YC.Chandoan) ) 
					, HOI_CHAN = null
					, PHAU_THUAT = isnull(pt.CanThiepPhauThuat,' ')	--+ isnull(pt.TrinhTuThucHien_Text,isnull(yc.NoiDungChiTiet,YC.Chandoan))
					, NGAY_YL = replace(convert(varchar , pt.ThoiGianKetThuc, 112)+convert(varchar(5), pt.ThoiGianKetThuc, 108), ':','')
					, Ma_Bsi = dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(pt.BenhAnPhauThuat_Id)
		From	(
					Select	*
					From	XacNhanChiPhi (nolock) 
					Where	TiepNhan_Id = @TiepNhan_Id
						And SoXacNhan IS NOT NULL
				) xn
		left Join	XacNhanChiPhiChiTiet (nolock)  xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
		left JOIN	dbo.VienPhiNoiTru_Loai_IDRef (nolock)  LI ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
		left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xn.TiepNhan_Id
		left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
		left join DM_NhomDichVu  (nolock) ndv on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
		left join CLSYeuCauChiTiet (nolock)  clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
		left join CLSYeuCau yc (nolock)  on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
		join BenhAnPhauThuat  pt (Nolock) on pt.CLSYeuCau_Id=yc.CLSYeuCau_Id
		WHERE	xnct.DonGiaHoTroChiTra > 0
		AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
		and ndv.LoaiDichVu_ID in (3,8)
		union all
		SELECT 
		dien_bien =  case when hc.HoiChan_Id is not null then isnull(hc.TomTat_TienSuBenh +', ','') + isnull(hc.TinhTrang +', ','') + isnull(TomTat_DienBienBenh,'')  else  '' end
		, hoi_chan =case when hc.HoiChan_Id is not null then isnull(hc.ChanDoan +', ','') + isnull(hc.HuongXuTri +', ','') + isnull(ChamSoc,'')   else '' end
		, phau_thuat = ''
		, ngay_yl = case when hc.HoiChan_Id is not null then replace(convert(varchar , hc.ThoiGianHoiChan, 112)+convert(varchar(5),  hc.ThoiGianHoiChan, 108), ':','')   else  '' end
		, Ma_Bsi = nv.SoChungChiHanhNghe
		From	(
					Select	*
					From	XacNhanChiPhi (nolock) 
					Where	TiepNhan_Id = @TiepNhan_Id
						And SoXacNhan IS NOT NULL
				) xn
		left join HoiChan hc (nolock) on hc.BenhAn_Id = xn.TiepNhan_Id
		left join vw_NhanVien nv on nv.NhanVien_Id = hc.BacSi_Id
		WHERE	hc.HoiChan_Id is not null
	) A

end