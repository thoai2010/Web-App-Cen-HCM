using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLNhaCungCapController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // 📋 Danh sách nhà cung cấp
        public ActionResult Index(string search)
        {
            List<NhaCungCap> ds = new List<NhaCungCap>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT * FROM NhaCungCap WHERE (@search IS NULL OR TenNCC LIKE '%' + @search + '%') ORDER BY MaNCC";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@search", (object)search ?? DBNull.Value);
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    ds.Add(new NhaCungCap
                    {
                        MaNCC = reader["MaNCC"].ToString(),
                        TenNCC = reader["TenNCC"].ToString(),
                        DiaChi = reader["DiaChi"].ToString(),
                        SDT = reader["SDT"].ToString(),
                    });
                }
            }

            ViewBag.Search = search;
            ViewBag.SuccessMessage = TempData["SuccessMessage"];
            ViewBag.ErrorMessage = TempData["ErrorMessage"];

            return View(ds);
        }


        // ➕ GET: Thêm
        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.NewMaNCC = GenerateMaNCC(); // Tạo mã tự động
            return View(new NhaCungCap());
        }

        // ➕ POST: Thêm
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(NhaCungCap ncc)
        {
            try
            {
                if (string.IsNullOrEmpty(ncc.MaNCC))
                    ncc.MaNCC = GenerateMaNCC();

                if (ModelState.IsValid)
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        string query = @"INSERT INTO NhaCungCap (MaNCC, TenNCC, DiaChi, SDT)
                                         VALUES (@MaNCC, @TenNCC, @DiaChi, @SDT)";
                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@MaNCC", ncc.MaNCC);
                        cmd.Parameters.AddWithValue("@TenNCC", ncc.TenNCC);
                        cmd.Parameters.AddWithValue("@DiaChi", (object)ncc.DiaChi ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@SDT", (object)ncc.SDT ?? DBNull.Value);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }

                    TempData["SuccessMessage"] = "✅ Thêm nhà cung cấp thành công!";
                    return RedirectToAction("Index");
                }

                TempData["ErrorMessage"] = "❌ Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.";
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "❌ Lỗi khi thêm: " + ex.Message;
            }

            // ⚠️ Gán lại mã khi view reload
            ViewBag.NewMaNCC = GenerateMaNCC();
            return View(ncc);
        }

        // ✏️ GET: Sửa
        [HttpGet]
        public ActionResult Edit(string id)
        {
            NhaCungCap ncc = null;
            id = id?.Trim();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT * FROM NhaCungCap WHERE MaNCC = @MaNCC";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@MaNCC", id);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    ncc = new NhaCungCap
                    {
                        MaNCC = reader["MaNCC"].ToString(),
                        TenNCC = reader["TenNCC"].ToString(),
                        DiaChi = reader["DiaChi"].ToString(),
                        SDT = reader["SDT"].ToString(),
                    };
                }
            }

            if (ncc == null) return HttpNotFound();
            return View(ncc);
        }

        // ✏️ POST: Sửa
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(NhaCungCap ncc)
        {
            if (ModelState.IsValid)
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string query = @"UPDATE NhaCungCap 
                                     SET TenNCC = @TenNCC, DiaChi = @DiaChi, SDT = @SDT
                                     WHERE MaNCC = @MaNCC";
                    SqlCommand cmd = new SqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@MaNCC", ncc.MaNCC);
                    cmd.Parameters.AddWithValue("@TenNCC", ncc.TenNCC);
                    cmd.Parameters.AddWithValue("@DiaChi", (object)ncc.DiaChi ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@SDT", (object)ncc.SDT ?? DBNull.Value);
                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["SuccessMessage"] = "✅ Cập nhật thành công!";
                return RedirectToAction("Index");
            }

            TempData["ErrorMessage"] = "❌ Có lỗi xảy ra. Vui lòng kiểm tra lại.";
            return View(ncc);
        }

        // 🔢 Sinh mã NCC tự động (NCC001, NCC002, ...)
        private string GenerateMaNCC()
        {
            string newMa = "NCC001";
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT TOP 1 MaNCC FROM NhaCungCap ORDER BY MaNCC DESC";
                SqlCommand cmd = new SqlCommand(query, conn);
                object result = cmd.ExecuteScalar();

                if (result != null)
                {
                    string lastCode = result.ToString();
                    if (lastCode.StartsWith("NCC"))
                    {
                        int number = int.Parse(lastCode.Substring(3));
                        newMa = "NCC" + (number + 1).ToString("D3");
                    }
                }
            }
            return newMa;
        }
    }
}
