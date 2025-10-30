using ClosedXML.Excel;
using System.Windows;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Service để đọc dữ liệu từ file Excel
    /// </summary>
    public class ExcelReaderService : IExcelReaderService
    {
     
        public async Task<List<string>> ReadMaLkFromExcelAsync(string filePath, string? sheetName = null, string columnName = "MA_LK")
        {
            return await Task.Run(() =>
            {
                var maLkList = new List<string>();

                try
                {
                    using var workbook = new XLWorkbook(filePath);
                    
                    // Lấy sheet theo tên hoặc sheet đầu tiên
                    IXLWorksheet worksheet;
                    if (!string.IsNullOrEmpty(sheetName))
                    {
                        worksheet = workbook.Worksheet(sheetName);
                    }
                    else
                    {
                        worksheet = workbook.Worksheet(1);
                    }

                 
                    int columnIndex = -1;
                    string foundColumnName = string.Empty;
                    
                    // Tìm trong 3 dòng đầu tiên (để xử lý trường hợp header không ở dòng 1)
                    for (int row = 1; row <= 3; row++)
                    {
                        var headerRow = worksheet.Row(row);
                        
                        // Duyệt qua nhiều cột hơn (từ A đến AZ = 52 cột)
                        for (int col = 1; col <= 52; col++)
                        {
                            var cell = headerRow.Cell(col);
                            var cellValue = cell.GetString().Trim().ToLower();
                            
                            // Chuẩn hóa: loại bỏ khoảng trắng, dấu gạch dưới, dấu gạch ngang
                            var normalizedCellValue = cellValue
                                .Replace(" ", "")
                                .Replace("_", "")
                                .Replace("-", "");
                            
                            var normalizedColumnName = columnName.ToLower()
                                .Replace(" ", "")
                                .Replace("_", "")
                                .Replace("-", "");
                            
                            // So sánh đã chuẩn hóa
                            if (normalizedCellValue == normalizedColumnName)
                            {
                                columnIndex = col;
                                foundColumnName = cell.GetString();
                                break;
                            }
                            
                            // So sánh chính xác (không chuẩn hóa) để ưu tiên
                            if (cellValue == columnName.ToLower())
                            {
                                columnIndex = col;
                                foundColumnName = cell.GetString();
                                break;
                            }
                        }
                        
                        // Nếu đã tìm thấy, dừng lại
                        if (columnIndex != -1)
                            break;
                    }

                    if (columnIndex == -1)
                    {
                        // Thu thập thông tin để hiển thị lỗi chi tiết
                        var firstRowCells = new List<string>();
                        for (int col = 1; col <= 10; col++)
                        {
                            var cellValue = worksheet.Row(1).Cell(col).GetString().Trim();
                            if (!string.IsNullOrEmpty(cellValue))
                                firstRowCells.Add(cellValue);
                        }
                        
                        throw new Exception(
                            $"Không tìm thấy cột '{columnName}' trong file Excel.\n\n" +
                            $"Các cột tìm thấy trong dòng đầu tiên: {string.Join(", ", firstRowCells)}\n" +
                            $"Sheet: '{worksheet.Name}'\n\n" +
                            $"Gợi ý:\n" +
                            $"- Đảm bảo tên cột là '{columnName}' (không phân biệt hoa thường)\n" +
                            $"- Đảm bảo cột nằm trong 52 cột đầu tiên (A đến AZ)\n" +
                            $"- Đảm bảo tiêu đề nằm ở 1 trong 3 dòng đầu tiên"
                        );
                    }

                    // Đọc dữ liệu từ cột ma_lk (bỏ qua header row)
                    var rows = worksheet.RowsUsed().Skip(1);
                    string previousValue = string.Empty; // Biến lưu giá trị vừa đọc
                    
                    foreach (var row in rows)
                    {
                        var cell = row.Cell(columnIndex);
                        var value = cell.GetString().Trim();
                        
                        // Chỉ thêm các giá trị không rỗng
                        if (!string.IsNullOrWhiteSpace(value))
                        {
                            // Nếu giá trị khác với giá trị vừa đọc, mới thêm vào danh sách
                            if (value != previousValue)
                            {
                                maLkList.Add(value);
                                previousValue = value; // Cập nhật giá trị vừa đọc
                            }
                            // Nếu giống với giá trị vừa đọc, bỏ qua (skip)
                        }
                    }
                }
                catch (Exception ex)
                {
                   MessageBox.Show("không tìm thấy mã liên kết trong file");
                }

                return maLkList;
            });
        }

        /// <summary>
        /// Đọc dữ liệu từ Excel - tự động phát hiện format (MA_LK hoặc MA_BN + dates)
        /// </summary>
        public async Task<List<ExcelRowData>> ReadDataFromExcelAsync(string filePath, string? sheetName = null)
        {
            return await Task.Run(() =>
            {
                var dataList = new List<ExcelRowData>();

                try
                {
                    using var workbook = new XLWorkbook(filePath);
                    
                    // Lấy sheet theo tên hoặc sheet đầu tiên
                    IXLWorksheet worksheet;
                    if (!string.IsNullOrEmpty(sheetName))
                    {
                        worksheet = workbook.Worksheet(sheetName);
                    }
                    else
                    {
                        worksheet = workbook.Worksheet(1);
                    }

                    // Tìm các cột trong 15 dòng đầu tiên (mở rộng để tìm header)
                    int maLkCol = -1, maBnCol = -1, ngayVaoCol = -1, ngayRaCol = -1;
                    int headerRow = 1;
                    
                    // Debug: In ra tất cả các cột trong 15 dòng đầu
                    System.Diagnostics.Debug.WriteLine("=== Excel Headers Debug (15 rows đầu) ===");
                    for (int debugRow = 1; debugRow <= 15; debugRow++)
                    {
                        var debugRowData = worksheet.Row(debugRow);
                        System.Diagnostics.Debug.Write($"Row {debugRow}: ");
                        for (int debugCol = 1; debugCol <= 20; debugCol++)
                        {
                            var debugCell = debugRowData.Cell(debugCol).GetString().Trim();
                            if (!string.IsNullOrEmpty(debugCell))
                            {
                                // Truncate dài quá 30 ký tự
                                var displayText = debugCell.Length > 30 ? debugCell.Substring(0, 30) + "..." : debugCell;
                                System.Diagnostics.Debug.Write($"[Col{debugCol}:{displayText}] ");
                            }
                        }
                        System.Diagnostics.Debug.WriteLine("");
                    }
                    System.Diagnostics.Debug.WriteLine("=========================");
                    
                    for (int row = 1; row <= 15; row++)
                    {
                        var currentRow = worksheet.Row(row);
                        
                        for (int col = 1; col <= 52; col++)
                        {
                            var originalValue = currentRow.Cell(col).GetString().Trim();
                            
                            // Bỏ qua cell có text quá dài (> 50 chars) - đó là mô tả, không phải header
                            if (originalValue.Length > 50)
                                continue;
                            
                            var cellValue = originalValue.ToLower()
                                .Replace(" ", "").Replace("_", "").Replace("-", "");
                            
                            // Tìm MA_LK (nhiều variant)
                            if (maLkCol == -1 && (
                                cellValue == "malk" || 
                                cellValue == "malienkết" || 
                                cellValue == "maliênkết" ||
                                cellValue == "xml1id" ||
                                cellValue.Contains("malk") ||
                                cellValue.Contains("xml1")))
                            {
                                maLkCol = col;
                                headerRow = row;
                                System.Diagnostics.Debug.WriteLine($"✓ Tìm thấy MA_LK tại Col {col}, Row {row}: '{originalValue}'");
                            }
                            // Tìm MA_BN (nhiều variant)
                            else if (maBnCol == -1 && (
                                cellValue == "mabn" || 
                                cellValue == "mabệnhnhân" ||
                                cellValue == "mabênhnhân" ||
                                cellValue.Contains("mabn")))
                            {
                                maBnCol = col;
                                headerRow = row;
                                System.Diagnostics.Debug.WriteLine($"✓ Tìm thấy MA_BN tại Col {col}, Row {row}: '{originalValue}'");
                            }
                            // Tìm NGAY_VAO (nhiều variant)
                            else if (ngayVaoCol == -1 && (
                                cellValue == "ngayvao" || 
                                cellValue == "ngaykham" ||
                                cellValue == "ngàyvào" ||
                                cellValue == "ngaynhapvien" ||
                                cellValue.Contains("ngayvao") ||
                                cellValue.Contains("ngaykham")))
                            {
                                ngayVaoCol = col;
                                headerRow = row;
                                System.Diagnostics.Debug.WriteLine($"✓ Tìm thấy NGAY_VAO tại Col {col}, Row {row}: '{originalValue}'");
                            }
                            // Tìm NGAY_RA (nhiều variant)
                            else if (ngayRaCol == -1 && (
                                cellValue == "ngayra" || 
                                cellValue == "ngayravien" ||
                                cellValue == "ngàyra" ||
                                cellValue == "ngayxuatvien" ||
                                cellValue.Contains("ngayra") ||
                                cellValue.Contains("ngayravien")))
                            {
                                ngayRaCol = col;
                                headerRow = row;
                                System.Diagnostics.Debug.WriteLine($"✓ Tìm thấy NGAY_RA tại Col {col}, Row {row}: '{originalValue}'");
                            }
                        }
                        
                        // Nếu đã tìm thấy ít nhất 1 cột thì dừng
                        if (maLkCol != -1 || maBnCol != -1)
                            break;
                    }

                    System.Diagnostics.Debug.WriteLine($"=== Kết quả tìm kiếm cột ===");
                    System.Diagnostics.Debug.WriteLine($"MA_LK: Column {maLkCol} {(maLkCol == -1 ? "❌ KHÔNG TÌM THẤY" : "✓")}");
                    System.Diagnostics.Debug.WriteLine($"MA_BN: Column {maBnCol} {(maBnCol == -1 ? "❌ KHÔNG TÌM THẤY" : "✓")}");
                    System.Diagnostics.Debug.WriteLine($"NGAY_VAO: Column {ngayVaoCol} {(ngayVaoCol == -1 ? "❌ KHÔNG TÌM THẤY" : "✓")}");
                    System.Diagnostics.Debug.WriteLine($"NGAY_RA: Column {ngayRaCol} {(ngayRaCol == -1 ? "❌ KHÔNG TÌM THẤY" : "✓")}");
                    System.Diagnostics.Debug.WriteLine($"===========================");

                    // Xác định loại dữ liệu
                    string dataType;
                    if (maLkCol != -1)
                    {
                        dataType = "MA_LK";
                        System.Diagnostics.Debug.WriteLine("Excel format: MA_LK");
                    }
                    else if (maBnCol != -1 && ngayVaoCol != -1 && ngayRaCol != -1)
                    {
                        dataType = "MA_BN";
                        System.Diagnostics.Debug.WriteLine("Excel format: MA_BN + Dates");
                    }
                    else
                    {
                        throw new Exception(
                            "Không tìm thấy định dạng hợp lệ trong file Excel.\n\n" +
                            "File phải có một trong hai format:\n" +
                            "1. Cột 'MA_LK'\n" +
                            "2. Cột 'MA_BN', 'NGAY_VAO', 'NGAY_RA'\n\n" +
                            $"Các cột tìm thấy:\n" +
                            $"- MA_LK: {(maLkCol == -1 ? "Không tìm thấy" : "Có")}\n" +
                            $"- MA_BN: {(maBnCol == -1 ? "Không tìm thấy" : "Có")}\n" +
                            $"- NGAY_VAO: {(ngayVaoCol == -1 ? "Không tìm thấy" : "Có")}\n" +
                            $"- NGAY_RA: {(ngayRaCol == -1 ? "Không tìm thấy" : "Có")}"
                        );
                    }

                    // Đọc dữ liệu (bỏ qua header row)
                    var rows = worksheet.RowsUsed().Skip(headerRow);
                    string previousValue = string.Empty;
                    
                    foreach (var row in rows)
                    {
                        var rowData = new ExcelRowData { DataType = dataType };
                        
                        if (dataType == "MA_LK")
                        {
                            var value = row.Cell(maLkCol).GetString().Trim();
                            if (!string.IsNullOrWhiteSpace(value) && value != previousValue)
                            {
                                rowData.MaLk = value;
                                dataList.Add(rowData);
                                previousValue = value;
                                System.Diagnostics.Debug.WriteLine($"Excel: Đọc MA_LK = {value}");
                            }
                        }
                        else // MA_BN
                        {
                            var maBn = row.Cell(maBnCol).GetString().Trim();
                            var ngayVao = row.Cell(ngayVaoCol).GetString().Trim();
                            var ngayRa = row.Cell(ngayRaCol).GetString().Trim();
                            
                            if (!string.IsNullOrWhiteSpace(maBn) && 
                                !string.IsNullOrWhiteSpace(ngayVao) && 
                                !string.IsNullOrWhiteSpace(ngayRa))
                            {
                                var combinedKey = $"{maBn}|{ngayVao}|{ngayRa}";
                                if (combinedKey != previousValue)
                                {
                                    rowData.MaBn = maBn;
                                    rowData.NgayVao = ngayVao;
                                    rowData.NgayRa = ngayRa;
                                    dataList.Add(rowData);
                                    previousValue = combinedKey;
                                    System.Diagnostics.Debug.WriteLine($"Excel: Đọc MA_BN = {maBn}, Ngày vào = {ngayVao}, Ngày ra = {ngayRa}");
                                }
                            }
                        }
                    }

                    System.Diagnostics.Debug.WriteLine($"Excel: Đọc thành công {dataList.Count} dòng");
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Lỗi khi đọc file Excel:\n{ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                }

                return dataList;
            });
        }
      
        public async Task<List<string>> GetSheetNamesAsync(string filePath)
        {
            return await Task.Run(() =>
            {
                var sheetNames = new List<string>();

                try
                {
                    using var workbook = new XLWorkbook(filePath);
                    
                    foreach (var worksheet in workbook.Worksheets)
                    {
                        sheetNames.Add(worksheet.Name);
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("file này đang được sử dungh yêu cầu tắt file trước khi import ");
                }

                return sheetNames;
            });
        }
    }
}

