using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Repos.Dto;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IPatientCacheService
    {
        /// <summary>
        /// Thêm bệnh nhân vào cache
        /// </summary>
        void AddPatientToCache(string patientId, PatientData patientData, List<ValidationRule> validationRules);

        /// <summary>
        /// Lấy danh sách tất cả bệnh nhân đã cache
        /// </summary>
        List<CachedPatientInfo> GetAllCachedPatients();

        /// <summary>
        /// Lấy dữ liệu bệnh nhân từ cache
        /// </summary>
        PatientData? GetPatientData(string patientId);

        /// <summary>
        /// Lấy thông tin bệnh nhân đã cache (bao gồm cả PatientData và ValidationRules)
        /// </summary>
        CachedPatientInfo? GetCachedPatient(string patientId);

        /// <summary>
        /// Lấy validation rules của bệnh nhân từ cache
        /// </summary>
        List<ValidationRule>? GetPatientValidationRules(string patientId);

        /// <summary>
        /// Kiểm tra bệnh nhân có trong cache không
        /// </summary>
        bool IsPatientCached(string patientId);

        /// <summary>
        /// Xóa bệnh nhân khỏi cache
        /// </summary>
        void RemovePatientFromCache(string patientId);

        /// <summary>
        /// Xóa tất cả cache
        /// </summary>
        void ClearAllCache();

        /// <summary>
        /// Lấy số lượng bệnh nhân đã cache
        /// </summary>
        int GetCachedPatientCount();
    }
}
