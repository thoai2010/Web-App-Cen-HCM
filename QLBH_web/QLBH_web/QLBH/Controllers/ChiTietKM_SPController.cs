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

        // ============================
        // DANH SÁCH
        // ============================
        public ActionResult Index(string search)
        {
            var list = new List<ChiTietKM_SP>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
                    SELECT c.MaKM, c.MaSP, c.TriGia, c.SoLuongToiThieu,
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
                        SoLuongToiThieu = Convert.ToInt32(dr["SoLuongToiThieu"])
                    });
                }
            }

            ViewBag.Search = search;
            return View(list);
        }

        // ============================
        // TẠO MỚI
        // ============================
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
                    string query = @"
                        INSERT INTO ChiTietKM_SP (MaKM, MaSP, TriGia, SoLuongToiThieu)
                        VALUES (@MaKM, @MaSP, @TriGia, @SoLuongToiThieu)";

                    SqlCommand cmd = new SqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@MaKM", model.MaKM);
                    cmd.Parameters.AddWithValue("@MaSP", model.MaSP);
                    cmd.Parameters.AddWithValue("@TriGia", model.TriGia);
                    cmd.Parameters.AddWithValue("@SoLuongToiThieu", model.SoLuongToiThieu);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["SuccessMessage"] = "Thêm khuyến mãi cho sản phẩm thành công!";
                return RedirectToAction("Index");
            }

            ViewBag.SanPhams = GetSanPhams();
            ViewBag.KhuyenMais = GetKhuyenMais();
            return View(model);
        }

        // ============================
        // XÓA
        // ============================
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
            }

            TempData["SuccessMessage"] = "Xóa thành công!";
            return RedirectToAction("Index");
        }

        // ============================
        // HELPER GET DATA
        // ============================
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
            }

            return list;
        }
    }
}
