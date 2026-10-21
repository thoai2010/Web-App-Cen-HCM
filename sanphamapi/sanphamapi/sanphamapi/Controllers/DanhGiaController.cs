using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DanhGiaController : ControllerBase
    {
        private readonly AppDbContext _db;
        public DanhGiaController(AppDbContext db) => _db = db;

        // GET: api/DanhGia
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _db.DanhGias
                .Select(d => new DanhGiaDto
                {
                    MaDG = d.MaDG.Trim(),
                    MaSP = d.MaSP.Trim(),
                    SoSao = d.SoSao,
                    NoiDung = d.NoiDung,
                    NgayDG = d.NgayDG
                })
                .ToListAsync();

            return Ok(data);
        }

        // POST: api/DanhGia
        [HttpPost]
        public async Task<IActionResult> TaoDanhGia(DanhGiaDto dto)
        {
            var daMua = await _db.CT_DonHang_SPs
                .AnyAsync(x =>
                    x.MaDH.Trim() == dto.MaDG.Trim() &&
                    x.MaSP.Trim() == dto.MaSP.Trim()
                );

            if (!daMua)
                return BadRequest("Chỉ được đánh giá khi đã mua sản phẩm");

            var dg = new Models.DanhGia
            {
                MaDG = Guid.NewGuid().ToString("N").Substring(0, 10),
                MaSP = dto.MaSP,
                SoSao = dto.SoSao,
                NoiDung = dto.NoiDung,
                NgayDG = DateTime.Now
            };

            _db.DanhGias.Add(dg);
            await _db.SaveChangesAsync();

            return Ok("Đánh giá thành công");
        }
    }
}
