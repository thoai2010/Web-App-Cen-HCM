using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Dynamic;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class HomeController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;

        public ActionResult Index()
        {
            var danhMuc = new List<dynamic>();
            var sanPhamNoiBat = new List<dynamic>();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();

                // --- Danh mục loại ---
                var sqlLoai = "SELECT MaLoai, TenLoai FROM LoaiSanPham ORDER BY TenLoai";
                using (var cmd = new SqlCommand(sqlLoai, conn))
                using (var r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        dynamic loai = new ExpandoObject();
                        loai.MaLoai = r["MaLoai"].ToString().Trim();
                        loai.TenLoai = r["TenLoai"].ToString();
                        loai.Hinh = Url.Content("~/Content/images/default-category.jpg");
                        danhMuc.Add(loai);
                    }
                }

                var sqlSP = @"
                    SELECT TOP 8 MaSP, TenSP, GiaBan, SLTon, ISNULL(Hinh, '') AS DuongDan
                    FROM SanPham
                    ORDER BY SLTon DESC";

                using (var cmd2 = new SqlCommand(sqlSP, conn))
                using (var r2 = cmd2.ExecuteReader())
                {
                    while (r2.Read())
                    {
                        dynamic sp = new ExpandoObject();
                        sp.MaSP = r2["MaSP"].ToString().Trim();
                        sp.TenSP = r2["TenSP"].ToString();
                        sp.GiaBan = Convert.ToInt32(r2["GiaBan"]);
                        sp.SLTon = Convert.ToInt32(r2["SLTon"]);

                        string duongDan = r2["DuongDan"].ToString();
                        sp.Hinh = string.IsNullOrEmpty(duongDan)
                            ? Url.Content("~/Content/images/default-product.jpg")
                            : Url.Content("~/" + duongDan.TrimStart('/'));

                        sanPhamNoiBat.Add(sp);
                    }
                }
            }

            // --- Banner ---
            ViewBag.BannerImages = new List<string>
            {
                Url.Content("~/Content/images/banner1.jpg"),
                Url.Content("~/Content/images/banner2.jpg"),
                Url.Content("~/Content/images/banner3.jpg")
            };

            // --- Company Info (dùng ExpandoObject thật) ---
            dynamic company = new ExpandoObject();
            company.Ten = "CEN HCM";
            company.DiaChi = "57 Nguyễn Cơ Thạch, An Khánh, TP. Thủ Đức, TP.HCM";
            company.Hotline = "+84 90 336 04 81";
            company.Email = "info.chcm@cenhomes.vn";
            ViewBag.Company = company;

            // --- Gán ViewBag ---
            ViewBag.DanhMucLoai = danhMuc;
            ViewBag.SanPhamNoiBat = sanPhamNoiBat;

            return View();
        }

        public ActionResult Contact()
        {
            dynamic company = new System.Dynamic.ExpandoObject();
            company.Ten = "CEN HCM";
            company.DiaChi = "57 Nguyễn Cơ Thạch, An Khánh, TP. Thủ Đức, TP.HCM";
            company.Hotline = "+84 90 336 04 81";
            company.Email = "info.chcm@cenhomes.vn";
            ViewBag.Company = company;

            return View();
        }


        [HttpPost]
        public ActionResult GuiLienHe(string Ten, string Email, string SDT)
        {
            TempData["Message"] = "Cảm ơn bạn đã liên hệ, chúng tôi sẽ phản hồi sớm!";
            return RedirectToAction("Index");
        }
    }
}
