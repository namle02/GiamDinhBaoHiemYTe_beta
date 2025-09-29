using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    public interface IDynamicValidationService
    {
        /// <summary>
        /// Áp dụng validation động dựa trên danh sách lỗi từ GoogleSheet
        /// </summary>
        /// <param name="patient">Dữ liệu bệnh nhân cần validate</param>
        /// <param name="errorList">Danh sách lỗi từ GoogleSheet</param>
        void ApplyDynamicValidation(PatientData patient, List<ErrorItem> errorList);
    }
}
