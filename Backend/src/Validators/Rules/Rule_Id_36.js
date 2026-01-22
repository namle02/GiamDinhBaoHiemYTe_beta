/**
 * Rule 36: Điều dưỡng đại học không được chỉ định dịch vụ này
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const Doctor = require('../../Repos/Models/Doctor');

const ma_dich_vu_sai = [
    '01.0032.0299',
    '01.0066.1888',
    '01.0069.0298',
    '01.0077.1888',
    '01.0080.0206',
    '01.0176.0118',
    '01.0178.0118',
    '01.0179.0118',
    '01.0180.0118',
    '02.0002.0071',
    '02.0026.0111',
    '02.0145.1777',
    '02.0227.0164',
    '02.0479.0264',
    '02.0495.0196',
    '02.0496.0195',
    '03.0077.1888',
    '03.1955.1029',
    '03.1956.1029',
    '03.3849.0521',
    '03.3851.0521',
    '03.3852.0521',
    '03.3865.0525',
    '03.3866.0525',
    '03.3867.0525',
    '06.0012.1814',
    '06.0013.1814',
    '06.0018.1808',
    '07.0230.0199',
    '07.0233.0355',
    '08.0006.0271',
    '08.0009.0228',
    '08.0013.0238',
    '08.0014.0238',
    '08.0019.0286',
    '08.0024.0249',
    '08.0028.0259',
    '08.0389.0280',
    '08.0391.0280',
    '08.0392.0280',
    '08.0396.0280',
    '08.0408.0280',
    '08.0409.0280',
    '08.0413.0280',
    '08.0414.0280',
    '08.0415.0280',
    '08.0418.0280',
    '08.0419.0280',
    '08.0425.0280',
    '08.0430.0280',
    '08.0431.0280',
    '08.0432.0280',
    '08.0435.0280',
    '08.0441.0280',
    '08.0442.0280',
    '08.0481.0235',
    '08.0482.0235',
    '08.0483.0280',
    '08.0484.0281',
    '08.0485.0235',
    '10.0989.0529',
    '10.0991.0523',
    '10.0995.0517',
    '10.0998.0527',
    '10.0999.0527',
    '10.1000.0515',
    '10.1001.0515',
    '10.1003.0527',
    '10.1006.0527',
    '10.1007.0521',
    '10.1008.0521',
    '10.1010.0523',
    '10.1012.0525',
    '10.1013.0529',
    '10.1017.0533',
    '10.1018.0513',
    '10.1020.0525',
    '10.1021.0525',
    '10.1022.0519',
    '10.1023.0532',
    '10.1024.0519',
    '10.1028.0519',
    '10.1030.0515',
    '10.1031.0513',
    '11.0003.1150',
    '11.0008.1150',
    '11.0009.1149',
    '11.0117.0111',
    '12.0366.1165',
    '14.0171.0769',
    '14.0204.0075',
    '14.0206.0730',
    '14.0211.0842',
    '14.0214.0778',
    '14.0258.0754',
    '15.0058.0899',
    '15.0059.0908',
    '15.0139.0897',
    '15.0141.0916',
    '15.0142.0868',
    '16.0043.1020',
    '16.0238.1029',
    '16.0239.1029',
    '21.0060.0890',
    '21.0106.1800',
];

const validateRule_Id_36 = async (patientData) => {
    const result = {
        ruleName: 'Điều dưỡng đại học không được chỉ định dịch vụ có sao (*)',
        ruleId: 'Rule_Id_36',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        if (!xml3_data || !Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }

        // Lấy ra tất cả dịch vụ có mã sai
        const dichVuSai = xml3_data.filter(item => ma_dich_vu_sai.includes(item.Ma_Dich_Vu));

        for (const item of dichVuSai) {
            const maBacSi = item.Nguoi_Thuc_Hien;
            if (!maBacSi) continue;
            const doctor = await Doctor.findOne({ MACCHN: maBacSi }).lean();
            if (doctor && Array.isArray(doctor.PHAMVI_CM) && doctor.PHAMVI_CM.includes(302)) {
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: `Điều dưỡng đại học (MACCHN: ${maBacSi}) không được chỉ định dịch vụ có sao (*) (Mã dịch vụ: ${item.Ma_Dich_Vu})`
                });
                result.isValid = false;
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Điều dưỡng đại học không được chỉ định dịch vụ có sao (*): ${error.message}`);
        result.message = 'Lỗi khi validate Điều dưỡng đại học không được chỉ định dịch vụ có sao (*)';
    }

    return result;
};

module.exports = validateRule_Id_36;

