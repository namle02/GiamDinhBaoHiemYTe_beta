# DANH SÁCH TẤT CẢ CÁC BIẾN ĐƯỢC SỬ DỤNG ĐỂ ĐỐI CHIẾU LOGIC
## (Từ Rule 1 đến Rule 48)

---

## RULE 1: Vi khuẩn nuôi cấy định danh
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '24.0001.1714', '24.0005.1716', '24.0003.1715')
- `LoaiBenhPham_Id` (nhóm theo loại bệnh phẩm)

---

## RULE 2: Nội soi can thiệp dạ dày tá - tràng
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ nội soi can thiệp)
- `Mo_Ta_Text` (phân tích bằng AI để tìm vùng bị u)

---

## RULE 3: Can thiệp ống tiêu hóa
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ can thiệp)
- `Mo_Ta_Text` (phân tích bằng AI để tìm vùng bị u)

---

## RULE 4: Nội soi tán sỏi niệu quản
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '20.0084.0440' và danh sách dịch vụ đặt ống thông)
- `TrinhTuThucHien` (phân tích bằng AI để xác định vị trí tán sỏi và đặt sonde JJ)

---

## RULE 5: HBA1C sai
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '23.0083.1523')
- `Ma_Benh` (kiểm tra có chứa: 'E10', 'E11', 'E12', 'E13', 'E14', 'O24')
- `Ngay_Yl` (ngày y lệnh)
- `Ngay_Kq` (ngày kết quả)
- `Khoang_Cach` (tính từ Ngay_Kq - Ngay_Yl, phải >= 87 ngày)

---

## RULE 6: Bơm thông lệ đạo
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '14.0197.0854', '14.0197.0855')
- `Ma_Benh` (kiểm tra có chứa: 'H04.2', 'H04.3', 'H04.4')

---

## RULE 7: PHCN thoái hóa cột sống
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '17.0011.0237', '17.0018.0221', '17.0004.0232', '17.0023.0272')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- `Ma_Benh` (từ XML3)
- `Ma_Benh_Yhct` (từ XML3)
- `Ngay_Yl` (nhóm theo ngày để kiểm tra trùng)

---

## RULE 8: Nội soi có sinh thiết
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ nội soi có sinh thiết)
- `Ma_Dich_Vu` (kiểm tra có dịch vụ đầu '25.xxxx.xxxx' - giải phẫu mô bệnh học)

---

## RULE 9: PHCN với ung thư
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '17.0007.0234', '17.0004.0232')
- `Ma_Benh` (kiểm tra có chứa mã từ 'C00' đến 'C97')

---

## RULE 10: Sinh thiết tức thì bằng cắt lạnh
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '25.0090.1757')
- `Ma_Nhom` (so sánh với: 8)
- `Ngay_Th_Yl` (ngày thực hiện y lệnh)
- `Ngay_Kq` (ngày kết quả)
- Khoảng thời gian giao nhau giữa dịch vụ 1757 và dịch vụ nhóm 8

---

## RULE 11: Pro-calcitonin
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '23.0130.1549')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- `Ma_Benh` (từ XML3)
- `Ma_Benh_Yhct` (từ XML3)
- `ketQua` (kết quả xét nghiệm)
- `mucBinhThuong` (mức bình thường)
- `Ngay_Th_Yl` / `Ngay_th_yl` (ngày thực hiện y lệnh)
- `Ngay_Kq` / `Ngay_kq` (ngày kết quả)
- Khoảng cách thời gian giữa các lần xét nghiệm (24h hoặc 48h tùy mã bệnh R57.2)

---

## RULE 12: Chọc sinh thiết dưới hướng dẫn siêu âm
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '18.0621.0090', '18.0001.0001')

---

## RULE 13: Chạy thận nhân tạo và thuốc chống đông
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (từ XML3, so sánh với danh sách mã dịch vụ thận nhân tạo)
- `Ma_Thuoc` (từ XML2, so sánh với: '40.443', '40.445')
- `Ngay_Yl` (từ XML3 và XML2, so sánh cùng ngày)

---

## RULE 14: Thay băng vết mổ mổ lấy thai
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '15.0303.2047')
- Số lượng dịch vụ (chỉ cho phép <= 3 lần)

---

## RULE 15: Dịch vụ kỹ thuật trong điều trị nội trú
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ kỹ thuật)
- `Ma_Loai_Kcb` (từ XML1, so sánh với: '1', '2')

---

