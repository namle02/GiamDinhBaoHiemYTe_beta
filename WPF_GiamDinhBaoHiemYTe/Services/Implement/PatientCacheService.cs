using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class PatientCacheService : IPatientCacheService
    {
        private readonly Dictionary<string, CachedPatientInfoSnapshot> _patientInfoCache = new();
        private readonly object _syncLock = new();
        private readonly string _cacheDirectory;
        private readonly JsonSerializerOptions _jsonOptions;

        private const string DataSuffix = "_data.json";
        private const string RulesSuffix = "_rules.json";
        private const string InfoSuffix = "_info.json";

        private sealed record CachedPatientInfoSnapshot
        {
            public string PatientId { get; init; } = string.Empty;
            public string PatientName { get; init; } = string.Empty;
            public string Gender { get; init; } = string.Empty;
            public string BirthYear { get; init; } = string.Empty;
            public string ErrorCount { get; init; } = string.Empty;
            public DateTime CachedTime { get; init; }
            public bool HasErrors { get; init; }
        }

        public PatientCacheService()
        {
            _cacheDirectory = Path.Combine(Path.GetTempPath(), "GiamDinhBaoHiemYTe", "PatientCache");
            Directory.CreateDirectory(_cacheDirectory);

            _jsonOptions = new JsonSerializerOptions
            {
                WriteIndented = false,
                DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
            };

            LoadSnapshotsFromDisk();
        }

        public void AddPatientToCache(string patientId, PatientData patientData, List<ValidationRule> validationRules)
        {
            if (string.IsNullOrWhiteSpace(patientId) || patientData == null)
                return;

            lock (_syncLock)
            {
                var snapshot = BuildSnapshot(patientId, patientData, validationRules);
                PersistPatientData(patientId, patientData);
                PersistValidationRules(patientId, validationRules ?? new List<ValidationRule>());
                PersistSnapshot(snapshot);

                _patientInfoCache[patientId] = snapshot;
            }
        }

        public List<CachedPatientInfo> GetAllCachedPatients()
        {
            lock (_syncLock)
            {
                return _patientInfoCache.Values
                    .Select(ToCachedPatientInfo)
                    .OrderByDescending(p => p.CachedTime)
                    .ToList();
            }
        }

        public PatientData? GetPatientData(string patientId)
        {
            lock (_syncLock)
            {
                return LoadPatientData(patientId);
            }
        }

        public CachedPatientInfo? GetCachedPatient(string patientId)
        {
            lock (_syncLock)
            {
                if (!_patientInfoCache.TryGetValue(patientId, out var snapshot))
                {
                    snapshot = LoadSnapshot(patientId);
                    if (snapshot == null)
                        return null;

                    _patientInfoCache[patientId] = snapshot;
                }

                var patientData = LoadPatientData(patientId);
                if (patientData == null)
                    return null;

                var validationRules = LoadValidationRules(patientId);

                var info = ToCachedPatientInfo(snapshot);
                info.PatientData = patientData;
                info.ValidationRules = validationRules;

                return info;
            }
        }

        public List<ValidationRule>? GetPatientValidationRules(string patientId)
        {
            lock (_syncLock)
            {
                return LoadValidationRules(patientId);
            }
        }

        public bool IsPatientCached(string patientId)
        {
            lock (_syncLock)
            {
                return File.Exists(GetDataPath(patientId));
            }
        }

        public void RemovePatientFromCache(string patientId)
        {
            lock (_syncLock)
            {
                _patientInfoCache.Remove(patientId);
                DeleteFileIfExists(GetDataPath(patientId));
                DeleteFileIfExists(GetRulesPath(patientId));
                DeleteFileIfExists(GetInfoPath(patientId));
            }
        }

        public void ClearAllCache()
        {
            lock (_syncLock)
            {
                _patientInfoCache.Clear();

                try
                {
                    if (Directory.Exists(_cacheDirectory))
                    {
                        foreach (var file in Directory.EnumerateFiles(_cacheDirectory))
                        {
                            DeleteFileIfExists(file);
                        }
                    }
                }
                catch
                {
                    // Ignore cleanup errors
                }
            }
        }

        public int GetCachedPatientCount()
        {
            lock (_syncLock)
            {
                return _patientInfoCache.Count;
            }
        }

        private void LoadSnapshotsFromDisk()
        {
            try
            {
                foreach (var infoFile in Directory.EnumerateFiles(_cacheDirectory, $"*{InfoSuffix}", SearchOption.TopDirectoryOnly))
                {
                    try
                    {
                        var json = File.ReadAllText(infoFile);
                        var snapshot = JsonSerializer.Deserialize<CachedPatientInfoSnapshot>(json, _jsonOptions);
                        if (snapshot != null && !string.IsNullOrWhiteSpace(snapshot.PatientId))
                        {
                            _patientInfoCache[snapshot.PatientId] = snapshot;
                        }
                    }
                    catch
                    {
                        // Corrupted snapshot - ignore and continue
                    }
                }
            }
            catch
            {
                // Ignore directory enumeration errors
            }
        }

        private CachedPatientInfoSnapshot? LoadSnapshot(string patientId)
        {
            var path = GetInfoPath(patientId);
            if (!File.Exists(path))
                return null;

            try
            {
                var json = File.ReadAllText(path);
                return JsonSerializer.Deserialize<CachedPatientInfoSnapshot>(json, _jsonOptions);
            }
            catch
            {
                return null;
            }
        }

        private PatientData? LoadPatientData(string patientId)
        {
            var path = GetDataPath(patientId);
            if (!File.Exists(path))
                return null;

            try
            {
                var json = File.ReadAllText(path);
                return JsonSerializer.Deserialize<PatientData>(json, _jsonOptions);
            }
            catch
            {
                return null;
            }
        }

        private List<ValidationRule>? LoadValidationRules(string patientId)
        {
            var path = GetRulesPath(patientId);
            if (!File.Exists(path))
                return null;

            try
            {
                var json = File.ReadAllText(path);
                return JsonSerializer.Deserialize<List<ValidationRule>>(json, _jsonOptions);
            }
            catch
            {
                return null;
            }
        }

        private void PersistPatientData(string patientId, PatientData patientData)
        {
            var path = GetDataPath(patientId);
            try
            {
                var json = JsonSerializer.Serialize(patientData, _jsonOptions);
                File.WriteAllText(path, json);
            }
            catch
            {
                // Ignore persistence errors
            }
        }

        private void PersistValidationRules(string patientId, List<ValidationRule> validationRules)
        {
            var path = GetRulesPath(patientId);
            try
            {
                var json = JsonSerializer.Serialize(validationRules ?? new List<ValidationRule>(), _jsonOptions);
                File.WriteAllText(path, json);
            }
            catch
            {
                // Ignore persistence errors
            }
        }

        private void PersistSnapshot(CachedPatientInfoSnapshot snapshot)
        {
            var path = GetInfoPath(snapshot.PatientId);
            try
            {
                var json = JsonSerializer.Serialize(snapshot, _jsonOptions);
                File.WriteAllText(path, json);
            }
            catch
            {
                // Ignore persistence errors
            }
        }

        private CachedPatientInfoSnapshot BuildSnapshot(string patientId, PatientData patientData, List<ValidationRule>? validationRules)
        {
            string patientName = string.Empty;
            string gender = string.Empty;
            string birthYear = string.Empty;

            if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
            {
                var xml1 = patientData.Xml1.FirstOrDefault(x =>
                    x.Ma_Lk?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true ||
                    x.Ma_Bn?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true
                ) ?? patientData.Xml1[0];

                patientName = xml1.Ho_Ten ?? string.Empty;
                gender = xml1.Gioi_Tinh switch
                {
                    1 => "Nam",
                    2 => "Nữ",
                    _ => "Khác"
                };
                birthYear = xml1.Ngay_Sinh ?? string.Empty;
            }

            var invalidCount = validationRules?.Count(r => !r.IsValid) ?? 0;
            var errorCount = invalidCount > 0 ? $"{invalidCount} lỗi" : "Không có lỗi";
            var hasErrors = invalidCount > 0;

            return new CachedPatientInfoSnapshot
            {
                PatientId = patientId,
                PatientName = patientName,
                Gender = gender,
                BirthYear = birthYear,
                ErrorCount = errorCount,
                HasErrors = hasErrors,
                CachedTime = DateTime.Now
            };
        }

        private CachedPatientInfo ToCachedPatientInfo(CachedPatientInfoSnapshot snapshot)
        {
            var info = new CachedPatientInfo
            {
                PatientData = null,
                ValidationRules = null
            };

            info.PatientId = snapshot.PatientId;
            info.PatientName = snapshot.PatientName;
            info.Gender = snapshot.Gender;
            info.BirthYear = snapshot.BirthYear;
            info.ErrorCount = snapshot.ErrorCount;
            info.CachedTime = snapshot.CachedTime;
            info.HasErrors = snapshot.HasErrors;

            return info;
        }

        private string GetDataPath(string patientId) =>
            Path.Combine(_cacheDirectory, $"{GetSafeFileName(patientId)}{DataSuffix}");

        private string GetRulesPath(string patientId) =>
            Path.Combine(_cacheDirectory, $"{GetSafeFileName(patientId)}{RulesSuffix}");

        private string GetInfoPath(string patientId) =>
            Path.Combine(_cacheDirectory, $"{GetSafeFileName(patientId)}{InfoSuffix}");

        private string GetSafeFileName(string patientId)
        {
            var sanitized = new string(patientId.Where(char.IsLetterOrDigit).ToArray());
            if (string.IsNullOrWhiteSpace(sanitized))
            {
                sanitized = "patient";
            }
            else if (sanitized.Length > 32)
            {
                sanitized = sanitized.Substring(0, 32);
            }

            using var sha256 = SHA256.Create();
            var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(patientId));
            var hashString = Convert.ToHexString(hash);

            return $"{sanitized}_{hashString}";
        }

        private static void DeleteFileIfExists(string path)
        {
            try
            {
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
            catch
            {
                // Ignore deletion errors
            }
        }
    }
}
