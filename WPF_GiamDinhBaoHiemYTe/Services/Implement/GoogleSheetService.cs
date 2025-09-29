using System.Net.Http;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using System.Linq;                        // <- thêm
using Microsoft.VisualBasic.FileIO;       // parse CSV an toàn
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class GoogleSheetService : IGoogleSheetService
    {
        private readonly HttpClient _http;
        public GoogleSheetService(HttpClient http) => _http = http;


        public async Task<List<ErrorItem>> GetErrorListAsync()
        {
            // có thể move URL này ra config/appsettings
            const string url =
                "https://docs.google.com/spreadsheets/d/e/2PACX-1vT0OG7KL53n9d-JrfpwUwbxJMDcy_p-yryLZmXRlhTl9bmXaS5SyIuaJ3zWZQKCPJnJd6Lnzp2f7J8J/pub?output=csv";

            var rows = await GetSheetAsCsvAsync(url);
            var list = new List<ErrorItem>();

            foreach (var cells in rows.Skip(1)) // bỏ header
            {
                if (cells.Length < 5) continue;

                list.Add(new ErrorItem
                {
                    Stt = int.TryParse(Strip(cells[0]), out var stt) ? stt : 0,
                    MaCoSoKCB = Strip(cells[1]),
                    MaChuyenDe = Strip(cells[2]),
                    MaLyDoTuChoi = Strip(cells[3]),
                    NoiDung = Strip(cells[4]),
                    ViTriLoi = Strip(cells[5])
                });
            }

            return list;
        }

        // Đọc CSV thành mảng string[]
        public async Task<List<string[]>> GetSheetAsCsvAsync(string csvUrl)
        {
            var raw = await _http.GetStringAsync(csvUrl);

            // Normalize line-endings để tránh \r gây lệch field cuối
            raw = raw.Replace("\r\n", "\n").Replace('\r', '\n');

            var rows = new List<string[]>();

            using var reader = new StringReader(raw);
            using var parser = new TextFieldParser(reader)
            {
                HasFieldsEnclosedInQuotes = true
            };
            parser.SetDelimiters(",");

            while (!parser.EndOfData)
            {
                var cells = parser.ReadFields();
                if (cells is { Length: > 0 })
                    rows.Add(cells);
            }

            return rows;
        }

        // Helper: trim + bỏ dấu ngoặc kép thừa nếu có
        private static string Strip(string? s)
            => string.IsNullOrEmpty(s) ? string.Empty : s.Trim().Trim('"');
    }
}
