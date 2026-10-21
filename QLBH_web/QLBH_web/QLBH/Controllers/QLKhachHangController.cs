using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class QLKhachHangController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        // GET: Danh sách khách hàng
        public ActionResult Index(string search)
        {
            List<KhachHangViewModel> khachHangList = new List<KhachHangViewModel>();

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string query = @"SELECT KH.MaKH, KH.TenKH, KH.DiaChi, KH.Email, KH.SDT, KH.AnhDaiDien,
                                        TK.TenDangNhap, TK.VaiTro, TK.TrangThai
                                 FROM KhachHang KH
                                 JOIN TaiKhoan TK ON KH.TenDangNhap = TK.TenDangNhap";

                if (!string.IsNullOrEmpty(search))
                {
                    query += " WHERE KH.TenKH LIKE @Search";
                }

                SqlCommand cmd = new SqlCommand(query, conn);

                if (!string.IsNullOrEmpty(search))
                {
                    cmd.Parameters.AddWithValue("@Search", "%" + search + "%");
                }

                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    khachHangList.Add(new KhachHangViewModel
                    {
                        MaKH = reader["MaKH"].ToString(),
                        TenKH = reader["TenKH"].ToString(),
                        DiaChi = reader["DiaChi"].ToString(),
                        Email = reader["Email"].ToString(),
                        SDT = reader["SDT"].ToString(),
                        TenDangNhap = reader["TenDangNhap"].ToString(),
                        VaiTro = reader["VaiTro"].ToString(),
                        TrangThai = reader["TrangThai"].ToString(),
                        AnhDaiDien = reader["AnhDaiDien"].ToString()
                    });
                }
            }

            return View(khachHangList);
        }
    }
}