# Màn Hình Loading với Progress Tracking

## Tổng Quan

Đã thêm màn hình loading overlay hiện đại với progress tracking chi tiết trong quá trình batch processing Excel. Màn hình này cung cấp thông tin real-time về tiến trình xử lý và cho phép người dùng theo dõi và kiểm soát quá trình.

## Tính Năng Chính

### 🎯 **Loading Overlay**
- **Full-screen overlay** với background mờ (semi-transparent)
- **Material Design Card** với thiết kế hiện đại
- **Responsive layout** tự động điều chỉnh theo nội dung
- **Smooth animations** và transitions

### 📊 **Progress Tracking**
- **Progress Bar** với percentage hiển thị
- **Số lượng đã xử lý / Tổng số** bệnh nhân
- **Percentage completion** (0.0% - 100.0%)
- **Real-time updates** mỗi khi có tiến trình mới

### 📈 **Statistics Dashboard**
- **Success Count**: Số bệnh nhân xử lý thành công (màu xanh)
- **Error Count**: Số bệnh nhân có lỗi (màu đỏ)
- **Processing Speed**: Tốc độ xử lý (bệnh nhân/giây)

### 🔄 **Real-time Information**
- **Current Patient**: Hiển thị mã bệnh nhân đang được xử lý
- **Status Message**: Thông báo trạng thái hiện tại
- **Dynamic Updates**: Cập nhật liên tục trong quá trình xử lý

### ⏹️ **Cancellation Support**
- **Cancel Button**: Cho phép hủy quá trình xử lý
- **Graceful Cancellation**: Hủy an toàn và lưu kết quả đã xử lý
- **State Management**: Quản lý trạng thái button (enabled/disabled)

## Giao Diện UI

### Layout Structure
```
┌─────────────────────────────────────┐
│           Loading Overlay           │
│  ┌─────────────────────────────┐   │
│  │     Material Design Card    │   │
│  │                             │   │
│  │  📋 Đang xử lý dữ liệu Excel│   │
│  │                             │   │
│  │  📊 Đã xử lý: 15 / 100     │   │
│  │  ████████░░░░░░░░░░ 15.0%   │   │
│  │                             │   │
│  │  📝 Đang xử lý: BN001234    │   │
│  │                             │   │
│  │  📈 Thống kê:               │   │
│  │  ✅ 12  ❌ 3  ⚡ 2.5/s      │   │
│  │                             │   │
│  │        [Hủy]                │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Visual Elements
- **Background**: Semi-transparent overlay (#80000000)
- **Card**: Material Design với shadow và rounded corners
- **Colors**: 
  - Success: Green (#4CAF50)
  - Error: Red (#F44336)
  - Primary: Theme color
  - Progress: Primary hue

## Technical Implementation

### ViewModel Properties
```csharp
[ObservableProperty] private bool IsBatchProcessing;
[ObservableProperty] private int BatchProgress;
[ObservableProperty] private int BatchTotal;
[ObservableProperty] private string BatchStatus;
[ObservableProperty] private bool CanCancelBatch;
[ObservableProperty] private int BatchSuccessCount;
[ObservableProperty] private int BatchErrorCount;
[ObservableProperty] private double BatchProcessingSpeed;
[ObservableProperty] private string CurrentProcessingPatient;
[ObservableProperty] private double BatchProgressPercentage;
```

### Progress Callback
```csharp
onProgress: (progress) =>
{
    System.Windows.Application.Current.Dispatcher.Invoke(() =>
    {
        BatchProgress = progress.Current;
        BatchStatus = progress.Status;
        CurrentProcessingPatient = progress.CurrentPatientId;
        BatchProgressPercentage = progress.Percentage;
        
        // Real-time speed calculation
        var elapsedSeconds = (DateTime.Now - _batchStartTime).TotalSeconds;
        if (elapsedSeconds > 0)
        {
            BatchProcessingSpeed = progress.Current / elapsedSeconds;
        }
    });
}
```

### XAML Structure
```xml
<Border Background="#80000000" 
        Visibility="{Binding IsBatchProcessing, Converter={StaticResource BoolToVis}}">
    <Grid>
        <materialDesign:Card Width="500" Height="300">
            <!-- Title -->
            <!-- Progress Info -->
            <!-- Progress Bar with Percentage -->
            <!-- Status Text -->
            <!-- Current Patient -->
            <!-- Statistics Grid -->
            <!-- Cancel Button -->
        </materialDesign:Card>
    </Grid>
