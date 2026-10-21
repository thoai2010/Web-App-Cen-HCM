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
    public class GioHangController : Controller
    {
        private readonly string connStr = ConfigurationManager.ConnectionStrings["QLBH"].ConnectionString;
        private const string CART_SESSION = "Cart";
        private const string CART_COOKIE = "CART_COOKIE";

        #region AUTH
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

            // 👉 Load cart từ cookie nếu session mất
            LoadCartFromCookie();
            base.OnActionExecuting(filterContext);
        }
        #endregion

        #region INDEX
        public ActionResult Index()
        {
            var cart = GetCart();

            foreach (var item in cart)
            {
                ApDungKhuyenMaiTheoSanPham(item);
            }

            SaveCart(cart);
            return View(cart);
        }
        #endregion

        #region ADD
        public ActionResult ThemVaoGio(string id, int soLuong = 1)
        {
            if (string.IsNullOrEmpty(id) || soLuong <= 0)
                return RedirectToAction("DanhMuc", "SanPham");

            var cart = GetCart();

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                SELECT 
                    LTRIM(RTRIM(MaSP)) MaSP,
                    CAST(TenSP AS NVARCHAR(MAX)) TenSP,
                    DonViTinh,
                    GiaBan,
                    ISNULL(Hinh,'') Hinh,
                    SLTon
                FROM SanPham
                WHERE LTRIM(RTRIM(MaSP)) = @id";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@id", id.Trim());
                    using (var r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            int slTon = Convert.ToInt32(r["SLTon"]);
                            var sp = cart.FirstOrDefault(x => x.MaSP == id);

                            if (sp != null)
                            {
                                sp.SoLuong = Math.Min(sp.SoLuong + soLuong, slTon);
                            }
                            else
                            {
                                string h = r["Hinh"].ToString().Trim();
                                string hinh = string.IsNullOrEmpty(h)
                                    ? Url.Content("~/Content/images/no-image.png")
                                    : Url.Content("~/Content/images/sanpham/" + h.TrimStart('/'));

                                cart.Add(new CartItem
                                {
                                    MaSP = r["MaSP"].ToString(),
                                    TenSP = r["TenSP"] as string,
                                    DonViTinh = r["DonViTinh"].ToString(),
                                    GiaBan = Convert.ToInt32(r["GiaBan"]),
                                    SoLuong = soLuong,
                                    SLTon = slTon,
                                    HinhAnh = hinh,
                                    IsSelected = true
                                });
                            }
                        }
                    }
                }
            }

            SaveCart(cart);
            TempData["Success"] = "Đã thêm sản phẩm vào giỏ hàng.";
            return RedirectToAction("Index");
        }
        #endregion

        #region UPDATE
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CapNhatSoLuong(List<CartItem> items)
        {
            var cart = GetCart();

            foreach (var i in items)
            {
                var sp = cart.FirstOrDefault(x => x.MaSP == i.MaSP);
                if (sp != null)
                {
                    sp.SoLuong = Math.Min(Math.Max(i.SoLuong, 1), sp.SLTon);
                    sp.IsSelected = i.IsSelected;
                    ApDungKhuyenMaiTheoSanPham(sp);
                }
            }

            SaveCart(cart);
            TempData["Success"] = "Cập nhật giỏ hàng thành công.";
            return RedirectToAction("Index");
        }
        #endregion

        #region DELETE
        public ActionResult Xoa(string id)
        {
            var cart = GetCart();
            cart.RemoveAll(x => x.MaSP == id);

            SaveCart(cart);
            TempData["Success"] = "Đã xóa sản phẩm khỏi giỏ hàng.";
            return RedirectToAction("Index");
        }

        public ActionResult XoaTatCa()
        {
            SaveCart(new List<CartItem>());
            TempData["Success"] = "Đã xóa toàn bộ sản phẩm trong giỏ hàng.";
            return RedirectToAction("Index");
        }
        #endregion

        #region KHUYEN MAI
        private void ApDungKhuyenMaiTheoSanPham(CartItem item)
        {
            decimal tong = item.GiaBan * item.SoLuong;
            decimal km = 0;

            using (var conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = @"
                SELECT k.LoaiKM, c.SoLuongToiThieu, c.TriGia
                FROM ChiTietKM_SP c
                JOIN KhuyenMai k ON c.MaKM = k.MaKM
                WHERE c.MaSP = @MaSP
                AND GETDATE() BETWEEN k.NgayBD AND k.NgayKT";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@MaSP", item.MaSP);
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            int slMin = Convert.ToInt32(r["SoLuongToiThieu"]);
                            decimal triGia = Convert.ToDecimal(r["TriGia"]);
                            string loai = r["LoaiKM"].ToString();

                            if (item.SoLuong >= slMin)
                            {
                                if (loai == "Tien")
                                    km += triGia * (item.SoLuong / slMin);
                                else
                                    km += tong * triGia / 100m;
                            }
                        }
                    }
                }
            }

            if (km > tong) km = tong;
            item.KhuyenMai = km;
            item.ThanhTienSauKM = tong - km;
        }
        #endregion

        #region SESSION + COOKIE
        private List<CartItem> GetCart()
        {
            return Session[CART_SESSION] as List<CartItem> ?? new List<CartItem>();
        }

        private void SaveCart(List<CartItem> cart)
        {
            Session[CART_SESSION] = cart;

            var json = JsonConvert.SerializeObject(cart);
            Response.Cookies.Set(new HttpCookie(CART_COOKIE, json)
            {
                Expires = DateTime.Now.AddDays(7)
            });
        }

        private void LoadCartFromCookie()
        {
            if (Session[CART_SESSION] != null) return;

            var cookie = Request.Cookies[CART_COOKIE];
            if (cookie != null)
            {
                Session[CART_SESSION] =
                    JsonConvert.DeserializeObject<List<CartItem>>(cookie.Value);
            }
        }
        #endregion
    }
}
