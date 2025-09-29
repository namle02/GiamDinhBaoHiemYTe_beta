using CommunityToolkit.Mvvm.Messaging.Messages;
using WPF_GiamDinhBaoHiem.Repos.Model;

namespace WPF_GiamDinhBaoHiem.Messenger
{
    public class PatientSelectedMessage : ValueChangedMessage<PatientData>
    {
        public PatientSelectedMessage(PatientData value) : base(value) { }
    }
}
