using ClosedXML.Excel;
using System.Windows;
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

