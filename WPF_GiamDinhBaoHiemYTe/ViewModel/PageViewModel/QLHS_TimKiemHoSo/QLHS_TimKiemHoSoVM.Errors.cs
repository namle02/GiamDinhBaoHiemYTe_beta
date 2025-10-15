using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{

    public partial class QLHS_TimKiemHoSoVM
    {
        // ==================== ERROR PROPERTIES ====================
        // Properties để track error IDs và highlight status
        [ObservableProperty]
        private HashSet<int> errorIds = new();

        [ObservableProperty]
        private HashSet<string> errorXmlTabs = new();

        // Error tracking cho overlay
        [ObservableProperty]
        private HashSet<int> overlayErrorIds = new();

        [ObservableProperty]
        private HashSet<string> overlayErrorXmlTabs = new();

        // ==================== ERROR CHECKING PROPERTIES ====================
        /// <summary>
        /// Properties riêng cho từng tab để binding (Main view)
        /// </summary>
        public bool HasXml1Error => ErrorXmlTabs.Contains("XML1");
        public bool HasXml2Error => ErrorXmlTabs.Contains("XML2");
        public bool HasXml3Error => ErrorXmlTabs.Contains("XML3");
        public bool HasXml4Error => ErrorXmlTabs.Contains("XML4");
        public bool HasXml5Error => ErrorXmlTabs.Contains("XML5");

        /// <summary>
        /// Properties riêng cho overlay để binding
        /// </summary>
        public bool HasOverlayXml1Error => OverlayErrorXmlTabs.Contains("XML1");
        public bool HasOverlayXml2Error => OverlayErrorXmlTabs.Contains("XML2");
        public bool HasOverlayXml3Error => OverlayErrorXmlTabs.Contains("XML3");
        public bool HasOverlayXml4Error => OverlayErrorXmlTabs.Contains("XML4");
        public bool HasOverlayXml5Error => OverlayErrorXmlTabs.Contains("XML5");

        /// <summary>
        /// Check xem một ID có trong danh sách error không
        /// </summary>
        public bool IsErrorId(int id)
        {
            return ErrorIds.Contains(id);
        }

        /// <summary>
        /// Check xem một XML tab có chứa error không
        /// </summary>
        public bool HasXmlTabError(string tabName)
        {
            return ErrorXmlTabs.Contains(tabName);
        }

        /// <summary>
        /// Normalize XML tab name từ validateFile
        /// Format: "XML3" → "XML3", "xml3" → "XML3", v.v.
        /// </summary>
        private string? NormalizeXmlTabName(string validateFile)
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

    
        /// <summary>
        /// Extract error IDs và XML tabs từ validation results (Main view)
        /// </summary>
        private void ExtractErrorIds(ValidateData validateData)
        {
            ErrorIds.Clear();
            ErrorXmlTabs.Clear();

            if (validateData.ValidationResults != null)
            {
                foreach (var rule in validateData.ValidationResults)
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
                                    ErrorIds.Add(error.Id.Value);
                                }
                            }
                        }

                        // Extract XML tab từ validateFile
                        if (!string.IsNullOrEmpty(rule.ValidateFile))
                        {
                            var xmlTab = NormalizeXmlTabName(rule.ValidateFile);
                            if (!string.IsNullOrEmpty(xmlTab))
                            {
                                ErrorXmlTabs.Add(xmlTab);
                            }
                        }
                    }
                }
            }

            // Notify UI về các tab error properties
            OnPropertyChanged(nameof(HasXml1Error));
            OnPropertyChanged(nameof(HasXml2Error));
            OnPropertyChanged(nameof(HasXml3Error));
            OnPropertyChanged(nameof(HasXml4Error));
            OnPropertyChanged(nameof(HasXml5Error));
        }

        /// <summary>
        /// Extract error IDs và XML tabs từ SelectedValidationResult cho overlay
        /// </summary>
        private void ExtractOverlayErrorIds()
        {
            OverlayErrorIds.Clear();
            OverlayErrorXmlTabs.Clear();

            if (SelectedValidationResult?.ValidationRules != null)
            {
                foreach (var rule in SelectedValidationResult.ValidationRules)
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
                                    OverlayErrorIds.Add(error.Id.Value);
                                }
                            }
                        }

                        // Extract XML tab từ validateFile
                        if (!string.IsNullOrEmpty(rule.ValidateFile))
                        {
                            var xmlTab = NormalizeXmlTabName(rule.ValidateFile);
                            if (!string.IsNullOrEmpty(xmlTab))
                            {
                                OverlayErrorXmlTabs.Add(xmlTab);
                            }
                        }
                    }
                }
            }

            // Notify UI về các overlay error properties
            OnPropertyChanged(nameof(HasOverlayXml1Error));
            OnPropertyChanged(nameof(HasOverlayXml2Error));
            OnPropertyChanged(nameof(HasOverlayXml3Error));
            OnPropertyChanged(nameof(HasOverlayXml4Error));
            OnPropertyChanged(nameof(HasOverlayXml5Error));
        }

        // ==================== ERROR CHECKING IN XMLS ====================    
        /// <summary>
        /// Đánh dấu các row có lỗi trong XML (Main view)
        /// Tối ưu: Chỉ check XML có lỗi (theo ErrorXmlTabs) thay vì check tất cả
        /// </summary>
        private void CheckErrorIdsInXmls()
        {
            if (_rawPatientData == null) return;

            // Tối ưu: Chỉ check XML có lỗi (theo ErrorXmlTabs từ ValidateFile)
            // Trước: Check TẤT CẢ 5 XML (~2500 records)
            // Sau: Chỉ check XML có lỗi (~500 records cho 1 XML)
            
            if (ErrorXmlTabs.Contains("XML1") && _rawPatientData.Xml1 != null)
            {
                foreach (var xml1 in _rawPatientData.Xml1)
                {
                    xml1.IsError = xml1.Id != 0 && ErrorIds.Contains(xml1.Id);
                }
            }

            if (ErrorXmlTabs.Contains("XML2") && _rawPatientData.Xml2 != null)
            {
                foreach (var xml2 in _rawPatientData.Xml2)
                {
                    xml2.IsError = xml2.Id != 0 && ErrorIds.Contains(xml2.Id);
                }
            }

            if (ErrorXmlTabs.Contains("XML3") && _rawPatientData.Xml3 != null)
            {
                foreach (var xml3 in _rawPatientData.Xml3)
                {
                    xml3.IsError = xml3.Id != 0 && ErrorIds.Contains(xml3.Id);
                }
            }

            if (ErrorXmlTabs.Contains("XML4") && _rawPatientData.Xml4 != null)
            {
                foreach (var xml4 in _rawPatientData.Xml4)
                {
                    xml4.IsError = xml4.Id != 0 && ErrorIds.Contains(xml4.Id);
                }
            }

            if (ErrorXmlTabs.Contains("XML5") && _rawPatientData.Xml5 != null)
            {
                foreach (var xml5 in _rawPatientData.Xml5)
                {
                    xml5.IsError = xml5.Id != 0 && ErrorIds.Contains(xml5.Id);
                }
            }
        }

        /// <summary>
        /// Đánh dấu các row có lỗi trong overlay XMLs
        /// Tối ưu: Chỉ check XML có lỗi (theo OverlayErrorXmlTabs) thay vì check tất cả
        /// </summary>
        private void CheckOverlayErrorIdsInXmls(PatientData patientData)
        {
            // Tối ưu: Chỉ check XML có lỗi (theo OverlayErrorXmlTabs từ ValidateFile)
            
            if (OverlayErrorXmlTabs.Contains("XML1") && patientData.Xml1 != null)
            {
                foreach (var xml1 in patientData.Xml1)
                {
                    xml1.IsError = xml1.Id != 0 && OverlayErrorIds.Contains(xml1.Id);
                }
            }

            if (OverlayErrorXmlTabs.Contains("XML2") && patientData.Xml2 != null)
            {
                foreach (var xml2 in patientData.Xml2)
                {
                    xml2.IsError = xml2.Id != 0 && OverlayErrorIds.Contains(xml2.Id);
                }
            }

            if (OverlayErrorXmlTabs.Contains("XML3") && patientData.Xml3 != null)
            {
                foreach (var xml3 in patientData.Xml3)
                {
                    xml3.IsError = xml3.Id != 0 && OverlayErrorIds.Contains(xml3.Id);
                }
            }

            if (OverlayErrorXmlTabs.Contains("XML4") && patientData.Xml4 != null)
            {
                foreach (var xml4 in patientData.Xml4)
                {
                    xml4.IsError = xml4.Id != 0 && OverlayErrorIds.Contains(xml4.Id);
                }
            }

            if (OverlayErrorXmlTabs.Contains("XML5") && patientData.Xml5 != null)
            {
                foreach (var xml5 in patientData.Xml5)
                {
                    xml5.IsError = xml5.Id != 0 && OverlayErrorIds.Contains(xml5.Id);
                }
            }
        }
    }
}

