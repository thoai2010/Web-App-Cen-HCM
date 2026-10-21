using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLTaiKhoanController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;


        // 🟢 Hiển thị danh sách và tìm kiếm
        public ActionResult Index(string search)
        {
            List<TaiKhoanViewModel> list = new List<TaiKhoanViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
                    SELECT TenDangNhap, MatKhau, VaiTro, TrangThai
                    FROM TaiKhoan
                    WHERE (@search IS NULL OR TenDangNhap LIKE '%' + @search + '%')
                    ORDER BY VaiTro, TenDangNhap";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@search", string.IsNullOrEmpty(search) ? (object)DBNull.Value : search);

                conn.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    list.Add(new TaiKhoanViewModel
                    {
                        TenDangNhap = dr["TenDangNhap"].ToString(),
                        MatKhau = dr["MatKhau"].ToString(),
                        VaiTro = dr["VaiTro"].ToString(),
                        TrangThai = dr["TrangThai"].ToString()
                    });
                }
                conn.Close();
            }

            return View(list);
        }

        // 🟡 Thay đổi vai trò (chỉ admin & nhân viên)
        [HttpPost]
        public ActionResult ChangeRole(string tenDangNhap, string vaiTro)
        {
            if (vaiTro == "KhachHang")
            {
                TempData["ErrorMessage"] = "Không thể thay đổi vai trò của khách hàng!";
                return RedirectToAction("Index");
            }

            string newRole = (vaiTro == "Admin") ? "NhanVien" : "Admin";

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "UPDATE TaiKhoan SET VaiTro = @newRole WHERE TenDangNhap = @TenDangNhap";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@newRole", newRole);
                cmd.Parameters.AddWithValue("@TenDangNhap", tenDangNhap);

                conn.Open();
                cmd.ExecuteNonQuery();
                conn.Close();
            }

            TempData["SuccessMessage"] = $"Đã đổi vai trò của {tenDangNhap} thành {newRole}.";
            return RedirectToAction("Index");
        }

        // 🔵 Thay đổi trạng thái
        [HttpPost]
        public ActionResult ChangeStatus(string tenDangNhap, string trangThai)
        {
            string newStatus = (trangThai == "Hoạt động") ? "Khóa" : "Hoạt động";

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "UPDATE TaiKhoan SET TrangThai = @TrangThai WHERE TenDangNhap = @TenDangNhap";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@TrangThai", newStatus);
                cmd.Parameters.AddWithValue("@TenDangNhap", tenDangNhap);

                conn.Open();
                cmd.ExecuteNonQuery();
                conn.Close();
            }

            TempData["SuccessMessage"] = $"Đã đổi trạng thái của {tenDangNhap} thành {newStatus}.";
            return RedirectToAction("Index");
        }

        // 🟣 Tạo tài khoản nhân viên mới
        [HttpGet]
        public ActionResult Create()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Create(TaiKhoanViewModel tk)
        {
            if (string.IsNullOrEmpty(tk.TenDangNhap) || string.IsNullOrEmpty(tk.MatKhau))
            {
                TempData["ErrorMessage"] = "Vui lòng nhập đủ thông tin!";
                return View(tk);
            }

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"INSERT INTO TaiKhoan (TenDangNhap, MatKhau, VaiTro, TrangThai)
                                 VALUES (@TenDangNhap, @MatKhau, N'NhanVien', N'Hoạt động')";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@TenDangNhap", tk.TenDangNhap);
                cmd.Parameters.AddWithValue("@MatKhau", tk.MatKhau);

                conn.Open();
                cmd.ExecuteNonQuery();
                conn.Close();
            }

            TempData["SuccessMessage"] = $"Đã tạo tài khoản nhân viên '{tk.TenDangNhap}'.";
            return RedirectToAction("Index");
        }
    }
}
