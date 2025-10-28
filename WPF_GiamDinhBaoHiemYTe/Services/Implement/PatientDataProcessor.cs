using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    /// <summary>
    /// Service xử lý patient data: STT assignment, sorting, finding
    /// </summary>
    public class PatientDataProcessor : IPatientDataProcessor
    {
        public void AssignSttToXmlData<T>(List<T>? xmlData) where T : IHasStt
        {
            if (xmlData == null || xmlData.Count == 0)
                return;

            // Chỉ gán STT nếu chưa có
            if (xmlData[0].Stt == null)
            {
                for (int i = 0; i < xmlData.Count; i++)
                {
                    xmlData[i].Stt = i + 1;
                }
            }
        }

        public List<XML3> SortAndAssignSttXml3(List<XML3>? xml3Data)
        {
            if (xml3Data == null || xml3Data.Count == 0)
                return new List<XML3>();

            // Sắp xếp theo ngày thực hiện y lệnh (Ngay_Th_Yl)
            var sorted = xml3Data.OrderBy(x =>
            {
                if (string.IsNullOrEmpty(x.Ngay_Th_Yl))
                    return DateTime.MaxValue;

                if (DateTime.TryParse(x.Ngay_Th_Yl, out DateTime date))
                    return date;

                return DateTime.MaxValue;
            }).ToList();

            // Gán STT theo thứ tự đã sắp xếp
            for (int i = 0; i < sorted.Count; i++)
            {
                sorted[i].Stt = i + 1;
            }

            return sorted;
        }

        public List<XML4> SortAndAssignSttXml4(List<XML4>? xml4Data)
        {
            if (xml4Data == null || xml4Data.Count == 0)
                return new List<XML4>();

            // Sắp xếp theo ngày kết quả (Ngay_Kq)
            var sorted = xml4Data.OrderBy(x =>
            {
                if (string.IsNullOrEmpty(x.Ngay_Kq))
                    return DateTime.MaxValue;

                if (DateTime.TryParse(x.Ngay_Kq, out DateTime date))
                    return date;

                return DateTime.MaxValue;
            }).ToList();

            // Gán STT theo thứ tự đã sắp xếp
            for (int i = 0; i < sorted.Count; i++)
            {
                sorted[i].Stt = i + 1;
            }

            return sorted;
        }

        public XML1? FindXml1ByPatientId(List<XML1>? xml1List, string patientId)
        {
            if (xml1List == null || xml1List.Count == 0 || string.IsNullOrWhiteSpace(patientId))
                return null;

            // Tìm theo Ma_Lk hoặc Ma_Bn
            return xml1List.FirstOrDefault(x =>
                x.Ma_Lk?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true ||
                x.Ma_Bn?.Equals(patientId, StringComparison.OrdinalIgnoreCase) == true
            ) ?? xml1List[0]; // Fallback: lấy record đầu tiên
        }

        public void ProcessPatientData(PatientData patientData)
        {
            if (patientData == null)
                return;

            // Process XML2
            if (patientData.Xml2 is IList<IHasStt> xml2List)
            {
                AssignSttToXmlData(xml2List as List<XML2>);
            }

            // Process XML3 (with sorting)
            if (patientData.Xml3 != null)
            {
                patientData.Xml3 = SortAndAssignSttXml3(patientData.Xml3);
            }

            // Process XML4 (with sorting)
            if (patientData.Xml4 != null)
            {
                patientData.Xml4 = SortAndAssignSttXml4(patientData.Xml4);
            }

            // Process XML5
            if (patientData.Xml5 is IList<IHasStt> xml5List)
            {
                AssignSttToXmlData(xml5List as List<XML5>);
            }
        }
    }
}