</Border>
```

## User Experience

### 🚀 **Khi Bắt Đầu**
1. User chọn file Excel
2. Loading overlay xuất hiện ngay lập tức
3. Hiển thị "Đang đọc file Excel..."
4. Progress bar ở 0%

### 📊 **Trong Quá Trình Xử Lý**
1. Progress bar cập nhật real-time
2. Hiển thị số lượng đã xử lý
3. Hiển thị patient ID hiện tại
4. Cập nhật thống kê success/error
5. Tính toán tốc độ xử lý

### ✅ **Khi Hoàn Thành**
1. Hiển thị thống kê cuối cùng
2. Hiển thị thời gian xử lý
3. Hiển thị tốc độ trung bình
4. Loading overlay tự động ẩn

### ⏹️ **Khi Hủy**
1. User click nút "Hủy"
2. Hiển thị "Đang hủy xử lý batch..."
3. Graceful cancellation
4. Hiển thị kết quả đã xử lý trước khi hủy

## Performance Features

### Real-time Updates
- **UI Thread Marshalling**: Sử dụng Dispatcher.Invoke để cập nhật UI an toàn
- **Efficient Binding**: Sử dụng ObservableProperty để tự động cập nhật UI
- **Minimal Overhead**: Chỉ cập nhật khi cần thiết

### Memory Management
- **Automatic Cleanup**: Reset tất cả properties khi bắt đầu mới
- **Resource Disposal**: Proper disposal của CancellationTokenSource
- **State Management**: Quản lý trạng thái loading một cách hiệu quả

## Customization

### Styling
- **Material Design Theme**: Tự động adapt với theme hiện tại
- **Responsive Design**: Tự động điều chỉnh kích thước
- **Color Scheme**: Sử dụng theme colors cho consistency

### Configuration
- **Card Size**: Có thể điều chỉnh Width/Height
- **Update Frequency**: Có thể điều chỉnh tần suất cập nhật
- **Animation Speed**: Có thể thêm animations nếu cần

## Error Handling

### Graceful Degradation
- **Network Errors**: Hiển thị thông báo lỗi rõ ràng
- **File Errors**: Xử lý lỗi file Excel
- **Cancellation**: Xử lý cancellation một cách an toàn

### User Feedback
- **Clear Messages**: Thông báo lỗi dễ hiểu
- **Status Updates**: Cập nhật trạng thái liên tục
- **Progress Indication**: Luôn hiển thị tiến trình

## Benefits

### 🎯 **User Experience**
- **Transparency**: Người dùng biết chính xác đang xảy ra gì
- **Control**: Có thể hủy bất kỳ lúc nào
- **Feedback**: Nhận được thông tin chi tiết về tiến trình

### 🚀 **Performance**
- **Non-blocking**: UI không bị freeze
- **Real-time**: Cập nhật ngay lập tức
- **Efficient**: Sử dụng tài nguyên tối ưu

### 🔧 **Maintainability**
- **Clean Code**: Code dễ đọc và maintain
- **Separation of Concerns**: UI và logic tách biệt
- **Reusable**: Có thể tái sử dụng cho các tính năng khác

## Conclusion

Màn hình loading mới cung cấp trải nghiệm người dùng tuyệt vời với:
- **Real-time progress tracking**
- **Detailed statistics**
- **Professional UI design**
- **Smooth user interactions**
- **Comprehensive error handling**

Điều này làm cho quá trình batch processing trở nên minh bạch, có thể kiểm soát và thân thiện với người dùng hơn rất nhiều! 🎉