## RULE 16: Vật lý trị liệu vượt quá số lượng
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ vật lý trị liệu)
- `Ngay_Yl` (nhóm theo ngày, đếm số lượng dịch vụ/ngày, tối đa 4)

---

## RULE 17: Xét nghiệm AFB
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '24.0017.1714')
- `Ngay_Yl` (nhóm theo ngày)
- `LoaiBenhPham_Id` (kiểm tra loại bệnh phẩm, tối đa 2 lần/ngày)

---

## RULE 18: Phẫu thuật cắt tử cung và phần phụ
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách dịch vụ chính và dịch vụ phụ)

---

## RULE 19: Siêu âm hệ tiết niệu/tử cung với siêu âm ổ bụng
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '18.0015.0001', '18.0016.0001')

---

## RULE 20: Oxy với dịch vụ thở máy
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (từ XML3, so sánh với danh sách mã dịch vụ thở máy)
- `Ma_Thuoc` (từ XML2, so sánh với: '40.17')
- `Ngay_Th_Yl` (ngày thực hiện y lệnh)
- `Ngay_Kq` (ngày kết quả)
- `Ngay_Yl` (ngày y lệnh thuốc)
- Khoảng thời gian giao nhau

---

## RULE 21: Số ngày giường điều trị nội trú
**Các biến đối chiếu:**
- `So_Ngay_Dtri` (từ XML1)
- `Ma_Nhom` (từ XML3, so sánh với: '15')
- `Ngay_Yl` (từ XML3, tính số ngày giường)

---

## RULE 22: Tiền khám bệnh tại khoa cấp cứu
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ giường và khám bệnh)

---

## RULE 23: Hồng cầu lưới và Huyết đồ
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '22.0605.1299', '22.0134.1296')

---

## RULE 24: Thủy châm - chức danh chuyên môn
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ thủy châm)
- `Nguoi_Thuc_Hien` (mã bác sĩ thực hiện)
- `PHAMVI_CM` (từ bảng Doctor, phải chứa: 108)

---

## RULE 25: Giường điều trị nội trú ban ngày YHCT
**Các biến đối chiếu:**
- `Ten_Dich_Vu` (kiểm tra chứa: 'ngày giường ban ngày nội khoa')
- `Ma_Khoa` (so sánh với danh sách mã khoa YHCT hợp lệ)

---

## RULE 26: Thuốc Peptid
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.563')
- `Ma_Benh` (kiểm tra có chứa: 'I63', 'I64', 'S06', 'Z48')

---

## RULE 27: Moxifloxacin
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.231')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- `Ngay_Sinh` / `ngay_sinh` (từ XML1, tính tuổi)
- Tuổi (phải >= 18, trừ trường hợp trẻ em mắc lao A15-A19)
- Mã bệnh (kiểm tra có thuộc nhóm O00-O99)

---

## RULE 28: Alphachymotrypsin
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.67')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- Mã bệnh (kiểm tra theo các khoảng: J00-J06, J20, T14.x, S00-S09, S10-S19, S40-S49, S50-S59, S60-S69, S70-S79, S80-S89, S90-S99)

---

## RULE 29: Sylimarin
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.751')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- Mã bệnh (kiểm tra: B18.0, B18.1, B18.2, B18.8, K76.0, K76.9, K71.x, K74.x)

---

## RULE 30: Omeprazol, Esomeprazol, Pantoprazol, Rabeprazol
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.677', '40.678', '40.679', '40.680')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- `Ma_Benh_Yhct` (từ XML1)
- Mã bệnh (kiểm tra: K25.x, K26.x, K27.x, K28.x, K21.x, E16.4, K20.x)

---

## RULE 31: Hirzt và Blondeau
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '18.0072.0028', '18.0073.0028')

---

## RULE 33: Phẫu thuật cắt dạ dày/đại tràng và nạo vét hạch
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ cắt dạ dày, cắt đại tràng, nạo vét hạch)

---

## RULE 34: Tỷ lệ thanh toán PT thứ 2
**Các biến đối chiếu:**
- `Ma_Nhom` (so sánh với: 8)
- `Ma_Pttt_Qt` (phải khác null)
- `Ngay_Th_Yl` (ngày thực hiện y lệnh)
- `Ngay_Kq` (ngày kết quả)
- `Tyle_Tt_Dv` (tỷ lệ thanh toán dịch vụ, so sánh với: 100)
- Khoảng thời gian giao nhau giữa các dịch vụ phẫu thuật

---

