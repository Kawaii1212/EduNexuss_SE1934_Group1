using System;
using System.Collections.Generic;
using DataAccessLayer.Models;

namespace EduNexus.Models
{
    public class StudentLibraryViewModel
    {
        public List<ResourceItemViewModel> Resources { get; set; } = new List<ResourceItemViewModel>();
        public List<string> Categories { get; set; } = new List<string>();
    }

    public class ResourceItemViewModel
    {
        public long Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string FileUrl { get; set; } = string.Empty;
        public string FileSize { get; set; } = string.Empty;
        
        public string ResourceType 
        { 
            get
            {
                if (string.IsNullOrEmpty(FileUrl)) return "LINK";
                var ext = System.IO.Path.GetExtension(FileUrl).ToLowerInvariant();
                return ext switch
                {
                    ".pdf" => "PDF",
                    ".mp4" or ".avi" or ".mov" => "MP4",
                    ".zip" or ".rar" => "ZIP",
                    _ => "LINK"
                };
            }
        }

        public string BadgeClass
        {
            get => ResourceType switch
            {
                "PDF" => "badge-pdf",
                "MP4" => "badge-video",
                "ZIP" => "badge-zip",
                _ => "badge-link"
            };
        }

        public string IconClass
        {
            get => ResourceType switch
            {
                "PDF" => "icon-pdf",
                "MP4" => "icon-video",
                "ZIP" => "icon-zip",
                _ => "icon-link"
            };
        }

        public string IconHtml
        {
            get => ResourceType switch
            {
                "PDF" => "<i class=\"fa-regular fa-file-pdf\"></i>",
                "MP4" => "<i class=\"fa-solid fa-video\"></i>",
                "ZIP" => "<i class=\"fa-regular fa-file-zipper\"></i>",
                _ => "<i class=\"fa-solid fa-link\"></i>"
            };
        }
    }
}
