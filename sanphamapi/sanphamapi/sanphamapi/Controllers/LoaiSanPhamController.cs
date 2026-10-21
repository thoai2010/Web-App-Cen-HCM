using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LoaiSanPhamController : ControllerBase
    {
        private readonly AppDbContext _db;
        public LoaiSanPhamController(AppDbContext db) => _db = db;

        // GET: api/LoaiSanPham
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _db.LoaiSanPhams
                .Select(l => new LoaiSanPhamDto
                {
                    MaLoai = l.MaLoai.Trim(),
                    TenLoai = l.TenLoai
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpGet("by-loai/{maLoai}")]
        public async Task<IActionResult> GetByLoai(string maLoai)
        {
            var data = await _db.SanPhams
                .Where(sp => sp.MaLoai.Trim() == maLoai.Trim())
                .Select(sp => new SanPhamTheoLoaiDto
                {
                    MaSP = sp.MaSP.Trim(),
                    TenSP = sp.TenSP,
                    GiaBan = sp.GiaBan,
                    Hinh = sp.Hinh
                })
                .ToListAsync();

            return Ok(data);
        }
    }
}
