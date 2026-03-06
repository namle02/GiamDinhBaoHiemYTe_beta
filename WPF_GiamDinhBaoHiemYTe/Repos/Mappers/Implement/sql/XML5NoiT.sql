SET NOCOUNT ON;

DECLARE @Sobenhan NVARCHAR(20) = N'{IDBenhNhan}'

-- ========== PHẦN 1: Khai báo biến cần thiết ==========
DECLARE @benhan_id NVARCHAR(20)
SELECT	@BenhAn_Id = ba.BenhAn_Id
FROM	dbo.BenhAn ba (nolock) 
INNER jOIN XacNhanChiPhi (nolock) xn on xn.xacnhanchiphi_id=ba.xacnhanchiphi_id
WHERE	ba.SoBenhAn = @SoBenhAn 

declare @Ma_Lk varchar (20) = null
DECLARE @TiepNhan_Id int

SELECT	@Ma_Lk = REPLACE(ba.SoBenhAn,'/','_')
		, @TiepNhan_Id = ba.TiepNhan_Id
FROM	dbo.BenhAn ba (nolock)
WHERE	ba.BenhAn_Id = @BenhAn_Id

-- ========== PHẦN 2: Temp table tính trước số lượng trả thuốc ==========
-- Thay vì quét toàn bộ NoiTru_TraThuocChiTiet mỗi lần, tính trước 1 lần
DROP TABLE IF EXISTS #TraThuocSL;
SELECT ToaThuoc_Id, SUM(SoLuong) AS sltra
INTO #TraThuocSL
FROM NoiTru_TraThuocChiTiet (nolock)
WHERE ToaThuoc_Id IN (
	SELECT nttt.ToaThuoc_Id 
	FROM NoiTru_KhamBenh kb (nolock)
	JOIN NoiTru_ToaThuoc nttt (nolock) ON nttt.KhamBenh_Id = kb.KhamBenh_Id
	WHERE kb.BenhAn_Id = @benhan_id
)
GROUP BY ToaThuoc_Id;

-- ========== PHẦN 3: CTE_XN (SELECT TOP 1) chạy 1 lần thay vì 3 lần ==========
;WITH CTE_XN AS (
	SELECT TOP 1
		TiepNhan_Id = ba.TiepNhan_Id,
		BenhNhan_Id = ba.BenhNhan_Id,
		BenhAn_Id = ba.BenhAn_Id,
		NgayVao = ba.NgayVaoVien,
		NgayRa = null,
		NgayKham = null,
		TenPhongKham = pb.TenPhongBan,
		ChanDoan = isnull(lt.ChanDoanRaKhoa,ba.ChanDoanVaoKhoa),
		BenhKhac = icd.MaICD
	FROM BenhAn ba (nolock)
	LEFT JOIN TiepNhan tn (nolock) ON tn.TiepNhan_Id = ba.TiepNhan_Id
	JOIN NoiTru_LuuTru lt (nolock) ON ba.BenhAn_Id = lt.BenhAn_Id
	JOIN DM_PhongBan pb (nolock) ON lt.PhongBan_Id = pb.PhongBan_Id
	LEFT JOIN DM_ICD icd (nolock) ON icd.ICD_Id = ba.ICD_BenhPhu
	WHERE ba.BenhAn_Id = @benhan_id
	ORDER BY lt.LuuTru_Id DESC
)
-- ========== PHẦN 4: Query chính ==========
SELECT  
[MA_LK] = @Ma_Lk	
      ,[STT] = row_number () over (order by (select 1))
      ,[DIEN_BIEN_LS] = dien_bien
      ,[GIAI_DOAN_BENH] = GiaiDoan
      ,[HOI_CHAN] = hoi_chan
      ,[PHAU_THUAT] = phau_thuat
      ,[THOI_DIEM_DBLS] = ngay_yl
      ,[NGUOI_THUC_HIEN] = Nguoi_TH
      ,[DU_PHONG] = NULL
	  
