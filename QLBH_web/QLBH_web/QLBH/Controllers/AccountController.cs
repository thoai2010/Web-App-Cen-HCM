using QLBH.Models;
using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class AccountController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // === ĐĂNG KÝ ===
        [HttpGet]
        public ActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Register(RegisterViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Kiểm tra trùng tên đăng nhập
                var checkCmd = new SqlCommand("SELECT COUNT(*) FROM TaiKhoan WHERE TenDangNhap=@ten", conn);
                checkCmd.Parameters.AddWithValue("@ten", model.TenDangNhap);
                if ((int)checkCmd.ExecuteScalar() > 0)
                {
                    ModelState.AddModelError("", "Tên đăng nhập đã tồn tại.");
                    return View(model);
                }

                // Thêm tài khoản khách hàng
                var insert = new SqlCommand(@"INSERT INTO TaiKhoan(TenDangNhap, MatKhau, VaiTro, TrangThai) 
                                              VALUES(@ten, @mk, N'KhachHang', N'Hoạt động')", conn);
                insert.Parameters.AddWithValue("@ten", model.TenDangNhap);
                insert.Parameters.AddWithValue("@mk", model.MatKhau);
                insert.ExecuteNonQuery();

                // Sau khi tạo tài khoản -> nhập thông tin cá nhân
                return RedirectToAction("NhapThongTin", new { ten = model.TenDangNhap });
            }
        }

        // === NHẬP THÔNG TIN KHÁCH HÀNG SAU ĐĂNG KÝ ===
        [HttpGet]
        public ActionResult NhapThongTin(string ten)
        {
            var model = new KhachHangViewModel { TenDangNhap = ten };
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult NhapThongTin(KhachHangViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            string fileName = null;

            if (model.AnhFile != null && model.AnhFile.ContentLength > 0)
            {
                fileName = System.IO.Path.GetFileName(model.AnhFile.FileName);
                string path = Server.MapPath("~/Content/images/khachhang/" + fileName);
                model.AnhFile.SaveAs(path);
            }

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var countCmd = new SqlCommand("SELECT COUNT(*) FROM KhachHang", conn);
                int count = (int)countCmd.ExecuteScalar() + 1;
                string maKH = "KH" + count.ToString("D3");

                var insert = new SqlCommand(@"INSERT INTO KhachHang(MaKH, TenKH, DiaChi, Email, SDT, TenDangNhap, AnhDaiDien)
                                      VALUES(@MaKH, @TenKH, @DiaChi, @Email, @SDT, @TenDangNhap, @AnhDaiDien)", conn);
                insert.Parameters.AddWithValue("@MaKH", maKH);
                insert.Parameters.AddWithValue("@TenKH", model.TenKH);
                insert.Parameters.AddWithValue("@DiaChi", (object)model.DiaChi ?? DBNull.Value);
                insert.Parameters.AddWithValue("@Email", model.Email);
                insert.Parameters.AddWithValue("@SDT", model.SDT);
                insert.Parameters.AddWithValue("@TenDangNhap", model.TenDangNhap);
                insert.Parameters.AddWithValue("@AnhDaiDien", (object)("images/khachhang/" + fileName ?? ""));

                insert.ExecuteNonQuery();
            }

            TempData["Message"] = "Đăng ký thành công!";
            return RedirectToAction("Login");
        }

        // === ĐĂNG NHẬP ===
        [HttpGet]
        public ActionResult Login()
        {
            Session.Remove("TenDangNhap");
            Session.Remove("VaiTro");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Login(LoginViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var cmd = new SqlCommand("SELECT MatKhau, VaiTro, TrangThai FROM TaiKhoan WHERE TenDangNhap=@ten", conn);
                cmd.Parameters.AddWithValue("@ten", model.TenDangNhap);

                using (var r = cmd.ExecuteReader())
                {
                    if (!r.Read())
                    {
                        ModelState.AddModelError("", "Tên đăng nhập không tồn tại.");
                        return View(model);
                    }

                    string mkDB = r["MatKhau"].ToString();
                    string role = r["VaiTro"].ToString();
                    string trangThai = r["TrangThai"].ToString();

                    if (mkDB != model.MatKhau)
                    {
                        ModelState.AddModelError("", "Mật khẩu sai.");
                        return View(model);
                    }

                    if (trangThai == "Khóa")
                    {
                        ModelState.AddModelError("", "Tài khoản của bạn đã bị khóa.");
                        return View(model);
                    }

                    // Đăng nhập thành công
                    Session["TenDangNhap"] = model.TenDangNhap;
                    Session["VaiTro"] = role;

                    if (role == "KhachHang")
                    {
                        using (var conn2 = new SqlConnection(connStr))
                        {
                            conn2.Open();
                            var cmdKH = new SqlCommand(@"
                            SELECT TOP 1 MaKH, TenKH, DiaChi, Email, SDT, ISNULL(AnhDaiDien, '') AS AnhDaiDien 
                            FROM KhachHang 
                            WHERE TenDangNhap=@ten", conn2);
                            cmdKH.Parameters.AddWithValue("@ten", model.TenDangNhap);

                            using (var r2 = cmdKH.ExecuteReader())
                            {
                                if (r2.Read())
                                {
                                    var kh = new KhachHangViewModel
                                    {
                                        MaKH = r2["MaKH"].ToString(),
                                        TenDangNhap = model.TenDangNhap,
                                        TenKH = r2["TenKH"].ToString(),
                                        DiaChi = r2["DiaChi"].ToString(),
                                        Email = r2["Email"].ToString(),
                                        SDT = r2["SDT"].ToString(),
                                        AnhDaiDien = r2["AnhDaiDien"].ToString()
                                    };
                                    Session["KhachHang"] = kh;
                                }
                            }
                        }

                        return RedirectToAction("Index", "Home");
                    }
                    else
                    {
                        using (var conn2 = new SqlConnection(connStr))
                        {
                            conn2.Open();
                            var cmdNV = new SqlCommand(@"
                                SELECT TOP 1 MaNV, TenNV
                                FROM NhanVien
                                WHERE TenDangNhap=@ten", conn2);
                            cmdNV.Parameters.AddWithValue("@ten", model.TenDangNhap);

                            using (var r2 = cmdNV.ExecuteReader())
                            {
                                if (r2.Read())
                                {
                                    string maNV = r2["MaNV"].ToString();
                                    string tenNV = r2["TenNV"].ToString();

                                    Session["MaNV"] = maNV;
                                    Session["TenNV"] = tenNV; 
                                }
                            }
                        }

                        if (role == "Admin")
                            return RedirectToAction("Index", "Admin");
                        else
                            return RedirectToAction("Index", "TrangNV");
                    }

                }
            }
        }

        // === THÔNG TIN CÁ NHÂN ===
        [HttpGet]
        public ActionResult ThongTinCaNhan()
        {
            if (!IsKhachHang())
                return RedirectToAction("Login");

            var model = new KhachHangViewModel();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var cmd = new SqlCommand("SELECT TenKH, DiaChi, Email, SDT, AnhDaiDien FROM KhachHang WHERE TenDangNhap=@ten", conn);
                cmd.Parameters.AddWithValue("@ten", Session["TenDangNhap"].ToString());
                using (var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        model.TenKH = r["TenKH"].ToString();
                        model.DiaChi = r["DiaChi"].ToString();
                        model.Email = r["Email"].ToString();
                        model.SDT = r["SDT"].ToString();
                        model.AnhDaiDien = r["AnhDaiDien"].ToString();
                    }
                }
            }

            model.TenDangNhap = Session["TenDangNhap"].ToString();
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThongTinCaNhan(KhachHangViewModel model)
        {
            if (!IsKhachHang())
                return RedirectToAction("Login");

            string fileName = model.AnhDaiDien;

            if (model.AnhFile != null && model.AnhFile.ContentLength > 0)
            {
                fileName = System.IO.Path.GetFileName(model.AnhFile.FileName);
                string path = Server.MapPath("~/Content/images/khachhang/" + fileName);
                model.AnhFile.SaveAs(path);
                fileName = "images/khachhang/" + fileName;
            }

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var cmd = new SqlCommand(@"UPDATE KhachHang 
                                   SET TenKH=@TenKH, DiaChi=@DiaChi, Email=@Email, SDT=@SDT, AnhDaiDien=@AnhDaiDien
                                   WHERE TenDangNhap=@TenDangNhap", conn);
                cmd.Parameters.AddWithValue("@TenKH", model.TenKH);
                cmd.Parameters.AddWithValue("@DiaChi", (object)model.DiaChi ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@SDT", model.SDT);
                cmd.Parameters.AddWithValue("@AnhDaiDien", (object)fileName ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@TenDangNhap", Session["TenDangNhap"].ToString());
                cmd.ExecuteNonQuery();
            }

            TempData["Message"] = "Cập nhật thông tin thành công!";
            return RedirectToAction("ThongTinCaNhan");
        }

        // === ĐỔI MẬT KHẨU ===
        [HttpGet]
        public ActionResult DoiMatKhau()
        {
            if (!IsKhachHang())
                return RedirectToAction("Login");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DoiMatKhau(string MatKhauCu, string MatKhauMoi, string XacNhanMatKhau)
        {
            if (!IsKhachHang())
                return RedirectToAction("Login");

            if (MatKhauMoi != XacNhanMatKhau)
            {
                TempData["Error"] = "Mật khẩu xác nhận không khớp.";
                return RedirectToAction("DoiMatKhau");
            }

            string user = Session["TenDangNhap"].ToString();
            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var cmd = new SqlCommand("SELECT MatKhau FROM TaiKhoan WHERE TenDangNhap=@ten", conn);
                cmd.Parameters.AddWithValue("@ten", user);
                string mkHienTai = cmd.ExecuteScalar()?.ToString();

                if (mkHienTai != MatKhauCu)
                {
                    TempData["Error"] = "Mật khẩu hiện tại không đúng.";
                    return RedirectToAction("DoiMatKhau");
                }

                var update = new SqlCommand("UPDATE TaiKhoan SET MatKhau=@mkMoi WHERE TenDangNhap=@ten", conn);
                update.Parameters.AddWithValue("@mkMoi", MatKhauMoi);
                update.Parameters.AddWithValue("@ten", user);
                update.ExecuteNonQuery();
            }

            TempData["Message"] = "Đổi mật khẩu thành công!";
            return RedirectToAction("DoiMatKhau");
        }

        // === ĐĂNG XUẤT ===
        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Index", "Home");
        }

        // === CHỈ CHO PHÉP KHÁCH HÀNG ===
        private bool IsKhachHang()
        {
            return Session["VaiTro"] != null && Session["VaiTro"].ToString() == "KhachHang";
        }
    }
}
