using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
 
    public partial class QLHS_TimKiemHoSoVM
    {
        // ==================== OVERLAY PROPERTIES ====================
        [ObservableProperty]
        private bool isOverlayVisible;

        [ObservableProperty]
        private PatientValidationResult? selectedValidationResult;

        // Dữ liệu XML cho overlay chi tiết
        [ObservableProperty]
        private XML1? overlayXml1Data;

        [ObservableProperty]
        private List<XML2>? overlayXml2Data;

        [ObservableProperty]
        private List<XML3>? overlayXml3Data;

        [ObservableProperty]
        private List<XML4>? overlayXml4Data;

        [ObservableProperty]
        private List<XML5>? overlayXml5Data;

        // ==================== OVERLAY ERROR TRACKING ====================
        [ObservableProperty]
        private HashSet<int> overlayErrorIds = new();

        [ObservableProperty]
        private HashSet<string> overlayErrorXmlTabs = new();

        // Computed properties để check error cho từng tab - FOR TAB HIGHLIGHTING IN OVERLAY
        public bool HasOverlayXml1Error => OverlayErrorXmlTabs.Contains("XML1");
        public bool HasOverlayXml2Error => OverlayErrorXmlTabs.Contains("XML2");
        public bool HasOverlayXml3Error => OverlayErrorXmlTabs.Contains("XML3");
        public bool HasOverlayXml4Error => OverlayErrorXmlTabs.Contains("XML4");
        public bool HasOverlayXml5Error => OverlayErrorXmlTabs.Contains("XML5");

        // ==================== OVERLAY COMMANDS ====================
        [RelayCommand]
        private async Task ShowErrorDetails(PatientValidationResult validationResult)
        {
            SelectedValidationResult = validationResult;
            
            // Load dữ liệu XML cho bệnh nhân được chọn
            // 🚀 Thường data đã được preload, nên sẽ instant
            await LoadOverlayData(validationResult.Ma_Lk);
            
            IsOverlayVisible = true;
        }

        private PatientData? TryGetPatientDataForOverlay(string maLk)
        {
            if (_rawPatientData != null &&
                (Xml1Data?.Ma_Lk?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true ||
                 Xml1Data?.Ma_Bn?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true))
            {
                return _rawPatientData;
            }

            return _patientCacheService.GetPatientData(maLk);
        }

        private void ApplyOverlayPatientData(string maLk, PatientData patientData)
        {
            if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
            {
                OverlayXml1Data = patientData.Xml1.FirstOrDefault(x =>
                    x.Ma_Lk?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true ||
                    x.Ma_Bn?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true
                ) ?? patientData.Xml1[0];
            }
            else
            {
                OverlayXml1Data = null;
            }

            var errorResult = SelectedValidationResult?.ValidationRules != null
                ? _validationErrorService.ExtractErrorIds(SelectedValidationResult.ValidationRules)
                : new ErrorExtractionResult();

            OverlayErrorIds.Clear();
            foreach (var id in errorResult.ErrorIds)
            {
                OverlayErrorIds.Add(id);
            }

            OverlayErrorXmlTabs.Clear();
            foreach (var tab in errorResult.ErrorXmlTabs)
            {
                OverlayErrorXmlTabs.Add(tab);
            }

            _validationErrorService.MarkErrorsInXmlData(patientData, OverlayErrorIds, OverlayErrorXmlTabs);

            var hasXml2Error = errorResult.HasErrorInTab("XML2");
            if (hasXml2Error && patientData.Xml2 != null)
            {
                OverlayXml2Data = patientData.Xml2
                    .Where(x => x.Id != 0 && errorResult.IsErrorId(x.Id))
                    .ToList();
                _patientDataProcessor.AssignSttToXmlData(OverlayXml2Data);
            }
            else
            {
                OverlayXml2Data = null;
            }

            var hasXml3Error = errorResult.HasErrorInTab("XML3");
            if (hasXml3Error && patientData.Xml3 != null)
            {
                var filteredXml3 = patientData.Xml3
                    .Where(x => x.Id != 0 && errorResult.IsErrorId(x.Id))
                    .ToList();
                OverlayXml3Data = _patientDataProcessor.SortAndAssignSttXml3(filteredXml3);
            }
            else
            {
                OverlayXml3Data = null;
            }

            var hasXml4Error = errorResult.HasErrorInTab("XML4");
            if (hasXml4Error && patientData.Xml4 != null)
            {
                var filteredXml4 = patientData.Xml4
                    .Where(x => x.Id != 0 && errorResult.IsErrorId(x.Id))
                    .ToList();
                OverlayXml4Data = _patientDataProcessor.SortAndAssignSttXml4(filteredXml4);
            }
            else
            {
                OverlayXml4Data = null;
            }

            var hasXml5Error = errorResult.HasErrorInTab("XML5");
            if (hasXml5Error && patientData.Xml5 != null)
            {
                OverlayXml5Data = patientData.Xml5
                    .Where(x => x.Id != 0 && errorResult.IsErrorId(x.Id))
                    .ToList();
                _patientDataProcessor.AssignSttToXmlData(OverlayXml5Data);
            }
            else
            {
                OverlayXml5Data = null;
            }

            OnPropertyChanged(nameof(HasOverlayXml1Error));
            OnPropertyChanged(nameof(HasOverlayXml2Error));
            OnPropertyChanged(nameof(HasOverlayXml3Error));
            OnPropertyChanged(nameof(HasOverlayXml4Error));
            OnPropertyChanged(nameof(HasOverlayXml5Error));
        }

        [RelayCommand]
        private void CloseOverlay()
        {
            IsOverlayVisible = false;
            SelectedValidationResult = null;
            
            // TỐI ƯU: Không clear data ngay - Giữ lại để reuse nếu user mở lại
            // Multi-patient cache sẽ xử lý việc switch giữa các patients
        }

        // ==================== OVERLAY DATA LOADING ====================
        /// <summary>
        /// Load dữ liệu XML cho overlay chi tiết - TỐI ƯU: Multi-patient cache
        /// </summary>
        private async Task LoadOverlayData(string maLk)
        {
            try
            {
                var patientData = TryGetPatientDataForOverlay(maLk);

                if (patientData == null)
                {
                    patientData = await _dataMapper.GetDataFromDB(maLk);
                    if (patientData != null)
                    {
                        var validationRules = SelectedValidationResult?.ValidationRules ?? new List<ValidationRule>();
                        _patientCacheService.AddPatientToCache(maLk, patientData, validationRules);
                    }
                }

                if (patientData == null)
                    return;

                ApplyOverlayPatientData(maLk, patientData);
            }
            catch (Exception)
            {
                // Error loading overlay data - suppress silently
            }
        }

        /// <summary>
        /// Preload overlay data trong background và LƯU VÀO CACHE cho nhiều patients
        /// Khi user click "Show Details" cho BẤT KỲ patient nào trong list → INSTANT!
        /// </summary>
        private async Task PreloadOverlayDataInBackground(PatientValidationResult validationResult)
        {
            try
            {
                var maLk = validationResult.Ma_Lk;
                if (string.IsNullOrWhiteSpace(maLk))
                    return;

                if (_patientCacheService.IsPatientCached(maLk))
                    return;

                var patientData = _rawPatientData;
                if (patientData == null)
                    return;

                var validationRules = validationResult.ValidationRules ?? new List<ValidationRule>();

                await Task.Run(() => _patientCacheService.AddPatientToCache(maLk, patientData, validationRules));
            }
            catch (Exception)
            {
                // Preload failed - OK, LoadOverlayData sẽ load lại khi cần
            }
        }
    }
}

