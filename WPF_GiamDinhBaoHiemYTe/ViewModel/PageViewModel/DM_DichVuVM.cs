using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class DM_DichVuVM : ObservableObject
    {
        private readonly IDataMapper _dataMapper;

        [ObservableProperty]
        private string searchText = string.Empty;

        [ObservableProperty]
        private ObservableCollection<DichVu> items = new();

        [ObservableProperty]
        private DichVu? selectedItem;

        public DM_DichVuVM(IDataMapper dataMapper)
        {
            _dataMapper = dataMapper;
        }

        [RelayCommand]
        private async Task SearchAsync()
        {
            if (string.IsNullOrWhiteSpace(SearchText))
            {
                Items.Clear();
                return;
            }

            var exact = await _dataMapper.GetDichVuByIdOrCodeAsync(SearchText.Trim());
            if (exact != null)
            {
                Items = new ObservableCollection<DichVu>(new[] { exact });
                SelectedItem = exact;
                return;
            }

            var list = await _dataMapper.SearchDichVuAsync(SearchText.Trim());
            Items = new ObservableCollection<DichVu>(list);
        }
    }
}
