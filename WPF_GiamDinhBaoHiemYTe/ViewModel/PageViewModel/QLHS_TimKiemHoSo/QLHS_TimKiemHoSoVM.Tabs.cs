using System;
using System.Collections.Generic;
using System.Linq;
using CommunityToolkit.Mvvm.ComponentModel;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    /// <summary>
    /// ViewModel cho trang Tìm Kiếm Hồ Sơ - TAB LOADING
    /// File này chứa: Tab Properties, Lazy Loading Logic
    /// </summary>
    public partial class QLHS_TimKiemHoSoVM
    {
        // ==================== TAB PROPERTIES ====================
        [ObservableProperty]
        private int selectedTabIndex = 0;

        // Dữ liệu XML1-5 để hiển thị trong các tab (Main view)
        [ObservableProperty]
        private XML1? xml1Data;

        [ObservableProperty]
        private List<XML2>? xml2Data;

        [ObservableProperty]
        private List<XML3>? xml3Data;

        [ObservableProperty]
        private List<XML4>? xml4Data;

        [ObservableProperty]
        private List<XML5>? xml5Data;

        // Các thuộc tính để theo dõi tab nào đã được load
        private bool _xml1Loaded = false;
        private bool _xml2Loaded = false;
        private bool _xml3Loaded = false;
        private bool _xml4Loaded = false;
        private bool _xml5Loaded = false;

        // ==================== TAB CHANGE HANDLER ====================
        /// <summary>
        /// Property để theo dõi khi tab được thay đổi
        /// </summary>
        partial void OnSelectedTabIndexChanged(int value)
        {
            LoadTabDataIfNeeded(value);
        }

        // ==================== LAZY LOADING LOGIC ====================
        /// <summary>
        /// Lazy load dữ liệu tab chỉ khi tab được chọn
        /// </summary>
        private void LoadTabDataIfNeeded(int tabIndex)
        {
            if (_rawPatientData == null) return;

            switch (tabIndex)
            {
                case 0: // XML1
                    if (!_xml1Loaded)
                    {
                        if (_rawPatientData.Xml1 != null && _rawPatientData.Xml1.Count > 0)
                        {
                            Xml1Data = _rawPatientData.Xml1.FirstOrDefault(x => 
                                x.Ma_Lk?.Equals(PatientID, StringComparison.OrdinalIgnoreCase) == true ||
                                x.Ma_Bn?.Equals(PatientID, StringComparison.OrdinalIgnoreCase) == true
                            ) ?? _rawPatientData.Xml1[0];
                        }
                        _xml1Loaded = true;
                    }
                    break;

                case 1: // XML2
                    if (!_xml2Loaded)
                    {
                        if (_rawPatientData.Xml2 != null)
                        {
                            for (int i = 0; i < _rawPatientData.Xml2.Count; i++)
                            {
                                _rawPatientData.Xml2[i].Stt = i + 1;
                            }
                        }
                        Xml2Data = _rawPatientData.Xml2;
                        _xml2Loaded = true;
                    }
                    break;

                case 2: // XML3
                    if (!_xml3Loaded)
                    {
                        if (_rawPatientData.Xml3 != null)
                        {
                            for (int i = 0; i < _rawPatientData.Xml3.Count; i++)
                            {
                                _rawPatientData.Xml3[i].Stt = i + 1;
                            }
                        }
                        Xml3Data = _rawPatientData.Xml3;
                        _xml3Loaded = true;
                    }
                    break;

                case 3: // XML4
                    if (!_xml4Loaded)
                    {
                        if (_rawPatientData.Xml4 != null)
                        {
                            for (int i = 0; i < _rawPatientData.Xml4.Count; i++)
                            {
                                _rawPatientData.Xml4[i].Stt = i + 1;
                            }
                        }
                        Xml4Data = _rawPatientData.Xml4;
                        _xml4Loaded = true;
                    }
                    break;

                case 4: // XML5
                    if (!_xml5Loaded)
                    {
                        if (_rawPatientData.Xml5 != null)
                        {
                            for (int i = 0; i < _rawPatientData.Xml5.Count; i++)
                            {
                                _rawPatientData.Xml5[i].Stt = i + 1;
                            }
                        }
                        Xml5Data = _rawPatientData.Xml5;
                        _xml5Loaded = true;
                    }
                    break;
            }
        }
    }
}

