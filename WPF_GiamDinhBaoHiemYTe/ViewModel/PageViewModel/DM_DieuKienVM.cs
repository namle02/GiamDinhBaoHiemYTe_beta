using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;
using System.ComponentModel;
using WPF_GiamDinhBaoHiem.Core;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.ViewModel.PageViewModel
{
    public partial class DM_DieuKienVM : BaseViewModel
    {
        private readonly IRuleServices _ruleServices;

        [ObservableProperty]
        private ObservableCollection<string> ruleNames = new();

        [ObservableProperty]
        private string searchText = string.Empty;

        [ObservableProperty]
        private ObservableCollection<string> filteredRuleNames = new();

        public DM_DieuKienVM(IRuleServices ruleServices)
        {
            _ruleServices = ruleServices;
            LoadRules();
            PropertyChanged += OnPropertyChanged;
        }

        /// <summary>
        /// Lấy danh sách tên rules từ cache (đã được load khi app khởi động)
        /// </summary>
        private void LoadRules()
        {
            var cachedRules = _ruleServices.GetCachedRules();
            var names = cachedRules.Select(r => r.Name).ToList();
            RuleNames = new ObservableCollection<string>(names);
            FilteredRuleNames = new ObservableCollection<string>(names);
        }

        /// <summary>
        /// Tìm kiếm rules theo từ khóa
        /// </summary>
        private void OnPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(SearchText))
            {
                if (string.IsNullOrWhiteSpace(SearchText))
                {
                    FilteredRuleNames = new ObservableCollection<string>(RuleNames);
                }
                else
                {
                    var filtered = RuleNames.Where(name => 
                        name.Contains(SearchText, StringComparison.OrdinalIgnoreCase)
                    ).ToList();
                    FilteredRuleNames = new ObservableCollection<string>(filtered);
                }
            }
        }
    }
}
