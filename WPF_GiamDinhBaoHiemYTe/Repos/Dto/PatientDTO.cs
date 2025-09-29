using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WPF_GiamDinhBaoHiem.Repos.Dto
{
    public class PatientDTO
    {
        public string Ma_lk { get; set; } = string.Empty;
        public string Ma_BenhNhan { get; set; } = string.Empty;
        public string Ho_Ten { get; set; } = string.Empty;
        public string Ngay_Sinh { get; set; } = string.Empty;
        public string Dia_Chi { get; set; } = string.Empty;

        public PatientDTO(string ma_lk, string ma_benhnhan, string ho_ten, string ngay_sinh, string dia_chi)
        {
            this.Ma_lk = ma_lk;
            this.Ma_BenhNhan = ma_benhnhan;
            this.Ho_Ten = ho_ten;
            this.Ngay_Sinh = ngay_sinh;
            this.Dia_Chi = dia_chi;
        }
    }
}
