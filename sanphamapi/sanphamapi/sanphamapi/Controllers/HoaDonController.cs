using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;
using sanphamapi.Services;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HoaDonController : ControllerBase
    {
        private readonly AppDbContext _db;
        public HoaDonController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _db.HoaDons
                .Select(h => new HoaDonDto
                {
                    MaHD = h.MaHD.Trim(),
                    NgayLap = h.NgayLap,
                    SoTien = h.SoTien,
                    PhuongThucThanhToan = h.PhuongThucThanhToan,
                    ChiTiet = h.ChiTiet.Select(ct => new HoaDonChiTietDto
                    {
                        MaSP = ct.MaSP.Trim(),
                        TenSP = ct.SanPham!.TenSP,
                        SoLuong = ct.SoLuong,
                        DonGia = ct.DonGia
                    }).ToList()
                }).ToListAsync();

            return Ok(data);
        }

        [HttpGet("{maHD}/pdf")]
        public IActionResult XuatPdf(string maHD)
        {
            var hoaDon = _db.HoaDons
                .Include(h => h.ChiTiet)
                .ThenInclude(ct => ct.SanPham)
                .Where(h => h.MaHD.Trim() == maHD.Trim())
                .Select(h => new HoaDonDto
                {
                    MaHD = h.MaHD.Trim(),
                    NgayLap = h.NgayLap,
                    SoTien = h.SoTien,
                    PhuongThucThanhToan = h.PhuongThucThanhToan,
                    ChiTiet = h.ChiTiet.Select(ct => new HoaDonChiTietDto
                    {
                        MaSP = ct.MaSP.Trim(),
                        TenSP = ct.SanPham!.TenSP,
                        SoLuong = ct.SoLuong,
                        DonGia = ct.DonGia
                    }).ToList()
                })
                .FirstOrDefault();

            if (hoaDon == null)
                return NotFound();

            var pdfService = new HoaDonPdfService();
            var bytes = pdfService.Generate(hoaDon);

            return File(bytes, "application/pdf", $"HoaDon_{maHD}.pdf");
        }
    }
}
