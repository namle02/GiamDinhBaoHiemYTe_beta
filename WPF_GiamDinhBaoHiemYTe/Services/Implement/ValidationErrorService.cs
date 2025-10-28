using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Service xử lý validation errors và marking
    /// </summary>
    public class ValidationErrorService : IValidationErrorService
    {
        public ErrorExtractionResult ExtractErrorIds(ValidateData validateData)
        {
            if (validateData.ValidationResults == null)
            {
                return new ErrorExtractionResult();
            }

            return ExtractErrorIds(validateData.ValidationResults);
        }

        public ErrorExtractionResult ExtractErrorIds(List<ValidationRule> validationRules)
        {
            var result = new ErrorExtractionResult();

            foreach (var rule in validationRules)
            {
                if (!rule.IsValid)
                {
                    // Extract error IDs
                    if (rule.Errors != null)
                    {
                        foreach (var error in rule.Errors)
                        {
                            if (error.Id.HasValue)
                            {
                                result.ErrorIds.Add(error.Id.Value);
                            }
                        }
                    }

                    // Extract XML tab từ validateFile
                    if (!string.IsNullOrEmpty(rule.ValidateFile))
                    {
                        var xmlTab = NormalizeXmlTabName(rule.ValidateFile);
                        if (!string.IsNullOrEmpty(xmlTab))
                        {
                            result.ErrorXmlTabs.Add(xmlTab);
                        }
                    }
                }
            }

            return result;
        }

        public void MarkErrorsInXmlData(PatientData patientData, HashSet<int> errorIds, HashSet<string> errorXmlTabs)
        {
            if (patientData == null || errorIds == null || errorXmlTabs == null)
                return;

            // Chỉ check XML có lỗi (theo errorXmlTabs) thay vì check tất cả
            if (errorXmlTabs.Contains("XML1") && patientData.Xml1 != null)
            {
                foreach (var xml1 in patientData.Xml1)
                {
                    xml1.IsError = xml1.Id != 0 && errorIds.Contains(xml1.Id);
                }
            }

            if (errorXmlTabs.Contains("XML2") && patientData.Xml2 != null)
            {
                foreach (var xml2 in patientData.Xml2)
                {
                    xml2.IsError = xml2.Id != 0 && errorIds.Contains(xml2.Id);
                }
            }

            if (errorXmlTabs.Contains("XML3") && patientData.Xml3 != null)
            {
                foreach (var xml3 in patientData.Xml3)
                {
                    xml3.IsError = xml3.Id != 0 && errorIds.Contains(xml3.Id);
                }
            }

            if (errorXmlTabs.Contains("XML4") && patientData.Xml4 != null)
            {
                foreach (var xml4 in patientData.Xml4)
                {
                    xml4.IsError = xml4.Id != 0 && errorIds.Contains(xml4.Id);
                }
            }

            if (errorXmlTabs.Contains("XML5") && patientData.Xml5 != null)
            {
                foreach (var xml5 in patientData.Xml5)
                {
                    xml5.IsError = xml5.Id != 0 && errorIds.Contains(xml5.Id);
                }
            }
        }

        public string? NormalizeXmlTabName(string validateFile)
        {
            if (string.IsNullOrEmpty(validateFile))
                return null;

            var normalized = validateFile.Trim().ToUpper();

            // Validate xem có phải là XML1-15 không (chỉ support XML1-5 trong UI)
            if (normalized == "XML1" || normalized == "XML2" || normalized == "XML3" ||
                normalized == "XML4" || normalized == "XML5")
            {
                return normalized;
            }

            return null;
        }
    }
}

