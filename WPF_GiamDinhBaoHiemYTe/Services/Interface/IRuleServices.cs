using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IRuleServices
    {
        Task<ApiResponse<List<RuleDto>>> GetAllRule();
        Task LoadRulesAsync();
        List<RuleDto> GetCachedRules();
    }
}
