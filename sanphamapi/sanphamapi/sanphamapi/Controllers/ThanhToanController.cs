using Microsoft.AspNetCore.Mvc;
using sanphamapi.Data;
using sanphamapi.DTOs;
using sanphamapi.Models;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ThanhToanController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ThanhToanController(AppDbContext db) => _db = db;

        [HttpPost]
        public async Task<IActionResult> ThanhToan(ThanhToanDto dto)
        {
            var dh = await _db.DonHangs.FindAsync(dto.MaDH);
            if (dh == null) return NotFound();

            var hd = new HoaDon
            {
                MaHD = "HD" + DateTime.Now.Ticks,
                MaDH = dh.MaDH,
                NgayLap = DateTime.Now,
                SoTien = dh.TongTien,
                PhuongThucThanhToan = dto.PhuongThucThanhToan
            };

            _db.HoaDons.Add(hd);
            await _db.SaveChangesAsync();

            return Ok(hd);
        }

        [HttpPost("vnpay")]
        public IActionResult ThanhToanVnPay(VnPayRequestDto dto)
        {
            var fakeUrl = $"https://sandbox.vnpayment.vn/payment?maHD={dto.MaHD}&amount={dto.SoTien}";
            return Ok(new
            {
                message = "Redirect VNPay",
                url = fakeUrl
            });
        }
    }
}
