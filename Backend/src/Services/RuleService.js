const fs = require('fs');
const path = require('path');
const LogService = require('./LogService');
const Logger = require('../Utils/Logger');

class RuleService {
    constructor() {
        this.rules = new Map();
        this.rulesPath = path.join(__dirname, '../Validators/Rules');
    }

    /**
     * Load tất cả rules từ thư mục Rules
     */
    async loadRules() {
        try {
            await LogService.info('RuleService', 'Bắt đầu load validation rules');
            
            // Xóa rules cũ
            this.rules.clear();
            
            // Đọc tất cả files trong thư mục Rules
            const files = fs.readdirSync(this.rulesPath);
            const ruleFiles = files.filter(file => file.endsWith('.js'));
            
            let loadedCount = 0;
            let errorCount = 0;
            
            for (const file of ruleFiles) {
                try {
                    const rulePath = path.join(this.rulesPath, file);

                    // Đọc nội dung file để lấy tên rule (dựa vào comment đầu file hoặc dòng đầu tiên)
                    let ruleDisplayName = '';
                    try {
                        const fileContent = fs.readFileSync(rulePath, 'utf8');
                        // Tìm dòng comment đầu tiên có chứa tên rule (bắt đầu bằng * Rule hoặc // Rule)
                        const match = fileContent.match(/^\s*[*\/]{1,2}\s*Rule\s*\d+\s*:\s*(.+)$/m);
                        if (match && match[1]) {
                            ruleDisplayName = match[1].trim();
                        } else {
                            // Nếu không tìm thấy, lấy dòng comment đầu tiên
                            const firstComment = fileContent.match(/^\s*[*\/]{1,2}\s*(.+)$/m);
                            if (firstComment && firstComment[1]) {
                                ruleDisplayName = firstComment[1].trim();
                            }
                        }
                    } catch (readErr) {
                        // Nếu lỗi khi đọc file, bỏ qua tên hiển thị
                        ruleDisplayName = '';
                    }

                    const ruleFunction = require(rulePath);
                    
                    // Lấy rule name từ function name hoặc file name
                    const ruleName = ruleFunction.name || file.replace('.js', '');
                    
                    this.rules.set(ruleName, {
                        name: ruleName,
                        displayName: ruleDisplayName || ruleName,
                        file: file,
                        function: ruleFunction,
                        isActive: true
                    });
                    
                    loadedCount++;
                    await LogService.info('RuleService', `Loaded rule: ${ruleName}`, { file, displayName: ruleDisplayName });
                } catch (error) {
                    errorCount++;
                    await LogService.error('RuleService', `Lỗi khi load rule ${file}`, error);
                }
            }
            
            await LogService.success('RuleService', `Load validation rules hoàn thành`, {
                loadedCount,
                errorCount,
                totalFiles: ruleFiles.length
            });
        } catch (error) {
            await LogService.error('RuleService', 'Lỗi khi load validation rules', error);
            throw error;
        }
    }

    /**
     * Validate patient data với tất cả rules đang active
     */
    async validatePatientData(patientData) {
        const validationResults = [];
        let overallValid = true;

        console.log(`Bắt đầu validate patient data với ${this.rules.size} rules...`);

        for (const [ruleName, ruleInfo] of this.rules) {
            if (!ruleInfo.isActive) {
                continue;
            }

            try {
               
                const result = await ruleInfo.function(patientData);

                // Đảm bảo result có đúng format
                if (!result || typeof result !== 'object') {
                    console.error(`Rule ${ruleName} trả về kết quả không hợp lệ`);
                    continue;
                }

                // Thêm thông tin rule vào result
                result.ruleName = result.ruleName || ruleName;
                result.ruleId = result.ruleId || `RULE_${ruleName.toUpperCase()}`;

                // Chỉ thêm vào validationResults nếu isValid là false
                if (result.isValid == false) {
                    validationResults.push(result);
                    overallValid = false;
                    console.log(`❌ Rule ${ruleName}: FAIL`);
                } else {
                    console.log(`✅ Rule ${ruleName}: PASS`);
                }
            } catch (error) {
                console.error(`❌ Lỗi khi chạy rule ${ruleName}:`, error.message);

                // Luôn thêm lỗi exception vào validationResults
                validationResults.push({
                    ruleName: ruleName,
                    ruleId: `${ruleName.toUpperCase()}`,
                    isValid: false,
                    message: `Lỗi khi chạy rule: ${error.message}`,
                    errors: [error.message],
                    warnings: []
                });

                overallValid = false;
            }
        }

        return {
            overallValid: overallValid,
            totalRules: this.rules.size,
            activeRules: Array.from(this.rules.values()).filter(rule => rule.isActive).length,
            validationResults: validationResults,
            summary: {
                passed: this.rules.size - validationResults.length,
                failed: validationResults.length,
                warnings: validationResults.reduce((sum, r) => sum + (r.warnings ? r.warnings.length : 0), 0),
                errors: validationResults.reduce((sum, r) => sum + (r.errors ? r.errors.length : 0), 0)
            }
        };
    }

    /**
     * Lấy danh sách tất cả rules
     */
    async getAllRules() {
        await LogService.info('RuleService', 'Bắt đầu lấy danh sách tất cả rules');
        return Array.from(this.rules.values()).map(rule => ({
            Id: rule.name.replace('validate',''),
            Name: rule.displayName,
            file: rule.file,
            isActive: rule.isActive
        }));
    }

    /**
     * Bật/tắt rule
     */
    async toggleRule(ruleName, isActive) {
        try {
            // Validate input
            if (!ruleName || typeof ruleName !== 'string') {
                await LogService.warn('RuleService', 'Tên rule không hợp lệ', { ruleName });
                return false;
            }
            
            if (typeof isActive !== 'boolean') {
                await LogService.warn('RuleService', 'isActive không hợp lệ, mặc định là true', { isActive });
                isActive = true;
            }
            
            if (this.rules.has(ruleName)) {
                this.rules.get(ruleName).isActive = isActive;
                await LogService.info('RuleService', `Rule ${ruleName} đã được ${isActive ? 'bật' : 'tắt'}`);
                return true;
            } else {
                await LogService.warn('RuleService', `Rule ${ruleName} không tồn tại`, { 
                    availableRules: Array.from(this.rules.keys()) 
                });
                return false;
            }
        } catch (error) {
            await LogService.error('RuleService', 'Lỗi khi toggle rule', error);
            return false;
        }
    }

    /**
     * Reload rules
     */
    async reloadRules() {
        console.log('Đang reload validation rules...');
        await this.loadRules();
        console.log('Reload validation rules thành công');
    }

    /**
     * Lấy thông tin rule cụ thể
     */
    getRuleInfo(ruleName) {
        return this.rules.get(ruleName);
    }
}

module.exports = new RuleService();
