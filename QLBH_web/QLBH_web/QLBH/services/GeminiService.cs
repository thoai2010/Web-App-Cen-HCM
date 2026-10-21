using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Configuration;
using QLBH.Models;

public class GeminiService
{
    private readonly string apiKey;

    // Đã sửa lỗi 404: Dùng Model và Endpoint ĐÚNG
    private const string API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";

    public GeminiService()
    {
        apiKey = ConfigurationManager.AppSettings["GeminiApiKey"];
    }

    public async Task<string> AskGemini(string question, string productContext)
    {
        var fullUrl = API_BASE_URL + apiKey;

        // Tối ưu hóa Prompt để buộc AI trả về JSON ở cuối
        string fullPrompt =
            "Bạn là trợ lý tư vấn sản phẩm. Bạn PHẢI trả lời câu hỏi của người dùng dựa trên danh sách sản phẩm được cung cấp. " +
            "Sau khi trả lời xong, bạn PHẢI xuống dòng và **chỉ** trích xuất chính xác MaSP của TẤT CẢ sản phẩm được đề xuất vào **CUỐI CÙNG** câu trả lời dưới dạng JSON. " +
            "Định dạng JSON KHÔNG được có ký tự dư thừa (như ```json) và phải là: {\"MaSP\":[\"MaSP_1\", \"MaSP_2\", ...]}" +
            "Nếu KHÔNG có sản phẩm nào được đề xuất, trả về: {\"MaSP\":[]}" +
            "\n\n--- DANH SÁCH SẢN PHẨM ---\n" +
            productContext +
            "\n\n--- CÂU HỎI NGƯỜI DÙNG ---\n" +
            question;

        // Cấu trúc Request Body JSON chuẩn của Gemini
        var requestBody = new
        {
            contents = new[]
            {
                new {
                    parts = new[] { new { text = fullPrompt } }
                }
            }
        };

        var json = JsonConvert.SerializeObject(requestBody);

        using (var client = new HttpClient())
        {
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            try
            {
                var response = await client.PostAsync(fullUrl, content);

                if (!response.IsSuccessStatusCode)
                {
                    string errorDetail = await response.Content.ReadAsStringAsync();
                    throw new Exception($"Gemini API Error ({response.StatusCode}): {errorDetail}");
                }

                var result = await response.Content.ReadAsStringAsync();

                // Trích xuất Text từ JSON trả về của Gemini
                dynamic obj = JsonConvert.DeserializeObject(result);
                string replyText = obj.candidates[0].content.parts[0].text.ToString();

                return replyText;
            }
            catch (Exception ex)
            {
                throw new Exception("Lỗi khi gọi API: " + ex.Message);
            }
        }
    }
}