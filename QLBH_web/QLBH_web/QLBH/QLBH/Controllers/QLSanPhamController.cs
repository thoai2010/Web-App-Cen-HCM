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
    public class QLSanPhamController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // ======================
        // 1️⃣ Danh sách sản phẩm
        // ======================
        public ActionResult Index()
        {
            List<SanPham> sanPhams = new List<SanPham>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = @"
                    SELECT sp.MaSP, sp.TenSP, sp.GiaBan, sp.SLTon, sp.Hinh,
                           lsp.TenLoai, ncc.TenNCC
                    FROM SanPham sp
                    JOIN LoaiSanPham lsp ON sp.MaLoai = lsp.MaLoai
                    JOIN NhaCungCap ncc ON sp.MaNCC = ncc.MaNCC";

                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    SanPham sp = new SanPham
                    {
                        MaSP = reader["MaSP"].ToString(),
                        TenSP = reader["TenSP"].ToString(),
                        GiaBan = Convert.ToInt32(reader["GiaBan"]),
                        SLTon = Convert.ToInt32(reader["SLTon"]),
                        Hinh = reader["Hinh"] != DBNull.Value ? reader["Hinh"].ToString() : "",
                        TenLoai = reader["TenLoai"].ToString(),
                        TenNCC = reader["TenNCC"].ToString()
                    };
                    sanPhams.Add(sp);
                }
            }

            return View(sanPhams);
        }

        // ======================
        // 2️⃣ GET: Hiển thị form thêm
        // ======================
        [HttpGet]
        public ActionResult Create()
        {
            ViewBag.LoaiList = LayDanhSachLoai();
            ViewBag.NCCList = LayDanhSachNCC();
            return View();
        }

        // ======================
        // 3️⃣ POST: Thêm sản phẩm mới
        // ======================
        [HttpPost]
        public ActionResult Create(SanPham sp, HttpPostedFileBase HinhAnh)
        {
            try
            {
                string filePath = null;

                // Nếu người dùng chọn ảnh
                if (HinhAnh != null && HinhAnh.ContentLength > 0)
                {
                    string fileName = Path.GetFileName(HinhAnh.FileName);
                    string folderPath = Server.MapPath("~/Images/SanPham");

                    if (!Directory.Exists(folderPath))
                        Directory.CreateDirectory(folderPath);

                    filePath = Path.Combine(folderPath, fileName);
                    HinhAnh.SaveAs(filePath);

                    // Lưu đường dẫn tương đối để hiển thị trong View
                    sp.Hinh = "~/Images/SanPham/" + fileName;
                }

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // ✅ Tạo mã sản phẩm tự động (VD: SP001, SP002, ...)
                    string newMaSP = TaoMaSPMoi(conn);

                    string query = @"
                INSERT INTO SanPham (MaSP, TenSP, GiaBan, SLTon, MaLoai, MaNCC, Hinh)
                VALUES (@MaSP, @TenSP, @GiaBan, @SLTon, @MaLoai, @MaNCC, @Hinh)";

                    SqlCommand cmd = new SqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@MaSP", newMaSP);
                    cmd.Parameters.AddWithValue("@TenSP", sp.TenSP);
                    cmd.Parameters.AddWithValue("@GiaBan", sp.GiaBan);
                    cmd.Parameters.AddWithValue("@SLTon", sp.SLTon);
                    cmd.Parameters.AddWithValue("@MaLoai", sp.MaLoai);
                    cmd.Parameters.AddWithValue("@MaNCC", sp.MaNCC);
                    cmd.Parameters.AddWithValue("@Hinh", (object)sp.Hinh ?? DBNull.Value);

                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "✅ Thêm sản phẩm thành công!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = "❌ Lỗi khi thêm sản phẩm: " + ex.Message;
                ViewBag.LoaiList = LayDanhSachLoai();
                ViewBag.NCCList = LayDanhSachNCC();
                return View(sp);
            }
        }


        // ======================
        // 🔹 Hàm phụ: Lấy danh sách loại
        // ======================
        private IEnumerable<SelectListItem> LayDanhSachLoai()
        {
            List<SelectListItem> list = new List<SelectListItem>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT MaLoai, TenLoai FROM LoaiSanPham";
                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    list.Add(new SelectListItem
                    {
                        Value = reader["MaLoai"].ToString(),
                        Text = reader["TenLoai"].ToString()
                    });
                }
            }

            return list;
        }

        // ======================
        // 🔹 Hàm phụ: Lấy danh sách NCC
        // ======================
        private IEnumerable<SelectListItem> LayDanhSachNCC()
        {
            List<SelectListItem> list = new List<SelectListItem>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT MaNCC, TenNCC FROM NhaCungCap";
                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    list.Add(new SelectListItem
                    {
                        Value = reader["MaNCC"].ToString(),
                        Text = reader["TenNCC"].ToString()
                    });
                }
            }

            return list;
        }
        private string TaoMaSPMoi(SqlConnection conn)
        {
            string query = "SELECT TOP 1 MaSP FROM SanPham ORDER BY MaSP DESC";
            SqlCommand cmd = new SqlCommand(query, conn);
            object result = cmd.ExecuteScalar();

            if (result == null)
                return "SP001";

            string lastMa = result.ToString();   // VD: "SP007"
            int number = int.Parse(lastMa.Substring(2)); // => 7
            number++; // => 8
            return "SP" + number.ToString("D3"); // => "SP008"
        }

        [HttpGet]
        public ActionResult Edit(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                TempData["Error"] = "❌ Không tìm thấy mã sản phẩm cần sửa.";
                return RedirectToAction("Index");
            }

            id = id.Trim(); // ✅ Loại bỏ khoảng trắng thừa

            SanPham sp = null;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT * FROM SanPham WHERE MaSP = @MaSP";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@MaSP", id);

                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    sp = new SanPham
                    {
                        MaSP = reader["MaSP"].ToString().Trim(),
                        TenSP = reader["TenSP"].ToString(),
                        GiaBan = Convert.ToInt32(reader["GiaBan"]),
                        SLTon = Convert.ToInt32(reader["SLTon"]),
                        MaLoai = reader["MaLoai"].ToString(),
                        MaNCC = reader["MaNCC"].ToString(),
                        Hinh = reader["Hinh"] != DBNull.Value ? reader["Hinh"].ToString() : ""
                    };
                }
            }

            if (sp == null)
            {
                TempData["Error"] = "❌ Không tìm thấy sản phẩm.";
                return RedirectToAction("Index");
            }

            ViewBag.LoaiList = LayDanhSachLoai();
            ViewBag.NCCList = LayDanhSachNCC();

            return View(sp);
        }

        [HttpPost]
        public ActionResult Edit(SanPham sp, HttpPostedFileBase HinhAnh)
        {
            try
            {
                // Xử lý hình ảnh mới (nếu có)
                if (HinhAnh != null && HinhAnh.ContentLength > 0)
                {
                    string fileName = Path.GetFileName(HinhAnh.FileName);
                    string folderPath = Server.MapPath("~/Images/SanPham");
                    if (!Directory.Exists(folderPath))
                        Directory.CreateDirectory(folderPath);
                    string filePath = Path.Combine(folderPath, fileName);
                    HinhAnh.SaveAs(filePath);
                    sp.Hinh = "~/Images/SanPham/" + fileName;
                }

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string query = @"
                UPDATE SanPham
                SET TenSP = @TenSP, GiaBan = @GiaBan, SLTon = @SLTon,
                    MaLoai = @MaLoai, MaNCC = @MaNCC, Hinh = @Hinh
                WHERE MaSP = @MaSP";

                    SqlCommand cmd = new SqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@TenSP", sp.TenSP);
                    cmd.Parameters.AddWithValue("@GiaBan", sp.GiaBan);
                    cmd.Parameters.AddWithValue("@SLTon", sp.SLTon);
                    cmd.Parameters.AddWithValue("@MaLoai", sp.MaLoai);
                    cmd.Parameters.AddWithValue("@MaNCC", sp.MaNCC);
                    cmd.Parameters.AddWithValue("@Hinh", (object)sp.Hinh ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@MaSP", sp.MaSP);

                    cmd.ExecuteNonQuery();
                }

                TempData["Success"] = "✅ Cập nhật sản phẩm thành công!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                TempData["Error"] = "❌ Lỗi khi cập nhật sản phẩm: " + ex.Message;
                ViewBag.LoaiList = LayDanhSachLoai();
                ViewBag.NCCList = LayDanhSachNCC();
                return View(sp);
            }
        }


    }
}
