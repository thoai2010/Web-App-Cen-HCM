using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace QLBH.Controllers
{
    public class AdminController : Controller
    {
        // GET: Admin
        private bool IsAdmin()
        {
            return string.Equals(Session["VaiTro"]?.ToString(), "Admin", StringComparison.OrdinalIgnoreCase);
        }

        public ActionResult Index()
        {
            if (!IsAdmin())
            {
                // Nếu là nhân viên, redirect về TrangNV
                if (string.Equals(Session["VaiTro"]?.ToString(), "NhanVien", StringComparison.OrdinalIgnoreCase))
                    return RedirectToAction("Index", "TrangNV");

                // Nếu không phải Admin và không phải NhanVien, redirect login
                return RedirectToAction("Login", "Account");
            }

            // 🔹 Gọi controller thống kê để lấy dữ liệu
            var thongKeCtrl = new ThongKeController();
            var result = thongKeCtrl.Index() as ViewResult;
            var model = result.Model;

            // 🔹 Copy ViewBag từ ThongKeController sang View hiện tại
            foreach (var key in thongKeCtrl.ViewData.Keys)
            {
                ViewData[key] = thongKeCtrl.ViewData[key];
            }

            return View(model);
        }



        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Login", "Account");
        }

        public ActionResult QuanLySanPham()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");
            return View();
        }

        public ActionResult QuanLyNhanVien()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");
            return View();
        }

        public ActionResult QuanLyNhaCungCap()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");
            return View();
        }

        public ActionResult QuanLyKhachHang()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");
            return View();
        }

        public ActionResult QuanLyDoanhThu()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");
            return View();
        }
    }
}