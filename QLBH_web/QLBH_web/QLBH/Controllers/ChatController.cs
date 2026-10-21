using Newtonsoft.Json;
using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Mvc;

public class ChatController : Controller
{
    private readonly GeminiService _geminiService = new GeminiService();

    // Lấy Connection String
    private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

    public ActionResult Index()
    {
        return View();
    }

    // Lấy dữ liệu sản phẩm từ SQL Server bằng ADO.NET
    private List<SanPham> GetProductData()
    {
        var products = new List<SanPham>();
        // Lấy TOP 20 sản phẩm có tồn kho > 0
        string query = "SELECT MaSP, TenSP, MoTa, GiaBan, SLTon, Hinh, MaLoai FROM SanPham WHERE SLTon > 0";

        using (SqlConnection conn = new SqlConnection(connStr))
        {
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        products.Add(new SanPham
                        {
                            MaSP = reader["MaSP"].ToString(),
                            TenSP = reader["TenSP"].ToString(),
                            MoTa = reader["MoTa"].ToString(),
                            GiaBan = Convert.ToInt32(reader["GiaBan"]),
                            SLTon = Convert.ToInt32(reader["SLTon"]),
                            Hinh = reader["Hinh"].ToString(),
                            MaLoai = reader["MaLoai"].ToString()
                        });
                    }
                }
            }
        }
        return products;
    }

    private string FormatProductContext(List<SanPham> products)
    {
        return string.Join(" | ", products.Select(p =>
            $"{p.MaSP}: {p.TenSP}. Giá {p.GiaBan:N0} VNĐ. Tồn {p.SLTon}. Mô tả: {p.MoTa}"
        ));
    }

    [HttpPost]
    public async Task<ActionResult> Ask(string message)
    {
        try
        {
            var allProducts = GetProductData();
            var productContext = FormatProductContext(allProducts);

            string geminiResponse = await _geminiService.AskGemini(message, productContext);

            // Regex tìm JSON {"MaSP": [...]} ở cuối câu trả lời
            var match = Regex.Match(geminiResponse, @"(\{\s*""MaSP""\s*:\s*\[.*?\]\s*\})",
                                       RegexOptions.Singleline | RegexOptions.RightToLeft);

            string replyText = geminiResponse;
            List<string> matchedMaSP = new List<string>();

            if (match.Success)
            {
                string jsonProductCodes = match.Value;
                // Cắt phần JSON ra khỏi câu trả lời để View chỉ hiển thị văn bản sạch
                replyText = geminiResponse.Replace(jsonProductCodes, "").Trim();

                dynamic productCodeObj = JsonConvert.DeserializeObject(jsonProductCodes);

                foreach (var code in productCodeObj.MaSP)
                {
                    matchedMaSP.Add(code.ToString());
                }
            }

            // Lọc sản phẩm để hiển thị Cards
            var productsToShow = allProducts
                                 .Where(p => matchedMaSP.Contains(p.MaSP))
                                 .ToList();

            // Trả về JSON cho View (AJAX)
            return Json(new
            {
                reply = replyText,
                products = productsToShow
            });
        }
        catch (Exception ex)
        {
            return Json(new { reply = $"Đã xảy ra lỗi hệ thống: {ex.Message}", products = new List<SanPham>() });
        }
    }
}