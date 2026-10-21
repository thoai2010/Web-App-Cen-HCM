using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.Models;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TaiKhoanController : ControllerBase
    {
        private readonly AppDbContext _db;

        public TaiKhoanController(AppDbContext db)
        {
            _db = db;
        }

        // =====================
        // GET ALL – CHỈ LẤY KHÁCH HÀNG HOẠT ĐỘNG
        // =====================
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _db.TaiKhoans
                .Where(t =>
                    t.VaiTro == "KhachHang" &&
                    t.TrangThai == "Hoạt động"
                )
                .ToListAsync();

            return Ok(data);
        }

        // =====================
        // ĐĂNG NHẬP – CHỈ CHO KHÁCH HÀNG HOẠT ĐỘNG
        // =====================
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] TaiKhoan login)
        {
            var user = await _db.TaiKhoans
                .Include(x => x.KhachHang)
                .FirstOrDefaultAsync(x =>
                    x.TenDangNhap == login.TenDangNhap &&
                    x.MatKhau == login.MatKhau &&
                    x.VaiTro == "KhachHang" &&
                    x.TrangThai == "Hoạt động"
                );

            if (user == null)
                return Unauthorized(new { message = "Sai tên đăng nhập hoặc tài khoản không được phép" });

            if (user.KhachHang == null)
                return BadRequest(new { message = "Tài khoản chưa có thông tin khách hàng (KhachHang)" });

            return Ok(new
            {
                message = "Đăng nhập thành công",
                tenDangNhap = user.TenDangNhap,
                vaiTro = user.VaiTro,
                trangThai = user.TrangThai,

                // ✅ trả đúng cho Flutter
                maKH = user.KhachHang.MaKH,
                tenKH = user.KhachHang.TenKH,
                anhDaiDien = user.KhachHang.AnhDaiDien
            });
        }




        // =====================
        // ĐĂNG KÝ – TỰ SET KHÁCH HÀNG + HOẠT ĐỘNG
        // =====================
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] TaiKhoan newAccount)
        {
            bool exist = await _db.TaiKhoans
                .AnyAsync(x => x.TenDangNhap == newAccount.TenDangNhap);

            if (exist)
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại" });

            // Tự set vai trò & trạng thái
            newAccount.VaiTro = "KhachHang";
            newAccount.TrangThai = "Hoạt động";

            _db.TaiKhoans.Add(newAccount);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Đăng ký thành công" });
        }
    }
}
