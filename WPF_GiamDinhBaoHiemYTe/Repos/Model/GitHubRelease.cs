namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public class GitHubRelease
    {
        public string tag_name { get; set; }
        public string name { get; set; }
        public string body { get; set; }
        public bool prerelease { get; set; }
        public DateTime published_at { get; set; }
        public List<GitHubAsset> assets { get; set; }
    }

    public class GitHubAsset
    {
        public string name { get; set; }
        public string browser_download_url { get; set; }
        public long size { get; set; }
    }
}

