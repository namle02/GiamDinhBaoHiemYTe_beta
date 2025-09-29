using WPF_GiamDinhBaoHiem.Repos.Model;
using WPF_GiamDinhBaoHiem.Services.Interface;

namespace WPF_GiamDinhBaoHiem.Services.Implement
{
    public class CheckConditionService : ICheckConditionService
    {
        public void ApplyPatientRules(PatientData patient)
        {
            if (patient == null) return;

           
            //if (patient.Xml1 != null)
            //{
            //    foreach (var x in patient.Xml1)
            //    {
            //        var err = new ErrorXML1();

            
            //        if (x.Gioi_Tinh == 2)
            //            err.Gioi_Tinh = true;
            //        if (x.Ma_DanToc == "01")
            //            err.Ma_DanToc = true;
                    
                    
            //        if (err.HasAnyError)
            //            err.XML1Header = true;
                    
            //        x.Error = err;
            //    }
            //}

            //// XML2 rules - TODO: Add validation rules later
            //if (patient.Xml2 != null)
            //{
            //    foreach (var x in patient.Xml2)
            //    {
            //        var err = new ErrorXML2();
            //        if(x.Ma_Thuoc == "40.48")
            //            err.Ma_Thuoc = true;
                    


            //        if (err.HasAnyError)
            //            err.XML2Header = true;
                    
            //        x.Error = err;
            //    }
            //}

            //// XML3 rules - TODO: Add validation rules later
            //if (patient.Xml3 != null)
            //{
            //    foreach (var x in patient.Xml3)
            //    {
            //        var err = new ErrorXML3();
            //        if (err.HasAnyError)
            //            err.XML3Header = true;
            //        x.Error = err;
            //    }
            //}

            //// XML4 rules - TODO: Add validation rules later
            //if (patient.Xml4 != null)
            //{
            //    foreach (var x in patient.Xml4)
            //    {
            //        var err = new ErrorXML4();
            //        // TODO: Add validation rules for XML4
            //        x.Error = err;
            //    }
            //}

            //// XML5 rules - TODO: Add validation rules later
            //if (patient.Xml5 != null)
            //{
            //    foreach (var x in patient.Xml5)
            //    {
            //        var err = new ErrorXML5();
            //        // TODO: Add validation rules for XML5
            //        x.Error = err;
            //    }
            //}

            //// XML6 rules - TODO: Add validation rules later
            //if (patient.Xml6 != null)
            //{
            //    foreach (var x in patient.Xml6)
            //    {
            //        var err = new ErrorXML6();
            //        // TODO: Add validation rules for XML6
            //        x.Error = err;
            //    }
            //}

            //// XML7 rules - TODO: Add validation rules later
            //if (patient.Xml7 != null)
            //{
            //    foreach (var x in patient.Xml7)
            //    {
            //        var err = new ErrorXML7();
            //        // TODO: Add validation rules for XML7
            //        x.Error = err;
            //    }
            //}

            //// XML8 rules - TODO: Add validation rules later
            //if (patient.Xml8 != null)
            //{
            //    foreach (var x in patient.Xml8)
            //    {
            //        var err = new ErrorXML8();
            //        // TODO: Add validation rules for XML8
            //        x.Error = err;
            //    }
            //}

            //// XML9 rules - TODO: Add validation rules later
            //if (patient.Xml9 != null)
            //{
            //    foreach (var x in patient.Xml9)
            //    {
            //        var err = new ErrorXML9();
            //        // TODO: Add validation rules for XML9
            //        x.Error = err;
            //    }
            //}

            //// XML10 rules - TODO: Add validation rules later
            //if (patient.Xml10 != null)
            //{
            //    foreach (var x in patient.Xml10)
            //    {
            //        var err = new ErrorXML10();
            //        // TODO: Add validation rules for XML10
            //        x.Error = err;
            //    }
            //}

            //// XML11 rules - TODO: Add validation rules later
            //if (patient.Xml11 != null)
            //{
            //    foreach (var x in patient.Xml11)
            //    {
            //        var err = new ErrorXML11();
            //        // TODO: Add validation rules for XML11
            //        x.Error = err;
            //    }
            //}

            //// XML13 rules - TODO: Add validation rules later
            //if (patient.Xml13 != null)
            //{
            //    foreach (var x in patient.Xml13)
            //    {
            //        var err = new ErrorXML13();
            //        // TODO: Add validation rules for XML13
            //        x.Error = err;
            //    }
            //}

            //// XML14 rules - TODO: Add validation rules later
            //if (patient.Xml14 != null)
            //{
            //    foreach (var x in patient.Xml14)
            //    {
            //        var err = new ErrorXML14();
            //        // TODO: Add validation rules for XML14
            //        x.Error = err;
            //    }
            //}

            //// XML15 rules - TODO: Add validation rules later
            //if (patient.Xml15 != null)
            //{
            //    foreach (var x in patient.Xml15)
            //    {
            //        var err = new ErrorXML15();
            //        // TODO: Add validation rules for XML15
            //        x.Error = err;
            //    }
            //}
        }
    }
}
