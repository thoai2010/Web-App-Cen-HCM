using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using QLBH.Models;

namespace QLBH.Controllers
{
    public class SanPhamController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // ================== DANH MỤC ==================
        public ActionResult DanhMuc(string maLoai = null, int page = 1)
        {
            int pageSize = 16;
            var dsSanPham = new List<SanPham>();
            var dsLoai = LayDanhMucLoai();
            int totalItems = 0;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sqlCount = "SELECT COUNT(*) FROM SanPham" +
                                  (string.IsNullOrEmpty(maLoai) ? "" : " WHERE LTRIM(RTRIM(MaLoai)) = @MaLoai");

                using (var cmdCount = new SqlCommand(sqlCount, conn))
                {
                    if (!string.IsNullOrEmpty(maLoai))
                        cmdCount.Parameters.AddWithValue("@MaLoai", maLoai.Trim());
                    totalItems = (int)cmdCount.ExecuteScalar();
                }

                string sql = @"
                    SELECT * FROM (
                        SELECT ROW_NUMBER() OVER (ORDER BY MaSP) AS RowNum,
                               LTRIM(RTRIM(MaSP)) AS MaSP, TenSP, DonViTinh, GiaBan,
                               ISNULL(Hinh,'') AS Hinh, LTRIM(RTRIM(MaLoai)) AS MaLoai
                        FROM SanPham " + (string.IsNullOrEmpty(maLoai) ? "" : " WHERE LTRIM(RTRIM(MaLoai)) = @MaLoai") + @"
                    ) AS SP
                    WHERE RowNum BETWEEN @Start AND @End";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(maLoai))
                        cmd.Parameters.AddWithValue("@MaLoai", maLoai.Trim());
                    cmd.Parameters.AddWithValue("@Start", (page - 1) * pageSize + 1);
                    cmd.Parameters.AddWithValue("@End", page * pageSize);

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            dsSanPham.Add(new SanPham
                            {
                                MaSP = r["MaSP"].ToString(),
                                TenSP = r["TenSP"].ToString(),
                                DonViTinh = r["DonViTinh"].ToString(),
                                GiaBan = Convert.ToInt32(r["GiaBan"]),
                                Hinh = XuLyDuongDanAnh(r["Hinh"].ToString())
                            });
                        }
                    }
                }
            }

            ViewBag.DanhMucLoai = dsLoai;
            ViewBag.CurrentLoai = maLoai?.Trim();
            ViewBag.CurrentPage = page;
            ViewBag.TotalPages = (int)Math.Ceiling(totalItems / (double)pageSize);
            ViewBag.KhuyenMai = LayDanhSachKhuyenMai();

            return View(dsSanPham);
        }


        // ================== TÌM KIẾM ==================
        public ActionResult TimKiem(string keyword)
        {
            if (string.IsNullOrWhiteSpace(keyword))
                return RedirectToAction("DanhMuc");

            var dsSanPham = new List<SanPham>();
            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                var sql = @"SELECT MaSP, TenSP, DonViTinh, GiaBan, ISNULL(Hinh,'') AS Hinh 
                            FROM SanPham
                            WHERE TenSP LIKE N'%' + @kw + '%' OR MaSP LIKE N'%' + @kw + '%'";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@kw", keyword.Trim());

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            dsSanPham.Add(new SanPham
                            {
                                MaSP = r["MaSP"].ToString().Trim(),
                                TenSP = r["TenSP"].ToString(),
                                DonViTinh = r["DonViTinh"].ToString(),
                                GiaBan = Convert.ToInt32(r["GiaBan"]),
                                Hinh = XuLyDuongDanAnh(r["Hinh"].ToString())
                            });
                        }
                    }
                }
            }

            ViewBag.Keyword = keyword;
            ViewBag.DanhMucLoai = LayDanhMucLoai();
            return View("DanhMuc", dsSanPham);
        }


        // ================== GỢI Ý TÌM KIẾM  ==================
        [HttpGet]
        public JsonResult GoiySanPham(string term)
        {
            var list = new List<object>();

            if (string.IsNullOrWhiteSpace(term))
                return Json(list, JsonRequestBehavior.AllowGet);

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
            SELECT TOP 8 MaSP, TenSP, GiaBan, ISNULL(Hinh,'') AS Hinh
            FROM SanPham
            WHERE TenSP LIKE '%' + @term + '%'
            ORDER BY TenSP";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@term", term.Trim());

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            list.Add(new
                            {
                                MaSP = r["MaSP"].ToString().Trim(),
                                TenSP = r["TenSP"].ToString(),
                                GiaBan = Convert.ToInt32(r["GiaBan"]),
                                Hinh = XuLyDuongDanAnh(r["Hinh"].ToString())
                            });
                        }
                    }
                }
            }

            return Json(list, JsonRequestBehavior.AllowGet);
        }


        // ================== CHI TIẾT SẢN PHẨM ==================
        public ActionResult ChiTiet(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
                return RedirectToAction("DanhMuc");

            id = id.Trim();
            SanPham sp = null;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
        SELECT LTRIM(RTRIM(sp.MaSP)) AS MaSP, sp.TenSP, sp.MoTa, sp.DonViTinh, sp.GiaBan,
        ISNULL(sp.Hinh,'') AS Hinh, sp.SLTon, l.TenLoai
        FROM SanPham sp
        LEFT JOIN LoaiSanPham l ON sp.MaLoai = l.MaLoai
        WHERE LTRIM(RTRIM(sp.MaSP)) = @MaSP
        ";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaSP", id);
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            sp = new SanPham
                            {
                                MaSP = r["MaSP"].ToString(),
                                TenSP = r["TenSP"].ToString(),
                                MoTa = r["MoTa"].ToString(),
                                DonViTinh = r["DonViTinh"].ToString(),
                                GiaBan = Convert.ToInt32(r["GiaBan"]),
                                Hinh = XuLyDuongDanAnh(r["Hinh"].ToString()),
                                SLTon = Convert.ToInt32(r["SLTon"]),
                                TenLoai = r["TenLoai"].ToString(),
                            };
                        }
                    }
                }
            }

            if (sp == null) return HttpNotFound();

            // Load đánh giá
            ViewBag.DanhGia = LayDanhSachDanhGia(id);

            var kh = Session["KhachHang"] as KhachHangViewModel;

            // Mặc định
            ViewBag.ChoPhepDanhGia = false;
            ViewBag.DaDanhGia = false;
            ViewBag.MaDH_DaDanhGia = "";
            ViewBag.MaDHForReview = "";

            // Chưa đăng nhập → dừng
            if (kh == null)
                return View(sp);

            string maKH = kh.MaKH;

            // Kiểm tra KH đã mua & hoàn thành đơn chưa
            bool daMuaHoanThanh = KiemTraQuyenDanhGia(maKH, id);

            if (!daMuaHoanThanh)
                return View(sp);

            // Lấy đơn hàng hoàn thành gần nhất
            string maDH = LayMaDHHoanThanhGanNhat(maKH, id);

            ViewBag.MaDHForReview = maDH;

            // Kiểm tra KH đã đánh giá trong đơn đó chưa
            bool daDG = DaDanhGia(maKH, id, maDH);

            if (daDG)
            {
                ViewBag.DaDanhGia = true;
                ViewBag.MaDH_DaDanhGia = maDH;
                return View(sp);
            }

            // Nếu đã mua, đã hoàn thành và chưa đánh giá → Được phép
            ViewBag.ChoPhepDanhGia = true;

            return View(sp);
        }

        // ================== LẤY ĐÁNH GIÁ ==================
        private List<DanhGia> LayDanhSachDanhGia(string maSP)
        {
            var list = new List<DanhGia>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
            SELECT dg.MaDG, dg.SoSao, ISNULL(dg.NoiDung,'') AS NoiDung, dg.NgayDG,
                   dg.MaKH, kh.TenKH, kh.AnhDaiDien
            FROM DanhGia dg
            JOIN KhachHang kh ON kh.MaKH = dg.MaKH
            WHERE dg.MaSP = @MaSP
            ORDER BY dg.NgayDG DESC";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaSP", maSP);

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            list.Add(new DanhGia
                            {
                                MaDG = r["MaDG"].ToString().Trim(),
                                SoSao = Convert.ToInt32(r["SoSao"]),
                                NoiDung = r["NoiDung"].ToString(),
                                NgayDG = Convert.ToDateTime(r["NgayDG"]),
                                MaKH = r["MaKH"].ToString().Trim(),
                                KhachHang = new KhachHangViewModel
                                {
                                    TenKH = r["TenKH"].ToString(),
                                    AnhDaiDien = r["AnhDaiDien"].ToString()
                                }
                            });
                        }
                    }
                }
            }

            return list;
        }

        // ================== KIỂM TRA QUYỀN ĐÁNH GIÁ (bằng MaKH + MaSP) ==================
        private bool KiemTraQuyenDanhGia(string maKH, string maSP)
        {
            if (string.IsNullOrWhiteSpace(maKH) || string.IsNullOrWhiteSpace(maSP))
                return false;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
            SELECT COUNT(1)
            FROM DonHang dh
            INNER JOIN CT_DonHang_SP ct ON dh.MaDH = ct.MaDH
            WHERE dh.MaKH = @MaKH
              AND ct.MaSP = @MaSP
              AND dh.TrangThai = N'Hoàn thành'";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKH", maKH.Trim());
                    cmd.Parameters.AddWithValue("@MaSP", maSP.Trim());

                    int count = Convert.ToInt32(cmd.ExecuteScalar() ?? 0);
                    return count > 0;
                }
            }
        }

        // ================== Lấy MaDH Hoàn thành gần nhất ==================
        private string LayMaDHHoanThanhGanNhat(string maKH, string maSP)
        {
            if (string.IsNullOrWhiteSpace(maKH) || string.IsNullOrWhiteSpace(maSP))
                return null;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
            SELECT TOP 1 dh.MaDH
            FROM DonHang dh
            INNER JOIN CT_DonHang_SP ct ON dh.MaDH = ct.MaDH
            WHERE dh.MaKH = @MaKH
              AND ct.MaSP = @MaSP
              AND dh.TrangThai = N'Hoàn thành'
            ORDER BY dh.NgayDat DESC, dh.MaDH DESC";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKH", maKH.Trim());
                    cmd.Parameters.AddWithValue("@MaSP", maSP.Trim());

                    var val = cmd.ExecuteScalar();
                    return val == null ? null : val.ToString().Trim();
                }
            }
        }

        // ================== ĐÁNH GIÁ SẢN PHẨM (POST) ==================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DanhGiaSP(DanhGia model)
        {
            // đảm bảo đăng nhập
            var kh = Session["KhachHang"] as KhachHangViewModel;
            if (kh == null)
            {
                TempData["Error"] = "Vui lòng đăng nhập để gửi đánh giá.";
                return RedirectToAction("ChiTiet", new { id = model?.MaSP ?? "" });
            }

            // validate cơ bản
            if (model == null || string.IsNullOrEmpty(model.MaSP) || model.SoSao < 1 || model.SoSao > 5)
            {
                TempData["Error"] = "Dữ liệu đánh giá không hợp lệ.";
                return RedirectToAction("ChiTiet", new { id = model?.MaSP ?? "" });
            }

            model.MaKH = kh.MaKH.Trim();

            // nếu client ko gửi MaDH, lấy MaDH hoàn thành gần nhất
            if (string.IsNullOrWhiteSpace(model.MaDH))
            {
                model.MaDH = LayMaDHHoanThanhGanNhat(model.MaKH, model.MaSP);
            }

            // kiểm quyền với MaDH
            if (!KiemTraQuyenDanhGiaTheoDH(model.MaKH, model.MaSP, model.MaDH))
            {
                TempData["Error"] = "Bạn không có quyền đánh giá (phải có đơn hàng Hoàn thành chứa sản phẩm này).";
                return RedirectToAction("ChiTiet", new { id = model.MaSP });
            }

            // tạo MaDG nếu chưa có
            if (string.IsNullOrWhiteSpace(model.MaDG))
                model.MaDG = Guid.NewGuid().ToString("N").Substring(0, 10).ToUpper();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
            INSERT INTO DanhGia (MaDG, MaKH, MaSP, MaDH, SoSao, NoiDung)
            VALUES (@MaDG, @MaKH, @MaSP, @MaDH, @SoSao, @NoiDung)";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaDG", model.MaDG);
                    cmd.Parameters.AddWithValue("@MaKH", model.MaKH);
                    cmd.Parameters.AddWithValue("@MaSP", model.MaSP);
                    cmd.Parameters.AddWithValue("@MaDH", model.MaDH);
                    cmd.Parameters.AddWithValue("@SoSao", model.SoSao);
                    cmd.Parameters.AddWithValue("@NoiDung", model.NoiDung ?? string.Empty);

                    try
                    {
                        cmd.ExecuteNonQuery();
                        TempData["Success"] = "Gửi đánh giá thành công.";
                    }
                    catch (SqlException ex)
                    {
                        // Lỗi do đã tồn tại đánh giá (trùng MaKH + MaSP + MaDH)
                        if (ex.Number == 2627 || ex.Number == 2601) // UNIQUE KEY
                        {
                            TempData["Error"] =
                                $"Bạn đã đánh giá sản phẩm này trong đơn hàng {model.MaDH} rồi. Vui lòng đặt đơn mới để tiếp tục đánh giá sản phẩm.";
                        }
                        else
                        {
                            TempData["Error"] = "Có lỗi xảy ra khi gửi đánh giá. Vui lòng thử lại.";
                        }
                    }

                }
            }

            return RedirectToAction("ChiTiet", new { id = model.MaSP });
        }

        // ================== KIỂM TRA QUYỀN ĐÁNH GIÁ THEO MA DH CỤ THỂ ==================
        private bool KiemTraQuyenDanhGiaTheoDH(string maKH, string maSP, string maDH)
        {
            if (string.IsNullOrWhiteSpace(maKH) || string.IsNullOrWhiteSpace(maSP) || string.IsNullOrWhiteSpace(maDH))
                return false;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
            SELECT COUNT(1)
            FROM DonHang dh
            INNER JOIN CT_DonHang_SP ct ON dh.MaDH = ct.MaDH
            WHERE dh.MaKH = @MaKH
              AND ct.MaSP = @MaSP
              AND dh.MaDH = @MaDH
              AND dh.TrangThai = N'Hoàn thành'";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKH", maKH.Trim());
                    cmd.Parameters.AddWithValue("@MaSP", maSP.Trim());
                    cmd.Parameters.AddWithValue("@MaDH", maDH.Trim());

                    int count = Convert.ToInt32(cmd.ExecuteScalar() ?? 0);
                    return count > 0;
                }
            }
        }
        private bool DaDanhGia(string maKH, string maSP, string maDH)
        {
            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
            SELECT COUNT(*) 
            FROM DanhGia 
            WHERE MaKH = @MaKH AND MaSP = @MaSP AND MaDH = @MaDH";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKH", maKH);
                    cmd.Parameters.AddWithValue("@MaSP", maSP);
                    cmd.Parameters.AddWithValue("@MaDH", maDH);

                    return (int)cmd.ExecuteScalar() > 0;
                }
            }
        }

        // ================== LẤY KHUYẾN MÃI ==================
        private List<KhuyenMai> LayDanhSachKhuyenMai()
        {
            var list = new List<KhuyenMai>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
            SELECT MaKM, TenCT, NgayBD, NgayKT, LoaiKM, MoTa
            FROM KhuyenMai
            WHERE NgayKT >= CAST(GETDATE() AS DATE)
            ORDER BY NgayBD DESC";

                using (var cmd = new SqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        list.Add(new KhuyenMai
                        {
                            MaKM = r["MaKM"].ToString(),
                            TenCT = r["TenCT"].ToString(),
                            MoTa = r["MoTa"].ToString(),
                            NgayBD = Convert.ToDateTime(r["NgayBD"]),
                            NgayKT = Convert.ToDateTime(r["NgayKT"]),
                            LoaiKM = r["LoaiKM"].ToString()
                        });
                    }
                }
            }

            return list;
        }

        // ================== CHI TIẾT KHUYẾN MÃI ==================
        public ActionResult ChiTietKM(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
                return RedirectToAction("DanhMuc");

            id = id.Trim();

            KhuyenMai km = null;
            List<ChiTietKM_SP> dsCT = new List<ChiTietKM_SP>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sqlKM = @"SELECT MaKM, TenCT, MoTa, NgayBD, NgayKT, LoaiKM
                         FROM KhuyenMai WHERE MaKM = @MaKM";

                using (var cmd = new SqlCommand(sqlKM, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKM", id);
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            km = new KhuyenMai
                            {
                                MaKM = r["MaKM"].ToString(),
                                TenCT = r["TenCT"].ToString(),
                                MoTa = r["MoTa"].ToString(),
                                NgayBD = Convert.ToDateTime(r["NgayBD"]),
                                NgayKT = Convert.ToDateTime(r["NgayKT"]),
                                LoaiKM = r["LoaiKM"].ToString()
                            };
                        }
                    }
                }

                if (km == null) return HttpNotFound();

                // Lấy chi tiết sản phẩm
                string sqlDetail = @"
                SELECT ct.MaSP, sp.TenSP, ct.SoLuongToiThieu, ct.TriGia
                FROM ChiTietKM_SP ct
                JOIN SanPham sp ON sp.MaSP = ct.MaSP
                WHERE ct.MaKM = @MaKM";

                using (var cmd = new SqlCommand(sqlDetail, conn))
                {
                    cmd.Parameters.AddWithValue("@MaKM", id);

                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            dsCT.Add(new ChiTietKM_SP
                            {
                                MaSP = r["MaSP"].ToString(),
                                TenSP = r["TenSP"].ToString(),
                                SoLuongToiThieu = Convert.ToInt32(r["SoLuongToiThieu"]),
                                TriGia = Convert.ToDecimal(r["TriGia"]),
                                MaKM = id
                            });
                        }
                    }
                }
            }

            ViewBag.ChiTiet = dsCT;
            return View(km);
        }

        // ================== HÀM XỬ LÝ ẢNH ==================
        private string XuLyDuongDanAnh(string hinh)
        {
            if (string.IsNullOrEmpty(hinh))
                return Url.Content("~/Content/images/no-image.png");

            hinh = hinh.Replace("\\", "/").Trim();

            return Url.Content("~/Content/images/sanpham/" + hinh.TrimStart('/'));
        }

        // ================== LẤY LOẠI SP ==================
        private List<LoaiSanPham> LayDanhMucLoai()
        {
            var list = new List<LoaiSanPham>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var sql = @"SELECT MaLoai, TenLoai FROM LoaiSanPham";

                using (var cmd = new SqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        list.Add(new LoaiSanPham
                        {
                            MaLoai = r["MaLoai"].ToString(),
                            TenLoai = r["TenLoai"].ToString()
                        });
                    }
                }
            }
            return list;
        }
    }
}
