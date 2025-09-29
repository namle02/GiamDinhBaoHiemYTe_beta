const RuleService = require('../Services/RuleService');
const LogService = require('../Services/LogService');

class ValidateController {
    /**
     * Validate patient data với tất cả rules
     */
    async validatePatient(req, res) {
        try {
            await LogService.info('ValidateController', 'Bắt đầu validate patient data', {
                patientId: req.body.PatientID
            }, req);
            
            const validationResult = await RuleService.validatePatientData(req.body);
            
            await LogService.success('ValidateController', 'Validation hoàn thành', {
                patientId: req.body.PatientID,
                overallValid: validationResult.overallValid,
                totalRules: validationResult.totalRules,
                passedRules: validationResult.summary.passed,
                failedRules: validationResult.summary.failed
            }, req);
            
            res.status(200).json({
                success: true,
                message: 'Validation hoàn thành',
                data: validationResult
            });
        } catch (error) {
            await LogService.error('ValidateController', 'Lỗi khi validate patient data', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy danh sách rules
     */
    async getRules(req, res) {
        try {
            const rules = await RuleService.getAllRules();
            
            res.status(200).json({
                success: true,
                message: 'Lấy danh sách rules thành công',
                data: rules
            });
        } catch (error) {
            console.error('Lỗi trong ValidateController.getRules:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Bật/tắt rule
     */
    async toggleRule(req, res) {
        try {
            const { ruleName } = req.params;
            
            // Validate ruleName
            if (!ruleName) {
                await LogService.warn('ValidateController', 'Toggle rule request without ruleName', {}, req);
                return res.status(400).json({
                    success: false,
                    message: 'Rule name là bắt buộc'
                });
            }
            
            // Get isActive from body, default to true if not provided
            const { isActive = true } = req.body || {};
            
            await LogService.info('ValidateController', 'Toggle rule request', {
                ruleName,
                isActive
            }, req);
            
            const success = RuleService.toggleRule(ruleName, isActive);
            
            if (success) {
                await LogService.success('ValidateController', `Rule ${ruleName} toggled successfully`, {
                    ruleName,
                    isActive
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: `Rule ${ruleName} đã được ${isActive ? 'bật' : 'tắt'}`
                });
            } else {
                await LogService.warn('ValidateController', `Rule ${ruleName} not found`, {
                    ruleName
                }, req);
                
                res.status(404).json({
                    success: false,
                    message: `Rule ${ruleName} không tồn tại`
                });
            }
        } catch (error) {
            await LogService.error('ValidateController', 'Lỗi khi toggle rule', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Reload rules
     */
    async reloadRules(req, res) {
        try {
            await RuleService.reloadRules();
            
            res.status(200).json({
                success: true,
                message: 'Reload rules thành công'
            });
        } catch (error) {
            console.error('Lỗi trong ValidateController.reloadRules:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy thông tin rule cụ thể
     */
    async getRuleInfo(req, res) {
        try {
            const { ruleName } = req.params;
            const ruleInfo = RuleService.getRuleInfo(ruleName);
            
            if (ruleInfo) {
                res.status(200).json({
                    success: true,
                    message: 'Lấy thông tin rule thành công',
                    data: {
                        name: ruleInfo.name,
                        file: ruleInfo.file,
                        isActive: ruleInfo.isActive
                    }
                });
            } else {
                res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy rule'
                });
            }
        } catch (error) {
            console.error('Lỗi trong ValidateController.getRuleInfo:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Validate với rule cụ thể
     */
    async validateWithRule(req, res) {
        try {
            const { ruleName } = req.params;
            const ruleInfo = RuleService.getRuleInfo(ruleName);
            
            if (!ruleInfo) {
                return res.status(404).json({
                    success: false,
                    message: 'Không tìm thấy rule'
                });
            }

            if (!ruleInfo.isActive) {
                return res.status(400).json({
                    success: false,
                    message: 'Rule đang bị tắt'
                });
            }

            console.log(`Đang chạy rule: ${ruleName}`);
            const result = ruleInfo.function(req.body);
            
            // Đảm bảo result có đúng format
            if (!result || typeof result !== 'object') {
                return res.status(500).json({
                    success: false,
                    message: 'Rule trả về kết quả không hợp lệ'
                });
            }
            
            // Thêm thông tin rule vào result
            result.ruleName = result.ruleName || ruleName;
            result.ruleId = result.ruleId || `RULE_${ruleName.toUpperCase()}`;
            
            res.status(200).json({
                success: true,
                message: 'Validation với rule cụ thể hoàn thành',
                data: result
            });
        } catch (error) {
            console.error('Lỗi trong ValidateController.validateWithRule:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Validate với nhiều rules cụ thể
     */
    async validateWithMultipleRules(req, res) {
        try {
            const { ruleNames } = req.body;
            
            if (!ruleNames || !Array.isArray(ruleNames)) {
                return res.status(400).json({
                    success: false,
                    message: 'ruleNames phải là một mảng'
                });
            }
            
            const results = [];
            let overallValid = true;
            
            for (const ruleName of ruleNames) {
                const ruleInfo = RuleService.getRuleInfo(ruleName);
                
                if (!ruleInfo) {
                    results.push({
                        success: false,
                        message: `Không tìm thấy rule: ${ruleName}`
                    });
                    overallValid = false;
                    continue;
                }

                if (!ruleInfo.isActive) {
                    results.push({
                        success: false,
                        message: `Rule ${ruleName} đang bị tắt`
                    });
                    overallValid = false;
                    continue;
                }

                try {
                    const result = ruleInfo.function(req.body.patientData);
                    
                    if (!result || typeof result !== 'object') {
                        results.push({
                            success: false,
                            message: `Rule ${ruleName} trả về kết quả không hợp lệ`
                        });
                        overallValid = false;
                        continue;
                    }
                    
                    result.ruleName = result.ruleName || ruleName;
                    result.ruleId = result.ruleId || `RULE_${ruleName.toUpperCase()}`;
                    
                    results.push({
                        success: true,
                        message: `Rule ${ruleName} validation hoàn thành`,
                        data: result
                    });
                    
                    if (!result.isValid) {
                        overallValid = false;
                    }
                } catch (error) {
                    results.push({
                        success: false,
                        message: `Lỗi khi chạy rule ${ruleName}: ${error.message}`
                    });
                    overallValid = false;
                }
            }
            
            res.status(200).json({
                success: true,
                message: 'Validation với multiple rules hoàn thành',
                data: {
                    overallValid: overallValid,
                    results: results
                }
            });
        } catch (error) {
            console.error('Lỗi trong ValidateController.validateWithMultipleRules:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }
}

module.exports = new ValidateController();
