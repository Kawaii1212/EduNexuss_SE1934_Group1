using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace EduNexus.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(string to, string subject, string body)
        {
            var smtpServer = _configuration["SmtpSettings:Server"];
            var smtpPortString = _configuration["SmtpSettings:Port"];
            var smtpUser = _configuration["SmtpSettings:Username"];
            var smtpPass = _configuration["SmtpSettings:Password"];
            var senderEmail = _configuration["SmtpSettings:SenderEmail"] ?? "noreply@edunexus.com";
            var senderName = _configuration["SmtpSettings:SenderName"] ?? "EduNexus Support";

            // If SMTP is not properly configured, log the email content for testing purposes.
            if (string.IsNullOrEmpty(smtpServer) || string.IsNullOrEmpty(smtpPortString))
            {
                _logger.LogWarning("SMTP is not configured in appsettings.json. Logging email instead.");
                _logger.LogInformation("=============================================");
                _logger.LogInformation($"To: {to}");
                _logger.LogInformation($"Subject: {subject}");
                _logger.LogInformation($"Body:\n{body}");
                _logger.LogInformation("=============================================");
                return;
            }

            int smtpPort = int.TryParse(smtpPortString, out int p) ? p : 587;

            try
            {
                var mailMessage = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };

                mailMessage.To.Add(to);

                using var smtpClient = new SmtpClient(smtpServer, smtpPort)
                {
                    Credentials = new NetworkCredential(smtpUser, smtpPass),
                    EnableSsl = true
                };

                await smtpClient.SendMailAsync(mailMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while sending email to {To}.", to);
                // Also log the body so developers can still get the code during development
                _logger.LogInformation($"Failed to send email. Body was:\n{body}");
            }
        }
    }
}
