using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;
using WPF_GiamDinhBaoHiem.Repos.Dto;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using System.Globalization;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    /// <summary>
    /// ViewModel cho trang Tìm Kiếm Hồ Sơ - CORE
    /// File này chứa: Constructor, Dependencies, Core Properties, Search Command
    /// </summary>
    public partial class QLHS_TimKiemHoSoVM : ObservableObject
    {
        // ==================== DEPENDENCIES ====================
        private readonly IPatientServices _patientServices;
        private readonly IDataMapper _dataMapper;
        private readonly IPatientCacheService _patientCacheService;
        private readonly IExcelReaderService _excelReaderService;
        private readonly IBatchProcessorService _batchProcessorService;
        private readonly IExcelExportService _excelExportService;
        private readonly IValidationErrorService _validationErrorService;
        private readonly IPatientDataProcessor _patientDataProcessor;
        private readonly IDialogService _dialogService;
        private readonly IValidationResultBuilder _validationResultBuilder;
        internal PatientData? _rawPatientData; // internal để các partial classes khác access được
        
        // ==================== CONSTANTS ====================
        // Memory management - Giới hạn số lượng ValidationResults để tiết kiệm RAM
        private const int MAX_VALIDATION_RESULTS = 100;
        
        // ==================== CORE PROPERTIES ====================
        [ObservableProperty]
        private bool isLoading;

        [ObservableProperty]
        private string patientID = string.Empty;

        [ObservableProperty]
        private ObservableCollection<PatientValidationResult> validationResults = new();

        // ==================== SEARCH MODE PROPERTIES ====================
        /// <summary>
        /// Chế độ tìm kiếm: true = tìm theo MA_BN, false = tìm theo MA_LK
        /// </summary>
        [ObservableProperty]
        private bool isSearchByMaBn = false;

        /// <summary>
        /// Mã bệnh nhân (khi tìm theo MA_BN)
        /// </summary>
        [ObservableProperty]
        private string maBenhNhan = string.Empty;

        /// <summary>
        /// Ngày vào (from)
        /// </summary>
        [ObservableProperty]
        private DateTime? ngayVaoFrom = DateTime.Now.AddMonths(-1);

        /// <summary>
        /// Ngày ra (to)
        /// </summary>
        [ObservableProperty]
        private DateTime? ngayRaTo = DateTime.Now;

        /// <summary>
        /// Danh sách MA_LK tìm được (khi tìm theo MA_BN)
        /// </summary>
        [ObservableProperty]
        private ObservableCollection<MaLkSearchResult> maLkSearchResults = new();

        /// <summary>
        /// MA_LK đang được chọn trong danh sách
        /// </summary>
        [ObservableProperty]
        private MaLkSearchResult? selectedMaLkResult;

        /// <summary>
        /// Helper property để bind visibility - tự động update khi Count thay đổi
        /// </summary>
        public bool HasMaLkSearchResults => MaLkSearchResults != null && MaLkSearchResults.Count > 0;

        /// <summary>
        /// Trạng thái mở rộng/thu gọn của danh sách MA_LK search results
        /// </summary>
        [ObservableProperty]
        private bool isSearchResultsExpanded = true;

        // ==================== BATCH PROCESSING PROPERTIES ====================
        [ObservableProperty]
        private bool isBatchProcessing;

        [ObservableProperty]
        private int batchProgress;

        [ObservableProperty]
        private int batchTotal;

        [ObservableProperty]
        private string batchStatus = string.Empty;

        [ObservableProperty]
        private bool canCancelBatch = false;

        [ObservableProperty]
        private int batchSuccessCount = 0;

        [ObservableProperty]
        private int batchErrorCount = 0;

        [ObservableProperty]
        private double batchProcessingSpeed = 0; // patients per second

        [ObservableProperty]
        private string currentProcessingPatient = string.Empty;

        [ObservableProperty]
        private double batchProgressPercentage = 0;

        private CancellationTokenSource? _batchCancellationTokenSource;
        private DateTime _batchStartTime;

        // ==================== CONSTRUCTOR ====================
        public QLHS_TimKiemHoSoVM(
            IPatientServices patientServices, 
            IDataMapper dataMapper, 
            IPatientCacheService patientCacheService, 
            IExcelReaderService excelReaderService, 
            IBatchProcessorService batchProcessorService, 
            IExcelExportService excelExportService,
            IValidationErrorService validationErrorService,
            IPatientDataProcessor patientDataProcessor,
            IDialogService dialogService,
            IValidationResultBuilder validationResultBuilder)
        {
            _patientServices = patientServices;
            _dataMapper = dataMapper;
            _patientCacheService = patientCacheService;
            _excelReaderService = excelReaderService;
            _batchProcessorService = batchProcessorService;
            _excelExportService = excelExportService;
            _validationErrorService = validationErrorService;
            _patientDataProcessor = patientDataProcessor;
            _dialogService = dialogService;
            _validationResultBuilder = validationResultBuilder;
        }

        // ==================== SEARCH MODE TOGGLE ====================
        [RelayCommand]
        private void ToggleSearchMode()
        {
            IsSearchByMaBn = !IsSearchByMaBn;
            
            // Clear results khi chuyển đổi mode
            MaLkSearchResults.Clear();
            SelectedMaLkResult = null;
            OnPropertyChanged(nameof(HasMaLkSearchResults));
            
            // Clear search inputs
            if (IsSearchByMaBn)
            {
                // Chuyển sang mode tìm theo MA_BN
                PatientID = string.Empty; // Clear MA_LK input
                System.Diagnostics.Debug.WriteLine("Chuyển sang tìm kiếm theo MA_BN");
            }
            else
            {
                // Chuyển về mode tìm theo MA_LK
                MaBenhNhan = string.Empty; // Clear MA_BN input
                System.Diagnostics.Debug.WriteLine("Chuyển về tìm kiếm theo MA_LK");
            }
            
            // Notify UI to update visibility
            OnPropertyChanged(nameof(IsSearchByMaBn));
        }

        // ==================== SEARCH BY MA_BN ====================
        [RelayCommand]
        private async Task SearchByMaBn()
        {
            if (string.IsNullOrWhiteSpace(MaBenhNhan))
            {
                _dialogService.ShowWarning("Vui lòng nhập mã bệnh nhân", "Thông báo");
                return;
            }

            if (NgayVaoFrom == null || NgayRaTo == null)
            {
                _dialogService.ShowWarning("Vui lòng chọn khoảng thời gian", "Thông báo");
                return;
            }

            if (NgayVaoFrom > NgayRaTo)
            {
                _dialogService.ShowWarning("Ngày vào phải nhỏ hơn hoặc bằng ngày ra", "Thông báo");
                return;
            }

            try
            {
                IsLoading = true;
                MaLkSearchResults.Clear();

                // Format ngày sang yyyyMMdd0000 và yyyyMMdd2359
                string ngayVaoFromStr = NgayVaoFrom.Value.ToString("yyyyMMdd") + "0000";
                string ngayRaToStr = NgayRaTo.Value.ToString("yyyyMMdd") + "2359";

                System.Diagnostics.Debug.WriteLine($"Tìm kiếm MA_LK với MA_BN: {MaBenhNhan}, từ {ngayVaoFromStr} đến {ngayRaToStr}");

                var results = await _dataMapper.GetMaLkByMaBnAndDate(MaBenhNhan, ngayVaoFromStr, ngayRaToStr);

                System.Diagnostics.Debug.WriteLine($"SearchByMaBn: Nhận được {results?.Count ?? 0} kết quả từ database");

                if (results == null || results.Count == 0)
                {
                    _dialogService.ShowInformation($"Không tìm thấy MA_LK nào cho bệnh nhân {MaBenhNhan} trong khoảng thời gian này", "Thông báo");
                    System.Diagnostics.Debug.WriteLine("SearchByMaBn: Không có kết quả, hiển thị thông báo");
                    return;
                }

                // Thêm kết quả vào ObservableCollection trên UI thread
                System.Diagnostics.Debug.WriteLine($"SearchByMaBn: Bắt đầu thêm {results.Count} kết quả vào MaLkSearchResults");
                
                // Đảm bảo update UI trên UI thread
                System.Windows.Application.Current.Dispatcher.Invoke(() =>
                {
                    foreach (var result in results)
                    {
                        MaLkSearchResults.Add(result);
                        System.Diagnostics.Debug.WriteLine($"SearchByMaBn: Thêm MA_LK: {result.Ma_Lk} - {result.DisplayText}");
                    }

                    System.Diagnostics.Debug.WriteLine($"SearchByMaBn: Hoàn thành! MaLkSearchResults.Count = {MaLkSearchResults.Count}");
                    
                    // Trigger property changed để UI update
                    OnPropertyChanged(nameof(MaLkSearchResults));
                    OnPropertyChanged(nameof(HasMaLkSearchResults));
                    
                    System.Diagnostics.Debug.WriteLine($"SearchByMaBn: HasMaLkSearchResults = {HasMaLkSearchResults}");
                });
            }
            catch (Exception ex)
            {
                _dialogService.ShowError($"Lỗi khi tìm kiếm: {ex.Message}", "Lỗi");
            }
            finally
            {
                IsLoading = false;
            }
        }

        // ==================== SELECT MA_LK FROM LIST ====================
        [RelayCommand]
        private async Task SelectMaLkFromList(MaLkSearchResult? maLkResult)
        {
            if (maLkResult == null || string.IsNullOrWhiteSpace(maLkResult.Ma_Lk))
            {
                System.Diagnostics.Debug.WriteLine("SelectMaLkFromList: MA_LK is null or empty");
                return;
            }

            System.Diagnostics.Debug.WriteLine($"SelectMaLkFromList: Selected MA_LK = {maLkResult.Ma_Lk}");

            // Gán MA_LK vào PatientID để sử dụng search command thông thường
            PatientID = maLkResult.Ma_Lk;

            // Gọi search command với MA_LK
            await Search(maLkResult.Ma_Lk);
        }

        /// <summary>
        /// Toggle mở rộng/thu gọn danh sách MA_LK search results
        /// </summary>
        [RelayCommand]
        private void ToggleSearchResultsExpand()
        {
            IsSearchResultsExpanded = !IsSearchResultsExpanded;
            System.Diagnostics.Debug.WriteLine($"ToggleSearchResultsExpand: IsExpanded = {IsSearchResultsExpanded}");
        }

        // ==================== SEARCH COMMAND ====================
        [RelayCommand]
        private async Task Search(string patientId)
        {
            if (string.IsNullOrWhiteSpace(patientId))
            {
                System.Diagnostics.Debug.WriteLine("Search: PatientId is null or empty");
                return;
            }

            try
            {
                IsLoading = true;
                System.Diagnostics.Debug.WriteLine($"Search: Starting search for patient {patientId}");

                // Lấy dữ liệu bệnh nhân từ DB
                PatientData? patientData = null;
                try
                {
                    patientData = await _dataMapper.GetDataFromDB(patientId);
                    System.Diagnostics.Debug.WriteLine($"Search: Database query completed for {patientId}");
                }
                catch (Exception dbEx)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: Database error for {patientId}: {dbEx.Message}");
                    throw new InvalidOperationException($"Không thể lấy dữ liệu bệnh nhân từ database: {dbEx.Message}", dbEx);
                }

                // Kiểm tra dữ liệu từ DB
                if (patientData == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: No patient data found for {patientId}");
                    throw new InvalidOperationException($"Không tìm thấy dữ liệu bệnh nhân với mã: {patientId}");
                }

                // Gọi API validate
                ApiResponse<ValidateData>? apiResponse = null;
                try
                {
                    System.Diagnostics.Debug.WriteLine($"Search: Calling API for {patientId}");
                    apiResponse = await _patientServices.LoadPatientAndValidateData(patientId);
                    System.Diagnostics.Debug.WriteLine($"Search: API call completed for {patientId}");
                }
                catch (Exception apiEx)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: API error for {patientId}: {apiEx.Message}");
                    throw new InvalidOperationException($"Không thể kết nối đến server validation: {apiEx.Message}", apiEx);
                }

                // Kiểm tra response từ API
                if (apiResponse == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: API returned null for {patientId}");
                    throw new InvalidOperationException("Server không phản hồi. Vui lòng thử lại sau.");
                }

                if (!apiResponse.Success)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: API failed for {patientId}: {apiResponse.Message}");
                    throw new InvalidOperationException($"Lỗi từ server: {apiResponse.Message ?? "Không xác định"}");
                }

                if (apiResponse.Data == null)
                {
                    System.Diagnostics.Debug.WriteLine($"Search: API returned null data for {patientId}");
                    throw new InvalidOperationException("Server trả về dữ liệu rỗng. Vui lòng kiểm tra lại.");
                }

                // Lưu trữ dữ liệu XML1-5 để hiển thị trong các tab
                System.Diagnostics.Debug.WriteLine($"Search: Processing patient data for {patientId}");
                _rawPatientData = patientData;
                
                if (patientData.Xml1 != null && patientData.Xml1.Count > 0)
                {
                    Xml1Data = patientData.Xml1.FirstOrDefault(x => 
                        x.Ma_Lk?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true ||
                        x.Ma_Bn?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true
                    ) ?? patientData.Xml1[0];
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine($"Search: No Xml1 data found for {patientId}");
                    throw new InvalidOperationException($"Không tìm thấy dữ liệu XML1 cho bệnh nhân: {patientId}");
                }

                // Reset trạng thái load cho các tab khác
                _xml1Loaded = true; 
                _xml2Loaded = false;
                _xml3Loaded = false;
                _xml4Loaded = false;
                _xml5Loaded = false;

                // Xử lý kết quả validation
                var validateData = apiResponse.Data;
                System.Diagnostics.Debug.WriteLine($"Search: Processing validation results for {patientId}");

                // Extract error IDs từ validation results - SỬ DỤNG SERVICE
                var errorResult = _validationErrorService.ExtractErrorIds(validateData);
                ErrorIds = errorResult.ErrorIds;
                ErrorXmlTabs = errorResult.ErrorXmlTabs;
                
                // Check error IDs trong các XML - SỬ DỤNG SERVICE
                if (_rawPatientData != null)
                {
                    _validationErrorService.MarkErrorsInXmlData(_rawPatientData, ErrorIds, ErrorXmlTabs);
                }
                
                // Notify UI để update tab highlighting
                OnPropertyChanged(nameof(HasXml1Error));
                OnPropertyChanged(nameof(HasXml2Error));
                OnPropertyChanged(nameof(HasXml3Error));
                OnPropertyChanged(nameof(HasXml4Error));
                OnPropertyChanged(nameof(HasXml5Error));
                
                // Tạo kết quả validation cho hiển thị trong bảng - SỬ DỤNG SERVICE
                if (Xml1Data != null)
                {
                    var result = _validationResultBuilder.BuildValidationResult(Xml1Data, validateData.ValidationResults);

                    // Kiểm tra xem bệnh nhân đã có trong ValidationResults chưa
                    var existingResult = ValidationResults.FirstOrDefault(r => r.Ma_Lk == result.Ma_Lk);
                    if (existingResult == null)
                    {
                        // Memory cleanup: Xóa kết quả cũ nhất nếu vượt quá giới hạn
                        if (ValidationResults.Count >= MAX_VALIDATION_RESULTS)
                        {
                            ValidationResults.RemoveAt(0);
                        }
                        ValidationResults.Add(result);
                    }
                    else
                    {
                        // Cập nhật kết quả hiện có
                        var index = ValidationResults.IndexOf(existingResult);
                        ValidationResults[index] = result;
                    }
                    
                    // Lưu vào cache
                    if (validateData.ValidationResults != null && patientData != null)
                    {
                        _patientCacheService.AddPatientToCache(patientId, patientData, validateData.ValidationResults);
                    }
                    
                    // Preload overlay data
                    _ = PreloadOverlayDataInBackground(result);
                    
                    System.Diagnostics.Debug.WriteLine($"Search: Successfully completed for {patientId}");
                }
                else
                {
                    throw new InvalidOperationException($"Không thể tạo kết quả validation cho bệnh nhân: {patientId}");
                }
            }
            catch (InvalidOperationException ex)
            {
                // Lỗi business logic - SỬ DỤNG DIALOG SERVICE
                System.Diagnostics.Debug.WriteLine($"Search: Business error for {patientId}: {ex.Message}");
                _dialogService.ShowWarning(ex.Message, "Lỗi tìm kiếm");
            }
            catch (HttpRequestException ex)
            {
                // Lỗi network - SỬ DỤNG DIALOG SERVICE
                System.Diagnostics.Debug.WriteLine($"Search: Network error for {patientId}: {ex.Message}");
                
                var message = ex.Message.Contains("timeout") || ex.Message.Contains("timed out")
                    ? "Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại."
                    : "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.";
                
                _dialogService.ShowError(message, "Lỗi kết nối");
            }
            catch (TaskCanceledException ex)
            {
                // Lỗi timeout hoặc cancel - SỬ DỤNG DIALOG SERVICE
                System.Diagnostics.Debug.WriteLine($"Search: Timeout/Cancel error for {patientId}: {ex.Message}");
                _dialogService.ShowWarning("Yêu cầu bị timeout. Vui lòng thử lại.", "Timeout");
            }
            catch (Exception ex)
            {
                // Lỗi không xác định - SỬ DỤNG DIALOG SERVICE
                System.Diagnostics.Debug.WriteLine($"Search: Unexpected error for {patientId}: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Search: Stack trace: {ex.StackTrace}");
                
                _dialogService.ShowError($"Đã xảy ra lỗi không xác định: {ex.Message}", "Lỗi hệ thống");
            }
            finally
            {
                IsLoading = false;
                System.Diagnostics.Debug.WriteLine($"Search: Loading completed for {patientId}");
            }
        }

        // ==================== BATCH PROCESSING COMMANDS ====================
        
        [RelayCommand]
        private async Task ImportExcelAndProcess()
        {
            try
            {
                // SỬ DỤNG DIALOG SERVICE
                var filePath = _dialogService.ShowOpenExcelFileDialog("Chọn file Excel chứa danh sách mã liên kết");
                if (filePath == null)
                    return;

                // Lấy danh sách tên các sheet trong file
                var sheetNames = await _excelReaderService.GetSheetNamesAsync(filePath);
                
                string? selectedSheet = null;
                
                // Nếu có nhiều sheet, hiển thị dialog chọn sheet - SỬ DỤNG DIALOG SERVICE
                if (sheetNames.Count > 1)
                {
                    selectedSheet = _dialogService.ShowSheetSelectionDialog(sheetNames);
                    if (selectedSheet == null)
                    {
                        // User đã hủy
                        return;
                    }
                }
                else if (sheetNames.Count == 1)
                {
                    // Chỉ có 1 sheet, tự động chọn
                    selectedSheet = sheetNames[0];
                }
                else
                {
                    BatchStatus = "Lỗi: File Excel không có sheet nào";
                    return;
                }
                
                await ProcessExcelFile(filePath, selectedSheet);
            }
            catch (Exception ex)
            {
                BatchStatus = $"Lỗi: {ex.Message}";
            }
        }

        private async Task ProcessExcelFile(string filePath, string? sheetName = null)
        {
            try
            {
                IsBatchProcessing = true;
                CanCancelBatch = true;
                BatchStatus = "Đang đọc file Excel...";
                BatchProgress = 0;
                BatchTotal = 0;
                BatchSuccessCount = 0;
                BatchErrorCount = 0;
                BatchProcessingSpeed = 0;
                CurrentProcessingPatient = string.Empty;
                BatchProgressPercentage = 0;

                // Tạo cancellation token source và ghi nhận thời gian bắt đầu
                _batchCancellationTokenSource = new CancellationTokenSource();
                _batchStartTime = DateTime.Now;

                // Đọc dữ liệu từ Excel (tự động phát hiện format MA_LK hoặc MA_BN + dates)
                var excelData = await _excelReaderService.ReadDataFromExcelAsync(filePath, sheetName);
                
                if (excelData == null || excelData.Count == 0)
                {
                    BatchStatus = "Không tìm thấy dữ liệu trong file Excel";
                    return;
                }

                // Đếm số lượng theo loại
                int maLkCount = excelData.Count(x => x.DataType == "MA_LK");
                int maBnCount = excelData.Count(x => x.DataType == "MA_BN");

                BatchTotal = excelData.Count;
                if (maBnCount > 0)
                {
                    BatchStatus = $"Đã đọc {excelData.Count} dòng (MA_LK: {maLkCount}, MA_BN: {maBnCount}). Bắt đầu xử lý...";
                    System.Diagnostics.Debug.WriteLine($"Excel: Phát hiện format MA_BN, sẽ tìm MA_LK tự động");
                }
                else
                {
                    BatchStatus = $"Đã đọc {excelData.Count} mã liên kết. Bắt đầu xử lý song song...";
                }

                // Sử dụng BatchProcessorService với method mới
                var batchResult = await _batchProcessorService.ProcessExcelDataAsync(
                    excelData,
                    maxConcurrency: 5, // Xử lý tối đa 5 request đồng thời
                    onProgress: (progress) =>
                    {
                        // Cập nhật UI từ UI thread
                        System.Windows.Application.Current.Dispatcher.Invoke(() =>
                        {
                            BatchProgress = progress.Current;
                            BatchStatus = progress.Status;
                            CurrentProcessingPatient = progress.CurrentPatientId;
                            BatchProgressPercentage = progress.Percentage;
                            
                            // Cập nhật thống kê real-time từ progress callback
                            BatchSuccessCount = progress.SuccessCount;
                            BatchErrorCount = progress.ErrorCount;
                            
                            // Tính toán tốc độ xử lý dựa trên thời gian đã trôi qua
                            if (progress.Current > 0)
                            {
                                var elapsedSeconds = (DateTime.Now - _batchStartTime).TotalSeconds;
                                if (elapsedSeconds > 0)
                                {
                                    BatchProcessingSpeed = progress.Current / elapsedSeconds;
                                }
                            }
                        });
                    },
                    cancellationToken: _batchCancellationTokenSource.Token
                );

                // Thống kê đã được cập nhật real-time trong progress callback
                // Chỉ cập nhật tốc độ cuối cùng
                BatchProcessingSpeed = batchResult.TotalTime.TotalSeconds > 0 
                    ? batchResult.SuccessCount / batchResult.TotalTime.TotalSeconds 
                    : 0;

                // Xử lý kết quả và cập nhật ValidationResults
                await ProcessBatchResults(batchResult);

                // Kiểm tra số lượng bệnh nhân sau khi xử lý
                await ValidatePatientCounts(batchResult);

                if (_batchCancellationTokenSource.Token.IsCancellationRequested)
                {
                    BatchStatus = $"Đã hủy! Đã xử lý {batchResult.SuccessCount}/{batchResult.TotalProcessed} bệnh nhân trước khi hủy.";
                }
                else
                {
                    BatchStatus = $"Hoàn thành! Đã xử lý {batchResult.SuccessCount}/{batchResult.TotalProcessed} bệnh nhân thành công trong {batchResult.TotalTime.TotalSeconds:F1}s (Tốc độ: {BatchProcessingSpeed:F1} bệnh nhân/giây).";
                }
            }
            catch (OperationCanceledException)
            {
                BatchStatus = "Đã hủy xử lý batch.";
            }
            catch (Exception ex)
            {
                BatchStatus = $"Lỗi: {ex.Message}";
            }
            finally
            {
                IsBatchProcessing = false;
                CanCancelBatch = false;
                _batchCancellationTokenSource?.Dispose();
                _batchCancellationTokenSource = null;
            }
        }

        /// <summary>
        /// Xử lý kết quả từ batch processing và cập nhật ValidationResults
        /// </summary>
        private async Task ProcessBatchResults(BatchProcessingResult batchResult)
        {
            
            foreach (var result in batchResult.Results.Where(r => r.IsSuccess && r.ValidationResult?.Data != null))
            {
                try
                {
                    // Lấy dữ liệu patient từ cache hoặc database
                    var patientData = _patientCacheService.GetCachedPatient(result.PatientId)?.PatientData;
                    if (patientData == null)
                    {
                        patientData = await _dataMapper.GetDataFromDB(result.PatientId);
                    }

                    if (patientData?.Xml1 != null && patientData.Xml1.Count > 0)
                    {
                        var xml1Data = patientData.Xml1.FirstOrDefault(x => 
                            x.Ma_Lk?.Equals(result.PatientId, StringComparison.OrdinalIgnoreCase) == true ||
                            x.Ma_Bn?.Equals(result.PatientId, StringComparison.OrdinalIgnoreCase) == true
                        ) ?? patientData.Xml1[0];

                        // SỬ DỤNG VALIDATION RESULT BUILDER SERVICE
                        var validationResult = _validationResultBuilder.BuildValidationResult(
                            xml1Data, 
                            result.ValidationResult.Data.ValidationResults);

                        // Kiểm tra xem bệnh nhân đã có trong ValidationResults chưa
                        var existingResult = ValidationResults.FirstOrDefault(r => r.Ma_Lk == validationResult.Ma_Lk);
                        if (existingResult == null)
                        {
                            // Memory cleanup: Xóa kết quả cũ nhất nếu vượt quá giới hạn
                            if (ValidationResults.Count >= MAX_VALIDATION_RESULTS)
                            {
                                ValidationResults.RemoveAt(0);
                            }
                            ValidationResults.Add(validationResult);
                        }
                        else
                        {
                            // Cập nhật kết quả hiện có
                            var index = ValidationResults.IndexOf(existingResult);
                            ValidationResults[index] = validationResult;
                        }
                    }
                }
                catch (Exception ex)
                {
                    // Log lỗi nhưng tiếp tục xử lý các kết quả khác
                    System.Diagnostics.Debug.WriteLine($"Error processing batch result for {result.PatientId}: {ex.Message}");
                }
            }
            
        }

        /// <summary>
        /// Kiểm tra số lượng bệnh nhân và tìm những MA_LK không hiển thị kết quả
        /// </summary>
        private async Task ValidatePatientCounts(BatchProcessingResult batchResult)
        {
            // Kiểm tra số lượng bệnh nhân
            if (batchResult.SuccessCount != ValidationResults.Count)
            {
                // Lấy danh sách MA_LK đã hiển thị trên màn hình
                var displayedMaLkList = ValidationResults.Select(r => r.Ma_Lk).ToList();
                
                // Tìm những MA_LK thành công nhưng không hiển thị trên màn hình
                var missingMaLkList = new List<string>();
                
                foreach (var result in batchResult.Results)
                {
                    if (result.IsSuccess && result.ValidationResult?.Data != null)
                    {
                        // Kiểm tra xem MA_LK này có hiển thị trên màn hình không
                        if (!displayedMaLkList.Contains(result.PatientId))
                        {
                            missingMaLkList.Add(result.PatientId);
                        }
                    }
                }
                
                if (missingMaLkList.Count > 0)
                {
                    var errorMessage = $"Phát hiện {missingMaLkList.Count} mã liên kết xử lý thành công nhưng không hiển thị kết quả:\n\n" +
                                     string.Join("\n", missingMaLkList) +
                                     "\n\nCó thể do:\n" +
                                     "- Dữ liệu không đầy đủ trong database\n" +
                                     "- Lỗi khi lấy thông tin XML1\n" +
                                     "- Vấn đề về format hoặc cấu trúc dữ liệu";
                    
                    // SỬ DỤNG DIALOG SERVICE
                    _dialogService.ShowWarning(errorMessage, "Cảnh báo: MA_LK không hiển thị");
                }
            }
        }

        // ==================== BATCH CANCELLATION ====================
        
        [RelayCommand]
        private void CancelBatchProcessing()
        {
            if (_batchCancellationTokenSource != null && !_batchCancellationTokenSource.Token.IsCancellationRequested)
            {
                _batchCancellationTokenSource.Cancel();
                BatchStatus = "Đang hủy xử lý batch...";
            }
        }

        // ==================== CACHE MANAGEMENT ====================
        
        [RelayCommand]
        private void ClearAllCache()
        {
            _patientCacheService.ClearAllCache();
            
            // Clear current data
            ValidationResults.Clear();
            _rawPatientData = null;
            Xml1Data = null;
            Xml2Data = null;
            Xml3Data = null;
            Xml4Data = null;
            Xml5Data = null;
            PatientID = string.Empty;
            
            // Clear overlay data
            OverlayXml1Data = null;
            OverlayXml2Data = null;
            OverlayXml3Data = null;
            OverlayXml4Data = null;
            OverlayXml5Data = null;
            OverlayErrorIds.Clear();
            OverlayErrorXmlTabs.Clear();
            
            //  Clear multi-patient overlay cache
            _overlayCache.Clear();
        }

        // ==================== EXPORT COMMANDS ====================
        
        [RelayCommand]
        private async Task ExportToExcel()
        {
            if (ValidationResults == null || !ValidationResults.Any())
            {
                // SỬ DỤNG DIALOG SERVICE
                _dialogService.ShowInformation("Không có dữ liệu để export", "Thông báo");
                return;
            }

            // SỬ DỤNG DIALOG SERVICE
            var filePath = _dialogService.ShowSaveExcelFileDialog(
                $"BaoCaoValidation_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx",
                "Lưu file Excel");

            if (filePath != null)
            {
                try
                {
                    IsLoading = true;
                    System.Diagnostics.Debug.WriteLine($"Export: Bắt đầu export {ValidationResults.Count} bệnh nhân ra file {filePath}");
                    
                    var success = await _excelExportService.ExportValidationResultsToExcelAsync(
                        ValidationResults.ToList(), 
                        filePath);
                    
                    if (success)
                    {
                        var message = $"Export thành công!\n\n" +
                                    $"File đã được lưu tại: {filePath}\n" +
                                    $"Tổng số bệnh nhân: {ValidationResults.Count}\n" +
                                    $"Số bệnh nhân có lỗi: {ValidationResults.Count(r => r.IsError)}\n" +
                                    $"Số bệnh nhân không lỗi: {ValidationResults.Count(r => !r.IsError)}\n\n" +
                                    $"File Excel bao gồm:\n" +
                                    $"- Sheet 'Tổng Quan': Thông tin tất cả bệnh nhân\n" +
                                    $"- Các sheet theo từng loại lỗi: Chi tiết bệnh nhân có lỗi";
                        
                        // SỬ DỤNG DIALOG SERVICE
                        _dialogService.ShowInformation(message, "Export thành công");
                        System.Diagnostics.Debug.WriteLine($"Export: Export thành công file {filePath}");
                    }
                    else
                    {
                        _dialogService.ShowError("Có lỗi xảy ra khi export file", "Lỗi Export");
                        System.Diagnostics.Debug.WriteLine($"Export: Export thất bại file {filePath}");
                    }
                }
                catch (Exception ex)
                {
                    var errorMessage = $"Lỗi khi export: {ex.Message}";
                    _dialogService.ShowError(errorMessage, "Lỗi Export");
                    System.Diagnostics.Debug.WriteLine($"Export: Lỗi khi export - {ex.Message}");
                }
                finally
                {
                    IsLoading = false;
                }
            }
        }

    }
}

