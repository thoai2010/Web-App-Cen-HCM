using QLBH.Models;
using QLBH.Models.ViewModels;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLDonHangController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;


        // =====================================================
        // 0. LIST ĐƠN HÀNG
        // =====================================================
        public ActionResult Index()
        {
            var list = new List<DonHangViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"
                SELECT DH.MaDH, DH.NgayDat, DH.TrangThai, DH.TongTien,
                       KH.MaKH, KH.TenKH
                FROM DonHang DH
                JOIN KhachHang KH ON DH.MaKH = KH.MaKH";

                conn.Open();
                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader rd = cmd.ExecuteReader();

                while (rd.Read())
                {
                    list.Add(new DonHangViewModel
                    {
                        MaDH = rd["MaDH"].ToString(),
                        NgayDat = Convert.ToDateTime(rd["NgayDat"]),
                        TrangThai = rd["TrangThai"].ToString(),
                        TongTien = Convert.ToInt32(rd["TongTien"]),
                        MaKH = rd["MaKH"].ToString(),
                        HoTen = rd["TenKH"].ToString(),
                        ChiTiet = new List<ChiTietDonHang>()
                    });
                }
                rd.Close();

                // LOAD CHI TIẾT
                foreach (var dh in list)
                {
                    string queryCT = @"
                    SELECT SP.MaSP, SP.TenSP, CT.SoLuong, CT.DonGia
                    FROM CT_DonHang_SP CT
                    JOIN SanPham SP ON CT.MaSP = SP.MaSP
                    WHERE CT.MaDH = @MaDH";

                    SqlCommand cmdCT = new SqlCommand(queryCT, conn);
                    cmdCT.Parameters.AddWithValue("@MaDH", dh.MaDH);
                    SqlDataReader rdCT = cmdCT.ExecuteReader();

                    while (rdCT.Read())
                    {
                        dh.ChiTiet.Add(new ChiTietDonHang
                        {
                            MaSP = rdCT["MaSP"].ToString(),
                            TenSP = rdCT["TenSP"].ToString(),
                            SoLuong = Convert.ToInt32(rdCT["SoLuong"]),
                            DonGia = Convert.ToInt32(rdCT["DonGia"])
                        });
                    }
                    rdCT.Close();
                }
            }

            return View(list);
        }



        // =====================================================
        // 1. DANH SÁCH YÊU CẦU HOÀN TRẢ
        // =====================================================
        public ActionResult YeuCauHoanTra()
        {
            List<PhieuXuLyViewModel> list = new List<PhieuXuLyViewModel>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = @"
                SELECT px.MaPX, px.MaDH, px.LoaiXuLy, px.LyDo, px.GhiChu,
                       px.TrangThaiPX, px.NgayLap,
                       kh.TenKH, kh.SDT, kh.DiaChi
                FROM PhieuXuLyDH px
                INNER JOIN DonHang dh ON px.MaDH = dh.MaDH
                INNER JOIN KhachHang kh ON dh.MaKH = kh.MaKH
                WHERE px.LoaiXuLy = N'HoanTien'
                ORDER BY px.NgayLap DESC";

                using (var cmd = new SqlCommand(sql, conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        list.Add(new PhieuXuLyViewModel
                        {
                            MaPX = r["MaPX"].ToString(),
                            MaDH = r["MaDH"].ToString(),
                            LoaiXuLy = r["LoaiXuLy"].ToString(),
                            LyDo = r["LyDo"].ToString(),
                            GhiChu = r["GhiChu"].ToString(),
                            TrangThaiPX = r["TrangThaiPX"].ToString(),
                            NgayLap = Convert.ToDateTime(r["NgayLap"]),

                            TenKhachHang = r["TenKH"].ToString(),
                            SoDienThoai = r["SDT"].ToString(),
                            DiaChi = r["DiaChi"].ToString(),

                            ChiTiet = new List<CTPhieuXuLyVM>()
                        });
                    }
                }

                // TẢI CHI TIẾT PHIẾU
                foreach (var px in list)
                {
                    string sqlCT = @"
                    SELECT ct.MaSP,
                           sp.TenSP AS TenSanPham,
                           ct.SoLuong,
                           ct.DonGia
                    FROM CT_PhieuXuLy ct
                    INNER JOIN SanPham sp ON ct.MaSP = sp.MaSP
                    WHERE ct.MaPX = @MaPX";

                    using (var cmd = new SqlCommand(sqlCT, conn))
                    {
                        cmd.Parameters.AddWithValue("@MaPX", px.MaPX);

                        using (var rd = cmd.ExecuteReader())
                        {
                            while (rd.Read())
                            {
                                px.ChiTiet.Add(new CTPhieuXuLyVM
                                {
                                    MaSP = rd["MaSP"].ToString(),
                                    TenSanPham = rd["TenSanPham"].ToString(),
                                    SoLuong = Convert.ToInt32(rd["SoLuong"]),
                                    DonGia = Convert.ToInt32(rd["DonGia"])
                                });
                            }
                        }
                    }
                }
            }

            return View(list);
        }



        // =====================================================
        // 2. DUYỆT HOÀN TRẢ
        // =====================================================
        [HttpPost]
        public JsonResult DuyetHoanTra(string maPX, string maDH)
        {
            if (string.IsNullOrEmpty(maPX) || string.IsNullOrEmpty(maDH))
                return Json(new { success = false, message = "Thiếu dữ liệu!" });

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Đơn hàng → ĐÃ HỦY
                    new SqlCommand(
                        "UPDATE DonHang SET TrangThai = N'Đã hủy' WHERE MaDH = @MaDH",
                        conn
                    )
                    { Parameters = { new SqlParameter("@MaDH", maDH) } }
                    .ExecuteNonQuery();

                    // Xóa hóa đơn gốc
                    new SqlCommand(
                        "DELETE FROM HoaDon WHERE MaDH = @MaDH",
                        conn
                    )
                    { Parameters = { new SqlParameter("@MaDH", maDH) } }
                    .ExecuteNonQuery();

                    // Phiếu → ĐÃ DUYỆT
                    new SqlCommand(
                        "UPDATE PhieuXuLyDH SET TrangThaiPX = N'DaDuyet' WHERE MaPX = @MaPX",
                        conn
                    )
                    { Parameters = { new SqlParameter("@MaPX", maPX) } }
                    .ExecuteNonQuery();
                }

                return Json(new { success = true, message = "Duyệt hoàn trả thành công!" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // =====================================================
        // 3. TỪ CHỐI HOÀN TRẢ
        // =====================================================
        [HttpPost]
        public JsonResult TuChoiHoanTra(string maPX, string maDH)
        {
            if (string.IsNullOrEmpty(maPX) || string.IsNullOrEmpty(maDH))
                return Json(new { success = false, message = "Thiếu dữ liệu!" });

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Đơn hàng giữ nguyên → Hoàn thành
                    new SqlCommand(
                        "UPDATE DonHang SET TrangThai = N'Hoàn thành' WHERE MaDH = @MaDH",
                        conn
                    )
                    { Parameters = { new SqlParameter("@MaDH", maDH) } }
                    .ExecuteNonQuery();

                    // Phiếu → TỪ CHỐI
                    new SqlCommand(
                        "UPDATE PhieuXuLyDH SET TrangThaiPX = N'TuChoi' WHERE MaPX = @MaPX",
                        conn
                    )
                    { Parameters = { new SqlParameter("@MaPX", maPX) } }
                    .ExecuteNonQuery();
                }

                return Json(new { success = true, message = "Đã từ chối hoàn trả!" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        // =====================================================
        // 4. CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (CHUNG)
        // =====================================================
        [HttpPost]
        public JsonResult UpdateTrangThai(string maDH, string trangThai)
        {
            if (string.IsNullOrEmpty(maDH) || string.IsNullOrEmpty(trangThai))
                return Json(new { success = false, message = "Thiếu dữ liệu đầu vào!" });

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    string sql = @"
                UPDATE DonHang
                SET TrangThai = @TrangThai
                WHERE MaDH = @MaDH";

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("@MaDH", System.Data.SqlDbType.Char, 10)
                                      .Value = maDH;

                        cmd.Parameters.Add("@TrangThai", System.Data.SqlDbType.NVarChar, 50)
                                      .Value = trangThai;

                        int rows = cmd.ExecuteNonQuery();

                        if (rows == 0)
                        {
                            return Json(new
                            {
                                success = false,
                                message = "Không tìm thấy đơn hàng để cập nhật!"
                            });
                        }
                    }
                }

                return Json(new
                {
                    success = true,
                    message = "Đã cập nhật trạng thái đơn hàng!"
                });
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    success = false,
                    message = ex.Message
                });
            }
        }
    }
}
