using ClosedXML.Excel;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;
using WPF_GiamDinhBaoHiem.ViewModel.PageViewModel;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    
    /// <summary>
    /// Service để export dữ liệu validation ra file Excel
    /// </summary>
    public class ExcelExportService : IExcelExportService
    {
        private readonly IPatientCacheService _patientCacheService;

        public ExcelExportService(IPatientCacheService patientCacheService)
        {
            _patientCacheService = patientCacheService;
        }

        public async Task<bool> ExportValidationResultsToExcelAsync(
            List<PatientValidationResult> validationResults, 
            string filePath, 
            bool includeErrorDetailsOnly = false)
        {
            return await Task.Run(() =>
            {
                try
                {
                    using var workbook = new XLWorkbook();
                    
                    // Tạo Sheet 1: Tổng Quan
                    var summarySheet = workbook.Worksheets.Add("Tổng Quan");
                    CreateSummarySheet(summarySheet, validationResults);
                    
                    // Tạo các sheet động theo từng loại lỗi
                    CreateErrorSheets(workbook, validationResults);
                    
                    workbook.SaveAs(filePath);
                    
                    return true;
                }
                catch (Exception ex)
                {
                    return false;
                }
            });
        }

        public async Task<bool> ExportDetailedReportToExcelAsync(
            List<PatientValidationResult> validationResults,
            string filePath)
        {
            // Sử dụng cùng logic với ExportValidationResultsToExcelAsync
            return await ExportValidationResultsToExcelAsync(validationResults, filePath, false);
        }

        /// <summary>
        /// Tạo sheet tổng quan với thông tin cơ bản của tất cả bệnh nhân
        /// </summary>
        private void CreateSummarySheet(IXLWorksheet worksheet, List<PatientValidationResult> results)
        {
            // Header row
            var headers = new[] 
            { 
                "STT", "Mã Liên Kết", "Họ Tên", "Giới Tính", "Năm Sinh", 
                "Có Lỗi", "Tổng Số Lỗi", "Danh Sách Lỗi" 
            };
            
            // Tạo header với style
            for (int i = 0; i < headers.Length; i++)
            {
                var cell = worksheet.Cell(1, i + 1);
                cell.Value = headers[i];
                cell.Style.Font.Bold = true;
                cell.Style.Fill.BackgroundColor = XLColor.LightBlue;
                cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            }
            
            // Data rows
            for (int i = 0; i < results.Count; i++)
            {
                var result = results[i];
                var row = i + 2; // Start from row 2
                
                worksheet.Cell(row, 1).Value = i + 1; // STT
                worksheet.Cell(row, 2).Value = result.Ma_Lk;
                worksheet.Cell(row, 3).Value = result.Ho_Ten;
                worksheet.Cell(row, 4).Value = result.Gioi_Tinh;
                worksheet.Cell(row, 5).Value = result.Nam_Sinh;
                worksheet.Cell(row, 6).Value = result.IsError ? "Có" : "Không";
                worksheet.Cell(row, 7).Value = result.IsError ? GetErrorCount(result) : 0;
                worksheet.Cell(row, 8).Value = result.IsError ? GetErrorNames(result) : "Không có lỗi";
                
                // Conditional formatting - màu đỏ cho những dòng có lỗi
                if (result.IsError)
                {
                    worksheet.Row(row).Style.Fill.BackgroundColor = XLColor.LightPink;
                }
                
                // Thêm border cho tất cả cells
                for (int col = 1; col <= headers.Length; col++)
                {
                    worksheet.Cell(row, col).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                }
            }
            
            // Auto-fit columns
            worksheet.ColumnsUsed().AdjustToContents();
        }

        /// <summary>
        /// Tạo các sheet động theo từng loại lỗi
        /// </summary>
        private void CreateErrorSheets(IXLWorkbook workbook, List<PatientValidationResult> results)
        {
            // Lấy tất cả các lỗi từ tất cả bệnh nhân
            var allErrors = new List<(PatientValidationResult patient, ValidationRule rule, errorData error)>();
            
            foreach (var result in results.Where(r => r.IsError))
            {
                foreach (var rule in result.ValidationRules?.Where(r => !r.IsValid) ?? new List<ValidationRule>())
                {
                    foreach (var error in rule.Errors ?? new List<errorData>())
                    {
                        allErrors.Add((result, rule, error));
                    }
                }
            }
            
            if (!allErrors.Any())
            {
                return;
            }
            
            // Group theo RuleName (không phải Message)
            var errorGroups = allErrors.GroupBy(x => x.rule.RuleName)
                                     .OrderBy(g => g.Key);
            
            foreach (var group in errorGroups)
            {
                var ruleName = group.Key;
                var sheetName = SanitizeSheetName(ruleName);
                
                var worksheet = workbook.Worksheets.Add(sheetName);
                CreateErrorSheet(worksheet, group.ToList(), ruleName);
            }
        }
        
        /// <summary>
        /// Tạo một sheet cho một loại lỗi cụ thể (theo RuleName)
        /// </summary>
        private void CreateErrorSheet(IXLWorksheet worksheet, List<(PatientValidationResult patient, ValidationRule rule, errorData error)> errors, string ruleName)
        {
            if (!errors.Any())
                return;

            // Lấy validateFile từ rule đầu tiên (vì cùng RuleName thì validateFile sẽ giống nhau)
            var firstRule = errors.First().rule;
            var validateFile = firstRule.ValidateFile;

            // Tạo header dựa trên validateFile (XML1, XML2, XML3, etc.)
            var headers = CreateHeadersForValidateFile(validateFile);
            
            // Tạo header với style
            for (int i = 0; i < headers.Count; i++)
            {
                var cell = worksheet.Cell(1, i + 1);
                cell.Value = headers[i];
                cell.Style.Font.Bold = true;
                cell.Style.Fill.BackgroundColor = XLColor.LightCoral;
                cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            }
            
            // Data rows
            for (int i = 0; i < errors.Count; i++)
            {
                var (patient, rule, error) = errors[i];
                var row = i + 2; // Start from row 2
                
                // Lấy dữ liệu XML tương ứng với validateFile
                var xmlData = GetXmlDataByValidateFile(patient.Ma_Lk, validateFile, error.Id); // SỬA: Đổi tên hàm và tham số
                
                // Điền dữ liệu vào các cột
                FillRowData(worksheet, row, headers, patient, xmlData, error.Id);
                
                // Thêm border cho tất cả cells
                for (int col = 1; col <= headers.Count; col++)
                {
                    worksheet.Cell(row, col).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                }
            }
            
            worksheet.ColumnsUsed().AdjustToContents();
        }

        /// <summary>
        /// Tạo header dựa trên validateFile (XML1, XML2, XML3, etc.)
        /// </summary>
        private List<string> CreateHeadersForValidateFile(string validateFile)
        {
            var headers = new List<string>
            {
                "STT", "Ma_Lk", "Ho_Ten", "Gioi_Tinh", "Nam_Sinh", "ID_Loi"
            };

            // Nếu validateFile null hoặc empty, return headers cơ bản
            if (string.IsNullOrWhiteSpace(validateFile))
            {
                return headers;
            }

            var validateFileUpper = validateFile.ToUpper().Trim();

            // Xử lý các biến thể của validateFile
            if (validateFileUpper.Contains("XML2") || validateFileUpper.Contains("XML 2"))
            {
                validateFileUpper = "XML2";
            }
            else if (validateFileUpper.Contains("XML3") || validateFileUpper.Contains("XML 3"))
            {
                validateFileUpper = "XML3";
            }
            else if (validateFileUpper.Contains("XML1") || validateFileUpper.Contains("XML 1"))
            {
                validateFileUpper = "XML1";
            }

            switch (validateFileUpper)
            {
                case "XML2":
                    headers.AddRange(new[]
                    {
                        "Id_XML2", "Ma_Lk_XML2", "STT_XML2", "Ma_Thuoc", "Ma_Pp_CheBien", "Ma_Cskcb_Thuoc", 
                        "Ma_Nhom", "Ten_Thuoc", "Don_Vi_Tinh", "Ham_Luong", "Duong_Dung", "Dang_Bao_Che", 
                        "Lieu_Dung", "Cach_Dung", "So_Dang_Ky", "Tt_Thau", "Pham_Vi", "Tyle_Tt_Bh", 
                        "So_Luong", "Don_Gia", "Thanh_Tien_Bv", "Thanh_Tien_Bh", "T_NguonKhac_Nsnn", 
                        "T_NguonKhac_Vtnn", "T_NguonKhac_Vttn", "T_NguonKhac_Cl", "T_NguonKhac", "Muc_Huong", 
                        "T_Bntt", "T_Bncct", "T_Bhtt", "Ma_Khoa", "Ma_Bac_Si", "Ma_Dich_Vu", "Ngay_Yl",
                        "Ma_Pttt", "Nguon_Ctra", "Vet_Thuong_Tp", "Du_Phong", "Ngay_Th_Yl", "IsError"
                    });
                    break;

                case "XML3":
                    headers.AddRange(new[]
                    {
                        "Id_XML3", "Ma_Lk_XML3", "STT_XML3", "Ma_Dich_Vu", "Ma_Pttt_Qt", "Ma_Vat_Tu", 
                        "Ma_Nhom", "Goi_Vtyt", "Ten_Vat_Tu", "Ten_Dich_Vu", "Ma_Xang_Dau", "Don_Vi_Tinh", 
                        "Pham_Vi", "So_Luong", "Don_Gia_Bv", "Don_Gia_Bh", "Tt_Thau", "Tyle_Tt_Dv", 
                        "Tyle_Tt_Bh", "Thanh_Tien_Bv", "Thanh_Tien_Bh", "T_TranTt", "Muc_Huong", 
                        "T_NguonKhac_Nsnn", "T_NguonKhac_Vtnn", "T_NguonKhac_Vttn", "T_NguonKhac_Cl", 
                        "T_NguonKhac", "T_Bntt", "T_Bncct", "T_Bhtt", "Ma_Khoa", "Ma_Giuong", "Ma_Bac_Si", 
                        "Nguoi_Thuc_Hien", "Ma_Benh", "Ma_Benh_Yhct", "Ngay_Yl", "Ngay_Th_Yl", "IsError",
                        "Ngay_Kq", "Ma_Pttt", "Vet_Thuong_Tp", "Pp_Vo_Cam", "Vi_Tri_Th_Dvkt", "Ma_May", 
                        "Ma_Hieu_Sp", "Tai_Su_Dung", "Du_Phong", "LoaiBenhPham_Id"
                    });
                    break;

                case "XML1":
                    headers.AddRange(new[]
                    {
                        "So_CCCD", "Dia_Chi", "Dien_Thoai", "Ma_The_BHYT", "Ma_Nghe_Nghiep",
                        "Ma_Benh_Chinh", "Ma_Benh_Kt", "Ngay_Vao", "Ngay_Ra", "Ma_Noi_Den",
                        "T_Thuoc", "T_Vtyt", "T_TongChi_Bv"
                    });
                    break;

                default:
                    // Fallback về XML1 nếu không xác định được
                    headers.AddRange(new[]
                    {
                        "So_CCCD", "Dia_Chi", "Dien_Thoai", "Ma_The_BHYT", "Ma_Nghe_Nghiep",
                        "Ma_Benh_Chinh", "Ma_Benh_Kt", "Ngay_Vao", "Ngay_Ra", "Ma_Noi_Den",
                        "T_Thuoc", "T_Vtyt", "T_TongChi_Bv"
                    });
                    break;
            }

            return headers;
        }

        /// <summary>
        /// Lấy dữ liệu XML dựa trên validateFile (XML1, XML2, XML3, etc.) và error ID
        /// </summary>
        private object? GetXmlDataByValidateFile(string maLk, string validateFile, int? errorId)
        {
            var cachedPatient = _patientCacheService.GetCachedPatient(maLk);
            if (cachedPatient?.PatientData == null)
            {
                return null;
            }

            // Normalize validateFile
            var validateFileUpper = string.IsNullOrWhiteSpace(validateFile) ? "" : validateFile.ToUpper().Trim();
            
            // Xử lý các biến thể của validateFile
            if (validateFileUpper.Contains("XML2") || validateFileUpper.Contains("XML 2"))
            {
                validateFileUpper = "XML2";
            }
            else if (validateFileUpper.Contains("XML3") || validateFileUpper.Contains("XML 3"))
            {
                validateFileUpper = "XML3";
            }
            else if (validateFileUpper.Contains("XML1") || validateFileUpper.Contains("XML 1"))
            {
                validateFileUpper = "XML1";
            }

            switch (validateFileUpper)
            {
                case "XML2":
                    var xml2Data = cachedPatient.PatientData.Xml2?.FirstOrDefault(x => x.Id == errorId);
                    if (xml2Data != null)
                    {
                        return xml2Data;
                    }
                    
                    // Fallback: lấy record đầu tiên nếu không tìm thấy theo ID
                    return cachedPatient.PatientData.Xml2?.FirstOrDefault();
                    
                case "XML3":
                    var xml3Data = cachedPatient.PatientData.Xml3?.FirstOrDefault(x => x.Id == errorId);
                    if (xml3Data != null)
                    {
                        return xml3Data;
                    }
                    
                    // Fallback: lấy record đầu tiên nếu không tìm thấy theo ID
                    return cachedPatient.PatientData.Xml3?.FirstOrDefault();
                    
                default:
                    return cachedPatient.PatientData.Xml1?.FirstOrDefault(x => x.Ma_Lk == maLk);
            }
        }

        /// <summary>
        /// Điền dữ liệu vào dòng Excel
        /// </summary>
        private void FillRowData(IXLWorksheet worksheet, int row, List<string> headers, PatientValidationResult patient, object? xmlData, int? errorId)
        {
            // Thông tin cơ bản
            worksheet.Cell(row, 1).Value = row - 1; // STT
            worksheet.Cell(row, 2).Value = patient.Ma_Lk;
            worksheet.Cell(row, 3).Value = patient.Ho_Ten;
            worksheet.Cell(row, 4).Value = patient.Gioi_Tinh;
            worksheet.Cell(row, 5).Value = patient.Nam_Sinh;
            worksheet.Cell(row, 6).Value = errorId?.ToString() ?? "";

            // Thông tin XML dựa trên loại dữ liệu
            if (xmlData is XML2 xml2Data)
            {
                FillXML2Data(worksheet, row, headers, xml2Data);
            }
            else if (xmlData is XML3 xml3Data)
            {
                FillXML3Data(worksheet, row, headers, xml3Data);
            }
            else if (xmlData is XML1 xml1Data)
            {
                FillXML1Data(worksheet, row, headers, xml1Data);
            }
        }

        /// <summary>
        /// Điền dữ liệu XML2
        /// </summary>
        private void FillXML2Data(IXLWorksheet worksheet, int row, List<string> headers, XML2 xml2Data)
        {
            var xml2Fields = new Dictionary<string, object?>
            {
                ["Id_XML2"] = xml2Data.Id,
                ["Ma_Lk_XML2"] = xml2Data.Ma_Lk,
                ["STT_XML2"] = xml2Data.Stt,
                ["Ma_Thuoc"] = xml2Data.Ma_Thuoc,
                ["Ma_Pp_CheBien"] = xml2Data.Ma_Pp_CheBien,
                ["Ma_Cskcb_Thuoc"] = xml2Data.Ma_Cskcb_Thuoc,
                ["Ma_Nhom"] = xml2Data.Ma_Nhom,
                ["Ten_Thuoc"] = xml2Data.Ten_Thuoc,
                ["Don_Vi_Tinh"] = xml2Data.Don_Vi_Tinh,
                ["Ham_Luong"] = xml2Data.Ham_Luong,
                ["Duong_Dung"] = xml2Data.Duong_Dung,
                ["Dang_Bao_Che"] = xml2Data.Dang_Bao_Che,
                ["Lieu_Dung"] = xml2Data.Lieu_Dung,
                ["Cach_Dung"] = xml2Data.Cach_Dung,
                ["So_Dang_Ky"] = xml2Data.So_Dang_Ky,
                ["Tt_Thau"] = xml2Data.Tt_Thau,
                ["Pham_Vi"] = xml2Data.Pham_Vi,
                ["Tyle_Tt_Bh"] = xml2Data.Tyle_Tt_Bh,
                ["So_Luong"] = xml2Data.So_Luong,
                ["Don_Gia"] = xml2Data.Don_Gia,
                ["Thanh_Tien_Bv"] = xml2Data.Thanh_Tien_Bv,
                ["Thanh_Tien_Bh"] = xml2Data.Thanh_Tien_Bh,
                ["T_NguonKhac_Nsnn"] = xml2Data.T_NguonKhac_Nsnn,
                ["T_NguonKhac_Vtnn"] = xml2Data.T_NguonKhac_Vtnn,
                ["T_NguonKhac_Vttn"] = xml2Data.T_NguonKhac_Vttn,
                ["T_NguonKhac_Cl"] = xml2Data.T_NguonKhac_Cl,
                ["T_NguonKhac"] = xml2Data.T_NguonKhac,
                ["Muc_Huong"] = xml2Data.Muc_Huong,
                ["T_Bntt"] = xml2Data.T_Bntt,
                ["T_Bncct"] = xml2Data.T_Bncct,
                ["T_Bhtt"] = xml2Data.T_Bhtt,
                ["Ma_Khoa"] = xml2Data.Ma_Khoa,
                ["Ma_Bac_Si"] = xml2Data.Ma_Bac_Si,
                ["Ma_Dich_Vu"] = xml2Data.Ma_Dich_Vu,
                ["Ngay_Yl"] = xml2Data.Ngay_Yl,
                ["Ma_Pttt"] = xml2Data.Ma_Pttt,
                ["Nguon_Ctra"] = xml2Data.Nguon_Ctra,
                ["Vet_Thuong_Tp"] = xml2Data.Vet_Thuong_Tp,
                ["Du_Phong"] = xml2Data.Du_Phong,
                ["Ngay_Th_Yl"] = xml2Data.Ngay_Th_Yl,
                ["IsError"] = xml2Data.IsError
            };

            FillDataToWorksheet(worksheet, row, headers, xml2Fields);
        }

        /// <summary>
        /// Điền dữ liệu XML3
        /// </summary>
        private void FillXML3Data(IXLWorksheet worksheet, int row, List<string> headers, XML3 xml3Data)
        {
            var xml3Fields = new Dictionary<string, object?>
            {
                ["Id_XML3"] = xml3Data.Id,
                ["Ma_Lk_XML3"] = xml3Data.Ma_Lk,
                ["STT_XML3"] = xml3Data.Stt,
                ["Ma_Dich_Vu"] = xml3Data.Ma_Dich_Vu,
                ["Ma_Pttt_Qt"] = xml3Data.Ma_Pttt_Qt,
                ["Ma_Vat_Tu"] = xml3Data.Ma_Vat_Tu,
                ["Ma_Nhom"] = xml3Data.Ma_Nhom,
                ["Goi_Vtyt"] = xml3Data.Goi_Vtyt,
                ["Ten_Vat_Tu"] = xml3Data.Ten_Vat_Tu,
                ["Ten_Dich_Vu"] = xml3Data.Ten_Dich_Vu,
                ["Ma_Xang_Dau"] = xml3Data.Ma_Xang_Dau,
                ["Don_Vi_Tinh"] = xml3Data.Don_Vi_Tinh,
                ["Pham_Vi"] = xml3Data.Pham_Vi,
                ["So_Luong"] = xml3Data.So_Luong,
                ["Don_Gia_Bv"] = xml3Data.Don_Gia_Bv,
                ["Don_Gia_Bh"] = xml3Data.Don_Gia_Bh,
                ["Tt_Thau"] = xml3Data.Tt_Thau,
                ["Tyle_Tt_Dv"] = xml3Data.Tyle_Tt_Dv,
                ["Tyle_Tt_Bh"] = xml3Data.Tyle_Tt_Bh,
                ["Thanh_Tien_Bv"] = xml3Data.Thanh_Tien_Bv,
                ["Thanh_Tien_Bh"] = xml3Data.Thanh_Tien_Bh,
                ["T_TranTt"] = xml3Data.T_TranTt,
                ["Muc_Huong"] = xml3Data.Muc_Huong,
                ["T_NguonKhac_Nsnn"] = xml3Data.T_NguonKhac_Nsnn,
                ["T_NguonKhac_Vtnn"] = xml3Data.T_NguonKhac_Vtnn,
                ["T_NguonKhac_Vttn"] = xml3Data.T_NguonKhac_Vttn,
                ["T_NguonKhac_Cl"] = xml3Data.T_NguonKhac_Cl,
                ["T_NguonKhac"] = xml3Data.T_NguonKhac,
                ["T_Bntt"] = xml3Data.T_Bntt,
                ["T_Bncct"] = xml3Data.T_Bncct,
                ["T_Bhtt"] = xml3Data.T_Bhtt,
                ["Ma_Khoa"] = xml3Data.Ma_Khoa,
                ["Ma_Giuong"] = xml3Data.Ma_Giuong,
                ["Ma_Bac_Si"] = xml3Data.Ma_Bac_Si,
                ["Nguoi_Thuc_Hien"] = xml3Data.Nguoi_Thuc_Hien,
                ["Ma_Benh"] = xml3Data.Ma_Benh,
                ["Ma_Benh_Yhct"] = xml3Data.Ma_Benh_Yhct,
                ["Ngay_Yl"] = xml3Data.Ngay_Yl,
                ["Ngay_Th_Yl"] = xml3Data.Ngay_Th_Yl,
                ["IsError"] = xml3Data.IsError,
                ["Ngay_Kq"] = xml3Data.Ngay_Kq,
                ["Ma_Pttt"] = xml3Data.Ma_Pttt,
                ["Vet_Thuong_Tp"] = xml3Data.Vet_Thuong_Tp,
                ["Pp_Vo_Cam"] = xml3Data.Pp_Vo_Cam,
                ["Vi_Tri_Th_Dvkt"] = xml3Data.Vi_Tri_Th_Dvkt,
                ["Ma_May"] = xml3Data.Ma_May,
                ["Ma_Hieu_Sp"] = xml3Data.Ma_Hieu_Sp,
                ["Tai_Su_Dung"] = xml3Data.Tai_Su_Dung,
                ["Du_Phong"] = xml3Data.Du_Phong,
                
            };

            FillDataToWorksheet(worksheet, row, headers, xml3Fields);
        }

        /// <summary>
        /// Điền dữ liệu XML1 (fallback)
        /// </summary>
        private void FillXML1Data(IXLWorksheet worksheet, int row, List<string> headers, XML1 xml1Data)
        {
            var xml1Fields = new Dictionary<string, object?>
            {
                ["So_CCCD"] = xml1Data.So_Cccd,
                ["Dia_Chi"] = xml1Data.Dia_Chi,
                ["Dien_Thoai"] = xml1Data.Dien_Thoai,
                ["Ma_The_BHYT"] = xml1Data.Ma_The_Bhyt,
                ["Ma_Nghe_Nghiep"] = xml1Data.Ma_Nghe_Nghiep,
                ["Ma_Benh_Chinh"] = xml1Data.Ma_Benh_Chinh,
                ["Ma_Benh_Kt"] = xml1Data.Ma_Benh_Kt,
                ["Ngay_Vao"] = xml1Data.Ngay_Vao,
                ["Ngay_Ra"] = xml1Data.Ngay_Ra,
                ["Ma_Noi_Den"] = xml1Data.Ma_Noi_Den,
                ["T_Thuoc"] = xml1Data.T_Thuoc,
                ["T_Vtyt"] = xml1Data.T_Vtyt,
                ["T_TongChi_Bv"] = xml1Data.T_TongChi_Bv
            };

            FillDataToWorksheet(worksheet, row, headers, xml1Fields);
        }

        /// <summary>
        /// Điền dữ liệu vào worksheet
        /// </summary>
        private void FillDataToWorksheet(IXLWorksheet worksheet, int row, List<string> headers, Dictionary<string, object?> dataFields)
        {
            // Bỏ qua 6 cột đầu tiên (STT, Ma_Lk, Ho_Ten, Gioi_Tinh, Nam_Sinh, ID_Loi) đã được điền trong FillRowData
            int startColumn = 7; // Bắt đầu từ cột 7
            
            for (int i = 0; i < headers.Count; i++)
            {
                var headerName = headers[i];
                
                // Bỏ qua 6 header đầu tiên
                if (i < 6)
                    continue;
                    
                if (dataFields.ContainsKey(headerName))
                {
                    var value = dataFields[headerName];
                    var cell = worksheet.Cell(row, startColumn);
                    
                    // Format giá trị dựa trên kiểu dữ liệu
                    if (value == null)
                    {
                        cell.Value = "";
                    }
                    else if (value is DateTime dateTime)
                    {
                        cell.Value = dateTime;
                        cell.Style.DateFormat.Format = "dd/MM/yyyy HH:mm:ss";
                    }
                    else if (value is decimal decimalValue)
                    {
                        cell.Value = decimalValue;
                        cell.Style.NumberFormat.Format = "#,##0.00";
                    }
                    else if (value is double doubleValue)
                    {
                        cell.Value = doubleValue;
                        cell.Style.NumberFormat.Format = "#,##0.00";
                    }
                    else if (value is float floatValue)
                    {
                        cell.Value = (double)floatValue;
                        cell.Style.NumberFormat.Format = "#,##0.00";
                    }
                    else if (value is int intValue)
                    {
                        cell.Value = intValue;
                    }
                    else if (value is long longValue)
                    {
                        cell.Value = longValue;
                    }
                    else if (value is bool boolValue)
                    {
                        cell.Value = boolValue;
                    }
                    else
                    {
                        cell.Value = value.ToString() ?? "";
                    }
                    
                    startColumn++;
                }
                else
                {
                    // Nếu không tìm thấy key, vẫn tăng column để giữ đúng thứ tự
                    startColumn++;
                }
            }
        }

        /// <summary>
        /// Làm sạch tên sheet để tránh ký tự không hợp lệ
        /// </summary>
        private string SanitizeSheetName(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return "Loi_Khong_Xac_Dinh";
            
            // Loại bỏ các ký tự không hợp lệ cho tên sheet Excel
            var invalidChars = new char[] { '\\', '/', '*', '?', ':', '[', ']' };
            var sanitizedName = name;
            
            foreach (var c in invalidChars)
            {
                sanitizedName = sanitizedName.Replace(c, '_');
            }
            
            // Giới hạn độ dài tên sheet (Excel chỉ cho phép 31 ký tự)
            if (sanitizedName.Length > 31)
            {
                sanitizedName = sanitizedName.Substring(0, 31);
            }
            
            return sanitizedName;
        }

        /// <summary>
        /// Lấy thông tin chi tiết bệnh nhân từ cache
        /// </summary>
        private XML1? GetPatientDetails(string maLk)
        {
            try
            {
                var cachedPatient = _patientCacheService.GetCachedPatient(maLk);
                return cachedPatient?.PatientData?.Xml1?.FirstOrDefault(x => x.Ma_Lk == maLk);
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        /// <summary>
        /// Đếm số lượng lỗi của một bệnh nhân
        /// </summary>
        private int GetErrorCount(PatientValidationResult result)
        {
            return result.ValidationRules?.Count(rule => !rule.IsValid) ?? 0;
        }

        /// <summary>
        /// Lấy danh sách tên lỗi của một bệnh nhân
        /// </summary>
        private string GetErrorNames(PatientValidationResult result)
        {
            if (result.ValidationRules == null) return "";
            
            var errorNames = result.ValidationRules
                .Where(rule => !rule.IsValid)
                .Select(rule => rule.RuleName)
                .ToList();
            
            return string.Join(", ", errorNames);
        }
    }
}
