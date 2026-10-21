using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class ChiTietKM_SPController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // ✅ Danh sách
        public ActionResult Index(string search)
        {
            var list = new List<ChiTietKM_SP>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
                    SELECT c.MaKM, c.MaSP, c.TriGia, c.LoaiTriGia, 
                           k.TenCT, s.TenSP
                    FROM ChiTietKM_SP c
                    JOIN KhuyenMai k ON c.MaKM = k.MaKM
                    JOIN SanPham s ON c.MaSP = s.MaSP
                    WHERE (@search IS NULL 
                        OR k.TenCT LIKE '%' + @search + '%' 
                        OR s.TenSP LIKE '%' + @search + '%')
                    ORDER BY k.TenCT, s.TenSP";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@search", (object)search ?? DBNull.Value);

                conn.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    list.Add(new ChiTietKM_SP
                    {
                        MaKM = dr["MaKM"].ToString(),
                        MaSP = dr["MaSP"].ToString(),
                        TenCT = dr["TenCT"].ToString(),
                        TenSP = dr["TenSP"].ToString(),
                        TriGia = Convert.ToDecimal(dr["TriGia"]),
                        LoaiTriGia = dr["LoaiTriGia"].ToString()
                    });
                }
                conn.Close();
            }

            // ✅ Truyền lại từ khóa tìm kiếm để giữ trong ô input
            ViewBag.Search = search;

            return View(list);
        }

        // ✅ Thêm mới
        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.SanPhams = GetSanPhams();
            ViewBag.KhuyenMais = GetKhuyenMais();
            return View();
        }

        [HttpPost]
        public ActionResult Create(ChiTietKM_SP model)
        {
            if (ModelState.IsValid)
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string query = @"INSERT INTO ChiTietKM_SP (MaKM, MaSP, TriGia, LoaiTriGia)
                                     VALUES (@MaKM, @MaSP, @TriGia, @LoaiTriGia)";
                    SqlCommand cmd = new SqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@MaKM", model.MaKM);
                    cmd.Parameters.AddWithValue("@MaSP", model.MaSP);
                    cmd.Parameters.AddWithValue("@TriGia", model.TriGia);
                    cmd.Parameters.AddWithValue("@LoaiTriGia", model.LoaiTriGia);
                    conn.Open();
                    cmd.ExecuteNonQuery();
                    conn.Close();
                }

                TempData["SuccessMessage"] = "Thêm khuyến mãi cho sản phẩm thành công!";
                return RedirectToAction("Index");
            }

            ViewBag.SanPhams = GetSanPhams();
            ViewBag.KhuyenMais = GetKhuyenMais();
            return View(model);
        }

        // ✅ Xóa
        public ActionResult Delete(string maKM, string maSP)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "DELETE FROM ChiTietKM_SP WHERE MaKM = @MaKM AND MaSP = @MaSP";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@MaKM", maKM);
                cmd.Parameters.AddWithValue("@MaSP", maSP);
                conn.Open();
                cmd.ExecuteNonQuery();
                conn.Close();
            }
            TempData["SuccessMessage"] = "Xóa thành công!";
            return RedirectToAction("Index");
        }

        // ===== Helper: danh sách sản phẩm & khuyến mãi =====
        private List<SanPham> GetSanPhams()
        {
            var list = new List<SanPham>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT MaSP, TenSP FROM SanPham";
                SqlCommand cmd = new SqlCommand(query, conn);
                conn.Open();
                var dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    list.Add(new SanPham
                    {
                        MaSP = dr["MaSP"].ToString(),
                        TenSP = dr["TenSP"].ToString()
                    });
                }
                conn.Close();
            }
            return list;
        }

        private List<KhuyenMai> GetKhuyenMais()
        {
            var list = new List<KhuyenMai>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT MaKM, TenCT FROM KhuyenMai";
                SqlCommand cmd = new SqlCommand(query, conn);
                conn.Open();
                var dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    list.Add(new KhuyenMai
                    {
                        MaKM = dr["MaKM"].ToString(),
                        TenCT = dr["TenCT"].ToString()
                    });
                }
                conn.Close();
            }
            return list;
        }
    }
}
