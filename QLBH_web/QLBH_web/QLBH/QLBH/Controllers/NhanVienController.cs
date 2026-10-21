using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using QLBH.Models;

namespace QLBH.Controllers
{
    public class NhanVienController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // Danh sách nhân viên
        public ActionResult Index()
        {
            var dsNV = new List<NhanVien>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"
                    SELECT NV.MaNV, NV.TenNV, NV.ChucVu, NV.Email, NV.SDT,
                           NV.TenDangNhap, NV.AnhDaiDien, TK.TrangThai
                    FROM NhanVien NV
                    LEFT JOIN TaiKhoan TK ON NV.TenDangNhap = TK.TenDangNhap";

                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    dsNV.Add(new NhanVien
                    {
                        MaNV = reader["MaNV"].ToString(),
                        HoTen = reader["TenNV"].ToString(),
                        ChucVu = reader["ChucVu"].ToString(),
                        Email = reader["Email"].ToString(),
                        SoDienThoai = reader["SDT"].ToString(),
                        TenDangNhap = reader["TenDangNhap"].ToString(),
                        TrangThai = reader["TrangThai"]?.ToString() ?? "Hoạt động",
                        AnhDaiDien = reader["AnhDaiDien"] == DBNull.Value ? null : reader["AnhDaiDien"].ToString()
                    });
                }
            }

            return View(dsNV);
        }

        // Form thêm nhân viên
        [HttpGet]
        public ActionResult Create()
        {
            var taiKhoanRanh = new List<RegisterViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"
                    SELECT tk.TenDangNhap, tk.MatKhau
                    FROM TaiKhoan tk
                    WHERE tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM NhanVien WHERE TenDangNhap IS NOT NULL)
                      AND tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM KhachHang WHERE TenDangNhap IS NOT NULL)";

                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    taiKhoanRanh.Add(new RegisterViewModel
                    {
                        TenDangNhap = reader["TenDangNhap"].ToString(),
                        MatKhau = reader["MatKhau"].ToString()
                    });
                }
            }

            ViewBag.TaiKhoanRanh = taiKhoanRanh;
            return View();
        }

        // Xử lý thêm nhân viên (tự tạo tài khoản)
        [HttpPost]
        public ActionResult Create(NhanVien nv)
        {
            if (string.IsNullOrEmpty(nv.TenDangNhap))
            {
                ModelState.AddModelError("", "Vui lòng chọn tài khoản đăng nhập!");
                return View(nv);
            }

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"INSERT INTO NhanVien(MaNV, TenNV, ChucVu, Email, SDT, TenDangNhap, AnhDaiDien)
                       VALUES(@MaNV, @TenNV, @ChucVu, @Email, @SDT, @TenDangNhap, @AnhDaiDien)";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaNV", nv.MaNV);
                cmd.Parameters.AddWithValue("@TenNV", nv.HoTen);
                cmd.Parameters.AddWithValue("@ChucVu", nv.ChucVu ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@Email", nv.Email ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@SDT", nv.SoDienThoai ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("@TenDangNhap", nv.TenDangNhap);
                cmd.Parameters.AddWithValue("@AnhDaiDien", nv.AnhDaiDien ?? (object)DBNull.Value);

                conn.Open();
                cmd.ExecuteNonQuery();
            }

            return RedirectToAction("Index");
        }

        //Sửa nhân viên
        [HttpGet]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id))
                return HttpNotFound();

            NhanVien nv = null;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT * FROM NhanVien WHERE MaNV=@MaNV";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaNV", id.Trim());
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    nv = new NhanVien
                    {
                        MaNV = reader["MaNV"].ToString(),
                        HoTen = reader["TenNV"].ToString(),
                        ChucVu = reader["ChucVu"].ToString(),
                        Email = reader["Email"].ToString(),
                        SoDienThoai = reader["SDT"].ToString(),
                        TenDangNhap = reader["TenDangNhap"].ToString(),
                        AnhDaiDien = reader["AnhDaiDien"] == DBNull.Value ? null : reader["AnhDaiDien"].ToString()
                    };
                }
            }

            if (nv == null)
                return HttpNotFound();

            return View(nv);
        }

        // ✅ [POST] /NhanVien/Edit
        [HttpPost]
        public ActionResult Edit(NhanVien model)
        {
            if (!ModelState.IsValid)
                return View(model);

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"UPDATE NhanVien 
                               SET TenNV = @TenNV, ChucVu = @ChucVu, Email = @Email, SDT = @SDT, 
                                   TenDangNhap = @TenDangNhap, AnhDaiDien = @AnhDaiDien
                               WHERE MaNV = @MaNV";

                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaNV", model.MaNV);
                cmd.Parameters.AddWithValue("@TenNV", model.HoTen ?? "");
                cmd.Parameters.AddWithValue("@ChucVu", model.ChucVu ?? "");
                cmd.Parameters.AddWithValue("@Email", model.Email ?? "");
                cmd.Parameters.AddWithValue("@SDT", model.SoDienThoai ?? "");
                cmd.Parameters.AddWithValue("@TenDangNhap", model.TenDangNhap ?? "");
                cmd.Parameters.AddWithValue("@AnhDaiDien", model.AnhDaiDien ?? "");

                conn.Open();
                cmd.ExecuteNonQuery();
            }

            return RedirectToAction("Index");
        }

        // Xóa nhân viên
        [HttpPost]
        public ActionResult Delete(string id)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "DELETE FROM NhanVien WHERE MaNV=@MaNV";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaNV", id);
                cmd.ExecuteNonQuery();
            }

            TempData["Success"] = "Đã xóa nhân viên.";
            return RedirectToAction("Index");
        }
    }
}
