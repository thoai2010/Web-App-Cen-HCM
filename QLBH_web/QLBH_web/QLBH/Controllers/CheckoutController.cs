using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web.Mvc;
using iTextSharp.text;
using iTextSharp.text.pdf;

namespace QLBH.Controllers
{
    public class CheckoutController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        public ActionResult Index(string ids)
        {
            var kh = Session["KhachHang"] as KhachHangViewModel;
            if (kh == null) return RedirectToAction("Login", "Account");

            var cart = Session["Cart"] as List<CartItem> ?? new List<CartItem>();
            if (!string.IsNullOrEmpty(ids))
            {
                var idList = ids.Split(',');
                cart.ForEach(x => x.IsSelected = idList.Contains(x.MaSP));
            }
            var selectedItems = cart.Where(x => x.IsSelected).ToList();
            if (!selectedItems.Any()) return RedirectToAction("Index", "GioHang");

            ViewBag.TongTien = selectedItems.Sum(x => x.ThanhTienSauKM);
            return View(selectedItems);
        }

        [HttpPost]
        public ActionResult PlaceOrder(string phuongThuc, string hoTen, string diaChi, string sdt, string email)
        {
            var cart = (Session["Cart"] as List<CartItem>)?.Where(x => x.IsSelected).ToList();
            if (cart == null || !cart.Any())
            {
                TempData["Error"] = "Giỏ hàng trống!";
                return RedirectToAction("Index", "GioHang");
            }

            var kh = Session["KhachHang"] as KhachHangViewModel;
            if (kh == null) return RedirectToAction("Login", "Account");

            string maKH = kh.MaKH;
            int tongTien = cart.Sum(x => (int)x.ThanhTienSauKM);
            string maDH;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (var tran = conn.BeginTransaction())
                {
                    try
                    {
                        // Tạo mã đơn hàng mới
                        string sqlGetMax = "SELECT ISNULL(MAX(MaDH), 'DH000') FROM DonHang";
                        using (var cmdMax = new SqlCommand(sqlGetMax, conn, tran))
                        {
                            string lastMa = cmdMax.ExecuteScalar().ToString();
                            int so = int.Parse(lastMa.Substring(2));
                            maDH = "DH" + (so + 1).ToString("D3");
                        }

                        // Chèn đơn hàng với TrangThai hợp lệ
                        string sqlDH = @"
                            INSERT INTO DonHang
                            (MaDH, NgayDat, TrangThai, TongTien, MaKH, HoTen, DiaChi, SDT, Email, PhuongThucThanhToan)
                            VALUES
                            (@MaDH, GETDATE(), @TrangThai, @TongTien, @MaKH, @HoTen, @DiaChi, @SDT, @Email, @PhuongThucThanhToan)";

                        using (var cmd = new SqlCommand(sqlDH, conn, tran))
                        {
                            cmd.Parameters.AddWithValue("@MaDH", maDH);
                            cmd.Parameters.AddWithValue("@TrangThai", "Đang xử lý"); 
                            cmd.Parameters.AddWithValue("@TongTien", tongTien);
                            cmd.Parameters.AddWithValue("@MaKH", maKH);
                            cmd.Parameters.AddWithValue("@HoTen", hoTen);
                            cmd.Parameters.AddWithValue("@DiaChi", diaChi);
                            cmd.Parameters.AddWithValue("@SDT", sdt);
                            cmd.Parameters.AddWithValue("@Email", email);
                            cmd.Parameters.AddWithValue("@PhuongThucThanhToan", phuongThuc);
                            cmd.ExecuteNonQuery();
                        }

                        // Chèn chi tiết đơn hàng
                        foreach (var item in cart)
                        {
                            string sqlCT = @"INSERT INTO CT_DonHang_SP(MaDH, MaSP, SoLuong, DonGia)
                                     VALUES(@MaDH, @MaSP, @SoLuong, @DonGia)";
                            using (var cmd = new SqlCommand(sqlCT, conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@MaDH", maDH);
                                cmd.Parameters.AddWithValue("@MaSP", item.MaSP);
                                cmd.Parameters.AddWithValue("@SoLuong", item.SoLuong);
                                cmd.Parameters.AddWithValue("@DonGia", item.GiaBan); 
                                cmd.Parameters.AddWithValue("@ThanhTien", item.ThanhTienSauKM);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tran.Commit();
                    }
                    catch (Exception ex)
                    {
                        tran.Rollback();
                        TempData["Error"] = "Đặt hàng thất bại: " + ex.Message;
                        return RedirectToAction("Index", "GioHang");
                    }
                }
            }

            // Tạo hóa đơn PDF
            string invoicePath = GenerateInvoice(maDH, cart, tongTien, phuongThuc, hoTen, diaChi, sdt, email);

            // Giữ lại các sản phẩm chưa chọn
            Session["Cart"] = (Session["Cart"] as List<CartItem>)?.Where(x => !x.IsSelected).ToList();

            TempData["MaDH"] = maDH;
            TempData["TongTien"] = tongTien;
            TempData["PhuongThuc"] = phuongThuc;
            TempData["HoTen"] = hoTen;
            TempData["DiaChi"] = diaChi;
            TempData["InvoicePath"] = invoicePath;

            return RedirectToAction("Success");
        }
        public ActionResult DownloadInvoice(string maDH)
        {
            if (string.IsNullOrEmpty(maDH)) return RedirectToAction("Index", "Home");

            // Đường dẫn file PDF đã lưu trước đó
            string filePath = Server.MapPath("~/Reports/HoaDon_" + maDH + ".pdf");
            if (!System.IO.File.Exists(filePath))
                return HttpNotFound("Hóa đơn không tồn tại.");

            return File(filePath, "application/pdf", "HoaDon_" + maDH + ".pdf");
        }

        public ActionResult Success()
        {
            ViewBag.MaDH = TempData["MaDH"];
            ViewBag.TongTien = TempData["TongTien"];
            ViewBag.PhuongThuc = TempData["PhuongThuc"];
            ViewBag.HoTen = TempData["HoTen"];
            ViewBag.DiaChi = TempData["DiaChi"];
            ViewBag.InvoicePath = TempData["InvoicePath"];
            return View();
        }

        private string GenerateInvoice(string maDH, List<CartItem> cart, decimal tongTien, string phuongThuc,
                               string hoTen, string diaChi, string sdt, string email)
        {
            string fileName = $"HoaDon_{maDH}.pdf";
            string reportsPath = Server.MapPath("~/Reports");
            if (!Directory.Exists(reportsPath))
                Directory.CreateDirectory(reportsPath);

            string filePath = Path.Combine(reportsPath, fileName);

            Document doc = new Document(PageSize.A4, 40, 40, 40, 40);
            PdfWriter.GetInstance(doc, new FileStream(filePath, FileMode.Create));
            doc.Open();

            string fontPath = Server.MapPath("~/Fonts/arial.ttf"); 
            BaseFont bf = BaseFont.CreateFont(fontPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);

            Font titleFont = new Font(bf, 20, Font.BOLD);
            Font cellFont = new Font(bf, 12, Font.NORMAL);
            Font totalFont = new Font(bf, 12, Font.BOLD);

            // Tiêu đề và thông tin khách hàng
            doc.Add(new Paragraph("HÓA ĐƠN MUA HÀNG", titleFont) { Alignment = Element.ALIGN_CENTER, SpacingAfter = 20f });
            doc.Add(new Paragraph($"Người nhận: {hoTen}", cellFont));
            doc.Add(new Paragraph($"Địa chỉ: {diaChi}", cellFont));
            doc.Add(new Paragraph($"SĐT: {sdt}", cellFont));
            doc.Add(new Paragraph($"Email: {email}", cellFont));
            doc.Add(new Paragraph($"Phương thức thanh toán: {phuongThuc}", cellFont));
            doc.Add(new Paragraph("\n"));

            // Bảng sản phẩm
            PdfPTable table = new PdfPTable(6) { WidthPercentage = 100 };
            table.SetWidths(new float[] { 4, 1, 2, 2, 2, 2 });

            string[] headers = { "Sản phẩm", "SL", "Đơn giá", "Khuyến mãi", "Tổng trước KM", "Tổng sau KM" };
            foreach (var h in headers)
                table.AddCell(new PdfPCell(new Phrase(h, cellFont)) { BackgroundColor = BaseColor.LIGHT_GRAY, HorizontalAlignment = Element.ALIGN_CENTER });

            foreach (var item in cart)
            {
                table.AddCell(new PdfPCell(new Phrase(item.TenSP, cellFont)));
                table.AddCell(new PdfPCell(new Phrase(item.SoLuong.ToString(), cellFont)) { HorizontalAlignment = Element.ALIGN_CENTER });
                table.AddCell(new PdfPCell(new Phrase(item.GiaBan.ToString("N0") + " VNĐ", cellFont)) { HorizontalAlignment = Element.ALIGN_RIGHT });
                table.AddCell(new PdfPCell(new Phrase(item.KhuyenMai.ToString("N0") + " VNĐ", cellFont)) { HorizontalAlignment = Element.ALIGN_RIGHT });
                table.AddCell(new PdfPCell(new Phrase(item.ThanhTien.ToString("N0") + " VNĐ", cellFont)) { HorizontalAlignment = Element.ALIGN_RIGHT });
                table.AddCell(new PdfPCell(new Phrase(item.ThanhTienSauKM.ToString("N0") + " VNĐ", cellFont)) { HorizontalAlignment = Element.ALIGN_RIGHT });
            }

            // Tổng tiền
            PdfPCell totalCell = new PdfPCell(new Phrase("Tạm tính", totalFont)) { Colspan = 5, HorizontalAlignment = Element.ALIGN_RIGHT };
            table.AddCell(totalCell);
            table.AddCell(new PdfPCell(new Phrase(tongTien.ToString("N0") + " VNĐ", totalFont)) { HorizontalAlignment = Element.ALIGN_RIGHT });

            doc.Add(table);

            // Lời cảm ơn
            doc.Add(new Paragraph("\nCảm ơn bạn đã mua hàng tại CEN HCM!\nChúc bạn một ngày tốt lành.", cellFont) { Alignment = Element.ALIGN_CENTER });

            doc.Close();
            return "/Reports/" + fileName;
        }
    }
}
