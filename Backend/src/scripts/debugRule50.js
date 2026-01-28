/**
 * Script debug để test Rule_Id_50: DVKT chưa nhập mã máy theo quy định
 * 
 * Chạy script: node src/scripts/debugRule50.js
 */

const validateRule_Id_50 = require('../Validators/Rules/Rule_Id_50');

// ============================================
// TEST CASE 1: Dịch vụ có Ma_May = null
// ============================================
const testCase1 = {
    PatientID: "BN001",
    Xml2: [],
    Xml3: [
        {
            id: 1,
            Ma_Dich_Vu: "02.1896", // Có trong danh sách cần check
            Ma_May: null, // ❌ Lỗi: null
            Ten_Dich_Vu: "Chụp X-quang ngực"
        },
        {
            id: 2,
            Ma_Dich_Vu: "01.0002.1778", // Có trong danh sách cần check
            Ma_May: null, // ❌ Lỗi: null
            Ten_Dich_Vu: "Đặt catheter động mạch"
        }
    ]
};

// ============================================
// TEST CASE 2: Dịch vụ có Ma_May = "KAD"
// ============================================
const testCase2 = {
    PatientID: "BN002",
    Xml2: [],
    Xml3: [
        {
            id: 3,
            Ma_Dich_Vu: "03.1896", // Có trong danh sách cần check
            Ma_May: "KAD", // ❌ Lỗi: "KAD"
            Ten_Dich_Vu: "Chụp CT scan"
        },
        {
            id: 4,
            Ma_Dich_Vu: "05.1896", // Có trong danh sách cần check
            Ma_May: "kad", // ❌ Lỗi: "kad" (case-insensitive)
            Ten_Dich_Vu: "Chụp MRI"
        },
        {
            id: 5,
            Ma_Dich_Vu: "07.1896", // Có trong danh sách cần check
            Ma_May: "  KAD  ", // ❌ Lỗi: "KAD" với spaces
            Ten_Dich_Vu: "Siêu âm"
        }
    ]
};

// ============================================
// TEST CASE 3: Dịch vụ có Ma_May = "" (rỗng)
// ============================================
const testCase3 = {
    PatientID: "BN003",
    Xml2: [],
    Xml3: [
        {
            id: 6,
            Ma_Dich_Vu: "08.1896", // Có trong danh sách cần check
            Ma_May: "", // ❌ Lỗi: rỗng
            Ten_Dich_Vu: "Nội soi"
        },
        {
            id: 7,
            Ma_Dich_Vu: "10.1896", // Có trong danh sách cần check
            Ma_May: "   ", // ❌ Lỗi: chỉ có spaces
            Ten_Dich_Vu: "Xét nghiệm"
        }
    ]
};

// ============================================
// TEST CASE 4: Dịch vụ có Ma_May hợp lệ
// ============================================
const testCase4 = {
    PatientID: "BN004",
    Xml2: [],
    Xml3: [
        {
            id: 8,
            Ma_Dich_Vu: "12.1896", // Có trong danh sách cần check
            Ma_May: "M001", // ✅ Hợp lệ
            Ten_Dich_Vu: "Chụp X-quang"
        },
        {
            id: 9,
            Ma_Dich_Vu: "13.1896", // Có trong danh sách cần check
            Ma_May: "MACHINE-001", // ✅ Hợp lệ
            Ten_Dich_Vu: "Chụp CT"
        },
        {
            id: 10,
            Ma_Dich_Vu: "14.1896", // Có trong danh sách cần check
            Ma_May: "12345", // ✅ Hợp lệ
            Ten_Dich_Vu: "MRI"
        }
    ]
};

// ============================================
// TEST CASE 5: Dịch vụ KHÔNG có trong danh sách cần check
// ============================================
const testCase5 = {
    PatientID: "BN005",
    Xml2: [],
    Xml3: [
        {
            id: 11,
            Ma_Dich_Vu: "99.9999.9999", // ❌ KHÔNG có trong danh sách
            Ma_May: null, // Không cần check vì không trong danh sách
            Ten_Dich_Vu: "Dịch vụ khác"
        },
        {
            id: 12,
            Ma_Dich_Vu: "INVALID_CODE", // ❌ KHÔNG có trong danh sách
            Ma_May: "KAD", // Không cần check vì không trong danh sách
            Ten_Dich_Vu: "Dịch vụ không cần check"
        }
    ]
};

// ============================================
// TEST CASE 6: Mix các trường hợp
// ============================================
const testCase6 = {
    PatientID: "BN006",
    Xml2: [],
    Xml3: [
        {
            id: 13,
            Ma_Dich_Vu: "15.1896", // Có trong danh sách
            Ma_May: null, // ❌ Lỗi
            Ten_Dich_Vu: "Test 1"
        },
        {
            id: 14,
            Ma_Dich_Vu: "16.1896", // Có trong danh sách
            Ma_May: "KAD", // ❌ Lỗi
            Ten_Dich_Vu: "Test 2"
        },
        {
            id: 15,
            Ma_Dich_Vu: "17.1896", // Có trong danh sách
            Ma_May: "VALID001", // ✅ Hợp lệ
            Ten_Dich_Vu: "Test 3"
        },
        {
            id: 16,
            Ma_Dich_Vu: "99.9999", // Không trong danh sách
            Ma_May: null, // Không cần check
            Ten_Dich_Vu: "Test 4"
        }
    ]
};

