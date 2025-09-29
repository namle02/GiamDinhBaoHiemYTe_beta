using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface ICheckConditionService
    {
        void ApplyPatientRules(PatientData patient);
    }
}


