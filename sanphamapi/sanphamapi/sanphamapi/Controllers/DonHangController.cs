using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;
using sanphamapi.Models;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DonHangController : ControllerBase
    {
        private readonly AppDbContext _db;
        public DonHangController(AppDbContext db) => _db = db;

        // ======================
        // GET: api/DonHang
        // ======================
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _db.DonHangs
                .AsNoTracking()
                .Include(d => d.ChiTiet)
                    .ThenInclude(ct => ct.SanPham)
                .OrderByDescending(d => d.NgayDat)
                .Select(d => new DonHangDto
                {
                    MaDH = d.MaDH.Trim(),
                    NgayDat = d.NgayDat,
                    TrangThai = d.TrangThai,
                    TongTien = d.TongTien,

                    MaKH = d.MaKH == null ? null : d.MaKH.Trim(),
                    HoTen = d.HoTen,
                    DiaChi = d.DiaChi,
                    SDT = d.SDT,
                    Email = d.Email,
                    PhuongThucThanhToan = d.PhuongThucThanhToan,

                    ChiTiet = d.ChiTiet.Select(ct => new DonHangChiTietDto
                    {
                        MaSP = ct.MaSP.Trim(),
                        TenSP = ct.SanPham != null ? ct.SanPham.TenSP : "",
                        SoLuong = ct.SoLuong,
                        DonGia = ct.DonGia
                    }).ToList()
                })
                .ToListAsync();

            return Ok(data);
        }

        // ======================
        // GET: api/DonHang/khachhang/{maKH}
        // ======================
        [HttpGet("khachhang/{maKH}")]
        public async Task<IActionResult> GetByMaKH(string maKH)
        {
            if (string.IsNullOrWhiteSpace(maKH))
                return BadRequest(new { message = "Thiếu maKH" });

            maKH = maKH.Trim();

            var data = await _db.DonHangs
                .AsNoTracking()
                .Where(d => d.MaKH != null && d.MaKH.Trim() == maKH)
                .Include(d => d.ChiTiet)
                    .ThenInclude(ct => ct.SanPham)
                .OrderByDescending(d => d.NgayDat)
                .Select(d => new DonHangDto
                {
                    MaDH = d.MaDH.Trim(),
                    NgayDat = d.NgayDat,
                    TrangThai = d.TrangThai,
                    TongTien = d.TongTien,

                    MaKH = d.MaKH == null ? null : d.MaKH.Trim(),
                    HoTen = d.HoTen,
                    DiaChi = d.DiaChi,
                    SDT = d.SDT,
                    Email = d.Email,
                    PhuongThucThanhToan = d.PhuongThucThanhToan,

                    ChiTiet = d.ChiTiet.Select(ct => new DonHangChiTietDto
                    {
                        MaSP = ct.MaSP.Trim(),
                        TenSP = ct.SanPham != null ? ct.SanPham.TenSP : "",
                        SoLuong = ct.SoLuong,
                        DonGia = ct.DonGia
                    }).ToList()
                })
                .ToListAsync();

            return Ok(data);
        }

        // ======================
        // GET: api/DonHang/{maDH}
        // ======================
        [HttpGet("{maDH}")]
        public async Task<IActionResult> GetByMaDH(string maDH)
        {
            if (string.IsNullOrWhiteSpace(maDH))
                return BadRequest(new { message = "Thiếu maDH" });

            maDH = maDH.Trim();

            var d = await _db.DonHangs
                .AsNoTracking()
                .Include(x => x.ChiTiet)
                    .ThenInclude(ct => ct.SanPham)
                .FirstOrDefaultAsync(x => x.MaDH.Trim() == maDH);

            if (d == null) return NotFound(new { message = "Không tìm thấy đơn hàng" });

            var dto = new DonHangDto
            {
                MaDH = d.MaDH.Trim(),
                NgayDat = d.NgayDat,
                TrangThai = d.TrangThai,
                TongTien = d.TongTien,

                MaKH = d.MaKH == null ? null : d.MaKH.Trim(),
                HoTen = d.HoTen,
                DiaChi = d.DiaChi,
                SDT = d.SDT,
                Email = d.Email,
                PhuongThucThanhToan = d.PhuongThucThanhToan,

                ChiTiet = d.ChiTiet.Select(ct => new DonHangChiTietDto
                {
                    MaSP = ct.MaSP.Trim(),
                    TenSP = ct.SanPham != null ? ct.SanPham.TenSP : "",
                    SoLuong = ct.SoLuong,
                    DonGia = ct.DonGia
                }).ToList()
            };

            return Ok(dto);
        }

        // ======================
        // Sinh mã DH001, DH002...
        // (tối ưu: chỉ lấy phần số về memory, không lấy cả list mã)
        // ======================
        private async Task<string> GenerateMaDHAsync()
        {
            var nums = await _db.DonHangs
                .AsNoTracking()
                .Where(x => x.MaDH.StartsWith("DH") && x.MaDH.Length >= 3)
                .Select(x => x.MaDH.Substring(2))
                .ToListAsync(); // về memory -> parse OK

            var last = 0;
            foreach (var s in nums)
            {
                if (int.TryParse(s, out var n) && n > last) last = n;
            }

            return "DH" + (last + 1).ToString("D3");
        }

        // ======================
        // POST: api/DonHang
        // ✅ TongTien lưu = (tong gốc DB - giảm) + ship
        // ✅ rollback đúng khi return sớm
        // ======================
        [HttpPost]
        public async Task<IActionResult> TaoDonHang([FromBody] TaoDonHangDto dto)
        {
            if (dto.Items == null || dto.Items.Count == 0)
                return BadRequest(new { message = "Giỏ hàng rỗng" });

            if (string.IsNullOrWhiteSpace(dto.HoTen) ||
                string.IsNullOrWhiteSpace(dto.DiaChi) ||
                string.IsNullOrWhiteSpace(dto.SDT) ||
                string.IsNullOrWhiteSpace(dto.Email))
            {
                return BadRequest(new { message = "Thiếu thông tin người nhận" });
            }

            var pttt = string.IsNullOrWhiteSpace(dto.PhuongThucThanhToan)
                ? "COD"
                : dto.PhuongThucThanhToan.Trim();

            if (dto.PhiVanChuyen < 0 || dto.TienGiam < 0)
                return BadRequest(new { message = "Giá trị giảm/ship không hợp lệ" });

            using var tran = await _db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
            try
            {
                var maDH = await GenerateMaDHAsync();

                int tongGocDb = 0;

                var dh = new DonHang
                {
                    MaDH = maDH,
                    NgayDat = DateTime.Now,
                    TrangThai = "Đang xử lý",
                    TongTien = 0,

                    MaKH = dto.MaKH,
                    HoTen = dto.HoTen.Trim(),
                    DiaChi = dto.DiaChi.Trim(),
                    SDT = dto.SDT.Trim(),
                    Email = dto.Email.Trim(),
                    PhuongThucThanhToan = pttt
                };

                _db.DonHangs.Add(dh);

                foreach (var i in dto.Items)
                {
                    var maSp = (i.MaSP ?? "").Trim();
                    if (string.IsNullOrWhiteSpace(maSp) || i.SoLuong <= 0)
                    {
                        await tran.RollbackAsync();
                        return BadRequest(new { message = "Dữ liệu sản phẩm không hợp lệ" });
                    }

                    var sp = await _db.SanPhams.FirstOrDefaultAsync(x => x.MaSP == maSp);
                    if (sp == null)
                    {
                        await tran.RollbackAsync();
                        return BadRequest(new { message = $"Sản phẩm không tồn tại: {maSp}" });
                    }

                    tongGocDb += sp.GiaBan * i.SoLuong;

                    _db.CT_DonHang_SPs.Add(new CT_DonHang_SP
                    {
                        MaDH = maDH,
                        MaSP = sp.MaSP,
                        SoLuong = i.SoLuong,
                        DonGia = sp.GiaBan
                    });
                }

                // ✅ đối soát tổng gốc (nếu client có gửi)
                if (dto.TongSanPham > 0 && dto.TongSanPham != tongGocDb)
                {
                    await tran.RollbackAsync();
                    return BadRequest(new
                    {
                        message = "Tổng sản phẩm không khớp",
                        tongClient = dto.TongSanPham,
                        tongDb = tongGocDb
                    });
                }

                var tongThanhToan = tongGocDb - dto.TienGiam + dto.PhiVanChuyen;
                if (tongThanhToan < 0) tongThanhToan = 0;

                // ✅ đối soát tổng thanh toán (nếu client có gửi)
                if (dto.TongTien > 0 && dto.TongTien != tongThanhToan)
                {
                    await tran.RollbackAsync();
                    return BadRequest(new
                    {
                        message = "Tổng thanh toán không khớp",
                        tongClient = dto.TongTien,
                        tongServer = tongThanhToan
                    });
                }

                dh.TongTien = tongThanhToan;

                await _db.SaveChangesAsync();
                await tran.CommitAsync();

                return Ok(new
                {
                    message = "Tạo đơn hàng thành công",
                    maDH,
                    tongGocDb,
                    tongThanhToan
                });
            }
            catch (Exception ex)
            {
                await tran.RollbackAsync();
                return StatusCode(500, new
                {
                    message = "Lỗi tạo đơn hàng",
                    error = ex.Message,
                    inner = ex.InnerException?.Message
                });
            }
        }
    }
}
