using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Model
{
    public class SheetConfigRaw
    {
        public string? range { get; set; }
        public string? majorDimension { get; set; }
        public List<List<string>>? values { get; set; }
    }
}
