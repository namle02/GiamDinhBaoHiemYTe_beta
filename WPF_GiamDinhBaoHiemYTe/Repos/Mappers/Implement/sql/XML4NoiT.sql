
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



	select * from (
		SELECT	[ID] = row_number () OVER (ORDER BY (SELECT 1))
	            , [MA_LK] = @Ma_Lk
				, [STT] = row_number () over (order by (select 1))
				, [MA_DICH_VU] = left (isnull(left(isnull(con2.maquidinh,con.MaQuiDinh),12), case when tn.NgayTiepNhan > '20250731' then DV.MaQuiDinh else DV.MaQuiDinhCu end),15)					
				, [MA_CHI_SO] = isnull(isnull(con2.machiso,con.MaChiSo),dv.MaChiSo)
				, [TEN_CHI_SO] = REPLACE(isnull(isnull(con2.tendichvu,con.TenDichVu),dv.TenDichVu), CHAR(0x1F), '')  
								
				, [GIA_TRI] = REPLACE(REPLACE(REPLACE(REPLACE(isnull(ct.ketqua, ''), CHAR(0x1F), ''),'.','.'),'',''),'','')	
				, [MUC_BINH_THUONG] = ct.MucBinhThuong
				,[DON_VI_DO] = isnull(isnull(con2.donvitinh,con.DonViTinh),dv.DonViTinh)			
				, [MO_TA] = left(REPLACE(isnull(SUBSTRING(kq.MoTa_Text, 0, 3999), ''), CHAR(0x1F), ''),1024)
							
				, [KET_LUAN] = kq.ketluaN
										
				,[NGAY_KQ]=CASE WHEN TRIM(ct.KetQua) = 'Dương tính' And isnull(ndv.TenNhomDichVu_Ru,'') = 'XNKSD'  
								THEN ISNULL(replace(convert(varchar , CONVERT(DATETIME,kq.ThoiGianThucHien), 112)+convert(varchar(5), CONVERT(DATETIME,kq.ThoiGianThucHien), 108), ':',''), replace(convert(varchar , yc.NgayGioYeuCau, 112)+convert(varchar(5), yc.NgayGioYeuCau, 108), ':',''))
							ELSE 
								ISNULL(replace(convert(varchar , isnull(kq.ngaykhoadulieu,kq.ThoiGianThucHien), 112)+convert(varchar(5), isnull(kq.ngaykhoadulieu,kq.ThoiGianThucHien), 108), ':',''), replace(convert(varchar , yc.NgayGioYeuCau, 112)+convert(varchar(5), yc.NgayGioYeuCau, 108), ':',''))				
							END	
				,[MA_BS_DOC_KQ] = bsi.SoChungChiHanhNghe

				, [DU_PHONG] = NULL
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
		JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI (nolock) ON LI.Loai_IDRef = xncpct.Loai_IDRef and xncpct.DonGiaHoTroChiTra>0
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
									 WHEN mbc.TenField in  ('NGCK','Giuong','GB','GI') THEN '12'
									 WHEN mbc.TenField = 'VTYT' THEN '10'
									 WHEN mbc.TenField = 'ThuocK' THEN '17'
								ELSE mbc.TenField
						END  as TenField
						FROM	dbo.DM_MauBaoCao mbc
						JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
						WHERE	MauBC = 'BCVP_097'
					) map  ON map.DichVu_Id = xncpct.NoiDung_Id AND LI.PhanNhom = 'DV'
		LEFT JOIN	dbo.BenhAn ba (Nolock) ON ba.BenhAn_Id = @BenhAn_Id
		LEFT JOIN	dbo.TiepNhan tn (Nolock)  ON tn.TiepNhan_Id = ba.TiepNhan_Id
		LEFT JOIN	dbo.DM_PhongBan pb (Nolock)  ON pb.PhongBan_Id = ba.KhoaRa_Id
		left join dbo.DM_DichVu dv (Nolock)  on dv.DichVu_Id = xncpct.NoiDung_Id AND li.PhanNhom = 'DV'
		left join DM_NhomDichVu ndv on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
		left join DM_DIchVU con on con.CapTren_Id = dv.DichVu_ID
		left join DM_DIchVU con2 on con2.CapTren_Id = con.DichVu_ID
		-- lấy thêm ngày yêu cầu CLS
		left join CLSYeuCauChiTiet clsyc  (Nolock) on clsyc.YeuCauChiTiet_Id=xncpct.IDRef
		left join CLSYeuCau yc  (Nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id

		left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
		left join clsketquachitiet ct (nolock) on ct.clsketqua_id = kq.clsketqua_id 
			and ct.DichVU_Id = isnull(isnull(con2.dichvu_id,con.DichVU_ID),dv.DichVU_ID)
		left join vw_NhanVien bsi on bsi.NhanVien_Id = kq.BacSiKetLuan_Id
		left join Lst_Dictionary mm (nolock) on mm.Dictionary_Id = kq.ThietBi_Id and mm.Dictionary_Type_Code = 'NhomThietBi'
		where xncpct.DonGiaHoTro > 0 
			and xncpct.DonGiaHoTroChiTra>0
			AND  map.TenField not in  ('08' ,'16')
			and ndv.LoaiDichVu_Id = 2	
			and ct.ketqua is not null
			and bsi.SoChungChiHanhNghe is not null
	) Xml4
	order by ma_dich_vu