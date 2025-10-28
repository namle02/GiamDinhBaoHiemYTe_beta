using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Implementation của IDialogService
    /// </summary>
    public class DialogService : IDialogService
    {
        public void ShowError(string message, string title = "Lỗi")
        {
            MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Error);
        }

        public void ShowWarning(string message, string title = "Cảnh báo")
        {
            MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Warning);
        }

        public void ShowInformation(string message, string title = "Thông báo")
        {
            MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Information);
        }

        public bool ShowConfirmation(string message, string title = "Xác nhận")
        {
            var result = MessageBox.Show(message, title, MessageBoxButton.YesNo, MessageBoxImage.Question);
            return result == MessageBoxResult.Yes;
        }

        public string? ShowOpenExcelFileDialog(string title = "Chọn file Excel")
        {
            var dialog = new Microsoft.Win32.OpenFileDialog
            {
                Filter = "Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls|All Files (*.*)|*.*",
                Title = title
            };

            return dialog.ShowDialog() == true ? dialog.FileName : null;
        }

        public string? ShowSaveExcelFileDialog(string defaultFileName, string title = "Lưu file Excel")
        {
            var dialog = new Microsoft.Win32.SaveFileDialog
            {
                Filter = "Excel Files (*.xlsx)|*.xlsx|All Files (*.*)|*.*",
                Title = title,
                FileName = defaultFileName
            };

            return dialog.ShowDialog() == true ? dialog.FileName : null;
        }

        public string? ShowSheetSelectionDialog(List<string> sheetNames, string title = "Chọn Sheet")
        {
            // Tạo WPF dialog
            var dialog = new Window
            {
                Title = title,
                Width = 400,
                Height = 300,
                WindowStartupLocation = WindowStartupLocation.CenterScreen,
                ResizeMode = ResizeMode.NoResize
            };

            var stackPanel = new StackPanel
            {
                Margin = new Thickness(10)
            };

            var label = new Label
            {
                Content = "Chọn sheet muốn đọc:",
                FontSize = 14,
                Margin = new Thickness(0, 0, 0, 10)
            };

            var listBox = new ListBox
            {
                Height = 150,
                Margin = new Thickness(0, 0, 0, 10)
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

            var buttonPanel = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                HorizontalAlignment = HorizontalAlignment.Right
            };

            var okButton = new Button
            {
                Content = "OK",
                Width = 75,
                Height = 30,
                Margin = new Thickness(0, 0, 10, 0),
                IsDefault = true
            };

            var cancelButton = new Button
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
    }
}


