using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web;
using System.Web.Mvc;
using System.IO;

namespace QLBH.Controllers
{
    public class QLNhanVienController : Controller
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
            // Tạo mã nhân viên tự động
            string newMaNV = "NV01";

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT TOP 1 MaNV FROM NhanVien ORDER BY MaNV DESC";
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                var result = cmd.ExecuteScalar();

                if (result != null)
                {
                    string lastId = result.ToString().Replace("NV", "");
                    int number = int.Parse(lastId) + 1;
                    newMaNV = "NV" + number.ToString("00");
                }
            }

            ViewBag.NewMaNV = newMaNV;

            // Lấy tài khoản rảnh
            var taiKhoanRanh = new List<RegisterViewModel>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"
            SELECT tk.TenDangNhap, tk.MatKhau, tk.TrangThai
            FROM TaiKhoan tk
            WHERE tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM NhanVien)
              AND tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM KhachHang)";
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                var reader = cmd.ExecuteReader();
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
        public ActionResult Create(NhanVien nv, HttpPostedFileBase AnhDaiDien)
        {
            try
            {
                if (!ModelState.IsValid)
                    return View(nv);

                string fileName = null;

                if (AnhDaiDien != null && AnhDaiDien.ContentLength > 0)
                {
                    fileName = Path.GetFileName(AnhDaiDien.FileName);
                    string path = Path.Combine(Server.MapPath("~/Content/images/nhanvien"), fileName);
                    AnhDaiDien.SaveAs(path);
                }

                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    var cmd = new SqlCommand(@"
                INSERT INTO NhanVien
                (MaNV, TenNV, ChucVu, Email, SDT, AnhDaiDien, TenDangNhap)
                VALUES
                (@MaNV, @TenNV, @ChucVu, @Email, @SDT, @AnhDaiDien, @TenDangNhap)
            ", conn);

                    cmd.Parameters.AddWithValue("@MaNV", nv.MaNV);
                    cmd.Parameters.AddWithValue("@TenNV", nv.HoTen);
                    cmd.Parameters.AddWithValue("@ChucVu", nv.ChucVu ?? "");
                    cmd.Parameters.AddWithValue("@Email", nv.Email ?? "");
                    cmd.Parameters.AddWithValue("@SDT", nv.SoDienThoai ?? "");
                    cmd.Parameters.AddWithValue("@AnhDaiDien", (object)fileName ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@TenDangNhap", nv.TenDangNhap);

                    cmd.ExecuteNonQuery();
                }

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                // ✅ Bắt lỗi và đẩy về View
                ViewBag.Error = "Lỗi khi thêm nhân viên: " + ex.Message;

                // Load lại danh sách tài khoản rảnh (nếu không View sẽ lỗi)
                var taiKhoanRanh = new List<RegisterViewModel>();
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = @"
                SELECT tk.TenDangNhap, tk.MatKhau, tk.TrangThai
                FROM TaiKhoan tk
                WHERE tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM NhanVien)
                  AND tk.TenDangNhap NOT IN (SELECT TenDangNhap FROM KhachHang)";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    conn.Open();
                    var reader = cmd.ExecuteReader();
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

                return View(nv); 
            }
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


        // [POST] /NhanVien/Edit
        [HttpPost]
        public ActionResult Edit(NhanVien model, HttpPostedFileBase AnhDaiDien)
        {
            try
            {
                if (!ModelState.IsValid)
                    return View(model);

                string fileName = model.AnhDaiDien; // giữ ảnh cũ nếu không upload ảnh mới

                // Nếu có upload ảnh mới
                if (AnhDaiDien != null && AnhDaiDien.ContentLength > 0)
                {
                    fileName = Path.GetFileName(AnhDaiDien.FileName);
                    string path = Path.Combine(Server.MapPath("~/Content/images/nhanvien"), fileName);
                    AnhDaiDien.SaveAs(path);
                }

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = @"UPDATE NhanVien 
                           SET TenNV = @TenNV,
                               ChucVu = @ChucVu,
                               Email = @Email,
                               SDT = @SDT, 
                               TenDangNhap = @TenDangNhap,
                               AnhDaiDien = @AnhDaiDien
                           WHERE MaNV = @MaNV";

                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@MaNV", model.MaNV);
                    cmd.Parameters.AddWithValue("@TenNV", model.HoTen ?? "");
                    cmd.Parameters.AddWithValue("@ChucVu", model.ChucVu ?? "");
                    cmd.Parameters.AddWithValue("@Email", model.Email ?? "");
                    cmd.Parameters.AddWithValue("@SDT", model.SoDienThoai ?? "");
                    cmd.Parameters.AddWithValue("@TenDangNhap", model.TenDangNhap ?? "");
                    cmd.Parameters.AddWithValue("@AnhDaiDien", (object)fileName ?? DBNull.Value);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                // ✅ BẮT LỖI – KHÔNG VĂNG RA NGOÀI
                ViewBag.Error = "Lỗi khi cập nhật nhân viên: " + ex.Message;
                return View(model); // quay lại view và hiển thị lỗi
            }
        }
    }
}
