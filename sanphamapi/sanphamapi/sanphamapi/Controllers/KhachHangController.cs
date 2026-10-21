using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;
using sanphamapi.Models;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class KhachHangController : ControllerBase
    {
        private readonly AppDbContext _db;

        public KhachHangController(AppDbContext db)
        {
            _db = db;
        }

        // GET: api/KhachHang
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var khachHangs = await _db.KhachHangs
                .AsNoTracking()
                .ToListAsync();

            return Ok(khachHangs);
        }

        // GET: api/KhachHang/KH001
        [HttpGet("{maKH}")]
        public async Task<IActionResult> GetById(string maKH)
        {
            maKH = (maKH ?? "").Trim();

            var kh = await _db.KhachHangs
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.MaKH == maKH);

            if (kh == null) return NotFound();
            return Ok(kh);
        }

        // POST: api/KhachHang
        // ✅ KHÔNG cần gửi MaKH, backend tự sinh
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] KhachHangCreateDto dto)
        {
            // (tuỳ chọn) validate trùng TenDangNhap
            var tenDangNhap = (dto.TenDangNhap ?? "").Trim();
            if (string.IsNullOrEmpty(tenDangNhap))
                return BadRequest("TenDangNhap không được trống.");

            // (tuỳ chọn) kiểm tra tài khoản tồn tại (nếu có DbSet<TaiKhoan>)
            // var tkExists = await _db.TaiKhoans.AnyAsync(x => x.TenDangNhap == tenDangNhap);
            // if (!tkExists) return BadRequest("Tài khoản không tồn tại.");

            // (tuỳ chọn) check trùng email/sdt
            var email = (dto.Email ?? "").Trim();
            var sdt = (dto.SDT ?? "").Trim();

            if (await _db.KhachHangs.AnyAsync(x => x.Email == email))
                return BadRequest("Email đã tồn tại.");

            if (await _db.KhachHangs.AnyAsync(x => x.SDT == sdt))
                return BadRequest("SĐT đã tồn tại.");

            // ✅ Tự sinh MaKH
            var maKH = await GenerateMaKH();

            var kh = new KhachHang
            {
                MaKH = maKH,
                TenKH = (dto.TenKH ?? "").Trim(),
                DiaChi = (dto.DiaChi ?? "").Trim(),
                Email = email,
                SDT = sdt,
                TenDangNhap = tenDangNhap,
                AnhDaiDien = string.IsNullOrWhiteSpace(dto.AnhDaiDien) ? null : dto.AnhDaiDien.Trim(),
            };

            _db.KhachHangs.Add(kh);
            await _db.SaveChangesAsync();

            // ✅ trả về object gọn (Flutter lấy maKH)
            return Ok(new
            {
                maKH = kh.MaKH,
                tenKH = kh.TenKH,
                diaChi = kh.DiaChi,
                email = kh.Email,
                sdt = kh.SDT,
                tenDangNhap = kh.TenDangNhap,
                anhDaiDien = kh.AnhDaiDien
            });
        }

        // PUT: api/KhachHang/KH001
        [HttpPut("{maKH}")]
        public async Task<IActionResult> Update(string maKH, [FromBody] KhachHangUpdateDto dto)
        {
            maKH = (maKH ?? "").Trim();
            dto.MaKH = (dto.MaKH ?? "").Trim();

            if (string.IsNullOrEmpty(maKH)) return BadRequest("MaKH không hợp lệ.");
            if (maKH != dto.MaKH) return BadRequest("MaKH không khớp.");

            var kh = await _db.KhachHangs.FirstOrDefaultAsync(x => x.MaKH == maKH);
            if (kh == null) return NotFound();

            var email = (dto.Email ?? "").Trim();
            var sdt = (dto.SDT ?? "").Trim();

            // (tuỳ chọn) check trùng email/sdt nhưng bỏ qua chính nó
            if (await _db.KhachHangs.AnyAsync(x => x.Email == email && x.MaKH != maKH))
                return BadRequest("Email đã tồn tại.");

            if (await _db.KhachHangs.AnyAsync(x => x.SDT == sdt && x.MaKH != maKH))
                return BadRequest("SĐT đã tồn tại.");

            kh.TenKH = (dto.TenKH ?? "").Trim();
            kh.DiaChi = (dto.DiaChi ?? "").Trim();
            kh.Email = email;
            kh.SDT = sdt;
            kh.AnhDaiDien = string.IsNullOrWhiteSpace(dto.AnhDaiDien) ? null : dto.AnhDaiDien.Trim();

            await _db.SaveChangesAsync();
            return Ok(kh);
        }

        // DELETE: api/KhachHang/KH001
        [HttpDelete("{maKH}")]
        public async Task<IActionResult> Delete(string maKH)
        {
            maKH = (maKH ?? "").Trim();

            var kh = await _db.KhachHangs.FirstOrDefaultAsync(x => x.MaKH == maKH);
            if (kh == null) return NotFound();

            _db.KhachHangs.Remove(kh);
            await _db.SaveChangesAsync();
            return Ok();
        }

        // ✅ Sinh mã KH001, KH002...
        private async Task<string> GenerateMaKH()
        {
            var last = await _db.KhachHangs
                .AsNoTracking()
                .Where(x => x.MaKH.StartsWith("KH"))
                .OrderByDescending(x => x.MaKH)
                .Select(x => x.MaKH)
                .FirstOrDefaultAsync();

            int next = 1;
            if (!string.IsNullOrEmpty(last) && last.Length > 2)
            {
                var numPart = last.Substring(2);
                if (int.TryParse(numPart, out var n))
                    next = n + 1;
            }

            return $"KH{next:000}";
        }
    }
}
