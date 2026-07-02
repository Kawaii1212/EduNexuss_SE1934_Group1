using System;
using Microsoft.EntityFrameworkCore;
using EduNexus.Models;

namespace EduNexus;

public static class AppConfiguration
{
    public static string ConnectionString { get; set; } = string.Empty;

    private static DbContextOptions<EduNexusContext>? _options = null;
    private static readonly object _optionsLock = new object();

    public static DbContextOptions<EduNexusContext> DbContextOptions
    {
        get
        {
            if (_options == null)
            {
                lock (_optionsLock)
                {
                    if (_options == null)
                    {
                        var optionsBuilder = new DbContextOptionsBuilder<EduNexusContext>();
                        optionsBuilder.UseSqlServer(ConnectionString);
                        _options = optionsBuilder.Options;
                    }
                }
            }
            return _options;
        }
    }
}
