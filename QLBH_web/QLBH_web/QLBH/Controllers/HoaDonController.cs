using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class HoaDonController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // ======================
        // Danh sách hóa đơn
        // ======================
        public ActionResult Index(string search)
        {
            List<HoaDon> list = new List<HoaDon>();

            using (SqlConnection con = new SqlConnection(connStr))
            {
                string query = @"
                    SELECT 
                        hd.MaHD,
                        hd.NgayLap,
                        hd.SoTien,
                        dh.PhuongThucThanhToan,
                        kh.TenKH
                    FROM HoaDon hd
                    JOIN DonHang dh ON hd.MaDH = dh.MaDH
                    JOIN KhachHang kh ON dh.MaKH = kh.MaKH
                    WHERE (@search IS NULL OR 
                           hd.MaHD LIKE @pattern OR 
                           kh.TenKH LIKE @pattern)";

                SqlCommand cmd = new SqlCommand(query, con);
                string pattern = string.IsNullOrEmpty(search) ? null : "%" + search + "%";

                cmd.Parameters.AddWithValue("@search", (object)search ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@pattern", (object)pattern ?? DBNull.Value);

                con.Open();
                SqlDataReader rd = cmd.ExecuteReader();

                while (rd.Read())
                {
                    list.Add(new HoaDon
                    {
                        MaHD = rd["MaHD"].ToString(),

                        NgayLap = rd["NgayLap"] != DBNull.Value
                            ? Convert.ToDateTime(rd["NgayLap"])
                            : (DateTime?)null,

                        SoTien = rd["SoTien"] != DBNull.Value
                            ? Convert.ToInt32(rd["SoTien"])
                            : 0,
                        
                        PhuongThucThanhToan = rd["PhuongThucThanhToan"] != DBNull.Value
                            ? rd["PhuongThucThanhToan"].ToString()
                            : "",
                        
                        TenKH = rd["TenKH"] != DBNull.Value
                            ? rd["TenKH"].ToString()
                            : ""
                    });
                }
            }

            ViewBag.Search = search;
            return View(list);
        }

        // ======================
        // Chi tiết hóa đơn
        // ======================
        public ActionResult Details(string id)
        {
            if (string.IsNullOrEmpty(id))
                return HttpNotFound();

            HoaDon hoaDon = null;
            id = id.Trim();

            using (SqlConnection con = new SqlConnection(connStr))
            {
                // Lấy thông tin hóa đơn + khách hàng
                string query = @"
                    SELECT 
                        hd.MaHD,
                        hd.NgayLap,
                        hd.SoTien,
                        dh.PhuongThucThanhToan,
                        kh.TenKH
                    FROM HoaDon hd
                    JOIN DonHang dh ON hd.MaDH = dh.MaDH
                    JOIN KhachHang kh ON dh.MaKH = kh.MaKH
                    WHERE hd.MaHD = @id";

                SqlCommand cmd = new SqlCommand(query, con);
                cmd.Parameters.AddWithValue("@id", id);

                con.Open();
                SqlDataReader rd = cmd.ExecuteReader();

                if (rd.Read())
                {
                    hoaDon = new HoaDon
                    {
                        MaHD = rd["MaHD"].ToString(),

                        NgayLap = rd["NgayLap"] != DBNull.Value
                            ? Convert.ToDateTime(rd["NgayLap"])
                            : (DateTime?)null,

                        SoTien = rd["SoTien"] != DBNull.Value
                            ? Convert.ToInt32(rd["SoTien"])
                            : 0,

                        PhuongThucThanhToan = rd["PhuongThucThanhToan"] != DBNull.Value
                            ? rd["PhuongThucThanhToan"].ToString()
                            : "",

                        TenKH = rd["TenKH"] != DBNull.Value
                            ? rd["TenKH"].ToString()
                            : "",

                        ChiTietSP = new List<ChiTietSPViewModel>()
                    };
                }
                rd.Close();

                if (hoaDon != null)
                {
                    // Lấy chi tiết sản phẩm
                    string ctQuery = @"
                        SELECT sp.TenSP, ctdh.SoLuong, ctdh.DonGia
                        FROM CT_DonHang_SP ctdh
                        JOIN DonHang dh ON ctdh.MaDH = dh.MaDH
                        JOIN SanPham sp ON ctdh.MaSP = sp.MaSP
                        WHERE dh.MaDH = (
                            SELECT MaDH FROM HoaDon WHERE MaHD = @id
                        )";

                    SqlCommand ctCmd = new SqlCommand(ctQuery, con);
                    ctCmd.Parameters.AddWithValue("@id", id);

                    SqlDataReader ctReader = ctCmd.ExecuteReader();

                    while (ctReader.Read())
                    {
                        hoaDon.ChiTietSP.Add(new ChiTietSPViewModel
                        {
                            TenSP = ctReader["TenSP"].ToString(),

                            SoLuong = ctReader["SoLuong"] != DBNull.Value
                                ? Convert.ToInt32(ctReader["SoLuong"])
                                : 0,

                            DonGia = ctReader["DonGia"] != DBNull.Value
                                ? Convert.ToInt32(ctReader["DonGia"])
                                : 0
                        });
                    }

                    ctReader.Close();
                }
            }

            if (hoaDon == null)
                return HttpNotFound();

            return View(hoaDon);
        }
    }
}
