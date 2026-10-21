using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class DonHangController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // =============================
        // BẮT BUỘC ĐĂNG NHẬP
        // =============================
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            if (Session["KhachHang"] == null)
            {
                filterContext.Result = RedirectToAction("Login", "Account");
                return;
            }
            base.OnActionExecuting(filterContext);
        }

        // =============================
        // DANH SÁCH ĐƠN HÀNG
        // =============================
        public ActionResult Index(string trangThai = "TatCa")
        {
            var kh = Session["KhachHang"] as KhachHangViewModel;
            string maKH = kh.MaKH;

            List<DonHangViewModel> ds = new List<DonHangViewModel>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
                    SELECT dh.MaDH, dh.NgayDat, dh.TrangThai, dh.TongTien,
                           kh.MaKH, kh.TenKH, kh.DiaChi, kh.SDT, kh.Email
                    FROM DonHang dh
                    INNER JOIN KhachHang kh ON dh.MaKH = kh.MaKH
                    WHERE dh.MaKH = @MaKH";

                if (trangThai != "TatCa")
                    sql += " AND dh.TrangThai = @TrangThai";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKH", maKH);
                    if (trangThai != "TatCa")
                        cmd.Parameters.AddWithValue("@TrangThai", trangThai);

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            ds.Add(new DonHangViewModel
                            {
                                MaDH = r["MaDH"].ToString().Trim(),
                                NgayDat = Convert.ToDateTime(r["NgayDat"]),
                                TrangThai = r["TrangThai"].ToString(),
                                TongTien = Convert.ToInt32(r["TongTien"]),
                                MaKH = r["MaKH"].ToString(),
                                HoTen = r["TenKH"].ToString(),
                                DiaChi = r["DiaChi"].ToString(),
                                SDT = r["SDT"].ToString(),
                                Email = r["Email"].ToString(),
                                ChiTiet = new List<ChiTietDonHang>()
                            });
                        }
                    }
                }

                // Lấy chi tiết từng đơn
                foreach (var dh in ds)
                {
                    string sqlCT = @"
                        SELECT c.MaSP, s.TenSP, c.SoLuong, c.DonGia
                        FROM CT_DonHang_SP c
                        INNER JOIN SanPham s ON c.MaSP = s.MaSP
                        WHERE c.MaDH = @MaDH";

                    using (var cmd2 = new SqlCommand(sqlCT, conn))
                    {
                        cmd2.Parameters.AddWithValue("@MaDH", dh.MaDH);

                        using (var r2 = cmd2.ExecuteReader())
                        {
                            while (r2.Read())
                            {
                                dh.ChiTiet.Add(new ChiTietDonHang
                                {
                                    MaSP = r2["MaSP"].ToString(),
                                    TenSP = r2["TenSP"].ToString(),
                                    SoLuong = Convert.ToInt32(r2["SoLuong"]),
                                    DonGia = Convert.ToInt32(r2["DonGia"])
                                });
                            }
                        }
                    }
                }
            }

            ViewBag.TrangThai = trangThai;
            return View(ds);
        }

        // =============================
        // CHI TIẾT ĐƠN HÀNG
        // =============================
        public ActionResult ChiTiet(string maDH)
        {
            if (string.IsNullOrEmpty(maDH))
                return RedirectToAction("Index");

            maDH = maDH.Trim(); 

            var kh = Session["KhachHang"] as KhachHangViewModel;

            var dh = LayDonHangTheoMa(maDH, kh.MaKH);

            if (dh == null)
                return HttpNotFound();

            return View(dh);
        }

        private DonHangViewModel LayDonHangTheoMa(string maDH, string maKH)
        {
            DonHangViewModel dh = null;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
                    SELECT dh.MaDH, dh.NgayDat, dh.TrangThai, dh.TongTien,
                           kh.MaKH, dh.HoTen, dh.DiaChi, dh.SDT, dh.Email
                    FROM DonHang dh
                    INNER JOIN KhachHang kh ON dh.MaKH = kh.MaKH
                    WHERE dh.MaDH = @MaDH AND dh.MaKH = @MaKH";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaDH", maDH);
                    cmd.Parameters.AddWithValue("@MaKH", maKH);

                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            dh = new DonHangViewModel
                            {
                                MaDH = r["MaDH"].ToString(),
                                NgayDat = Convert.ToDateTime(r["NgayDat"]),
                                TrangThai = r["TrangThai"].ToString(),
                                TongTien = Convert.ToInt32(r["TongTien"]),
                                MaKH = r["MaKH"].ToString(),
                                HoTen = r["Hoten"].ToString(),
                                DiaChi = r["DiaChi"].ToString(),
                                SDT = r["SDT"].ToString(),
                                Email = r["Email"].ToString(),
                                ChiTiet = new List<ChiTietDonHang>()
                            };
                        }
                    }
                }

                if (dh == null) return null;

                string sqlCT = @"
                    SELECT c.MaSP, s.TenSP, c.SoLuong, c.DonGia
                    FROM CT_DonHang_SP c
                    INNER JOIN SanPham s ON c.MaSP = s.MaSP
                    WHERE c.MaDH = @MaDH";

                using (var cmd2 = new SqlCommand(sqlCT, conn))
                {
                    cmd2.Parameters.AddWithValue("@MaDH", maDH);

                    using (var r2 = cmd2.ExecuteReader())
                    {
                        while (r2.Read())
                        {
                            dh.ChiTiet.Add(new ChiTietDonHang
                            {
                                MaSP = r2["MaSP"].ToString(),
                                TenSP = r2["TenSP"].ToString(),
                                SoLuong = Convert.ToInt32(r2["SoLuong"]),
                                DonGia = Convert.ToInt32(r2["DonGia"])
                            });
                        }
                    }
                }
            }

            return dh;
        }

        // =============================
        // KHÁCH HÀNG GỬI YÊU CẦU XỬ LÝ (HỦY / HOÀN TIỀN)
        // =============================
        [HttpGet]
        public ActionResult XuLy(string maDH, string loai)
        {
            if (string.IsNullOrEmpty(maDH) || string.IsNullOrEmpty(loai))
                return RedirectToAction("Index");

            maDH = maDH.Trim();

            return View(new YeuCauXuLyViewModel
            {
                MaDH = maDH,
                LoaiXuLy = loai
            });
        }

        [HttpPost]
        public ActionResult XuLy(YeuCauXuLyViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string maPX = GenerateMaPX();

                // Tạo phiếu xử lý
                using (var cmd = new SqlCommand(@"
                    INSERT INTO PhieuXuLyDH (MaPX, MaDH, LoaiXuLy, TrangThaiPX, LyDo, GhiChu)
                    VALUES (@MaPX, @MaDH, @LoaiXuLy, N'Chờ xử lý', @LyDo, @GhiChu)", conn))
                {
                    cmd.Parameters.AddWithValue("@MaPX", maPX);
                    cmd.Parameters.AddWithValue("@MaDH", model.MaDH);
                    cmd.Parameters.AddWithValue("@LoaiXuLy", model.LoaiXuLy);
                    cmd.Parameters.AddWithValue("@LyDo", model.LyDo ?? "");
                    cmd.Parameters.AddWithValue("@GhiChu", model.GhiChu ?? "");
                    cmd.ExecuteNonQuery();
                }

                // Lưu chi tiết SP
                var dh = LayDonHangTheoMa(model.MaDH, (Session["KhachHang"] as KhachHangViewModel).MaKH);
                if (dh != null)
                {
                    foreach (var sp in dh.ChiTiet)
                    {
                        using (var cmd = new SqlCommand(@"
                            INSERT INTO CT_PhieuXuLy (MaPX, MaSP, SoLuong, DonGia)
                            VALUES (@MaPX, @MaSP, @SoLuong, @DonGia)", conn))
                        {
                            cmd.Parameters.AddWithValue("@MaPX", maPX);
                            cmd.Parameters.AddWithValue("@MaSP", sp.MaSP);
                            cmd.Parameters.AddWithValue("@SoLuong", sp.SoLuong);
                            cmd.Parameters.AddWithValue("@DonGia", sp.DonGia);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }

                // Nếu KH chọn "Hủy", hủy ngay lập tức không đòi lý do
                if (model.LoaiXuLy == "Huy")
                {
                    using (var cmd = new SqlCommand("UPDATE DonHang SET TrangThai = N'Đã hủy' WHERE MaDH = @MaDH", conn))
                    {
                        cmd.Parameters.AddWithValue("@MaDH", model.MaDH);
                        cmd.ExecuteNonQuery();
                    }
                }
            }

            TempData["msg"] = "Yêu cầu của bạn đã được gửi!";
            return RedirectToAction("ChiTiet", new { maDH = model.MaDH });
        }

        // =============================
        // KH HỦY ĐƠN TRỰC TIẾP (KHÔNG PHẢI XỬ LÝ)
        // =============================
        public ActionResult Huy(string maDH)
        {
            if (string.IsNullOrWhiteSpace(maDH))
                return RedirectToAction("Index");

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                var cmd = new SqlCommand("UPDATE DonHang SET TrangThai = N'Đã hủy' WHERE MaDH = @MaDH", conn);
                cmd.Parameters.AddWithValue("@MaDH", maDH.Trim());
                cmd.ExecuteNonQuery();
            }

            TempData["Success"] = "Hủy đơn hàng thành công!";
            return RedirectToAction("Index");
        }

        // =============================
        // KHÁCH XÁC NHẬN ĐÃ NHẬN HÀNG
        // =============================
        [HttpPost]
        public ActionResult XacNhanDaNhan(string maDH)
        {
            if (string.IsNullOrWhiteSpace(maDH))
                return RedirectToAction("Index");

            maDH = maDH.Trim();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                // 1. Cập nhật trạng thái đơn hàng
                using (var cmd = new SqlCommand(
                    "UPDATE DonHang SET TrangThai = N'Hoàn thành' WHERE MaDH = @MaDH", conn))
                {
                    cmd.Parameters.AddWithValue("@MaDH", maDH);
                    cmd.ExecuteNonQuery();
                }

                // 2. Lấy tổng tiền + MaKH từ đơn hàng
                int tongTien = 0;
                string maKH = "";

                using (var cmd = new SqlCommand(@"
            SELECT dh.MaKH, SUM(ct.SoLuong * ct.DonGia) AS TongTien
            FROM DonHang dh
            JOIN CT_DonHang_SP ct ON dh.MaDH = ct.MaDH
            WHERE dh.MaDH = @MaDH
            GROUP BY dh.MaKH", conn))
                {
                    cmd.Parameters.AddWithValue("@MaDH", maDH);

                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            maKH = rd["MaKH"].ToString();
                            tongTien = Convert.ToInt32(rd["TongTien"]);
                        }
                    }
                }

                // 3. Sinh mã hóa đơn
                string maHD = GenerateMaHD();

                // 4. Tạo hóa đơn 
                using (var cmd = new SqlCommand(@"
            INSERT INTO HoaDon (MaHD, MaDH, MaKH, SoTien, NgayLap)
            VALUES (@MaHD, @MaDH, @MaKH, @SoTien, GETDATE())", conn))
                {
                    cmd.Parameters.AddWithValue("@MaHD", maHD);
                    cmd.Parameters.AddWithValue("@MaDH", maDH);
                    cmd.Parameters.AddWithValue("@MaKH", maKH);
                    cmd.Parameters.AddWithValue("@SoTien", tongTien);
                    cmd.ExecuteNonQuery();
                }
            }

            TempData["msg"] = "Xác nhận nhận hàng thành công!";
            return RedirectToAction("Index");
        }

        // =============================
        // SINH MÃ HÓA ĐƠN: HD001 → HD002
        // =============================
        private string GenerateMaHD()
        {
            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
                    SELECT TOP 1 MaHD 
                    FROM HoaDon 
                    WHERE MaHD LIKE 'HD%'
                    ORDER BY MaHD DESC";

                using (var cmd = new SqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        int so = int.Parse(r["MaHD"].ToString().Substring(2));
                        return "HD" + (so + 1).ToString("D3");
                    }
                }
            }

            return "HD001";
        }

        // =============================
        // SINH MÃ PHIẾU XỬ LÝ: PX001 → PX002
        // =============================
        private string GenerateMaPX()
        {
            int max = 0;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                using (var cmd = new SqlCommand("SELECT MaPX FROM PhieuXuLyDH", conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        string ma = r["MaPX"].ToString().Trim();

                        if (ma.StartsWith("PX") && ma.Length == 5)
                        {
                            if (int.TryParse(ma.Substring(2), out int so))
                                if (so > max) max = so;
                        }
                    }
                }
            }

            return "PX" + (max + 1).ToString("D3");
        }
    }
}
