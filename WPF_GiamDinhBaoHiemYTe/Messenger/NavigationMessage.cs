using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Messenger
{
    public class NavigationMessage
    {
        public string PageName { get; } = string.Empty;

        public NavigationMessage(string _pageName)
        {
            PageName = _pageName;
        }
    }
}