// ============================================
// TEST CASE 7: Test với các mã đặc biệt (có suffix _GT, _BS, K prefix)
// ============================================
const testCase7 = {
    PatientID: "BN007",
    Xml2: [],
    Xml3: [
        {
            id: 17,
            Ma_Dich_Vu: "03.2264.0669_GT", // Có trong danh sách
            Ma_May: null, // ❌ Lỗi
            Ten_Dich_Vu: "Test _GT"
        },
        {
            id: 18,
            Ma_Dich_Vu: "09.9000.1894_BS", // Có trong danh sách
            Ma_May: "KAD", // ❌ Lỗi
            Ten_Dich_Vu: "Test _BS"
        },
        {
            id: 19,
            Ma_Dich_Vu: "K02.1905", // Có trong danh sách
            Ma_May: "M001", // ✅ Hợp lệ
            Ten_Dich_Vu: "Test K prefix"
        }
    ]
};

// ============================================
// TEST CASE 8: Xml3 rỗng
// ============================================
const testCase8 = {
    PatientID: "BN008",
    Xml2: [],
    Xml3: []
};

// ============================================
// TEST CASE 9: Không có Xml3
// ============================================
const testCase9 = {
    PatientID: "BN009",
    Xml2: []
};

// ============================================
// Hàm chạy test
// ============================================
async function runTest(testCase, testName) {
    console.log('\n' + '='.repeat(80));
    console.log(`🧪 TEST: ${testName}`);
    console.log('='.repeat(80));
    
    try {
        const result = await validateRule_Id_50(testCase);
        
        console.log(`\n📊 KẾT QUẢ:`);
        console.log(`   Rule Name: ${result.ruleName}`);
        console.log(`   Rule ID: ${result.ruleId}`);
        console.log(`   Is Valid: ${result.isValid ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`   Validate Field: ${result.validateField}`);
        console.log(`   Validate File: ${result.validateFile}`);
        console.log(`   Message: ${result.message || '(không có)'}`);
        
        if (result.errors && result.errors.length > 0) {
            console.log(`\n❌ ERRORS (${result.errors.length}):`);
            result.errors.forEach((error, index) => {
                console.log(`   ${index + 1}. ID: ${error.Id || 'N/A'}`);
                console.log(`      Error: ${error.Error}`);
            });
        } else {
            console.log(`\n✅ KHÔNG CÓ LỖI`);
        }
        
        if (result.warnings && result.warnings.length > 0) {
            console.log(`\n⚠️  WARNINGS (${result.warnings.length}):`);
            result.warnings.forEach((warning, index) => {
                console.log(`   ${index + 1}. ${warning}`);
            });
        }
        
        // Hiển thị dữ liệu test
        console.log(`\n📋 DỮ LIỆU TEST:`);
        console.log(`   PatientID: ${testCase.PatientID}`);
        if (testCase.Xml3 && Array.isArray(testCase.Xml3)) {
            console.log(`   Số lượng dịch vụ (Xml3): ${testCase.Xml3.length}`);
            testCase.Xml3.forEach((dv, index) => {
                console.log(`   ${index + 1}. Ma_Dich_Vu: ${dv.Ma_Dich_Vu || 'N/A'}, Ma_May: ${dv.Ma_May || dv.ma_May || 'null'}`);
            });
        } else {
            console.log(`   Xml3: ${testCase.Xml3 ? 'không phải array' : 'không có'}`);
        }
        
    } catch (error) {
        console.error(`\n❌ LỖI KHI CHẠY TEST: ${error.message}`);
        console.error(error.stack);
    }
}

// ============================================
// Chạy tất cả các test
// ============================================
async function runAllTests() {
    console.log('\n');
    console.log('╔' + '═'.repeat(78) + '╗');
    console.log('║' + ' '.repeat(20) + 'DEBUG RULE_ID_50: DVKT CHƯA NHẬP MÃ MÁY' + ' '.repeat(20) + '║');
    console.log('╚' + '═'.repeat(78) + '╝');
    
    await runTest(testCase1, "Test Case 1: Ma_May = null");
    await runTest(testCase2, "Test Case 2: Ma_May = 'KAD' (case-insensitive)");
    await runTest(testCase3, "Test Case 3: Ma_May = '' (rỗng hoặc spaces)");
    await runTest(testCase4, "Test Case 4: Ma_May hợp lệ");
    await runTest(testCase5, "Test Case 5: Dịch vụ không trong danh sách cần check");
    await runTest(testCase6, "Test Case 6: Mix các trường hợp");
    await runTest(testCase7, "Test Case 7: Mã đặc biệt (_GT, _BS, K prefix)");
    await runTest(testCase8, "Test Case 8: Xml3 rỗng");
    await runTest(testCase9, "Test Case 9: Không có Xml3");
    
    console.log('\n' + '='.repeat(80));
    console.log('✅ HOÀN THÀNH TẤT CẢ CÁC TEST');
    console.log('='.repeat(80) + '\n');
}

// Chạy tests
runAllTests().catch(error => {
    console.error('❌ Lỗi khi chạy tests:', error);
    process.exit(1);
});
