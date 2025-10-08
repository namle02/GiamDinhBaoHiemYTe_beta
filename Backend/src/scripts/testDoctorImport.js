const DoctorServices = require('../Services/DoctorServices');
const XLSX = require('xlsx');
const path = require('path');

/**
 * Script test để kiểm tra việc import Excel
 */
async function testExcelImport() {
    try {
        console.log('🚀 Bắt đầu test import Excel...');
        
        // Tạo file Excel mẫu để test
        const sampleData = [
            {
                STT: 1,
                MA_LOAI_KCB: 1,
                MA_KHOA: 'K27.2;13.27.1',
                TEN_KHOA: 'Khoa Nội',
                MA_BHXH: 123456789,
                HO_TEN: 'Nguyễn Văn A',
                GIOI_TINH: 1,
                CHUCDANH_NN: 1,
                VI_TRI: 1,
                MACCHN: 'CCHN001',
                NGAYCAP_CCHN: '7/2/2014 0:00',
                NOICAP_CCHN: 'Bộ Y Tế',
                PHAMVI_CM: '116;128',
                PHAMVI_CMBS: 1,
                DVKT_KHAC: '01.0176;01.0185;01.0178',
                VB_PHANCONG: 1,
                THOIGIAN_DK: 1,
                THOIGIAN_NGAY: '0700-1630',
                THOIGIAN_TUAN: 'T2T3T4T5T6',
                CSKCB_KHAC: 'Bệnh viện ABC',
                CSKCB_CGKT: 'Phòng khám XYZ',
                QD_CGKT: 'Quyết định 001',
                TU_NGAY: '20150106',
                DEN_NGAY: '',
                ID: 1
            },
            {
                STT: 2,
                MA_LOAI_KCB: 2,
                MA_KHOA: 'K15.1',
                TEN_KHOA: 'Khoa Ngoại',
                MA_BHXH: 987654321,
                HO_TEN: 'Trần Thị B',
                GIOI_TINH: 0,
                CHUCDANH_NN: 2,
                VI_TRI: 2,
                MACCHN: 'CCHN002',
                NGAYCAP_CCHN: '15/3/2015 0:00',
                NOICAP_CCHN: 'Sở Y Tế',
                PHAMVI_CM: '200;201',
                PHAMVI_CMBS: 2,
                DVKT_KHAC: '02.0235;03.0114',
                VB_PHANCONG: 2,
                THOIGIAN_DK: 2,
                THOIGIAN_NGAY: '0800-1700',
                THOIGIAN_TUAN: 'T2T3T4T5',
                CSKCB_KHAC: 'Bệnh viện DEF',
                CSKCB_CGKT: 'Phòng khám GHI',
                QD_CGKT: 'Quyết định 002',
                TU_NGAY: '20160101',
                DEN_NGAY: '20251231',
                ID: 2
            }
        ];

        // Tạo workbook
        const workbook = XLSX.utils.book_new();
        const worksheet = XLSX.utils.json_to_sheet(sampleData);
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Doctors');

        // Lưu file test
        const testFilePath = path.join(__dirname, 'test_doctors.xlsx');
        XLSX.writeFile(workbook, testFilePath);
        console.log('✅ Đã tạo file test Excel:', testFilePath);

        // Test import
        console.log('📥 Bắt đầu import từ file Excel...');
        const result = await DoctorServices.importDoctorsFromExcel(testFilePath);
        
        console.log('📊 Kết quả import:');
        console.log('- Tổng số dòng:', result.totalRows);
        console.log('- Thành công:', result.successCount);
        console.log('- Lỗi:', result.errorCount);
        
        if (result.errors && result.errors.length > 0) {
            console.log('❌ Chi tiết lỗi:');
            result.errors.forEach(error => {
                console.log(`  Dòng ${error.row}: ${error.errors.join(', ')}`);
            });
        }
        
        if (result.importedDoctors && result.importedDoctors.length > 0) {
            console.log('✅ Doctors đã import:');
            result.importedDoctors.forEach(doctor => {
                console.log(`  - ID: ${doctor.ID}, Tên: ${doctor.HO_TEN}, Mã BHXH: ${doctor.MA_BHXH}`);
            });
        }

        // Test lấy danh sách doctors
        console.log('\n📋 Test lấy danh sách doctors...');
        const doctorsList = await DoctorServices.getDoctors(1, 10);
        if (doctorsList.success) {
            console.log(`✅ Tìm thấy ${doctorsList.data.pagination.totalItems} doctors`);
            doctorsList.data.doctors.forEach(doctor => {
                console.log(`  - ID: ${doctor.ID}, Tên: ${doctor.HO_TEN}, Khoa: ${doctor.TEN_KHOA}`);
            });
        }

        console.log('\n🎉 Test hoàn thành!');

    } catch (error) {
        console.error('❌ Lỗi trong quá trình test:', error.message);
        console.error(error.stack);
    }
}

// Chạy test nếu file được gọi trực tiếp
if (require.main === module) {
    testExcelImport();
}

module.exports = { testExcelImport };
