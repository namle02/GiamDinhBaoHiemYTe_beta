
using System.Linq;
using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
   
    public class DynamicValidationService : IDynamicValidationService
    {
        public void ApplyDynamicValidation(PatientData patient, List<ErrorItem> errorList)
        {
            if (patient == null || errorList == null || !errorList.Any()) return;

            // Clear previous activated errors
            patient.ActivatedErrors.Clear();

            
            var errorsByXmlType = errorList.GroupBy(e => e.ViTriLoi?.ToUpper())
                                          .ToDictionary(g => g.Key, g => g.ToList());

            // Validate XML1
            if (errorsByXmlType.ContainsKey("XML1") && patient.Xml1 != null)
            {
                ValidateXml1(patient.Xml1, errorsByXmlType["XML1"], patient);
            }

            // Validate XML2
            if (errorsByXmlType.ContainsKey("XML2") && patient.Xml2 != null)
            {
                ValidateXml2(patient.Xml2, errorsByXmlType["XML2"], patient);
            }

            // Validate XML3
            if (errorsByXmlType.ContainsKey("XML3") && patient.Xml3 != null)
            {
                ValidateXml3(patient.Xml3, errorsByXmlType["XML3"], patient);
            }

            // TODO: Thêm các XML khác khi cần
        }

        private void ValidateXml1(List<XML1> xml1List, List<ErrorItem> errors, PatientData patient)
        {
            foreach (var x in xml1List)
            {
                // Sử dụng Error object hiện có hoặc tạo mới
                var err = x.Error ?? new ErrorXML1();

                // Validate dựa trên STT từ GoogleSheet
                foreach (var error in errors)
                {
                    switch (error.Stt)
                    {
                        case 31: 
                            bool hasError = false;
                            if (x.Gioi_Tinh == 2)
                            {
                                err.Gioi_Tinh = true;
                                hasError = true;
                            }
                            if (x.Ma_DanToc == "01")
                            {
                                err.Ma_DanToc = true;
                                hasError = true;
                            }
                            if (x.Ma_Dkbd == "22043")
                            {
                                err.Ma_Dkbd = true;
                                hasError = true;
                            }
                            
                            // Chỉ add error một lần cho mỗi STT
                            if (hasError && !patient.ActivatedErrors.Any(e => e.Stt == error.Stt))
                            {
                                patient.ActivatedErrors.Add(error);
                            }
                            break;
                        
                        
                    }
                }

             
                if (err.HasAnyError)
                    err.XML1Header = true;

              
                x.Error = err;
            }
        }

        private void ValidateXml2(List<XML2> xml2List, List<ErrorItem> errors, PatientData patient)
        {
            System.Diagnostics.Debug.WriteLine($"ValidateXml2 - Found {xml2List.Count} XML2 records, {errors.Count} error rules");
            
            bool hasAnyXml2Error = false;
            
            for (int i = 0; i < xml2List.Count; i++)
            {
                var x = xml2List[i];
                // Sử dụng Error object hiện có hoặc tạo mới
                var err = x.Error ?? new ErrorXML2();

                System.Diagnostics.Debug.WriteLine($"XML2 Record [{i}] - Ma_Thuoc: {x.Ma_Thuoc}");

            
                foreach (var error in errors)
                {
                    System.Diagnostics.Debug.WriteLine($"Checking error rule STT: {error.Stt}, ViTriLoi: {error.ViTriLoi}");
                    
                    switch (error.Stt)
                    {
                        case 32: // STT 32 cho XML2
                            if (x.Ma_Thuoc == "40.48")
                            {
                                err.Ma_Thuoc = true;
                                hasAnyXml2Error = true;
                                // Chỉ add error một lần cho mỗi STT
                                if (!patient.ActivatedErrors.Any(e => e.Stt == error.Stt))
                                {
                                    patient.ActivatedErrors.Add(error);
                                }
                                System.Diagnostics.Debug.WriteLine($"XML2 Record [{i}] - Set Ma_Thuoc error to true");
                            }
                            break;
                        
                        // TODO: Thêm các STT khác cho XML2
                    }
                }

                if (err.HasAnyError)
                {
                    err.XML2Header = true;
                    hasAnyXml2Error = true;
                    System.Diagnostics.Debug.WriteLine($"XML2 Record [{i}] - Set XML2Header to TRUE (HasAnyError = true)");
                }
                else
                {
                    err.XML2Header = false;
                    System.Diagnostics.Debug.WriteLine($"XML2 Record [{i}] - Set XML2Header to FALSE (HasAnyError = false)");
                }

                // Force gán Error object để đảm bảo UI được notify
                x.Error = err;
            }
            
            // Update PatientData XML2 header state
            patient.Xml2HeaderError = hasAnyXml2Error;
            System.Diagnostics.Debug.WriteLine($"PatientData.Xml2HeaderError set to: {hasAnyXml2Error}");
        }

        private void ValidateXml3(List<XML3> xml3List, List<ErrorItem> errors, PatientData patient)
        {
            bool hasAnyXml3Error = false;
            
            foreach (var x in xml3List)
            {
                // Sử dụng Error object hiện có hoặc tạo mới
                var err = x.Error ?? new ErrorXML3();

                // Validate dựa trên STT từ GoogleSheet
                foreach (var error in errors)
                {
                    switch (error.Stt)
                    {
                        case 1:
                            // Kiểm tra lỗi: Thanh toán dịch vụ Vi khuẩn nuôi cấy định danh, không thanh toán thêm DVKT Vi khuẩn nhuộm soi
                            // Nếu có Ma_Dich_Vu = 24.0003.1715 (Vi khuẩn nuôi cấy định danh)
                            bool hasViKhuẩnNuoiCay = patient.Xml3?.Any(xml => xml.Ma_Dich_Vu == "24.0003.1715") ?? false;
                            
                            // Và đang xử lý record có Ma_Dich_Vu = 24.0001.1714 (Vi khuẩn nhuộm soi)
                            if (hasViKhuẩnNuoiCay && x.Ma_Dich_Vu == "24.0001.1714")
                            {
                                // Kiểm tra Thanh_Tien của record 24.0001.1714
                                if (x.Thanh_Tien_Bh > 0 || x.Thanh_Tien_Bv > 0)
                                {
                                    err.Ma_Dich_Vu = true;
                                    err.Ten_Dich_Vu = true;
                                    hasAnyXml3Error = true;
                                    
                                    // Set error cho tất cả các record có cùng Ma_Dich_Vu (mục lớn)
                                    if (!string.IsNullOrEmpty(x.Ma_Dich_Vu))
                                    {
                                        var sameServiceRecords = patient.Xml3?.Where(xml => 
                                            xml.Ma_Dich_Vu == x.Ma_Dich_Vu && xml != x) ?? new List<XML3>();
                                        
                                        foreach (var sameRecord in sameServiceRecords)
                                        {
                                            var sameErr = sameRecord.Error ?? new ErrorXML3();
                                            sameErr.Ma_Dich_Vu = true;
                                            sameErr.Ten_Dich_Vu = true;
                                            sameRecord.Error = sameErr;
                                        }
                                    }
                                    
                                    // Chỉ add error một lần cho mỗi STT
                                    if (!patient.ActivatedErrors.Any(e => e.Stt == error.Stt))
                                    {
                                        patient.ActivatedErrors.Add(error);
                                    }
                                }
                            }
                            break;
                        
                        case 2:
                            // Kiểm tra lỗi: Thanh toán dịch vụ nội soi can thiệp không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng
                            // Nếu có Ma_Dich_Vu = nội soi can thiệp (02.0295.0498 hoặc 02.0296.0500)
                            bool hasNoiSoiCanThiep = patient.Xml3?.Any(xml => 
                                xml.Ma_Dich_Vu == "02.0295.0498" || // Nội soi can thiệp - cắt 1 polyp < 1 cm
                                xml.Ma_Dich_Vu == "02.0296.0500") ?? false; // Nội soi can thiệp - cắt polyp > 1 cm hoặc nhiều polyp
                            
                            // Và đang xử lý record có Ma_Dich_Vu = 02.0304.0134 (Nội soi thực quản - dạ dày - tá tràng có sinh thiết)
                            if (hasNoiSoiCanThiep && x.Ma_Dich_Vu == "02.0304.0134")
                            {
                                // Kiểm tra Thanh_Tien của record nội soi thường
                                if (x.Thanh_Tien_Bh > 0 || x.Thanh_Tien_Bv > 0)
                                {
                                    err.Ma_Dich_Vu = true;
                                    err.Ten_Dich_Vu = true;
                                    hasAnyXml3Error = true;
                                    
                                    // Set error cho tất cả các record có cùng Ma_Dich_Vu (mục lớn)
                                    if (!string.IsNullOrEmpty(x.Ma_Dich_Vu))
                                    {
                                        var sameServiceRecords = patient.Xml3?.Where(xml => 
                                            xml.Ma_Dich_Vu == x.Ma_Dich_Vu && xml != x) ?? new List<XML3>();
                                        
                                        foreach (var sameRecord in sameServiceRecords)
                                        {
                                            var sameErr = sameRecord.Error ?? new ErrorXML3();
                                            sameErr.Ma_Dich_Vu = true;
                                            sameErr.Ten_Dich_Vu = true;
                                            sameRecord.Error = sameErr;
                                        }
                                    }
                                    
                                    // Chỉ add error một lần cho mỗi STT
                                    if (!patient.ActivatedErrors.Any(e => e.Stt == error.Stt))
                                    {
                                        patient.ActivatedErrors.Add(error);
                                    }
                                }
                            }
                            break;
                        
                        // TODO: Thêm các STT khác cho XML3
                    }
                }

                if (err.HasAnyError)
                {
                    err.XML3Header = true;
                    hasAnyXml3Error = true;
                    System.Diagnostics.Debug.WriteLine($"XML3 Record - Set XML3Header to TRUE (HasAnyError = true)");
                }
                else
                {
                    err.XML3Header = false;
                    System.Diagnostics.Debug.WriteLine($"XML3 Record - Set XML3Header to FALSE (HasAnyError = false)");
                }

                x.Error = err;
            }
            
            // Update PatientData XML3 header state
            patient.Xml3HeaderError = hasAnyXml3Error;
            System.Diagnostics.Debug.WriteLine($"PatientData.Xml3HeaderError set to: {hasAnyXml3Error}");
        }
    }
}