From 
( 
	-- PHẦN A: Phiếu điều trị (dùng temp table thay subquery)
SELECT	distinct

		dien_bien =  SUBSTRING(dienbien, 1, 2000)
		, hoi_chan = null
		, phau_thuat = null
		, ngay_yl =  replace(convert(varchar , kb.ThoiGianKham, 112)+convert(varchar(5),  kb.ThoiGianKham, 108), ':','') 
		, Nguoi_TH = bsi.SoChungChiHanhNghe
		, GiaiDoan = xn.ChanDoan
From	CTE_XN xn

join NoiTru_KhamBenh (nolock)  kb on kb.BenhAn_Id = xn.BenhAn_Id
left join NoiTru_ToaThuoc nttt (nolock) on nttt.KhamBenh_Id = kb.KhamBenh_Id
join vw_NhanVien (nolock)  bsi on bsi.NhanVien_Id = kb.BasSiKham_Id
LEFT JOIN #TraThuocSL ntttct ON ntttct.ToaThuoc_Id = nttt.ToaThuoc_Id  
where  kb.DienBien is not null
and  REPLACE(REPLACE(kb.dienbien, CHAR(13), ''), CHAR(10), '') <> ''
and kb.DienBien <> ''
AND ((ntttct.sltra!=nttt.SoLuong OR nttt.SoLuong IS NULL OR ntttct.sltra IS NULL) AND ISNULL(HuyToaThuoc, 0) = 0)

union all
	-- PHẦN B: Tường trình phẫu thuật
	-- Tối ưu: bỏ xncpct UNION ALL vì ndv.LoaiDichVu_Id in (3,8) CHỈ match DichVu (Loai_IDRef='A')
	-- => ChungTuXuatBenhNhan (thuốc/VTYT) luôn bị drop bởi filter này, nên bỏ đi an toàn
SELECT	distinct

		dien_bien =   left(isnull(pt.ICD_TruocPhauThuat_MoTa,isnull(yc.NoiDungChiTiet,YC.Chandoan) ) ,2000)
		, hoi_chan = null
		, phau_thuat = isnull(pt.CanThiepPhauThuat,' ')	+ isnull(yc.NoiDungChiTiet,'')
		, ngay_yl =  replace(convert(varchar , pt.ThoiGianKetThuc, 112)+convert(varchar(5), pt.ThoiGianKetThuc, 108), ':','') 
		, Nguoi_TH =  bscls.SoChungChiHanhNghe + (dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(pt.BenhAnPhauThuat_Id))
		, GiaiDoan = xn.ChanDoan
From	CTE_XN xn
left join (
		-- Chỉ lấy CLSYeuCauChiTiet (Loai_IDRef = 'A'), bỏ ChungTuXuatBenhNhan
		SELECT 
			Loai_IDRef = 'A',
			IDRef = ycct.YeuCauChiTiet_Id,
			NoiDung_Id = ycct.DichVu_Id,
			SoLuong = ycct.SoLuong,
			DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(ycct.DonGiaHoTro as varchar(20))) > 0 
								THEN CAST(REPLACE(CAST(ycct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
						ELSE CAST(ycct.DonGiaHoTro as Decimal(18, 3)) END,
			DonGiaHoTroChiTra = ycct.DonGiaHoTroChiTra,
			BenhAn_Id = @benhan_id,
			TiepNhan_Id = @tiepnhan_id

		FROM CLSYeuCauChiTiet ycct (Nolock)
		JOIN CLSYeuCau yc_inner (Nolock) ON ycct.CLSYeuCau_Id = yc_inner.CLSYeuCau_Id
		WHERE yc_inner.BenhAn_Id = @benhan_id

			) xncpct On xncpct.BenhAn_Id = xn.BenhAn_Id and xncpct.DonGiaHoTroChiTra>0
JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI (nolock) ON LI.Loai_IDRef = xncpct.Loai_IDRef
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
				FROM	dbo.DM_MauBaoCao mbc (nolock)
				JOIN	dbo.DM_DinhNghiaDichVu dndv (nolock) ON dndv.NhomBaoCao_Id = mbc.ID
				WHERE	MauBC = 'BCVP_097'
			) map  ON map.DichVu_Id = xncpct.NoiDung_Id AND LI.PhanNhom = 'DV'
LEFT JOIN	dbo.BenhAn ba (Nolock) ON ba.BenhAn_Id = @BenhAn_Id
LEFT JOIN	dbo.TiepNhan tn (Nolock)  ON tn.TiepNhan_Id = ba.TiepNhan_Id
left join dbo.DM_DichVu dv (Nolock)  on dv.DichVu_Id = xncpct.NoiDung_Id AND li.PhanNhom = 'DV'
left join DM_NhomDichVu ndv (nolock) on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
left join DM_DIchVU con (nolock) on con.CapTren_Id = dv.DichVu_ID
left join CLSYeuCauChiTiet clsyc  (Nolock) on clsyc.YeuCauChiTiet_Id=xncpct.IDRef
left join CLSYeuCau yc  (Nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
join BenhAnPhauThuat pt (Nolock) on pt.CLSYeuCau_Id=yc.CLSYeuCau_Id
left join vw_NhanVien bscls  (Nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id

where xncpct.DonGiaHoTro > 0 
	and xncpct.DonGiaHoTroChiTra > 0
	and ndv.LoaiDichVu_Id in (3,8)
	
union all 
	-- PHẦN C: Biên bản hội chẩn
SELECT	distinct

dien_bien =  left(
N'Tóm tắt tiền sử bệnh: ' +	isnull(hc.TomTat_TienSuBenh,'') 
+ N', tình trang: '+ isnull(hc.TinhTrang ,'') 
+ N', tóm tắt diễn biến bệnh: ' + isnull(TomTat_DienBienBenh,'')
,2000)
, hoi_chan = 
N'Chẩn đoán: '+ isnull(hc.ChanDoan,'') 
+ N', Hướng Xử Lý:' + isnull(hc.HuongXuTri , '') 
+ N', Chăm Sóc: ' + isnull(hc.ChamSoc,'')
, phau_thuat = ''
, ngay_yl =replace(convert(varchar , isnull(hc.ThoiGianHoiChan, hc.NgayTao), 112)+convert(varchar(5),  isnull(hc.ThoiGianHoiChan, hc.NgayTao), 108), ':','')
, Nguoi_TH =  dbo.Get_MaBacSi_HoiChan(hc.HoiChan_Id)
, GiaiDoan = xn.ChanDoan
From	CTE_XN xn
join dbo.BenhAn ba (Nolock) ON ba.BenhAn_Id = @BenhAn_Id
 join HoiChan hc (nolock) on hc.BenhAn_Id = ba.BenhAn_Id
where hc.HoiChan_Id is not null
and (hc.ChanDoan is not null or hc.HuongXuTri is not null or hc.ChamSoc is not null)
) A order by THOI_DIEM_DBLS

-- Dọn dẹp
DROP TABLE IF EXISTS #TraThuocSL;
