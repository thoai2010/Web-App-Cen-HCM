using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLNhapHangController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // GET: Danh sách phiếu nhập
        public ActionResult Index()
        {
            List<NhapHangViewModel> list = new List<NhapHangViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
                    SELECT 
                        PNH.MaPNH, PNH.NgayNhap, PNH.TongTien,
                        NV.TenNV, NCC.TenNCC,
                        SP.TenSP, CTPNH.SoLuong, CTPNH.DonGia
                    FROM dbo.PhieuNhapHang PNH
                    JOIN dbo.NhanVien NV ON PNH.MaNV = NV.MaNV
                    JOIN dbo.NhaCungCap NCC ON PNH.MaNCC = NCC.MaNCC
                    JOIN dbo.CT_PhieuNhapHang CTPNH ON PNH.MaPNH = CTPNH.MaPNH
                    JOIN dbo.SanPham SP ON CTPNH.MaSP = SP.MaSP
                    ORDER BY PNH.MaPNH DESC";

                SqlCommand cmd = new SqlCommand(query, conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    list.Add(new NhapHangViewModel
                    {
                        MaPNH = reader["MaPNH"].ToString(),
                        NgayNhap = Convert.ToDateTime(reader["NgayNhap"]),
                        TenNV = reader["TenNV"].ToString(),
                        TenNCC = reader["TenNCC"].ToString(),
                        TenSP = reader["TenSP"].ToString(),
                        SoLuong = Convert.ToInt32(reader["SoLuong"]),
                        DonGia = Convert.ToInt32(reader["DonGia"]),
                        TongTien = Convert.ToInt32(reader["TongTien"])
                    });
                }
            }

            return View(list);
        }

        // GET: Hiển thị form tạo phiếu nhập
        public ActionResult Create()
        {
            string newMaPNH = GenerateMaPNH();
            ViewBag.NewMaPNH = newMaPNH;

            // Lấy thông tin nhân viên từ session
            if (Session["MaNV"] != null && Session["TenNV"] != null)
            {
                ViewBag.MaNV = Session["MaNV"].ToString();
                ViewBag.TenNV = Session["TenNV"].ToString();
            }
            return View();
        }

        private string GenerateMaPNH()
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT TOP 1 MaPNH FROM PhieuNhapHang ORDER BY MaPNH DESC";
                SqlCommand cmd = new SqlCommand(query, conn);
                object result = cmd.ExecuteScalar();

                if (result != null)
                {
                    string lastMa = result.ToString();
                    int num = int.Parse(lastMa.Substring(3));
                    return "PNH" + (num + 1).ToString("D3");
                }
                else
                {
                    return "PNH001";
                }
            }
        }

        // POST: Lưu phiếu nhập mới
        [HttpPost]
        public ActionResult Create(
    string MaPNH,
    string MaNV,
    string MaNCC,
    List<string> MaSP,
    List<int> SoLuong,
    List<int> DonGia)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                SqlTransaction tran = conn.BeginTransaction();

                try
                {
                    // Gộp các sản phẩm trùng nhau
                    var grouped = new Dictionary<string, (int SoLuong, int DonGia)>();

                    for (int i = 0; i < MaSP.Count; i++)
                    {
                        if (string.IsNullOrWhiteSpace(MaSP[i])) continue;

                        if (SoLuong[i] <= 0)
                            throw new Exception("Số lượng nhập phải lớn hơn 0!");

                        if (DonGia[i] < 0)
                            throw new Exception("Đơn giá không được âm!");

                        if (grouped.ContainsKey(MaSP[i]))
                        {
                            grouped[MaSP[i]] =
                                (grouped[MaSP[i]].SoLuong + SoLuong[i], DonGia[i]);
                        }
                        else
                        {
                            grouped.Add(MaSP[i], (SoLuong[i], DonGia[i]));
                        }
                    }

                    if (grouped.Count == 0)
                        throw new Exception("Phiếu nhập phải có ít nhất 1 sản phẩm!");

                    // Tính tổng tiền
                    int tongTien = grouped.Sum(x => x.Value.SoLuong * x.Value.DonGia);

                    // Insert Phiếu Nhập
                    string queryPNH = @"
                INSERT INTO PhieuNhapHang
                (MaPNH, MaNV, MaNCC, NgayNhap, TongTien)
                VALUES
                (@MaPNH, @MaNV, @MaNCC, GETDATE(), @TongTien)";

                    SqlCommand cmdPNH = new SqlCommand(queryPNH, conn, tran);
                    cmdPNH.Parameters.AddWithValue("@MaPNH", MaPNH);
                    cmdPNH.Parameters.AddWithValue("@MaNV", MaNV);
                    cmdPNH.Parameters.AddWithValue("@MaNCC", MaNCC);
                    cmdPNH.Parameters.AddWithValue("@TongTien", tongTien);
                    cmdPNH.ExecuteNonQuery();

                    // Insert Chi tiết Phiếu Nhập
                    foreach (var item in grouped)
                    {
                        string queryCT = @"
                    INSERT INTO CT_PhieuNhapHang
                    (MaPNH, MaSP, SoLuong, DonGia)
                    VALUES
                    (@MaPNH, @MaSP, @SoLuong, @DonGia)";

                        SqlCommand cmdCT = new SqlCommand(queryCT, conn, tran);
                        cmdCT.Parameters.AddWithValue("@MaPNH", MaPNH);
                        cmdCT.Parameters.AddWithValue("@MaSP", item.Key);
                        cmdCT.Parameters.AddWithValue("@SoLuong", item.Value.SoLuong);
                        cmdCT.Parameters.AddWithValue("@DonGia", item.Value.DonGia);
                        cmdCT.ExecuteNonQuery();

                    }

                    tran.Commit();
                    TempData["SuccessMessage"] = "✅ Tạo phiếu nhập hàng thành công!";
                    return RedirectToAction("Index");
                }
                catch (Exception ex)
                {
                    tran.Rollback();
                    TempData["ErrorMessage"] = "❌ " + ex.Message;
                    return RedirectToAction("Create");
                }
            }
        }


        // API: Gợi ý NCC
        public JsonResult GetNCC(string term)
        {
            var list = new List<object>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT MaNCC, TenNCC FROM NhaCungCap WHERE TenNCC LIKE @term";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@term", "%" + term + "%");
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new
                    {
                        label = reader["TenNCC"].ToString(),
                        value = reader["MaNCC"].ToString()
                    });
                }
            }
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        // API: Gợi ý sản phẩm
        public JsonResult GetSanPham(string term)
        {
            var list = new List<object>();
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = "SELECT MaSP, TenSP FROM SanPham WHERE TenSP LIKE @term";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@term", "%" + term + "%");
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new
                    {
                        label = reader["TenSP"].ToString(),
                        value = reader["MaSP"].ToString()
                    });
                }
            }
            return Json(list, JsonRequestBehavior.AllowGet);
        }
    }
}
