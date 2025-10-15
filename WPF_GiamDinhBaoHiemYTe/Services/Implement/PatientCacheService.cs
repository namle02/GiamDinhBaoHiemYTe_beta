using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class PatientCacheService : IPatientCacheService
    {
        private readonly Dictionary<string, PatientData> _patientDataCache = new();
        private readonly Dictionary<string, List<ValidationRule>> _validationRulesCache = new();
        private readonly Dictionary<string, CachedPatientInfo> _patientInfoCache = new();

        public void AddPatientToCache(string patientId, PatientData patientData, List<ValidationRule> validationRules)
        {
            if (string.IsNullOrWhiteSpace(patientId) || patientData == null)
                return;

            // Lưu dữ liệu gốc
            _patientDataCache[patientId] = patientData;
            _validationRulesCache[patientId] = validationRules ?? new List<ValidationRule>();

            // Tạo thông tin hiển thị
            var cachedInfo = new CachedPatientInfo
            {
                PatientId = patientId,
                CachedTime = DateTime.Now,
                PatientData = patientData,
                ValidationRules = validationRules
            };

            // Lấy thông tin từ XML1 nếu có
            if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
            {
                var xml1 = patientData.Xml1.FirstOrDefault(x => 
                    x.Ma_Lk?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true ||
                    x.Ma_Bn?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true
                ) ?? patientData.Xml1[0];

                cachedInfo.PatientName = xml1.Ho_Ten ?? "";
                cachedInfo.Gender = xml1.Gioi_Tinh == 1 ? "Nam" : (xml1.Gioi_Tinh == 2 ? "Nữ" : "Khác");
                cachedInfo.BirthYear = xml1.Ngay_Sinh ?? "";
            }

            // Đếm số lỗi
            var errorCount = validationRules?.Count(r => !r.IsValid) ?? 0;
            cachedInfo.ErrorCount = errorCount > 0 ? $"{errorCount} lỗi" : "Không có lỗi";
            cachedInfo.HasErrors = errorCount > 0;

            _patientInfoCache[patientId] = cachedInfo;
        }

        public List<CachedPatientInfo> GetAllCachedPatients()
        {
            return _patientInfoCache.Values
                .OrderByDescending(p => p.CachedTime)
                .ToList();
        }

        public PatientData? GetPatientData(string patientId)
        {
            return _patientDataCache.TryGetValue(patientId, out var data) ? data : null;
        }

        public CachedPatientInfo? GetCachedPatient(string patientId)
        {
            return _patientInfoCache.TryGetValue(patientId, out var info) ? info : null;
        }

        public List<ValidationRule>? GetPatientValidationRules(string patientId)
        {
            return _validationRulesCache.TryGetValue(patientId, out var rules) ? rules : null;
        }

        public bool IsPatientCached(string patientId)
        {
            return _patientDataCache.ContainsKey(patientId);
        }

        public void RemovePatientFromCache(string patientId)
        {
            _patientDataCache.Remove(patientId);
            _validationRulesCache.Remove(patientId);
            _patientInfoCache.Remove(patientId);
        }

        public void ClearAllCache()
        {
            _patientDataCache.Clear();
            _validationRulesCache.Clear();
            _patientInfoCache.Clear();
        }

        public int GetCachedPatientCount()
        {
            return _patientDataCache.Count;
        }
    }
}
