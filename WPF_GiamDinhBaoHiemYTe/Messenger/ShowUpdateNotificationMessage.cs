namespace WPF_GiamDinhBaoHiem.Messenger;

/// <summary>
/// Message để hiện thông báo có phiên bản mới (trong MainWindow).
/// </summary>
public class ShowUpdateNotificationMessage
{
    public string LatestVersion { get; }

    public ShowUpdateNotificationMessage(string latestVersion)
    {
        LatestVersion = latestVersion ?? "";
    }
}
