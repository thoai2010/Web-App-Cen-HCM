using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;
using QLBH.Models;

namespace QLBH.Controllers
{
    public class ThongKeController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        public ActionResult Index()
        {
            var model = new ThongKeViewModel();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // ✅ 1. Doanh thu = tổng SoTien của bảng HoaDon
                string sqlDoanhThu = @"
                    SELECT CAST(ISNULL(SUM(CAST(SoTien AS BIGINT)), 0) AS DECIMAL(18,2)) 
                    FROM HoaDon";
                using (SqlCommand cmd = new SqlCommand(sqlDoanhThu, conn))
                {
                    model.TongDoanhThu = Convert.ToDecimal(cmd.ExecuteScalar());
                }

                // ✅ 2. Công nợ = tổng TongTien của bảng PhieuNhapHang
                string sqlCongNo = @"
                    SELECT CAST(ISNULL(SUM(CAST(TongTien AS BIGINT)), 0) AS DECIMAL(18,2)) 
                    FROM PhieuNhapHang";
                using (SqlCommand cmd = new SqlCommand(sqlCongNo, conn))
                {
                    model.TongCongNo = Convert.ToDecimal(cmd.ExecuteScalar());
                }

                // ✅ 3. Số lượng hàng nhập = tổng SoLuong trong CT_PhieuNhapHang
                string sqlNhap = @"SELECT ISNULL(SUM(SoLuong), 0) FROM CT_PhieuNhapHang";
                using (SqlCommand cmd = new SqlCommand(sqlNhap, conn))
                {
                    model.SoLuongNhap = Convert.ToInt32(cmd.ExecuteScalar());
                }

                // ✅ 4. Số lượng tồn kho = tổng SLTon trong SanPham
                string sqlTonKho = @"SELECT ISNULL(SUM(SLTon), 0) FROM SanPham";
                using (SqlCommand cmd = new SqlCommand(sqlTonKho, conn))
                {
                    model.SoLuongTonKho = Convert.ToInt32(cmd.ExecuteScalar());
                }

                // ✅ 5. Tổng số sản phẩm
                string sqlSanPham = @"SELECT COUNT(*) FROM SanPham";
                using (SqlCommand cmd = new SqlCommand(sqlSanPham, conn))
                {
                    model.TongSanPham = Convert.ToInt32(cmd.ExecuteScalar());
                }

                // ✅ 6. Tổng số khách hàng
                string sqlKhachHang = @"SELECT COUNT(*) FROM KhachHang";
                using (SqlCommand cmd = new SqlCommand(sqlKhachHang, conn))
                {
                    model.TongKhachHang = Convert.ToInt32(cmd.ExecuteScalar());
                }

                // ✅ 7. Biểu đồ doanh thu & công nợ theo tháng
                string sqlChart = @"
                    SELECT 
                        MONTH(ISNULL(hd.NgayLap, pn.NgayNhap)) AS Thang,
                        CAST(ISNULL(SUM(CAST(hd.SoTien AS BIGINT)), 0) AS DECIMAL(18,2)) AS DoanhThu,
                        CAST(ISNULL(SUM(CAST(pn.TongTien AS BIGINT)), 0) AS DECIMAL(18,2)) AS CongNo
                    FROM HoaDon hd
                    FULL JOIN PhieuNhapHang pn 
                        ON MONTH(hd.NgayLap) = MONTH(pn.NgayNhap)
                    GROUP BY MONTH(ISNULL(hd.NgayLap, pn.NgayNhap))
                    ORDER BY Thang";

                using (SqlCommand cmd = new SqlCommand(sqlChart, conn))
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    model.Thang = new List<string>();
                    model.DoanhThuThang = new List<decimal>();
                    model.CongNoThang = new List<decimal>();

                    while (reader.Read())
                    {
                        model.Thang.Add(reader["Thang"].ToString());
                        model.DoanhThuThang.Add(Convert.ToDecimal(reader["DoanhThu"]));
                        model.CongNoThang.Add(Convert.ToDecimal(reader["CongNo"]));
                    }
                }
                // 🔹 Lấy tỷ lệ sản phẩm theo loại (cho biểu đồ tròn)
                string sqlTyLe = @"
                    SELECT LSP.TenLoai, COUNT(SP.MaSP) AS SoLuong
                    FROM SanPham SP
                    INNER JOIN LoaiSanPham LSP ON SP.MaLoai = LSP.MaLoai
                    GROUP BY LSP.TenLoai";

                using (SqlCommand cmd = new SqlCommand(sqlTyLe, conn))
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    List<string> tenLoai = new List<string>();
                    List<int> soLuong = new List<int>();

                    while (reader.Read())
                    {
                        tenLoai.Add(reader["TenLoai"].ToString());
                        soLuong.Add(Convert.ToInt32(reader["SoLuong"]));
                    }

                    ViewBag.TenLoaiSP = tenLoai;
                    ViewBag.SoLuongTheoLoai = soLuong;
                }

            }
            return View(model);
        }
    }
}