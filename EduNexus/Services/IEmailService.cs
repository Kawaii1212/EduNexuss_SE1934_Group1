using System.Threading.Tasks;

namespace EduNexus.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string to, string subject, string body);
    }
}
