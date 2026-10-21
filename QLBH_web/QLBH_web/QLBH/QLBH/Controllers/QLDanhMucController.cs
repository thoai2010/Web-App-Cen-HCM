using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLDanhMucController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // ====================== 1️⃣ Danh sách + tìm kiếm
        public ActionResult Index(string search)
        {
            var list = new List<LoaiSanPham>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                var sql = "SELECT * FROM LoaiSanPham";
                if (!string.IsNullOrEmpty(search))
                    sql += " WHERE TenLoai LIKE @search";
                sql += " ORDER BY MaLoai"; // 🔹 Tự động sắp xếp theo Mã loại

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(search))
                        cmd.Parameters.AddWithValue("@search", "%" + search + "%");

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            list.Add(new LoaiSanPham
                            {
                                MaLoai = reader["MaLoai"].ToString().Trim(),
                                TenLoai = reader["TenLoai"].ToString(),
                                
                            });
                        }
                    }
                }
            }

            ViewBag.Search = search;
            return View(list);
        }


        // ====================== 2️⃣ Create GET
        public ActionResult Create()
        {
            var model = new LoaiSanPham
            {
                MaLoai = TaoMaLoaiTuDong()
            };
            return View(model);
        }

        // ====================== 3️⃣ Create POST
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(LoaiSanPham model)
        {
            if (ModelState.IsValid)
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = "INSERT INTO LoaiSanPham(MaLoai, TenLoai) VALUES(@MaLoai, @TenLoai)";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@MaLoai", model.MaLoai);
                    cmd.Parameters.AddWithValue("@TenLoai", model.TenLoai);
                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "Thêm loại sản phẩm thành công!";
                return RedirectToAction("Index");
            }

            TempData["Error"] = "Vui lòng kiểm tra lại thông tin nhập!";
            return View(model);
        }


        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id))
                return RedirectToAction("Index");

            LoaiSanPham loai = null;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "SELECT * FROM LoaiSanPham WHERE MaLoai=@MaLoai";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaLoai", id);

                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    loai = new LoaiSanPham
                    {
                        MaLoai = reader["MaLoai"].ToString().Trim(),
                        TenLoai = reader["TenLoai"].ToString()
                    };
                }
            }

            if (loai == null)
                return RedirectToAction("Index");

            return View(loai);
        }

        // 5️⃣ Sửa loại POST
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(LoaiSanPham model)
        {
            if (ModelState.IsValid)
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = "UPDATE LoaiSanPham SET TenLoai=@TenLoai WHERE MaLoai=@MaLoai";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@TenLoai", model.TenLoai);
                    cmd.Parameters.AddWithValue("@MaLoai", model.MaLoai);
                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "Cập nhật danh mục thành công!";
                return RedirectToAction("Index");
            }
            return View(model);
        }

        // ====================== 🔹 Hàm tự sinh mã LSP001, LSP002...
        private string TaoMaLoaiTuDong()
        {
            int nextId = 1;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "SELECT TOP 1 MaLoai FROM LoaiSanPham ORDER BY MaLoai DESC";
                SqlCommand cmd = new SqlCommand(sql, conn);
                var result = cmd.ExecuteScalar();

                if (result != null)
                {
                    string maCu = result.ToString().Trim();
                    if (maCu.StartsWith("LSP"))
                    {
                        int so = int.Parse(maCu.Substring(3));
                        nextId = so + 1;
                    }
                }
            }
            return "LSP" + nextId.ToString("D3");
        }
    }
}
