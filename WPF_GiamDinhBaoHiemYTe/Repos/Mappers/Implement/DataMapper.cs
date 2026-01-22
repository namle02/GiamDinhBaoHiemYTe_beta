using Dapper;
using Microsoft.Data.SqlClient;
using System.Windows;
using System.Reflection;
using System.IO;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Repos.Model.Patietn_XML_data;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Implement
{
    public class DataMapper : IDataMapper
    {

        private readonly IConfigReader _configReader;
        // Biến để lưu kết quả từ GoogleSheetService
        private object? _googleSheetData;

        // Property để truy cập dữ liệu GoogleSheet từ bên ngoài
        public object? GoogleSheetData => _googleSheetData;

        public DataMapper(IConfigReader configReader)
        {
            _configReader = configReader;
        }

        /// <summary>
        /// Đọc SQL query từ file trong folder sql
        /// </summary>
        private string LoadSqlFromFile(string fileName, string idBenhNhan)
        {
            try
            {
                // Lấy đường dẫn thư mục chứa assembly hiện tại
                string? assemblyPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string sqlFilePath = string.Empty;
                
                if (!string.IsNullOrEmpty(assemblyPath))
                {
                    sqlFilePath = Path.Combine(assemblyPath, "sql", fileName);
                }
                
                // Nếu không tìm thấy trong thư mục assembly, thử tìm trong thư mục hiện tại
                if (string.IsNullOrEmpty(sqlFilePath) || !File.Exists(sqlFilePath))
                {
                    string? currentDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    if (!string.IsNullOrEmpty(currentDir))
                    {
                        sqlFilePath = Path.Combine(currentDir, "sql", fileName);
                    }
                }
                
                // Nếu vẫn không tìm thấy, thử tìm trong thư mục gốc của project
                if (string.IsNullOrEmpty(sqlFilePath) || !File.Exists(sqlFilePath))
                {
                    string? projectRoot = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    while (projectRoot != null && !Directory.Exists(Path.Combine(projectRoot, "sql")))
                    {
                        projectRoot = Directory.GetParent(projectRoot)?.FullName;
                    }
                    if (!string.IsNullOrEmpty(projectRoot))
                    {
                        sqlFilePath = Path.Combine(projectRoot, "Repos", "Mappers", "Implement", "sql", fileName);
                    }
                }

                if (!string.IsNullOrEmpty(sqlFilePath) && File.Exists(sqlFilePath))
                {
                    string sql = File.ReadAllText(sqlFilePath);
                    // Thay thế {IDBenhNhan} bằng giá trị thực tế
                    return sql.Replace("{IDBenhNhan}", idBenhNhan);
                }
                else
                {
                    return string.Empty;
                }
            }
            catch
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Đọc SQL query từ file trong folder sql (không thay thế placeholder)
        /// </summary>
        private string LoadSqlFromFile(string fileName)
        {
            try
            {
                // Lấy đường dẫn thư mục chứa assembly hiện tại
                string? assemblyPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string sqlFilePath = string.Empty;
                
                if (!string.IsNullOrEmpty(assemblyPath))
                {
                    sqlFilePath = Path.Combine(assemblyPath, "sql", fileName);
                }
                
                // Nếu không tìm thấy trong thư mục assembly, thử tìm trong thư mục hiện tại
                if (string.IsNullOrEmpty(sqlFilePath) || !File.Exists(sqlFilePath))
                {
                    string? currentDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    if (!string.IsNullOrEmpty(currentDir))
                    {
                        sqlFilePath = Path.Combine(currentDir, "sql", fileName);
                    }
                }
                
                // Nếu vẫn không tìm thấy, thử tìm trong thư mục gốc của project
                if (string.IsNullOrEmpty(sqlFilePath) || !File.Exists(sqlFilePath))
                {
                    string? projectRoot = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    while (projectRoot != null && !Directory.Exists(Path.Combine(projectRoot, "sql")))
                    {
                        projectRoot = Directory.GetParent(projectRoot)?.FullName;
                    }
                    if (!string.IsNullOrEmpty(projectRoot))
                    {
                        sqlFilePath = Path.Combine(projectRoot, "Repos", "Mappers", "Implement", "sql", fileName);
                    }
                }

                if (!string.IsNullOrEmpty(sqlFilePath) && File.Exists(sqlFilePath))
                {
                    return File.ReadAllText(sqlFilePath);
                }
                else
                {
                    return string.Empty;
                }
            }
            catch
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Lấy thông tin phân loại bệnh án từ IDBenhNhan (có thể là Ma_TN, Ma_BA, hoặc Ma_BN)
        /// </summary>
        private async Task<PhanLoaiBenhAn?> GetPhanLoaiBenhAn(string IDBenhNhan, string connectionStringForAll)
        {
            try
            {
                // Load SQL query từ file PhanLoaiBenhAn.sql
                string query = LoadSqlFromFile("PhanLoaiBenhAn.sql");
                
                if (string.IsNullOrWhiteSpace(query))
                {
                    return null;
                }

                // Xác định loại input: Ma_TN (có "TN" ở đầu), Ma_BA, hoặc Ma_BN
                string? sovv = null;      // Ma_BN (Sovv)
                string? ngaytn = null;   // Ngày vào (cho Ma_BN)
                string? sotn = null;     // Ma_TN (SoTiepNhan) - có "TN" ở đầu
                string? soba = null;     // Ma_BA (SoBenhAn) - không có "TN" ở đầu

                // Kiểm tra nếu input bắt đầu bằng "TN" (case-insensitive)
                if (IDBenhNhan.Trim().StartsWith("TN", StringComparison.OrdinalIgnoreCase))
                {
                    // Tình huống 2: Mã có "TN" ở đầu (SoTiepNhan)
                    sotn = IDBenhNhan.Trim();
                }
                else
                {
                    // Có thể là Ma_BA hoặc Ma_BN
                    // Thử với Ma_BA trước (tình huống 3)
                    soba = IDBenhNhan.Trim();
                }

                using (SqlConnection connection = new SqlConnection(connectionStringForAll))
                {
                    await connection.OpenAsync();
                    var result = await connection.QueryFirstOrDefaultAsync<PhanLoaiBenhAn>(query, new
                    {
                        Sovv = sovv,
                        Ngaytn = ngaytn,
                        Sotn = sotn,
                        Soba = soba
                    });

                    return result;
                }
            }
            catch
            {
                return null;
            }
        }

        public async Task<PatientData> GetDataFromDB(string IDBenhNhan)
        {
            PatientData patient = new() { PatientID = IDBenhNhan };

            string connectionString = _configReader.Config["DB_string"];
            string GetConnectionStringForDatabase(string baseConnectionString)
            {
                try
                {
                    var builder = new SqlConnectionStringBuilder(baseConnectionString);
                    builder.InitialCatalog = "eHospital_ThuyDienUB";
                    return builder.ConnectionString;
                }
                catch
                {
                    if (baseConnectionString.Contains("Initial Catalog=XML130") || baseConnectionString.Contains("Database=XML130"))
                    {
                        return baseConnectionString.Replace("Initial Catalog=XML130", "Initial Catalog=eHospital_ThuyDienUB")
                                                  .Replace("Database=XML130", "Database=eHospital_ThuyDienUB");
                    }
                    else if (baseConnectionString.Contains("Initial Catalog="))
                    {
                        int startIndex = baseConnectionString.IndexOf("Initial Catalog=");
                        int endIndex = baseConnectionString.IndexOf(";", startIndex);
                        if (endIndex == -1) endIndex = baseConnectionString.Length;
                        return baseConnectionString.Substring(0, startIndex) + "Initial Catalog=eHospital_ThuyDienUB" + baseConnectionString.Substring(endIndex);
                    }
                    else
                    {
                        return baseConnectionString.TrimEnd(';') + ";Initial Catalog=eHospital_ThuyDienUB;";
                    }
                }
            }

            string connectionStringForAll = GetConnectionStringForDatabase(connectionString);
            
            try
            {
                if (string.IsNullOrWhiteSpace(connectionStringForAll))
                {
                    return patient;
                }

                // Bước 1: Lấy thông tin phân loại bệnh án
                var phanLoai = await GetPhanLoaiBenhAn(IDBenhNhan, connectionStringForAll);
                
                if (phanLoai == null)
                {
                    // Nếu không tìm thấy phân loại, thử với cách cũ (fallback)
                    return await GetDataFromDBFallback(IDBenhNhan, connectionStringForAll);
                }

                // Bước 2: Xác định Ma_TN và Ma_BA từ kết quả phân loại
                string? maTN = phanLoai.Ma_TN;
                string? maBA = phanLoai.Ma_BA;
                int loaiBenhAn = phanLoai.LoaiBenhAn;

                // Bước 3: Quyết định load XML nào dựa vào LoaiBenhAn
                Dictionary<XMLDataType, string> XML_Query_List = new Dictionary<XMLDataType, string>();

                if (loaiBenhAn == 1)
                {
                    // Nội trú: Load XML1NoiT - XML5NoiT với SoBenhAn = Ma_BA
                    if (!string.IsNullOrWhiteSpace(maBA))
                    {
                        XML_Query_List.Add(XMLDataType.XML0, LoadSqlFromFile("XML0.sql", maBA));
                        XML_Query_List.Add(XMLDataType.XML1, LoadSqlFromFile("XML1NoiT.sql", maBA));
                        XML_Query_List.Add(XMLDataType.XML2, LoadSqlFromFile("XML2NoiT.sql", maBA));
                        XML_Query_List.Add(XMLDataType.XML3, LoadSqlFromFile("XML3NoiT.sql", maBA));
                        XML_Query_List.Add(XMLDataType.XML4, LoadSqlFromFile("XML4NoiT.sql", maBA));
                        XML_Query_List.Add(XMLDataType.XML5, LoadSqlFromFile("XML5NoiT.sql", maBA));
                    }
                }
                else if (loaiBenhAn == 2)
                {
                    // Ngoại trú: Load XML1NT - XML5NT với SoTiepNhan = Ma_TN
                    if (!string.IsNullOrWhiteSpace(maTN))
                    {
                        XML_Query_List.Add(XMLDataType.XML0, LoadSqlFromFile("XML0.sql", maTN));
                        XML_Query_List.Add(XMLDataType.XML1, LoadSqlFromFile("XML1NT.sql", maTN));
                        XML_Query_List.Add(XMLDataType.XML2, LoadSqlFromFile("XML2NT.sql", maTN));
                        XML_Query_List.Add(XMLDataType.XML3, LoadSqlFromFile("XML3NT.sql", maTN));
                        XML_Query_List.Add(XMLDataType.XML4, LoadSqlFromFile("XML4NT.sql", maTN));
                        XML_Query_List.Add(XMLDataType.XML5, LoadSqlFromFile("XML5NT.sql", maTN));
                    }
                }

                // Load các XML khác (XML11, XML13-15) nếu cần
                XML_Query_List.Add(XMLDataType.XML11, LoadSqlFromFile("XML11.sql", IDBenhNhan));
                XML_Query_List.Add(XMLDataType.XML13, LoadSqlFromFile("XML13.sql", IDBenhNhan));
                XML_Query_List.Add(XMLDataType.XML14, LoadSqlFromFile("XML14.sql", IDBenhNhan));
                XML_Query_List.Add(XMLDataType.XML15, LoadSqlFromFile("XML15.sql", IDBenhNhan));

                // Bước 4: Thực thi các queries
                foreach (var query in XML_Query_List)
                {
                    try
                    {
                        if (string.IsNullOrWhiteSpace(query.Value))
                        {
                            continue;
                        }

                        using (SqlConnection connection = new SqlConnection(connectionStringForAll))
                        {
                            await connection.OpenAsync();
                            await GetXMLData(query.Key, query.Value, patient, connection);
                        }
                    }
                    catch
                    {
                        // Ignore errors for individual queries
                    }
                }
            }
            catch
            {
                _googleSheetData = null;
            }

            return patient;
        }

        /// <summary>
        /// Fallback method nếu không tìm thấy phân loại bệnh án
        /// </summary>
        private async Task<PatientData> GetDataFromDBFallback(string IDBenhNhan, string connectionStringForAll)
        {
            PatientData patient = new() { PatientID = IDBenhNhan };

            // Load tất cả SQL queries (cách cũ)
            Dictionary<XMLDataType, string> XML_Query_List = new Dictionary<XMLDataType, string>
            {
                {XMLDataType.XML0, LoadSqlFromFile("XML0.sql", IDBenhNhan) },
                {XMLDataType.XML1, LoadSqlFromFile("XML1.sql", IDBenhNhan) },
                {XMLDataType.XML2, LoadSqlFromFile("XML2.sql", IDBenhNhan) },
                {XMLDataType.XML3, LoadSqlFromFile("XML3.sql", IDBenhNhan) },
                {XMLDataType.XML4, LoadSqlFromFile("XML4.sql", IDBenhNhan) },
                {XMLDataType.XML5, LoadSqlFromFile("XML5.sql", IDBenhNhan) },
                {XMLDataType.XML6, LoadSqlFromFile("XML6.sql", IDBenhNhan) },
                {XMLDataType.XML7, LoadSqlFromFile("XML7.sql", IDBenhNhan) },
                {XMLDataType.XML8, LoadSqlFromFile("XML8.sql", IDBenhNhan) },
                {XMLDataType.XML9, LoadSqlFromFile("XML9.sql", IDBenhNhan) },
                {XMLDataType.XML10, LoadSqlFromFile("XML10.sql", IDBenhNhan) },
                {XMLDataType.XML11, LoadSqlFromFile("XML11.sql", IDBenhNhan) },
                {XMLDataType.XML13, LoadSqlFromFile("XML13.sql", IDBenhNhan) },
                {XMLDataType.XML14, LoadSqlFromFile("XML14.sql", IDBenhNhan) },
                {XMLDataType.XML15, LoadSqlFromFile("XML15.sql", IDBenhNhan) },
            };

            foreach (var query in XML_Query_List)
            {
                try
                {
                    if (string.IsNullOrWhiteSpace(query.Value))
                    {
                        continue;
                    }

                    using (SqlConnection connection = new SqlConnection(connectionStringForAll))
                    {
                        await connection.OpenAsync();
                        await GetXMLData(query.Key, query.Value, patient, connection);
                    }
                }
                catch
                {
                    // Ignore errors for individual queries
                }
            }

            return patient;
        }

        private async Task GetXMLData(XMLDataType type, string query, PatientData patient, SqlConnection connection)
        {
            try
            {
                switch (type)
                {
                    case XMLDataType.XML0:
                        patient.Xml0 = (await connection.QueryAsync<XML0>(query)).ToList();
                        break;
                    case XMLDataType.XML1:
                        patient.Xml1 = (await connection.QueryAsync<XML1>(query)).ToList();
                        break;
                    case XMLDataType.XML2:
                        patient.Xml2 = (await connection.QueryAsync<XML2>(query)).ToList();
                        break;
                    case XMLDataType.XML3:
                        patient.Xml3 = (await connection.QueryAsync<XML3>(query)).ToList();
                        break;
                    case XMLDataType.XML4:
                        patient.Xml4 = (await connection.QueryAsync<XML4>(query)).ToList();
                        break;
                    case XMLDataType.XML5:
                        patient.Xml5 = (await connection.QueryAsync<XML5>(query)).ToList();
                        break;
                    case XMLDataType.XML6:
                        patient.Xml6 = (await connection.QueryAsync<XML6>(query)).ToList();
                        break;
                    case XMLDataType.XML7:
                        patient.Xml7 = (await connection.QueryAsync<XML7>(query)).ToList();
                        break;
                    case XMLDataType.XML8:
                        patient.Xml8 = (await connection.QueryAsync<XML8>(query)).ToList();
                        break;
                    case XMLDataType.XML9:
                        patient.Xml9 = (await connection.QueryAsync<XML9>(query)).ToList();
                        break;
                    case XMLDataType.XML10:
                        patient.Xml10 = (await connection.QueryAsync<XML10>(query)).ToList();
                        break;
                    case XMLDataType.XML11:
                        patient.Xml11 = (await connection.QueryAsync<XML11>(query)).ToList();
                        break;
                    case XMLDataType.XML13:
                        patient.Xml13 = (await connection.QueryAsync<XML13>(query)).ToList();
                        break;
                    case XMLDataType.XML14:
                        patient.Xml14 = (await connection.QueryAsync<XML14>(query)).ToList();
                        break;
                    case XMLDataType.XML15:
                        patient.Xml15 = (await connection.QueryAsync<XML15>(query)).ToList();
                        break;
                }
            }
            catch
            {
                throw;
            }
        }


        public async Task<List<MaLkSearchResult>> GetMaLkByMaBnAndDate(string maBn, string ngayVaoFrom)
        {
            try
            {
                string connectionString = _configReader.Config["DB_string"];

                // Tạo connection string với database eHospital_ThuyDienUB
                string connectionStringForAll;
                if (connectionString.Contains("Initial Catalog=XML130") || connectionString.Contains("Database=XML130"))
                {
                    connectionStringForAll = connectionString.Replace("Initial Catalog=XML130", "Initial Catalog=eHospital_ThuyDienUB")
                                                          .Replace("Database=XML130", "Database=eHospital_ThuyDienUB");
                }
                else if (connectionString.Contains("Initial Catalog") || connectionString.Contains("Database"))
                {
                    var builder = new SqlConnectionStringBuilder(connectionString);
                    builder.InitialCatalog = "eHospital_ThuyDienUB";
                    connectionStringForAll = builder.ConnectionString;
                }
                else
                {
                    connectionStringForAll = connectionString.TrimEnd(';') + ";Initial Catalog=eHospital_ThuyDienUB;";
                }

                // Load SQL query từ file PhanLoaiBenhAn.sql
                string query = LoadSqlFromFile("PhanLoaiBenhAn.sql");
                
                if (string.IsNullOrWhiteSpace(query))
                {
                    MessageBox.Show("Không thể tải file SQL PhanLoaiBenhAn.sql", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                    return new List<MaLkSearchResult>();
                }

                // Tình huống 1: Nhập MA_BN (Sovv) và Ngày vào (Ngaytn)
                // @ngayVaoFrom format: yyyyMMdd (8 ký tự)
                string ngaytnFormatted = ngayVaoFrom.Length >= 8 ? ngayVaoFrom.Substring(0, 8) : ngayVaoFrom;
                
                using (SqlConnection connection = new SqlConnection(connectionStringForAll))
                {
                    await connection.OpenAsync();
                    // Query trả về PhanLoaiBenhAn, sau đó map sang MaLkSearchResult
                    var phanLoaiResults = await connection.QueryAsync<PhanLoaiBenhAn>(query, new
                    {
                        Sovv = maBn,           // MA_BN
                        Ngaytn = ngaytnFormatted,  // Ngày vào (format: yyyyMMdd - 8 ký tự)
                        Sotn = (string?)null,  // Tình huống 2: Mã có "TN" ở đầu
                        Soba = (string?)null   // Tình huống 3: Mã không có "TN" ở đầu
                    });

                    // Map từ PhanLoaiBenhAn sang MaLkSearchResult
                    var results = new List<MaLkSearchResult>();
                    foreach (var item in phanLoaiResults)
                    {
                        // Xác định Ma_Lk: ưu tiên Ma_TN, nếu không có thì dùng Ma_BA
                        string? maLk = !string.IsNullOrWhiteSpace(item.Ma_TN) ? item.Ma_TN : item.Ma_BA;
                        
                        // Format ngày vào
                        string? ngayVaoFormatted = null;
                        if (item.Ngay_vao_vien.HasValue)
                        {
                            var date = item.Ngay_vao_vien.Value;
                            ngayVaoFormatted = date.ToString("yyyyMMdd") + date.ToString("HHmm");
                        }

                        results.Add(new MaLkSearchResult
                        {
                            Ma_Bn = maBn,
                            Ma_Lk = maLk,
                            Ngay_Vao = ngayVaoFormatted,
                            LoaiBenhAn_Id = item.LoaiBenhAn
                        });
                    }

                    return results;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi khi tìm kiếm MA_LK: {ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return new List<MaLkSearchResult>();
            }
        }

        public async Task<List<MaLkSearchResult>> GetMaLkByInput(string? maBn = null, string? ngayVaoFrom = null, string? inputCode = null)
        {
            try
            {
                string connectionString = _configReader.Config["DB_string"];

                // Tạo connection string với database eHospital_ThuyDienUB
                string connectionStringForAll;
                if (connectionString.Contains("Initial Catalog=XML130") || connectionString.Contains("Database=XML130"))
                {
                    connectionStringForAll = connectionString.Replace("Initial Catalog=XML130", "Initial Catalog=eHospital_ThuyDienUB")
                                                          .Replace("Database=XML130", "Database=eHospital_ThuyDienUB");
                }
                else if (connectionString.Contains("Initial Catalog") || connectionString.Contains("Database"))
                {
                    var builder = new SqlConnectionStringBuilder(connectionString);
                    builder.InitialCatalog = "eHospital_ThuyDienUB";
                    connectionStringForAll = builder.ConnectionString;
                }
                else
                {
                    connectionStringForAll = connectionString.TrimEnd(';') + ";Initial Catalog=eHospital_ThuyDienUB;";
                }

                // Load SQL query từ file PhanLoaiBenhAn.sql
                string query = LoadSqlFromFile("PhanLoaiBenhAn.sql");
                
                if (string.IsNullOrWhiteSpace(query))
                {
                    MessageBox.Show("Không thể tải file SQL PhanLoaiBenhAn.sql", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                    return new List<MaLkSearchResult>();
                }

                // Xác định tình huống và set parameters
                string? sovv = null;      // Tình huống 1: MA_BN
                string? ngaytn = null;   // Tình huống 1: Ngày vào
                string? sotn = null;     // Tình huống 2: Mã có "TN" ở đầu
                string? soba = null;     // Tình huống 3: Mã không có "TN" ở đầu

                // Tình huống 1: Có MA_BN và Ngày vào
                if (!string.IsNullOrWhiteSpace(maBn) && !string.IsNullOrWhiteSpace(ngayVaoFrom))
                {
                    sovv = maBn;
                    ngaytn = ngayVaoFrom;
                }
                // Tình huống 2 hoặc 3: Có inputCode
                else if (!string.IsNullOrWhiteSpace(inputCode))
                {
                    // Kiểm tra nếu inputCode bắt đầu bằng "TN" (case-insensitive)
                    if (inputCode.Trim().StartsWith("TN", StringComparison.OrdinalIgnoreCase))
                    {
                        // Tình huống 2: Mã có "TN" ở đầu (SoTiepNhan)
                        sotn = inputCode.Trim();
                    }
                    else
                    {
                        // Tình huống 3: Mã không có "TN" ở đầu (SoBenhAn)
                        soba = inputCode.Trim();
                    }
                }
                else
                {
                    MessageBox.Show("Vui lòng cung cấp đầy đủ thông tin: (MA_BN + Ngày vào) hoặc Mã input", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                    return new List<MaLkSearchResult>();
                }

                using (SqlConnection connection = new SqlConnection(connectionStringForAll))
                {
                    await connection.OpenAsync();
                    var results = await connection.QueryAsync<MaLkSearchResult>(query, new
                    {
                        Sovv = sovv,     // Tình huống 1: MA_BN
                        Ngaytn = ngaytn, // Tình huống 1: Ngày vào
                        Sotn = sotn,     // Tình huống 2: Mã có "TN" ở đầu
                        Soba = soba      // Tình huống 3: Mã không có "TN" ở đầu
                    });

                    return results.ToList();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Lỗi khi tìm kiếm MA_LK: {ex.Message}", "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                return new List<MaLkSearchResult>();
            }
        }

    }
}
