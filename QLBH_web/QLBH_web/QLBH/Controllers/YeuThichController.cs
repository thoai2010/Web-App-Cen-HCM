using QLBH.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Newtonsoft.Json;

namespace QLBH.Controllers
{
    public class YeuThichController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;
        private const string WISHLIST_SESSION = "WishList";
        private const string WISHLIST_COOKIE = "WISHLIST_COOKIE";

        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            var ten = Session["TenDangNhap"];
            var role = Session["VaiTro"];
            if (ten == null || role == null || role.ToString() != "KhachHang")
            {
                filterContext.Result = RedirectToAction("Login", "Account",
                    new { returnUrl = filterContext.HttpContext.Request.RawUrl });
                return;
            }

            LoadWishFromCookie();
            base.OnActionExecuting(filterContext);
        }

        public ActionResult Index()
        {
            return View(GetWish());
        }

        public ActionResult ThemYeuThich(string id)
        {
            var list = GetWish();
            if (list.Any(x => x.MaSP == id))
            {
                TempData["Message"] = "Sản phẩm đã có trong yêu thích.";
                return RedirectToAction("Index");
            }

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                SELECT 
                    LTRIM(RTRIM(MaSP)) MaSP,
                    CAST(TenSP AS NVARCHAR(MAX)) TenSP,
                    GiaBan,
                    ISNULL(Hinh,'') Hinh
                FROM SanPham
                WHERE LTRIM(RTRIM(MaSP)) = @id";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", id.Trim());
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            list.Add(new YeuThichItem
                            {
                                MaSP = r["MaSP"].ToString(),
                                TenSP = r["TenSP"] as string,
                                GiaBan = Convert.ToInt32(r["GiaBan"]),
                                Hinh = Url.Content("~/Content/images/sanpham/" + r["Hinh"].ToString())
                            });
                        }
                    }
                }
            }

            SaveWish(list);
            TempData["Message"] = "Đã thêm sản phẩm vào yêu thích.";
            return RedirectToAction("Index");
        }

        public ActionResult Xoa(string id)
        {
            var list = GetWish();
            list.RemoveAll(x => x.MaSP == id);
            SaveWish(list);
            TempData["Message"] = "Đã xóa sản phẩm khỏi yêu thích.";
            return RedirectToAction("Index");
        }

        public ActionResult XoaTatCa()
        {
            SaveWish(new List<YeuThichItem>());
            TempData["Message"] = "Đã xóa toàn bộ yêu thích.";
            return RedirectToAction("Index");
        }

        #region SESSION + COOKIE
        private List<YeuThichItem> GetWish()
        {
            return Session[WISHLIST_SESSION] as List<YeuThichItem> ?? new List<YeuThichItem>();
        }

        private void SaveWish(List<YeuThichItem> list)
        {
            Session[WISHLIST_SESSION] = list;
            var json = JsonConvert.SerializeObject(list);
            Response.Cookies.Set(new HttpCookie(WISHLIST_COOKIE, json)
            {
                Expires = DateTime.Now.AddDays(7)
            });
        }

        private void LoadWishFromCookie()
        {
            if (Session[WISHLIST_SESSION] != null) return;

            var cookie = Request.Cookies[WISHLIST_COOKIE];
            if (cookie != null)
            {
                Session[WISHLIST_SESSION] =
                    JsonConvert.DeserializeObject<List<YeuThichItem>>(cookie.Value);
            }
        }
        #endregion
    }
}
