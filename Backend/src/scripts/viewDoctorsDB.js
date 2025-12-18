/**
 * Script để xem dữ liệu bác sĩ trong MongoDB
 * Hiển thị thông tin PHAMVI_CM và các thông tin khác
 */

const mongoose = require('mongoose');
const Doctor = require('../Repos/Models/Doctor');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/GiamDinhBHYT';

async function viewDoctorsDB() {
    try {
        console.log('🔌 Đang kết nối MongoDB...');
        console.log(`   URI: ${MONGO_URI}`);
        
        await mongoose.connect(MONGO_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        
        console.log('✅ Đã kết nối MongoDB thành công!\n');
        
        // Lấy tên database
        const dbName = mongoose.connection.db.databaseName;
        console.log(`📊 Database: ${dbName}`);
        console.log(`📁 Collection: doctors\n`);
        
        // Đếm tổng số bác sĩ
        const totalDoctors = await Doctor.countDocuments();
        console.log(`📈 Tổng số bác sĩ trong database: ${totalDoctors}\n`);
        
        // Tìm bác sĩ theo MACCHN (nếu có tham số)
        const macchn = process.argv[2];
        
        if (macchn) {
            console.log(`🔍 Tìm kiếm bác sĩ có MACCHN: ${macchn}\n`);
            const doctor = await Doctor.findOne({ MACCHN: macchn }).lean();
            
            if (!doctor) {
                console.log(`❌ Không tìm thấy bác sĩ với MACCHN: ${macchn}`);
            } else {
                console.log('═══════════════════════════════════════════════════════');
                console.log('📋 THÔNG TIN BÁC SĨ:');
                console.log('═══════════════════════════════════════════════════════');
                console.log(`ID: ${doctor.ID}`);
                console.log(`MACCHN: ${doctor.MACCHN}`);
                console.log(`Họ tên: ${doctor.HO_TEN}`);
                console.log(`Mã BHXH: ${doctor.MA_BHXH}`);
                console.log(`Giới tính: ${doctor.GIOI_TINH === 1 ? 'Nam' : 'Nữ'}`);
                console.log(`Chức danh: ${doctor.CHUCDANH_NN}`);
                console.log(`Vị trí: ${doctor.VI_TRI || 'N/A'}`);
                console.log(`Khoa: ${doctor.TEN_KHOA}`);
                console.log(`Ngày cấp CCHN: ${doctor.NGAYCAP_CCHN}`);
                console.log(`Nơi cấp CCHN: ${doctor.NOICAP_CCHN}`);
                
                console.log('\n═══════════════════════════════════════════════════════');
                console.log('📊 PHAMVI_CM (Phạm vi chuyên môn):');
                console.log('═══════════════════════════════════════════════════════');
                console.log(`Giá trị gốc: ${JSON.stringify(doctor.PHAMVI_CM)}`);
                console.log(`Kiểu dữ liệu: ${typeof doctor.PHAMVI_CM}`);
                console.log(`Là array: ${Array.isArray(doctor.PHAMVI_CM)}`);
                
                if (Array.isArray(doctor.PHAMVI_CM)) {
                    console.log(`Số lượng: ${doctor.PHAMVI_CM.length}`);
                    console.log(`Danh sách: [${doctor.PHAMVI_CM.join(', ')}]`);
                    console.log(`Có chứa 108: ${doctor.PHAMVI_CM.includes(108) ? '✅ CÓ' : '❌ KHÔNG'}`);
                    
                    if (doctor.PHAMVI_CM.includes(108)) {
                        const index = doctor.PHAMVI_CM.indexOf(108);
                        console.log(`Vị trí của 108: index ${index}`);
                    }
                } else {
                    console.log(`⚠️  PHAMVI_CM không phải là array!`);
                    console.log(`Giá trị thực tế: ${doctor.PHAMVI_CM}`);
                }
                
                console.log('\n═══════════════════════════════════════════════════════');
                console.log('📄 TOÀN BỘ DỮ LIỆU (JSON):');
                console.log('═══════════════════════════════════════════════════════');
                console.log(JSON.stringify(doctor, null, 2));
            }
        } else {
            // Hiển thị danh sách một số bác sĩ
            console.log('📋 Danh sách 10 bác sĩ đầu tiên:\n');
            const doctors = await Doctor.find().limit(10).lean();
            
            doctors.forEach((doctor, index) => {
                console.log(`\n--- Bác sĩ ${index + 1} ---`);
                console.log(`MACCHN: ${doctor.MACCHN}`);
                console.log(`Họ tên: ${doctor.HO_TEN}`);
                console.log(`PHAMVI_CM: ${JSON.stringify(doctor.PHAMVI_CM)}`);
                console.log(`  - Là array: ${Array.isArray(doctor.PHAMVI_CM)}`);
                if (Array.isArray(doctor.PHAMVI_CM)) {
                    console.log(`  - Số lượng: ${doctor.PHAMVI_CM.length}`);
                    console.log(`  - Danh sách: [${doctor.PHAMVI_CM.join(', ')}]`);
                    console.log(`  - Có chứa 108: ${doctor.PHAMVI_CM.includes(108) ? '✅' : '❌'}`);
                }
            });
            
            // Thống kê PHAMVI_CM
            console.log('\n═══════════════════════════════════════════════════════');
            console.log('📊 THỐNG KÊ PHAMVI_CM:');
            console.log('═══════════════════════════════════════════════════════');
            
            const allDoctors = await Doctor.find().lean();
            const doctorsWith108 = allDoctors.filter(d => 
                Array.isArray(d.PHAMVI_CM) && d.PHAMVI_CM.includes(108)
            );
            
            console.log(`Tổng số bác sĩ: ${allDoctors.length}`);
            console.log(`Bác sĩ có PHAMVI_CM chứa 108: ${doctorsWith108.length} (${((doctorsWith108.length / allDoctors.length) * 100).toFixed(2)}%)`);
            
            // Thống kê các giá trị PHAMVI_CM phổ biến
            const phamViCMCounts = {};
            allDoctors.forEach(d => {
                if (Array.isArray(d.PHAMVI_CM)) {
                    d.PHAMVI_CM.forEach(val => {
                        phamViCMCounts[val] = (phamViCMCounts[val] || 0) + 1;
                    });
                }
            });
            
            console.log('\nCác giá trị PHAMVI_CM phổ biến:');
            const sortedPhamVi = Object.entries(phamViCMCounts)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10);
            
            sortedPhamVi.forEach(([value, count]) => {
                console.log(`  - ${value}: ${count} bác sĩ`);
            });
        }
        
        console.log('\n✅ Hoàn thành!');
        
    } catch (error) {
        console.error('❌ Lỗi:', error.message);
        console.error(error);
    } finally {
        await mongoose.disconnect();
        console.log('\n🔌 Đã ngắt kết nối MongoDB');
        process.exit(0);
    }
}

// Chạy script
viewDoctorsDB();

