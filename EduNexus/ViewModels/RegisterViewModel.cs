using System.ComponentModel.DataAnnotations;

namespace EduNexus.ViewModels
{
    public class RegisterViewModel
    {
        [Required(ErrorMessage = "Full Name is required")]
        public string FullName { get; set; } = null!;

        [Required(ErrorMessage = "Email is required")]
        [EmailAddress(ErrorMessage = "Invalid Email Address")]
        public string Email { get; set; } = null!;

        [Required(ErrorMessage = "Password is required")]
        [DataType(DataType.Password)]
        public string Password { get; set; } = null!;
        
        [Required(ErrorMessage = "You must agree to the terms")]
        public bool AgreeTerms { get; set; }
    }
}
