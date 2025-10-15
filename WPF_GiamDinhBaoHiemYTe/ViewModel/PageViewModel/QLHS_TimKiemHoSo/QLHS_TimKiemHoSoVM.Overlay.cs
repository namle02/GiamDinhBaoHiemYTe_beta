using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
 
    public partial class QLHS_TimKiemHoSoVM
    {
        // ==================== MULTI-PATIENT OVERLAY CACHE ====================
        
        private const int MAX_OVERLAY_CACHE_SIZE = 10; // Cache tối đa 10 patients
        private readonly Dictionary<string, OverlayCacheItem> _overlayCache = new();
        
        /// <summary>
        /// Class để lưu overlay cache data cho mỗi patient
        /// </summary>
        private class OverlayCacheItem
        {
            public XML1? Xml1 { get; set; }
            public List<XML2>? Xml2 { get; set; }
            public List<XML3>? Xml3 { get; set; }
            public List<XML4>? Xml4 { get; set; }
            public List<XML5>? Xml5 { get; set; }
            public HashSet<int> ErrorIds { get; set; } = new();
            public HashSet<string> ErrorXmlTabs { get; set; } = new();
            public DateTime CachedTime { get; set; } = DateTime.UtcNow;
        }

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
                // 🚀 SIÊU TỐI ƯU: Check multi-patient cache trước
                if (_overlayCache.TryGetValue(maLk, out var cachedItem))
                {
                    // ✅ Có trong cache - INSTANT! (Patient A, B, C... đều instant)
                    OverlayXml1Data = cachedItem.Xml1;
                    OverlayXml2Data = cachedItem.Xml2;
                    OverlayXml3Data = cachedItem.Xml3;
                    OverlayXml4Data = cachedItem.Xml4;
                    OverlayXml5Data = cachedItem.Xml5;
                    
                    // Set error IDs và tabs từ cache
                    OverlayErrorIds.Clear();
                    foreach (var id in cachedItem.ErrorIds)
                        OverlayErrorIds.Add(id);
                    
                    OverlayErrorXmlTabs.Clear();
                    foreach (var tab in cachedItem.ErrorXmlTabs)
                        OverlayErrorXmlTabs.Add(tab);
                    
                    // QUAN TRỌNG: Notify UI để update header highlighting!
                    OnPropertyChanged(nameof(HasOverlayXml1Error));
                    OnPropertyChanged(nameof(HasOverlayXml2Error));
                    OnPropertyChanged(nameof(HasOverlayXml3Error));
                    OnPropertyChanged(nameof(HasOverlayXml4Error));
                    OnPropertyChanged(nameof(HasOverlayXml5Error));
                    
                    return; // INSTANT return! (~5ms)
                }
                
                // Không có trong cache - Load từ DB hoặc _rawPatientData
                PatientData? patientData = null;
                
                // Kiểm tra _rawPatientData trước (patient vừa search)
                if (_rawPatientData != null && 
                    (Xml1Data?.Ma_Lk?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true ||
                     Xml1Data?.Ma_Bn?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true))
                {
                    // Patient hiện tại - REUSE!
                    patientData = _rawPatientData;
                }
                else
                {
                    // Patient khác - Load từ DB
                    patientData = await _dataMapper.GetDataFromDB(maLk);
                }
                
                if (patientData != null)
                {
                    // Load XML1
                    if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
                    {
                        OverlayXml1Data = patientData.Xml1.FirstOrDefault(x => 
                            x.Ma_Lk?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true ||
                            x.Ma_Bn?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true
                        ) ?? patientData.Xml1[0];
                    }

                    // Load XML2-5
                    OverlayXml2Data = patientData.Xml2;
                    OverlayXml3Data = patientData.Xml3;
                    OverlayXml4Data = patientData.Xml4;
                    OverlayXml5Data = patientData.Xml5;

                    // Set STT cho tất cả các tab có cột STT
                    if (OverlayXml2Data != null && OverlayXml2Data.Count > 0 && OverlayXml2Data[0].Stt == null)
                    {
                        for (int i = 0; i < OverlayXml2Data.Count; i++)
                        {
                            OverlayXml2Data[i].Stt = i + 1;
                        }
                    }

                    if (OverlayXml3Data != null && OverlayXml3Data.Count > 0 && OverlayXml3Data[0].Stt == null)
                    {
                        for (int i = 0; i < OverlayXml3Data.Count; i++)
                        {
                            OverlayXml3Data[i].Stt = i + 1;
                        }
                    }

                    if (OverlayXml4Data != null && OverlayXml4Data.Count > 0 && OverlayXml4Data[0].Stt == null)
                    {
                        for (int i = 0; i < OverlayXml4Data.Count; i++)
                        {
                            OverlayXml4Data[i].Stt = i + 1;
                        }
                    }

                    if (OverlayXml5Data != null && OverlayXml5Data.Count > 0 && OverlayXml5Data[0].Stt == null)
                    {
                        for (int i = 0; i < OverlayXml5Data.Count; i++)
                        {
                            OverlayXml5Data[i].Stt = i + 1;
                        }
                    }

                    // Extract error IDs từ SelectedValidationResult
                    ExtractOverlayErrorIds();
                    
                    // QUAN TRỌNG: Check errors để update header highlighting!
                    CheckOverlayErrorIdsInXmls(patientData);
                }
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
                
                // Check xem đã có trong cache chưa
                if (_overlayCache.ContainsKey(maLk))
                    return; // Đã cache rồi, skip
                
                // Chạy trong background thread
                await Task.Run(async () =>
                {
                    if (_rawPatientData == null) return;
                    
                    var patientData = _rawPatientData;
                    
                    // Prepare data trên background thread
                    XML1? xml1 = null;
                    if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
                    {
                        xml1 = patientData.Xml1.FirstOrDefault(x => 
                            x.Ma_Lk?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true ||
                            x.Ma_Bn?.Equals(maLk, StringComparison.OrdinalIgnoreCase) == true
                        ) ?? patientData.Xml1[0];
                    }
                    
                    var xml2 = patientData.Xml2;
                    var xml3 = patientData.Xml3;
                    var xml4 = patientData.Xml4;
                    var xml5 = patientData.Xml5;
                    
                    // Set STT cho tất cả các tab có cột STT
                    if (xml2 != null && xml2.Count > 0 && xml2[0].Stt == null)
                    {
                        for (int i = 0; i < xml2.Count; i++)
                            xml2[i].Stt = i + 1;
                    }
                    
                    if (xml3 != null && xml3.Count > 0 && xml3[0].Stt == null)
                    {
                        for (int i = 0; i < xml3.Count; i++)
                            xml3[i].Stt = i + 1;
                    }
                    
                    if (xml4 != null && xml4.Count > 0 && xml4[0].Stt == null)
                    {
                        for (int i = 0; i < xml4.Count; i++)
                            xml4[i].Stt = i + 1;
                    }
                    
                    if (xml5 != null && xml5.Count > 0 && xml5[0].Stt == null)
                    {
                        for (int i = 0; i < xml5.Count; i++)
                            xml5[i].Stt = i + 1;
                    }
                    
                    // Extract errors và XML tabs trên background thread
                    var preloadErrorIds = new HashSet<int>();
                    var preloadErrorXmlTabs = new HashSet<string>();
                    
                    if (validationResult.ValidationRules != null)
                    {
                        foreach (var rule in validationResult.ValidationRules)
                        {
                            if (!rule.IsValid)
                            {
                                // Extract error IDs
                                if (rule.Errors != null)
                                {
                                    foreach (var error in rule.Errors)
                                    {
                                        if (error.Id.HasValue)
                                            preloadErrorIds.Add(error.Id.Value);
                                    }
                                }

                                // Extract XML tab từ validateFile
                                if (!string.IsNullOrEmpty(rule.ValidateFile))
                                {
                                    var xmlTab = NormalizeXmlTabName(rule.ValidateFile);
                                    if (!string.IsNullOrEmpty(xmlTab))
                                    {
                                        preloadErrorXmlTabs.Add(xmlTab);
                                    }
                                }
                            }
                        }
                    }
                    
                    // 🚀 LƯU VÀO CACHE
                    await System.Windows.Application.Current.Dispatcher.InvokeAsync(() =>
                    {
                        // Memory cleanup: Xóa cache cũ nhất nếu vượt quá giới hạn
                        if (_overlayCache.Count >= MAX_OVERLAY_CACHE_SIZE)
                        {
                            var oldestKey = _overlayCache.OrderBy(x => x.Value.CachedTime).First().Key;
                            _overlayCache.Remove(oldestKey);
                        }
                        
                        // Add vào cache
                        _overlayCache[maLk] = new OverlayCacheItem
                        {
                            Xml1 = xml1,
                            Xml2 = xml2,
                            Xml3 = xml3,
                            Xml4 = xml4,
                            Xml5 = xml5,
                            ErrorIds = preloadErrorIds,
                            ErrorXmlTabs = preloadErrorXmlTabs,
                            CachedTime = DateTime.UtcNow
                        };
                    });
                });
            }
            catch (Exception)
            {
                // Preload failed - OK, LoadOverlayData sẽ load lại khi cần
            }
        }
    }
}

