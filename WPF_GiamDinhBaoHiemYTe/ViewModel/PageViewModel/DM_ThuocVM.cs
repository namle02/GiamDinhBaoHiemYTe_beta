using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Data;
using System.Dynamic;
using WPF_GiamDinhBaoHiem.Repos.Mappers.Interface;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class DM_ThuocVM : ObservableObject
    {
        private readonly IDataMapper _dataMapper;

        [ObservableProperty] private string duocId = string.Empty;
        [ObservableProperty] private Thuoc? thuoc; 
        [ObservableProperty] private bool isLoading;

        public DM_ThuocVM(IDataMapper dataMapper)
        {
            _dataMapper = dataMapper;
        }

        [RelayCommand]
        private async Task TraCuuThuoc()
        {
            if (IsLoading) return;
            IsLoading = true;
            try
            {
                Thuoc = await _dataMapper.GetThuocByDuocIdAsync(DuocId.Trim());
            }
            finally
            {
                IsLoading = false;
            }
        }
    }
}
