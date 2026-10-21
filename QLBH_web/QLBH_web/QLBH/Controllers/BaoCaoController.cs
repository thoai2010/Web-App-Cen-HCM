using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Web.Mvc;

// iTextSharp alias để tránh đụng System.Drawing.Font
using iTextSharp.text;
using iTextSharp.text.pdf;
using Font = iTextSharp.text.Font;

namespace QLBH.Controllers
{
    public class BaoCaoController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // =========================================================
        // 1) LỊCH SỬ BÁO CÁO
        // =========================================================
        public ActionResult Index()
        {
            var list = new List<BaoCaoViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT MaBC, NgayLap FROM BaoCao ORDER BY NgayLap DESC";
                SqlCommand cmd = new SqlCommand(query, conn);

                conn.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    list.Add(new BaoCaoViewModel
                    {
                        MaBC = dr["MaBC"].ToString(),
                        NgayLap = Convert.ToDateTime(dr["NgayLap"])
                    });
                }
            }

            return View(list);
        }

        // =========================================================
        // 2) NÚT XUẤT BÁO CÁO (LƯU LỊCH SỬ)
        // =========================================================
        public ActionResult XuatBaoCao()
        {
            string maNV = Session["MaNV"] as string;
            if (string.IsNullOrEmpty(maNV))
                maNV = "NV01";

            string maBC = TaoMaBaoCaoMoi();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand(@"
            INSERT INTO BaoCao (MaBC, NoiDung, NgayLap, MaNV)
            VALUES (@MaBC, N'Báo cáo thống kê tổng hợp', GETDATE(), @MaNV)", conn);

                cmd.Parameters.AddWithValue("@MaBC", maBC);
                cmd.Parameters.AddWithValue("@MaNV", maNV);
                cmd.ExecuteNonQuery();
            }

            return Json(new { MaBC = maBC }, JsonRequestBehavior.AllowGet);
        }

        // =========================================================
        // 3) NHẬN 2 BIỂU ĐỒ + SINH PDF + LƯU FILE
        // =========================================================
        [HttpPost]
        public ActionResult ExportPDF(string img1, string img2,
                                      string doanhThu, string congNo,
                                      string tonKho, string soLuongNhap, string maBC)
        {
            decimal _doanhThu = decimal.Parse(doanhThu);
            decimal _congNo = decimal.Parse(congNo);
            int _tonKho = int.Parse(tonKho);
            int _soLuongNhap = int.Parse(soLuongNhap);

            
            string maNV = Session["MaNV"] as string ?? "NV01";
            DateTime ngayLap = DateTime.Now;

            using (var ms = new MemoryStream())
            {
                Document doc = new Document(PageSize.A4, 40, 40, 40, 40);
                PdfWriter.GetInstance(doc, ms);
                doc.Open();

                // Font Unicode
                string fontPath = Server.MapPath("~/Fonts/arial.ttf");
                BaseFont bf = BaseFont.CreateFont(fontPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
                Font titleFont = new Font(bf, 20, Font.BOLD);
                Font headerFont = new Font(bf, 12, Font.BOLD);
                Font normalFont = new Font(bf, 12);

                // TIÊU ĐỀ
                doc.Add(new Paragraph("BÁO CÁO & THỐNG KÊ TỔNG HỢP", titleFont)
                {
                    Alignment = Element.ALIGN_CENTER,
                    SpacingAfter = 10f
                });

                // THÔNG TIN
                doc.Add(new Paragraph($"Mã báo cáo: {maBC}", normalFont));
                doc.Add(new Paragraph($"Ngày lập: {ngayLap:dd/MM/yyyy HH:mm}", normalFont));
                doc.Add(new Paragraph($"Nhân viên lập: {maNV}\n", normalFont));
                doc.Add(new Paragraph("\n"));
                // BẢNG
                PdfPTable table = new PdfPTable(2);
                table.WidthPercentage = 100;
                table.SetWidths(new float[] { 4, 3 });

                PdfPCell HeaderCell(string text) =>
                    new PdfPCell(new Phrase(text, headerFont))
                    {
                        BackgroundColor = new BaseColor(230, 230, 230),
                        HorizontalAlignment = Element.ALIGN_CENTER,
                        Padding = 6
                    };

                table.AddCell(HeaderCell("Chỉ tiêu"));
                table.AddCell(HeaderCell("Giá trị"));
                table.AddCell(new Phrase("Doanh thu", normalFont));
                table.AddCell(new Phrase(_doanhThu.ToString("N0") + " ₫", normalFont));
                table.AddCell(new Phrase("Công nợ (Chi phí nhập)", normalFont));
                table.AddCell(new Phrase(_congNo.ToString("N0") + " ₫", normalFont));
                table.AddCell(new Phrase("Tồn kho", normalFont));
                table.AddCell(new Phrase(_tonKho.ToString("N0"), normalFont));
                table.AddCell(new Phrase("Số lượng nhập", normalFont));
                table.AddCell(new Phrase(_soLuongNhap.ToString("N0"), normalFont));

                doc.Add(table);
                doc.Add(new Paragraph("\n"));

                // BIỂU ĐỒ 1 (GIẢM CAO)
                if (!string.IsNullOrEmpty(img1))
                {
                    Image barChart = Image.GetInstance(Convert.FromBase64String(img1.Replace("data:image/png;base64,", "")));
                    barChart.ScaleToFit(400, 250);   // GIẢM CHIỀU CAO
                    barChart.Alignment = Element.ALIGN_CENTER;
                    doc.Add(barChart);
                    doc.Add(new Paragraph("\n"));
                }

                // BIỂU ĐỒ 2 (GIẢM CAO HƠN)
                if (!string.IsNullOrEmpty(img2))
                {
                    Image pieChart = Image.GetInstance(Convert.FromBase64String(img2.Replace("data:image/png;base64,", "")));
                    pieChart.ScaleToFit(420, 220);   // GIẢM KÍCH THƯỚC
                    pieChart.Alignment = Element.ALIGN_CENTER;
                    doc.Add(pieChart);
                    doc.Add(new Paragraph("\n"));
                }

                // CẢM ƠN
                doc.Add(new Paragraph("Cảm ơn bạn đã sử dụng hệ thống CEN HCM!", normalFont)
                {
                    Alignment = Element.ALIGN_CENTER,
                    SpacingBefore = 10f
                });

                doc.Close();

                return File(ms.ToArray(), "application/pdf", "BaoCaoTongHop_" + maBC + ".pdf");
            }
        }




        // =========================================================
        // 4) TẢI FILE PDF VỀ MÁY
        // =========================================================
        public ActionResult DownloadLatestPDF()
        {
            string fileName = Session["LastReportPDF"] as string;

            if (fileName == null)
                return Content("Không tìm thấy file PDF!");

            string fullPath = Server.MapPath("~/Reports/" + fileName);
            byte[] bytes = System.IO.File.ReadAllBytes(fullPath);

            return File(bytes, "application/pdf", fileName);
        }

        // =========================================================
        // HÀM PHỤ — Sinh mã BC mới
        // =========================================================
        private string TaoMaBaoCaoMoi()
        {
            string last = "BC000";

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand(
                    "SELECT TOP 1 MaBC FROM BaoCao ORDER BY MaBC DESC", conn);

                conn.Open();
                object result = cmd.ExecuteScalar();
                if (result != null)
                    last = result.ToString();
            }

            int so = int.Parse(last.Substring(2)) + 1;
            return "BC" + so.ToString("000");
        }

        // =========================================================
        // HÀM PHỤ — Lấy dữ liệu thống kê
        // =========================================================
        private ThongKeViewModel GetThongKeData()
        {
            var tkCtrl = new ThongKeController();
            tkCtrl.ControllerContext = new ControllerContext(this.Request.RequestContext, tkCtrl);

            var result = tkCtrl.Index() as ViewResult;

            return result?.Model as ThongKeViewModel ?? new ThongKeViewModel();
        }
    }
}
