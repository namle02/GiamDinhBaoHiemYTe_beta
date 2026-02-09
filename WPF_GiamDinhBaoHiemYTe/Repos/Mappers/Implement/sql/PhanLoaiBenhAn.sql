-- Tham số: Ngày vào (@Ngayvao dạng yyyyMMdd), Số vv (@Sovv), Số TN (@Sotn), Số BA (@Soba)
-- Tình huống 1: Nhập MA_BN (@Sovv) và Ngày vào (@Ngayvao) - so khớp NgayVaoKhoa hoặc NgayTiepNhan
-- Tình huống 2: Nhập mã có "TN" ở đầu (@Sotn) - SoTiepNhan
-- Tình huống 3: Nhập mã không có "TN" ở đầu (@Soba) - SoBenhAn

-- Tham số do ứng dụng truyền vào: @Ngayvao (yyyyMMdd), @Sovv, @Sotn, @Soba
SELECT 
    Ma_TN = tn.SoTiepNhan,
    Ma_BA = ba.SoBenhAn,
    Ngay_vao_vien =
        CASE 
            WHEN lba.Dictionary_Name_En = N'Ngoại trú' THEN tn.NgayTiepNhan
            WHEN lba.Dictionary_Name_En IN (N'Nội ngày', N'Nội trú') THEN ba.NgayVaoKhoa
            WHEN lba.Dictionary_Name_En IS NULL THEN tn.NgayTiepNhan
            ELSE tn.NgayTiepNhan
        END,
    LoaiBenhAn =
        CASE 
            WHEN lba.Dictionary_Name_En = N'Ngoại trú' THEN 2
            WHEN lba.Dictionary_Name_En IN (N'Nội ngày', N'Nội trú') THEN 1
            WHEN lba.Dictionary_Name_En IS NULL THEN 2
            ELSE 2
        END
FROM TiepNhan tn
LEFT JOIN BenhAn ba ON tn.TiepNhan_Id = ba.TiepNhan_Id
LEFT JOIN DM_BenhNhan bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
LEFT JOIN Lst_Dictionary lba ON lba.Dictionary_Id = ba.LoaiBenhAn_Id
WHERE
(
    -- Tình huống 1: Nhập MA_BN (Sovv) và Ngày vào (Ngayvao)
    (
        @Sovv IS NOT NULL
        AND bn.Sovaovien = @Sovv
        AND (
            ba.NgayVaoKhoa = SUBSTRING(@Ngayvao, 1, 4) + '-' + SUBSTRING(@Ngayvao, 5, 2) + '-' + SUBSTRING(@Ngayvao, 7, 2)
            OR tn.NgayTiepNhan = SUBSTRING(@Ngayvao, 1, 4) + '-' + SUBSTRING(@Ngayvao, 5, 2) + '-' + SUBSTRING(@Ngayvao, 7, 2)
        )
    )
    OR
    -- Tình huống 2: Nhập mã có "TN" ở đầu (Sotn) - SoTiepNhan
    (
        @Sovv IS NULL
        AND @Sotn IS NOT NULL
        AND tn.SoTiepNhan = @Sotn
    )
    OR
    -- Tình huống 3: Nhập mã không có "TN" ở đầu (Soba) - SoBenhAn
    (
        @Sovv IS NULL
        AND @Sotn IS NULL
        AND @Soba IS NOT NULL
        AND ba.SoBenhAn = @Soba
    )
)
ORDER BY tn.NgayTiepNhan DESC
