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
using System.Windows;

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
        public QLHS_TimKiemHoSoVM(IPatientServices patientServices, IDataMapper dataMapper, IPatientCacheService patientCacheService, IExcelReaderService excelReaderService, IBatchProcessorService batchProcessorService)
        {
            _patientServices = patientServices;
            _dataMapper = dataMapper;
            _patientCacheService = patientCacheService;
            _excelReaderService = excelReaderService;
            _batchProcessorService = batchProcessorService;
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

                // Extract error IDs từ validation results
                ExtractErrorIds(validateData);
                
                // Check error IDs trong các XML
                CheckErrorIdsInXmls();
                
                // Tạo kết quả validation cho hiển thị trong bảng
                if (Xml1Data != null)
                {
                    // Tạo string tổng hợp các lỗi
                    var errorMessages = new List<string>();
                    
                    if (validateData.ValidationResults != null)
                    {
                        foreach (var rule in validateData.ValidationResults)
                        {
                            if (!rule.IsValid)
                            {
                                errorMessages.Add($"• {rule.RuleName}");
                            }
                        }
                    }

                    var result = new PatientValidationResult
                    {
                        Ma_Lk = Xml1Data.Ma_Lk ?? "",
                        Ho_Ten = Xml1Data.Ho_Ten ?? "",
                        Gioi_Tinh = Xml1Data.Gioi_Tinh == 1 ? "Nam" : (Xml1Data.Gioi_Tinh == 2 ? "Nữ" : "Khác"),
                        Nam_Sinh = Xml1Data.Ngay_Sinh ?? "",
                        Noi_Dung_Loi = errorMessages.Count > 0 
                            ? string.Join("\n", errorMessages) 
                            : "Không có lỗi",
                        IsError = errorMessages.Count > 0,
                        ValidationRules = validateData.ValidationResults
                    };

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
                    
                    System.Diagnostics.Debug.WriteLine($"Search: Successfully completed for {patientId} with {errorMessages.Count} errors");
                }
                else
                {
                    throw new InvalidOperationException($"Không thể tạo kết quả validation cho bệnh nhân: {patientId}");
                }
            }
            catch (InvalidOperationException ex)
            {
                // Lỗi business logic - hiển thị thông báo cho user
                System.Diagnostics.Debug.WriteLine($"Search: Business error for {patientId}: {ex.Message}");
                
                // TODO: Thay thế bằng notification service hoặc MessageBox
                MessageBox.Show(ex.Message, "Lỗi tìm kiếm", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
            catch (HttpRequestException ex)
            {
                // Lỗi network - hiển thị thông báo network
                System.Diagnostics.Debug.WriteLine($"Search: Network error for {patientId}: {ex.Message}");
                
                var message = ex.Message.Contains("timeout") || ex.Message.Contains("timed out")
                    ? "Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại."
                    : "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.";
                
                MessageBox.Show(message, "Lỗi kết nối", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            catch (TaskCanceledException ex)
            {
                // Lỗi timeout hoặc cancel
                System.Diagnostics.Debug.WriteLine($"Search: Timeout/Cancel error for {patientId}: {ex.Message}");
                
                MessageBox.Show("Yêu cầu bị timeout. Vui lòng thử lại.", "Timeout", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
            catch (Exception ex)
            {
                // Lỗi không xác định
                System.Diagnostics.Debug.WriteLine($"Search: Unexpected error for {patientId}: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"Search: Stack trace: {ex.StackTrace}");
                
                MessageBox.Show($"Đã xảy ra lỗi không xác định: {ex.Message}", "Lỗi hệ thống", MessageBoxButton.OK, MessageBoxImage.Error);
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
                // Mở dialog để chọn file Excel
                var dialog = new Microsoft.Win32.OpenFileDialog
                {
                    Filter = "Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls|All Files (*.*)|*.*",
                    Title = "Chọn file Excel chứa danh sách mã liên kết"
                };

                if (dialog.ShowDialog() == true)
                {
                    var filePath = dialog.FileName;
                    
                    // Lấy danh sách tên các sheet trong file
                    var sheetNames = await _excelReaderService.GetSheetNamesAsync(filePath);
                    
                    string? selectedSheet = null;
                    
                    // Nếu có nhiều sheet, hiển thị dialog chọn sheet
                    if (sheetNames.Count > 1)
                    {
                        selectedSheet = ShowSheetSelectionDialog(sheetNames);
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
            }
            catch (Exception ex)
            {
                BatchStatus = $"Lỗi: {ex.Message}";
            }
        }

        /// <summary>
        /// Hiển thị dialog để user chọn sheet
        /// </summary>
        private string? ShowSheetSelectionDialog(List<string> sheetNames)
        {
            // Tạo WPF dialog
            var dialog = new System.Windows.Window
            {
                Title = "Chọn Sheet",
                Width = 400,
                Height = 300,
                WindowStartupLocation = System.Windows.WindowStartupLocation.CenterScreen,
                ResizeMode = System.Windows.ResizeMode.NoResize
            };

            var stackPanel = new System.Windows.Controls.StackPanel
            {
                Margin = new System.Windows.Thickness(10)
            };

            var label = new System.Windows.Controls.Label
            {
                Content = "Chọn sheet muốn đọc:",
                FontSize = 14,
                Margin = new System.Windows.Thickness(0, 0, 0, 10)
            };

            var listBox = new System.Windows.Controls.ListBox
            {
                Height = 150,
                Margin = new System.Windows.Thickness(0, 0, 0, 10)
            };

            foreach (var sheetName in sheetNames)
            {
                listBox.Items.Add(sheetName);
            }
            
            // Chọn sheet đầu tiên
            if (listBox.Items.Count > 0)
            {
                listBox.SelectedIndex = 0;
            }

            var buttonPanel = new System.Windows.Controls.StackPanel
            {
                Orientation = System.Windows.Controls.Orientation.Horizontal,
                HorizontalAlignment = System.Windows.HorizontalAlignment.Right
            };

            var okButton = new System.Windows.Controls.Button
            {
                Content = "OK",
                Width = 75,
                Height = 30,
                Margin = new System.Windows.Thickness(0, 0, 10, 0),
                IsDefault = true
            };

            var cancelButton = new System.Windows.Controls.Button
            {
                Content = "Hủy",
                Width = 75,
                Height = 30,
                IsCancel = true
            };

            okButton.Click += (s, e) =>
            {
                dialog.DialogResult = true;
                dialog.Close();
            };

            cancelButton.Click += (s, e) =>
            {
                dialog.DialogResult = false;
                dialog.Close();
            };

            buttonPanel.Children.Add(okButton);
            buttonPanel.Children.Add(cancelButton);

            stackPanel.Children.Add(label);
            stackPanel.Children.Add(listBox);
            stackPanel.Children.Add(buttonPanel);

            dialog.Content = stackPanel;

            if (dialog.ShowDialog() == true)
            {
                return listBox.SelectedItem?.ToString();
            }

            return null;
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

                // Đọc danh sách ma_lk từ Excel
                var maLkList = await _excelReaderService.ReadMaLkFromExcelAsync(filePath, sheetName);
                
                if (maLkList == null || maLkList.Count == 0)
                {
                    BatchStatus = "Không tìm thấy dữ liệu trong file Excel";
                    return;
                }

                BatchTotal = maLkList.Count;
                BatchStatus = $"Đã đọc {maLkList.Count} mã liên kết. Bắt đầu xử lý song song...";

                // Sử dụng BatchProcessorService để xử lý song song với Semaphore
                var batchResult = await _batchProcessorService.ProcessPatientsAsync(
                    maLkList,
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

                        // Tạo error messages
                        var errorMessages = new List<string>();
                        if (result.ValidationResult.Data.ValidationResults != null)
                        {
                            foreach (var rule in result.ValidationResult.Data.ValidationResults)
                            {
                                if (!rule.IsValid)
                                {
                                    errorMessages.Add($"• {rule.RuleName}");
                                }
                            }
                        }

                        var validationResult = new PatientValidationResult
                        {
                            Ma_Lk = xml1Data.Ma_Lk ?? "",
                            Ho_Ten = xml1Data.Ho_Ten ?? "",
                            Gioi_Tinh = xml1Data.Gioi_Tinh == 1 ? "Nam" : (xml1Data.Gioi_Tinh == 2 ? "Nữ" : "Khác"),
                            Nam_Sinh = xml1Data.Ngay_Sinh ?? "",
                            Noi_Dung_Loi = errorMessages.Count > 0 
                                ? string.Join("\n", errorMessages) 
                                : "Không có lỗi",
                            IsError = errorMessages.Count > 0,
                            ValidationRules = result.ValidationResult.Data.ValidationResults
                        };

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
    }
}

