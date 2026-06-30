using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace DataAccessLayer.Services;


public class GeminiService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _model;

    public GeminiService(HttpClient httpClient, IConfiguration config)
    {
        _httpClient = httpClient;
        _apiKey = config["Gemini:ApiKey"]
            ?? throw new InvalidOperationException("Thiếu Gemini:ApiKey trong appsettings.json");
        _model = config["Gemini:Model"] ?? "gemini-2.5-flash";
        _httpClient.Timeout = TimeSpan.FromSeconds(30); // NFR timeout 30s
    }

    public async Task<string> GenerateTextAsync(string prompt)
    {
        Console.WriteLine($">>> [GeminiService] Đang gửi request tới model {_model}...");
        Console.WriteLine($">>> [GeminiService] Prompt: {prompt.Substring(0, Math.Min(100, prompt.Length))}...");

        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{_model}:generateContent?key={_apiKey}";

        var body = new
        {
            contents = new[] { new { parts = new[] { new { text = prompt } } } },
            generationConfig = new { temperature = 0.7, maxOutputTokens = 4096 }
        };

        var content = new StringContent(
            JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");

        HttpResponseMessage response;
        try
        {
            response = await _httpClient.PostAsync(url, content);
        }
        catch (TaskCanceledException)
        {
            Console.WriteLine(">>> [GeminiService] LỖI: Timeout 30 giây khi gọi Gemini API.");
            throw new TimeoutException("Gemini API không phản hồi trong 30 giây. Vui lòng thử lại.");
        }

        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync();
            Console.WriteLine($">>> [GeminiService] LỖI API ({(int)response.StatusCode}): {err}");
            throw new Exception($"Gemini API lỗi {(int)response.StatusCode}: {err}");
        }

        var resultJson = await response.Content.ReadAsStringAsync();
        Console.WriteLine(">>> [GeminiService] Đã nhận được response từ API.");
        using var doc = JsonDocument.Parse(resultJson);

        var responseText = doc.RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString() ?? string.Empty;

        Console.WriteLine($">>> [GeminiService] Response text: {responseText.Substring(0, Math.Min(100, responseText.Length))}...");
        return responseText;
    }

    public int EstimateTokens(string prompt, string response)
        => (prompt.Length + response.Length) / 4;
}
