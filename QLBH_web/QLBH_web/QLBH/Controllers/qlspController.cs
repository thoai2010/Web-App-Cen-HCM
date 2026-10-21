using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Web;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class qlspController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // =================== INDEX ===================
        public ActionResult Index(string search)
        {
            var dsSP = new List<SanPham>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = @"
            SELECT SP.MaSP, SP.TenSP, SP.MoTa, SP.DonViTinh, 
                   SP.GiaBan, SP.SLTon, SP.Hinh,
                   SP.MaLoai, LSP.TenLoai
            FROM SanPham SP
            LEFT JOIN LoaiSanPham LSP ON SP.MaLoai = LSP.MaLoai
            WHERE (@search IS NULL
                   OR SP.TenSP LIKE N'%' + @search + '%'
                   OR SP.MaSP LIKE '%' + @search + '%')
            ORDER BY SP.MaSP";

                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@search",
                    string.IsNullOrWhiteSpace(search) ? (object)DBNull.Value : search.Trim());

                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    dsSP.Add(new SanPham
                    {
                        MaSP = reader["MaSP"].ToString(),
                        TenSP = reader["TenSP"].ToString(),
                        MoTa = reader["MoTa"]?.ToString(),
                        DonViTinh = reader["DonViTinh"]?.ToString(),
                        GiaBan = reader["GiaBan"] != DBNull.Value ? Convert.ToInt32(reader["GiaBan"]) : 0,
                        SLTon = reader["SLTon"] != DBNull.Value ? Convert.ToInt32(reader["SLTon"]) : 0,
                        Hinh = reader["Hinh"]?.ToString(),
                        MaLoai = reader["MaLoai"]?.ToString(),
                        TenLoai = reader["TenLoai"]?.ToString()
                    });
                }
            }

            return View(dsSP);
        }

        // =================== CREATE ===================
        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.LoaiSP = GetLoaiSP();

            string newMaSP = "SP001";
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT TOP 1 MaSP FROM SanPham ORDER BY MaSP DESC";
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                var result = cmd.ExecuteScalar();
                if (result != null)
                {
                    string lastMa = result.ToString(); 
                    int number = int.Parse(lastMa.Substring(2)) + 1;
                    newMaSP = "SP" + number.ToString("D3"); 
                }
            }

            var sp = new SanPham();
            sp.MaSP = newMaSP;
            return View(sp);
        }

        [HttpPost]
        public ActionResult Create(SanPham sp, HttpPostedFileBase HinhAnh)
        {
            try
            {
                if (HinhAnh != null && HinhAnh.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnh.FileName);
                    var path = Server.MapPath("~/Content/images/sanpham/" + fileName);
                    HinhAnh.SaveAs(path);
                    sp.Hinh = fileName;
                }

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = @"INSERT INTO SanPham(MaSP, TenSP, MoTa, DonViTinh, GiaBan, SLTon, Hinh, MaLoai)
                           VALUES(@MaSP, @TenSP, @MoTa, @DonViTinh, @GiaBan, @SLTon, @Hinh, @MaLoai)";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@MaSP", sp.MaSP);
                    cmd.Parameters.AddWithValue("@TenSP", sp.TenSP ?? "");
                    cmd.Parameters.AddWithValue("@MoTa", sp.MoTa ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@DonViTinh", sp.DonViTinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@GiaBan", sp.GiaBan);
                    cmd.Parameters.AddWithValue("@SLTon", sp.SLTon);
                    cmd.Parameters.AddWithValue("@Hinh", sp.Hinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@MaLoai", sp.MaLoai ?? (object)DBNull.Value);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "Thêm sản phẩm thành công!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi: " + ex.Message;
                ViewBag.LoaiSP = GetLoaiSP(sp.MaLoai);
                return View(sp);
            }
        }


        // =================== EDIT ===================
        [HttpGet]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id)) return HttpNotFound();

            SanPham sp = null;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT * FROM SanPham WHERE MaSP=@MaSP";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaSP", id.Trim());
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    sp = new SanPham
                    {
                        MaSP = reader["MaSP"].ToString(),
                        TenSP = reader["TenSP"].ToString(),
                        MoTa = reader["MoTa"]?.ToString(),
                        DonViTinh = reader["DonViTinh"]?.ToString(),
                        GiaBan = reader["GiaBan"] != DBNull.Value ? Convert.ToInt32(reader["GiaBan"]) : 0,
                        SLTon = reader["SLTon"] != DBNull.Value ? Convert.ToInt32(reader["SLTon"]) : 0,
                        Hinh = reader["Hinh"]?.ToString(),
                        MaLoai = reader["MaLoai"]?.ToString()
                    };
                }
            }

            if (sp == null) return HttpNotFound();

            ViewBag.LoaiSP = GetLoaiSP(sp.MaLoai);
            return View(sp);
        }

        [HttpPost]
        public ActionResult Edit(SanPham sp, HttpPostedFileBase HinhAnh)
        {
            try
            {
                // Nếu có upload ảnh mới thì lưu và ghi đè tên ảnh
                if (HinhAnh != null && HinhAnh.ContentLength > 0)
                {
                    var fileName = Path.GetFileName(HinhAnh.FileName);
                    var path = Server.MapPath("~/Content/images/sanpham/" + fileName);
                    HinhAnh.SaveAs(path);
                    sp.Hinh = fileName;
                }
                // else: KHÔNG làm gì cả, vì sp.Hinh đã có từ HiddenFor

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = @"UPDATE SanPham
                           SET TenSP=@TenSP, MoTa=@MoTa, DonViTinh=@DonViTinh, GiaBan=@GiaBan, SLTon=@SLTon,
                               Hinh=@Hinh, MaLoai=@MaLoai
                           WHERE MaSP=@MaSP";

                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@MaSP", sp.MaSP);
                    cmd.Parameters.AddWithValue("@TenSP", sp.TenSP ?? "");
                    cmd.Parameters.AddWithValue("@MoTa", sp.MoTa ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@DonViTinh", sp.DonViTinh ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@GiaBan", sp.GiaBan);
                    cmd.Parameters.AddWithValue("@SLTon", sp.SLTon);
                    cmd.Parameters.AddWithValue("@Hinh", string.IsNullOrEmpty(sp.Hinh) ? (object)DBNull.Value : sp.Hinh);
                    cmd.Parameters.AddWithValue("@MaLoai", sp.MaLoai ?? (object)DBNull.Value);

                    conn.Open();
                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "Cập nhật sản phẩm thành công!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi: " + ex.Message;
                ViewBag.LoaiSP = GetLoaiSP(sp.MaLoai);
                return View(sp);
            }
        }


        // =================== DELETE ===================
        [HttpPost]
        public ActionResult Delete(string id)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "DELETE FROM SanPham WHERE MaSP=@MaSP";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@MaSP", id);
                cmd.ExecuteNonQuery();
            }

            TempData["Success"] = "Đã xóa sản phẩm.";
            return RedirectToAction("Index");
        }

        // =================== COMBO BOX ===================
        private List<SelectListItem> GetLoaiSP(string selectedMaLoai = null)
        {
            var list = new List<SelectListItem>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT MaLoai, TenLoai FROM LoaiSanPham";
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new SelectListItem
                    {
                        Value = reader["MaLoai"].ToString(),
                        Text = reader["TenLoai"].ToString(),
                        Selected = reader["MaLoai"].ToString() == selectedMaLoai
                    });
                }
            }
            return list;
        }


        private string GenerateMaSP()
        {
            string maMoi = "SP001";

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sql = "SELECT TOP 1 MaSP FROM SanPham ORDER BY MaSP DESC";
                SqlCommand cmd = new SqlCommand(sql, conn);
                conn.Open();
                var result = cmd.ExecuteScalar();
                if (result != null)
                {
                    string lastMa = result.ToString(); 
                    int number = 0;
                    if (int.TryParse(lastMa.Substring(2), out number))
                    {
                        number++; 
                        maMoi = "SP" + number.ToString("D3"); 
                    }
                }
            }

            return maMoi;
        }

    }
}
