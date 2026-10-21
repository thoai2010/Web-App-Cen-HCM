using QLBH.Models;
using QLBH.Utils;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;
namespace QLBH.Controllers
{
    public class AccountController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;
        // ĐĂNG KÝ (Chỉ KHÁCH HÀNG)
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
                var checkCmd = new SqlCommand("SELECT COUNT(*) FROM TaiKhoan WHERE TenDangNhap=@ten", conn);
                checkCmd.Parameters.AddWithValue("@ten", model.TenDangNhap);
                if ((int)checkCmd.ExecuteScalar() > 0)
                {
                    ModelState.AddModelError("", "Tên đăng nhập đã tồn tại.");
                    return View(model);
                }

                var insert = new SqlCommand("INSERT INTO TaiKhoan(TenDangNhap, MatKhau, VaiTro) VALUES(@ten, @mk, N'KhachHang')", conn);
                insert.Parameters.AddWithValue("@ten", model.TenDangNhap);
                insert.Parameters.AddWithValue("@mk", model.MatKhau);
                insert.ExecuteNonQuery();
                return RedirectToAction("NhapThongTin", new { ten = model.TenDangNhap });
            }
        }

        // NHẬP THÔNG TIN KHÁCH HÀNG
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

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var checkCmd = new SqlCommand("SELECT COUNT(*) FROM KhachHang WHERE Email = @Email", conn);
                checkCmd.Parameters.AddWithValue("@Email", model.Email);
                int existing = (int)checkCmd.ExecuteScalar();

                if (existing > 0)
                {
                    ModelState.AddModelError("Email", "Email này đã được sử dụng, vui lòng chọn email khác.");
                    return View(model);
                }
                var cmdCount = new SqlCommand("SELECT COUNT(*) FROM KhachHang", conn);
                int count = (int)cmdCount.ExecuteScalar() + 1;
                string maKH = "KH" + count.ToString("D3");

                var cmd = new SqlCommand(@"INSERT INTO KhachHang(MaKH, TenKH, DiaChi, Email, SDT, TenDangNhap)
VALUES(@MaKH, @TenKH, @DiaChi, @Email, @SDT, @TenDangNhap)", conn);
                cmd.Parameters.AddWithValue("@MaKH", maKH);
                cmd.Parameters.AddWithValue("@TenKH", model.TenKH);
                cmd.Parameters.AddWithValue("@DiaChi", (object)model.DiaChi ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@SDT", model.SDT);
                cmd.Parameters.AddWithValue("@TenDangNhap", model.TenDangNhap);
                cmd.ExecuteNonQuery();
            }

            TempData["Message"] = "Đăng ký thành công, vui lòng đăng nhập!";
            return RedirectToAction("Login", "Account");
        }


        // ĐĂNG NHẬP
        public ActionResult Login()
        {
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
                var cmd = new SqlCommand("SELECT MatKhau, VaiTro FROM TaiKhoan WHERE TenDangNhap=@ten", conn);
                cmd.Parameters.AddWithValue("@ten", model.TenDangNhap);
                using (var r = cmd.ExecuteReader())
                {
                    if (!r.Read())
                    {
                        ModelState.AddModelError("", "Tên đăng nhập không tồn tại");
                        return View(model);
                    }

                    var mkDB = r.GetString(0);
                    var role = r.GetString(1);
                    if (model.MatKhau != mkDB)
                    {
                        ModelState.AddModelError("", "Mật khẩu sai");
                        return View(model);
                    }
                    Session["TenDangNhap"] = model.TenDangNhap;
                    Session["VaiTro"] = role;
                    if (role == "Admin") return RedirectToAction("Index", "Admin");
                    if (role == "NhanVien") return RedirectToAction("Index", "NhanVien");
                    return RedirectToAction("Index", "Home");
                }
            }
        }
        // ĐĂNG XUẤT
        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Index", "Home");
        }
    }
}