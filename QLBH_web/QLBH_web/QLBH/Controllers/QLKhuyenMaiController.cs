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

        // ============================
        // 📌 Hiển thị danh sách khuyến mãi
        // ============================
        public ActionResult Index(string search)
        {
            List<KhuyenMai> ds = new List<KhuyenMai>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
            SELECT MaKM, TenCT, MoTa, NgayBD, NgayKT, LoaiKM
            FROM KhuyenMai
            WHERE (@search IS NULL
                   OR MaKM LIKE '%' + @search + '%'
                   OR TenCT LIKE N'%' + @search + '%')
            ORDER BY MaKM DESC";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@search",
                    string.IsNullOrWhiteSpace(search) ? (object)DBNull.Value : search.Trim());

                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    ds.Add(new KhuyenMai
                    {
                        MaKM = reader["MaKM"].ToString(),
                        TenCT = reader["TenCT"].ToString(),
                        MoTa = reader["MoTa"] == DBNull.Value ? "" : reader["MoTa"].ToString(),
                        NgayBD = Convert.ToDateTime(reader["NgayBD"]),
                        NgayKT = Convert.ToDateTime(reader["NgayKT"]),
                        LoaiKM = reader["LoaiKM"].ToString()
                    });
                }
            }

            ViewBag.Search = search;
            return View(ds);
        }


        // ============================
        // 📌 Form thêm mới
        // ============================
        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.NewMaKM = GenerateMaKM();
            return View(new KhuyenMai());
        }

        // ============================
        // ➕ Thêm mới khuyến mãi (POST)
        // ============================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(KhuyenMai km)
        {
            if (string.IsNullOrEmpty(km.MaKM))
                km.MaKM = GenerateMaKM();

            if (km.NgayKT < km.NgayBD)
                ModelState.AddModelError("NgayKT", "❌ Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu");

            if (ModelState.IsValid)
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        string query = @"INSERT INTO KhuyenMai (MaKM, TenCT, MoTa, NgayBD, NgayKT, LoaiKM)
                                         VALUES (@MaKM, @TenCT, @MoTa, @NgayBD, @NgayKT, @LoaiKM)";

                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@MaKM", km.MaKM);
                        cmd.Parameters.AddWithValue("@TenCT", km.TenCT);
                        cmd.Parameters.AddWithValue("@MoTa", (object)km.MoTa ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@NgayBD", km.NgayBD);
                        cmd.Parameters.AddWithValue("@NgayKT", km.NgayKT);
                        cmd.Parameters.AddWithValue("@LoaiKM", km.LoaiKM);

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

            ViewBag.NewMaKM = km.MaKM;
            TempData["ErrorMessage"] = "❌ Vui lòng kiểm tra lại thông tin nhập.";
            return View(km);
        }

        // ============================
        // ✏️ Form sửa
        // ============================
        public ActionResult Edit(string id)
        {
            if (id == null) return HttpNotFound();

            KhuyenMai km = null;
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
                        LoaiKM = reader["LoaiKM"].ToString()
                    };
                }
            }

            if (km == null) return HttpNotFound();
            return View(km);
        }

        // ============================
        // ✏️ Cập nhật khuyến mãi (POST)
        // ============================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(KhuyenMai km)
        {
            if (km.NgayKT < km.NgayBD)
                ModelState.AddModelError("NgayKT", "❌ Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu");

            if (ModelState.IsValid)
            {
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        string query = @"UPDATE KhuyenMai 
                                         SET TenCT = @TenCT, MoTa = @MoTa, NgayBD = @NgayBD, NgayKT = @NgayKT, LoaiKM = @LoaiKM
                                         WHERE MaKM = @MaKM";

                        SqlCommand cmd = new SqlCommand(query, conn);
                        cmd.Parameters.AddWithValue("@MaKM", km.MaKM);
                        cmd.Parameters.AddWithValue("@TenCT", km.TenCT);
                        cmd.Parameters.AddWithValue("@MoTa", (object)km.MoTa ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@NgayBD", km.NgayBD);
                        cmd.Parameters.AddWithValue("@NgayKT", km.NgayKT);
                        cmd.Parameters.AddWithValue("@LoaiKM", km.LoaiKM);

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

            TempData["ErrorMessage"] = "❌ Vui lòng kiểm tra thông tin nhập!";
            return View(km);
        }

        // ============================
        // 🔢 Tự sinh mã KM
        // ============================
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
    }
}
