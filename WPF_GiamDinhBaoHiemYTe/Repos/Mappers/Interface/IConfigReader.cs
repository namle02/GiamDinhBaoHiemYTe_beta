using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Repos.Mappers.Interface
{
    public interface IConfigReader
    {
        Task GetConfigFromSheet();
        Dictionary<string, string> Config { get; }
    }
}
