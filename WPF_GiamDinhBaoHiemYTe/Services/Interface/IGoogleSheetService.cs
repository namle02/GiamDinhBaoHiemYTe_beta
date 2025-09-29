using System.Collections.Generic;
using System.Threading.Tasks;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IGoogleSheetService
    {

        Task<List<ErrorItem>> GetErrorListAsync();
        Task<List<string[]>> GetSheetAsCsvAsync(string csvUrl);
    }
}