## RULE 35: BS chỉ định thuốc ung thư
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với danh sách mã thuốc ung thư)
- `MA_BAC_SI` (mã bác sĩ chỉ định)
- `PHAMVI_CM` (từ bảng Doctor, phải chứa: 112)

---

## RULE 36: Điều dưỡng đại học chỉ định dịch vụ
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ có sao)
- `Nguoi_Thuc_Hien` (mã người thực hiện)
- `PHAMVI_CM` (từ bảng Doctor, kiểm tra có chứa: 302)

---

## RULE 37: Điều dưỡng chỉ định thuốc
**Các biến đối chiếu:**
- `Chucdanh_id` (so sánh với: 7232, 7362)

---

## RULE 38: Điều dưỡng chỉ định sai dịch vụ
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ sai)
- `Chucdanh_id` (so sánh với: 7232, 7362)

---

## RULE 40: Azithromycin quá liều
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.219')
- `Ngay_Yl` (nhóm theo ngày)
- `Ham_Luong` (hàm lượng thuốc, tính tổng theo ngày)
- Khoảng cách ngày (kiểm tra không được sử dụng liên tiếp 5 ngày)

---

## RULE 42: Glucosamin
**Các biến đối chiếu:**
- `Ma_Thuoc` (so sánh với: '40.64')
- `Ma_Benh_Chinh` (từ XML1)
- `Ma_Benh_Kt` (từ XML1)
- Mã bệnh (kiểm tra có chứa: M17)

---

## RULE 43: Băng gạc
**Các biến đối chiếu:**
- `Ma_Vat_Tu` (so sánh với danh sách mã vật tư băng gạc)
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ thay băng)
- `Ngay_Yl` (so sánh cùng ngày)

---

## RULE 44: Dịch vụ thở máy
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với danh sách mã dịch vụ thở máy)
- `Ngay_Th_Yl` / `Ngay_th_yl` (ngày thực hiện y lệnh)
- `Ngay_Kq` / `Ngay_kq` (ngày kết quả)
- `So_Luong` (số lượng, tính: So_Luong * 24 <= (Ngay_Kq - Ngay_Th_Yl) tính bằng giờ)

---

## RULE 46: Holter điện tâm đồ hoặc lập trình máy tạo nhịp tim
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '02.0095.1798', '02.0100.0069' và danh sách mã dịch vụ điện tim)
- `Ngay_Yl` (so sánh cùng thời điểm)

---

## RULE 47: HbA1c khoảng cách
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (so sánh với: '23.0083.1523')
- `Ngay_Yl` (tính khoảng cách giữa các lần xét nghiệm, phải >= 87 ngày)

---

## RULE 48: Châm, cứu
**Các biến đối chiếu:**
- `Ma_Dich_Vu` (kiểm tra bắt đầu bằng: '08.')
- `Ten_Dich_Vu` (kiểm tra chứa: 'điện châm', 'điện mãng châm', 'điện nhĩ câm', 'thủy câm', 'cứu')
- `Ngay_Th_Yl` / `Ngay_Yl` (nhóm theo ngày, chỉ cho phép 1 lần/ngày)

---

## TỔNG HỢP CÁC BIẾN ĐƯỢC SỬ DỤNG NHIỀU NHẤT:

### Từ XML1:
- `Ma_Benh_Chinh`
- `Ma_Benh_Kt`
- `Ma_Benh_Yhct`
- `Ma_Loai_Kcb`
- `So_Ngay_Dtri`
- `Ngay_Sinh` / `ngay_sinh`

### Từ XML2:
- `Ma_Thuoc`
- `Ma_Benh`
- `Ngay_Yl`
- `Ham_Luong`
- `ketQua`
- `mucBinhThuong`
- `Chucdanh_id`
- `MA_BAC_SI`

### Từ XML3:
- `Ma_Dich_Vu`
- `Ma_Benh`
- `Ma_Benh_Yhct`
- `Ngay_Yl`
- `Ngay_Th_Yl` / `Ngay_th_yl`
- `Ngay_Kq` / `Ngay_kq`
- `LoaiBenhPham_Id`
- `Ma_Nhom`
- `Ma_Khoa`
- `Ten_Dich_Vu`
- `So_Luong`
- `Tyle_Tt_Dv`
- `Nguoi_Thuc_Hien`
- `Ma_Vat_Tu`
- `Ma_Pttt_Qt`
- `TrinhTuThucHien`
- `Mo_Ta_Text`

### Từ bảng Doctor:
- `MACCHN`
- `PHAMVI_CM`
- `MA_BAC_SI`

