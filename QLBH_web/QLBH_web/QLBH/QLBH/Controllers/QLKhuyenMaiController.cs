using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLKhuyenMaiController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // 📄 Hiển thị danh sách khuyến mãi
        public ActionResult Index()
        {
            List<KhuyenMai> ds = new List<KhuyenMai>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT * FROM KhuyenMai ORDER BY MaKM";
                SqlCommand cmd = new SqlCommand(query, conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    ds.Add(new KhuyenMai
                    {
                        MaKM = reader["MaKM"].ToString(),
                        TenCT = reader["TenCT"].ToString(),
                        MoTa = reader["MoTa"].ToString(),
                        NgayBD = Convert.ToDateTime(reader["NgayBD"]),
                        NgayKT = Convert.ToDateTime(reader["NgayKT"]),
                        DieuKien = reader["DieuKien"].ToString()
                    });
                }
            }
            return View(ds);
        }

        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.NewMaKM = GenerateMaKM();
            return View(new KhuyenMai());
        }

        // ➕ Thêm mới khuyến mãi (POST)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(KhuyenMai km)
        {
            // Giữ lại mã hiện có
            if (string.IsNullOrEmpty(km.MaKM))
                km.MaKM = GenerateMaKM();

            // Ràng buộc ngày
            if (km.NgayKT < km.NgayBD)
                ModelState.AddModelError("NgayKT", "❌ Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu");

            if (ModelState.IsValid)
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        string query = @"INSERT INTO KhuyenMai (MaKM, TenCT, MoTa, NgayBD, NgayKT, DieuKien)
                                         VALUES (@MaKM, @TenCT, @MoTa, @NgayBD, @NgayKT, @DieuKien)";
                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@MaKM", km.MaKM);
                        cmd.Parameters.AddWithValue("@TenCT", km.TenCT);
                        cmd.Parameters.AddWithValue("@MoTa", (object)km.MoTa ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@NgayBD", km.NgayBD);
                        cmd.Parameters.AddWithValue("@NgayKT", km.NgayKT);
                        cmd.Parameters.AddWithValue("@DieuKien", (object)km.DieuKien ?? DBNull.Value);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                    TempData["SuccessMessage"] = "✅ Thêm khuyến mãi thành công!";
                    return RedirectToAction("Index");
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = "Lỗi khi thêm: " + ex.Message;
                }
            }

            // Nếu lỗi: giữ mã lại, không mất
            ViewBag.NewMaKM = km.MaKM;
            TempData["ErrorMessage"] = "❌ Vui lòng kiểm tra lại thông tin nhập.";
            return View(km);
        }

        // 🔢 Sinh mã tự động
        private string GenerateMaKM()
        {
            string newMa = "KM001";
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT TOP 1 MaKM FROM KhuyenMai ORDER BY MaKM DESC";
                SqlCommand cmd = new SqlCommand(query, conn);
                var result = cmd.ExecuteScalar();
                if (result != null)
                {
                    string last = result.ToString();
                    if (last.StartsWith("KM") && int.TryParse(last.Substring(2), out int num))
                        newMa = "KM" + (num + 1).ToString("D3");
                }
            }
            return newMa;
        }


        // 📄 Sửa
        public ActionResult Edit(string id)
        {
            KhuyenMai km = null;
            id = id?.Trim();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT * FROM KhuyenMai WHERE MaKM = @MaKM";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@MaKM", id);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    km = new KhuyenMai
                    {
                        MaKM = reader["MaKM"].ToString(),
                        TenCT = reader["TenCT"].ToString(),
                        MoTa = reader["MoTa"].ToString(),
                        NgayBD = Convert.ToDateTime(reader["NgayBD"]),
                        NgayKT = Convert.ToDateTime(reader["NgayKT"]),
                        DieuKien = reader["DieuKien"].ToString()
                    };
                }
            }
            if (km == null) return HttpNotFound();
            return View(km);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(KhuyenMai km)
        {
            // Ràng buộc ngày
            if (km.NgayKT < km.NgayBD)
                ModelState.AddModelError("NgayKT", "❌ Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu");

            if (ModelState.IsValid)
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        string query = @"UPDATE KhuyenMai 
                                 SET TenCT = @TenCT, MoTa = @MoTa, NgayBD = @NgayBD, NgayKT = @NgayKT, DieuKien = @DieuKien
                                 WHERE MaKM = @MaKM";
                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@MaKM", km.MaKM);
                        cmd.Parameters.AddWithValue("@TenCT", km.TenCT);
                        cmd.Parameters.AddWithValue("@MoTa", (object)km.MoTa ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@NgayBD", km.NgayBD);
                        cmd.Parameters.AddWithValue("@NgayKT", km.NgayKT);
                        cmd.Parameters.AddWithValue("@DieuKien", (object)km.DieuKien ?? DBNull.Value);

                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                    TempData["SuccessMessage"] = "✅ Cập nhật khuyến mãi thành công!";
                    return RedirectToAction("Index");
                }
                catch (Exception ex)
                {
                    TempData["ErrorMessage"] = "Lỗi khi cập nhật: " + ex.Message;
                }
            }
            else
            {
                TempData["ErrorMessage"] = "❌ Vui lòng kiểm tra lại thông tin nhập!";
            }

            return View(km);
        }



    }
}
