const RuleService = require('../Services/RuleService');

// Dữ liệu test mẫu
const testPatientData = {
    PatientID: "BN001",
    Xml0: [
        {
            Ma_Lk: "LK001",
            Ma_Dich_Vu: "DV001",
            Ten_Dich_Vu: "Khám tổng quát",
            So_Luong: 1,
            Don_Gia: 100000,
            Thanh_Tien: 100000
        },
        {
            Ma_Lk: "LK002",
            Ma_Dich_Vu: "DV002",
            Ten_Dich_Vu: "Xét nghiệm máu",
            So_Luong: 2,
            Don_Gia: 50000,
            Thanh_Tien: 100000
        }
    ],
    Xml1: [
        {
            Ma_Lk: "LK003",
            Ma_Dich_Vu: "DV003",
            Ten_Dich_Vu: "Chụp X-quang",
            So_Luong: 1,
            Don_Gia: 200000,
            Thanh_Tien: 200000
        }
    ],
    Xml2: [],
    Xml3: [],
    Xml4: [],
    Xml5: [],
    Xml6: [],
    Xml7: [],
    Xml8: [],
    Xml9: [],
    Xml10: [],
    Xml11: [],
    Xml13: [],
    Xml14: [],
    Xml15: []
};

// Dữ liệu test không hợp lệ
const invalidPatientData = {
    PatientID: "", // Trống
    Xml0: [
        {
            Ma_Lk: "LK001",
            Ma_Dich_Vu: "", // Trống
            Ten_Dich_Vu: "",
            So_Luong: -1, // Số âm
            Don_Gia: -100, // Số âm
            Thanh_Tien: 100000
        }
    ],
    Xml1: [],
    Xml2: [],
    Xml3: [],
    Xml4: [],
    Xml5: [],
    Xml6: [],
    Xml7: [],
    Xml8: [],
    Xml9: [],
    Xml10: [],
    Xml11: [],
    Xml13: [],
    Xml14: [],
    Xml15: []
};

async function testValidation() {
    try {
        console.log('=== TEST VALIDATION SYSTEM ===\n');
        
        // Load rules
        console.log('1. Đang load validation rules...');
        await RuleService.loadRules();
        console.log('✅ Load rules thành công\n');
        
        // Test với dữ liệu hợp lệ
        console.log('2. Test với dữ liệu hợp lệ:');
        console.log('PatientID:', testPatientData.PatientID);
        console.log('XML0 records:', testPatientData.Xml0.length);
        console.log('XML1 records:', testPatientData.Xml1.length);
        console.log('');
        
        const validResult = await RuleService.validatePatientData(testPatientData);
        
        console.log('📊 KẾT QUẢ VALIDATION:');
        console.log(`Overall Valid: ${validResult.overallValid ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`Total Rules: ${validResult.totalRules}`);
        console.log(`Active Rules: ${validResult.activeRules}`);
        console.log(`Summary: ${validResult.summary.passed} passed, ${validResult.summary.failed} failed`);
        console.log(`Warnings: ${validResult.summary.warnings}, Errors: ${validResult.summary.errors}`);
        console.log('');
        
        console.log('📋 CHI TIẾT TỪNG RULE:');
        validResult.validationResults.forEach((result, index) => {
            console.log(`${index + 1}. ${result.ruleName} (${result.ruleId}): ${result.isValid ? '✅ PASS' : '❌ FAIL'}`);
            console.log(`   Message: ${result.message}`);
            if (result.errors && result.errors.length > 0) {
                console.log(`   Errors: ${result.errors.join(', ')}`);
            }
            if (result.warnings && result.warnings.length > 0) {
                console.log(`   Warnings: ${result.warnings.join(', ')}`);
            }
            console.log('');
        });
        
        // Test với dữ liệu không hợp lệ
        console.log('3. Test với dữ liệu không hợp lệ:');
        console.log('PatientID:', invalidPatientData.PatientID);
        console.log('XML0 records:', invalidPatientData.Xml0.length);
        console.log('');
        
        const invalidResult = await RuleService.validatePatientData(invalidPatientData);
        
        console.log('📊 KẾT QUẢ VALIDATION:');
        console.log(`Overall Valid: ${invalidResult.overallValid ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`Summary: ${invalidResult.summary.passed} passed, ${invalidResult.summary.failed} failed`);
        console.log(`Warnings: ${invalidResult.summary.warnings}, Errors: ${invalidResult.summary.errors}`);
        console.log('');
        
        console.log('📋 CHI TIẾT TỪNG RULE:');
        invalidResult.validationResults.forEach((result, index) => {
            console.log(`${index + 1}. ${result.ruleName} (${result.ruleId}): ${result.isValid ? '✅ PASS' : '❌ FAIL'}`);
            console.log(`   Message: ${result.message}`);
            if (result.errors && result.errors.length > 0) {
                console.log(`   Errors: ${result.errors.join(', ')}`);
            }
            if (result.warnings && result.warnings.length > 0) {
                console.log(`   Warnings: ${result.warnings.join(', ')}`);
            }
            console.log('');
        });
        
        // Test toggle rule
        console.log('4. Test toggle rule:');
        const rules = RuleService.getAllRules();
        console.log('Danh sách rules:', rules.map(r => `${r.name} (${r.isActive ? 'active' : 'inactive'})`).join(', '));
        
        if (rules.length > 0) {
            const firstRule = rules[0];
            console.log(`Tắt rule: ${firstRule.name}`);
            RuleService.toggleRule(firstRule.name, false);
            
            const updatedRules = RuleService.getAllRules();
            console.log('Rules sau khi tắt:', updatedRules.map(r => `${r.name} (${r.isActive ? 'active' : 'inactive'})`).join(', '));
            
            console.log(`Bật lại rule: ${firstRule.name}`);
            RuleService.toggleRule(firstRule.name, true);
        }
        
        console.log('\n=== TEST HOÀN THÀNH ===');
        
    } catch (error) {
        console.error('❌ Lỗi khi test validation:', error);
    }
}

// Chạy test
testValidation();
