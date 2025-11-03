using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Services.Interface
{
    /// <summary>
    /// Service xử lý patient data: STT assignment, sorting, finding
    /// </summary>
    public interface IPatientDataProcessor
    {
        /// <summary>
        /// Gán STT cho danh sách XML data (XML2, XML5)
        /// </summary>
        void AssignSttToXmlData<T>(List<T>? xmlData) where T : IHasStt;

        /// <summary>
        /// Sắp xếp XML3 theo ngày thực hiện y lệnh và gán STT
        /// </summary>
        List<XML3> SortAndAssignSttXml3(List<XML3>? xml3Data);

        /// <summary>
        /// Sắp xếp XML4 theo ngày kết quả và gán STT
        /// </summary>
        List<XML4> SortAndAssignSttXml4(List<XML4>? xml4Data);

        /// <summary>
        /// Tìm XML1 theo patient ID (Ma_Lk hoặc Ma_Bn)
        /// </summary>
        XML1? FindXml1ByPatientId(List<XML1>? xml1List, string patientId);

        /// <summary>
        /// Process toàn bộ patient data: assign STT và sort
        /// </summary>
        void ProcessPatientData(PatientData patientData);
    }

    /// <summary>
    /// Interface cho các class có thuộc tính Stt
    /// </summary>
    public interface IHasStt
    {
        int? Stt { get; set; }
    }
}

