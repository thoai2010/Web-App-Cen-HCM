using QLBH.Models;
using System;
using System.Web.Mvc;
using System.Data.SqlClient;
using System.Configuration;

namespace QLBH.Controllers
{
    public class TrangNVController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // Kiểm tra đăng nhập nhân viên
        private bool IsNhanVien()
        {
            return string.Equals(Session["VaiTro"]?.ToString(), "NhanVien", StringComparison.OrdinalIgnoreCase);
        }
        [OutputCache(NoStore = true, Duration = 0, VaryByParam = "*")]
        public ActionResult Index()
        {
            if (!IsNhanVien())
                return RedirectToAction("Login", "Account");

            // Lấy MaNV hoặc TenDangNhap từ session
            string maNV = Session["MaNV"]?.ToString();
            if (string.IsNullOrEmpty(maNV))
                return RedirectToAction("Login", "Account");

            NhanVien nv = GetNhanVien(maNV);
            return View(nv);
        }

        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Login", "Account");
        }

        // Lấy thông tin nhân viên từ DB
        private NhanVien GetNhanVien(string maNV)
        {
            NhanVien nv = null;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                    SELECT MaNV, TenNV, ChucVu, Email, SDT, TenDangNhap, AnhDaiDien 
                    FROM NhanVien 
                    WHERE MaNV=@MaNV";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaNV", maNV);
                    using (SqlDataReader rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            nv = new NhanVien
                            {
                                MaNV = rd["MaNV"].ToString(),
                                HoTen = rd["TenNV"].ToString(),
                                ChucVu = rd["ChucVu"].ToString(),
                                Email = rd["Email"].ToString(),
                                SoDienThoai = rd["SDT"].ToString(),
                                TenDangNhap = rd["TenDangNhap"].ToString(),
                                AnhDaiDien = rd["AnhDaiDien"]?.ToString()
                            };
                        }
                    }
                }
            }
            return nv;
        }
    }
}
