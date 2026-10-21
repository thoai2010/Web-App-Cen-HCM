# 🔧 Hướng Dẫn Sửa Backend C# - Lưu Đầy Đủ Thông Tin Đơn Hàng

## 1. Model DonHang - Thêm các trường mới

```csharp
public class DonHang
{
    public string MaDH { get; set; }
    public DateTime NgayDat { get; set; }
    public string TrangThai { get; set; }
    
    // ✅ THÊM CÁC TRƯỜNG MỚI
    public int? TongSanPham { get; set; }      // Tổng sản phẩm gốc (trước KM)
    public int? TienGiam { get; set; }         // Tiền giảm khuyến mãi
    public int? PhiVanChuyen { get; set; }     // Phí vận chuyển
    public int TongTien { get; set; }          // Tổng tiền thanh toán (đã tính tất cả)
    
    // Thông tin người nhận
    public string? MaKH { get; set; }
    public string? HoTen { get; set; }
    public string? DiaChi { get; set; }
    public string? SDT { get; set; }
    public string? Email { get; set; }
    public string? PhuongThucThanhToan { get; set; }  // ✅ THÊM
    public string? GhiChu { get; set; }              // ✅ THÊM
    
    // Foreign key
    public ICollection<CT_DonHang_SP> ChiTiet { get; set; }
}
```

## 2. DTO - TaoDonHangDto

```csharp
public class TaoDonHangDto
{
    public string? MaKH { get; set; }
    public string HoTen { get; set; }
    public string DiaChi { get; set; }
    public string SDT { get; set; }
    public string Email { get; set; }
    public string? PhuongThucThanhToan { get; set; }
    
    // ✅ THÊM CÁC TRƯỜNG MỚI
    public int TongSanPham { get; set; }        // Frontend gửi: tổng sản phẩm gốc
    public int TienGiam { get; set; }           // Frontend gửi: tiền giảm
    public int PhiVanChuyen { get; set; }       // Frontend gửi: phí vận chuyển
    public int TongTien { get; set; }           // Frontend gửi: tổng thanh toán
    
    public List<TaoDonHangItemDto> Items { get; set; }
}

public class TaoDonHangItemDto
{
    public string MaSP { get; set; }
    public int SoLuong { get; set; }
}
```

## 3. DTO - DonHangDto (Response)

```csharp
public class DonHangDto
{
    public string MaDH { get; set; }
    public DateTime NgayDat { get; set; }
    public string TrangThai { get; set; }
    
    // ✅ THÊM CÁC TRƯỜNG MỚI
    public int? TongSanPham { get; set; }
    public int? TienGiam { get; set; }
    public int? PhiVanChuyen { get; set; }
    public int TongTien { get; set; }
    
    public string? MaKH { get; set; }
    public string? HoTen { get; set; }
    public string? DiaChi { get; set; }
    public string? SDT { get; set; }
    public string? Email { get; set; }
    public string? PhuongThucThanhToan { get; set; }  // ✅ THÊM
    public string? GhiChu { get; set; }              // ✅ THÊM
    
    public List<DonHangChiTietDto> ChiTiet { get; set; }
}

public class DonHangChiTietDto
{
    public string MaSP { get; set; }
    public string TenSP { get; set; }
    public int SoLuong { get; set; }
    public int DonGia { get; set; }
}
```

## 4. Controller - Sửa POST (TaoDonHang)

```csharp
[HttpPost]
public async Task<IActionResult> TaoDonHang([FromBody] TaoDonHangDto dto)
{
    if (dto.Items == null || dto.Items.Count == 0)
        return BadRequest(new { message = "Giỏ hàng trống" });

    var maDH = "DH" + DateTime.Now.Ticks;

    var donHang = new DonHang
    {
        MaDH = maDH,
        NgayDat = DateTime.Now,
        TrangThai = "Chờ xử lý",
        
        // ✅ LƯU CÁC TRƯỜNG TỪ FRONTEND
        TongSanPham = dto.TongSanPham,
        TienGiam = dto.TienGiam,
        PhiVanChuyen = dto.PhiVanChuyen,
        TongTien = dto.TongTien,  // LƯU ĐÚNG GIÁ TRỊ, KHÔNG TÍNH LẠI
        
        MaKH = dto.MaKH,
        HoTen = dto.HoTen,
        DiaChi = dto.DiaChi,
        SDT = dto.SDT,
        Email = dto.Email,
        PhuongThucThanhToan = dto.PhuongThucThanhToan
    };

    _db.DonHangs.Add(donHang);

    // ✅ Thêm chi tiết sản phẩm
    foreach (var item in dto.Items)
    {
        var sp = await _db.SanPhams.FindAsync(item.MaSP);
        if (sp == null) continue;

        _db.CT_DonHang_SPs.Add(new CT_DonHang_SP
        {
            MaDH = maDH,
            MaSP = sp.MaSP,
            SoLuong = item.SoLuong,
            DonGia = sp.GiaBan  // ✅ Lưu giá tại thời điểm đặt hàng
        });
    }

    await _db.SaveChangesAsync();

    return Ok(new
    {
        message = "Tạo đơn hàng thành công",
        maDH = maDH
    });
}
```

## 5. Controller - Sửa GET (GetAll)

```csharp
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var data = await _db.DonHangs
        .Include(d => d.ChiTiet)
            .ThenInclude(ct => ct.SanPham)
        .Select(d => new DonHangDto
        {
            MaDH = d.MaDH.Trim(),
            NgayDat = d.NgayDat,
            TrangThai = d.TrangThai,
            
            // ✅ THÊM CÁC TRƯỜNG MỚI
            TongSanPham = d.TongSanPham,
            TienGiam = d.TienGiam,
            PhiVanChuyen = d.PhiVanChuyen,
            TongTien = d.TongTien,
            
            MaKH = d.MaKH == null ? null : d.MaKH.Trim(),
            HoTen = d.HoTen,
            DiaChi = d.DiaChi,
            SDT = d.SDT,
            Email = d.Email,
            PhuongThucThanhToan = d.PhuongThucThanhToan,
            GhiChu = d.GhiChu,
            
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
```

## 6. Endpoint mới - GET theo maDH (Optional)

```csharp
// GET: api/DonHang/DH123456
[HttpGet("{maDH}")]
public async Task<IActionResult> GetByMaDH(string maDH)
{
    var donHang = await _db.DonHangs
        .Include(d => d.ChiTiet)
            .ThenInclude(ct => ct.SanPham)
        .FirstOrDefaultAsync(d => d.MaDH == maDH);

    if (donHang == null)
        return NotFound(new { message = "Không tìm thấy đơn hàng" });

    var dto = new DonHangDto
    {
        MaDH = donHang.MaDH.Trim(),
        NgayDat = donHang.NgayDat,
        TrangThai = donHang.TrangThai,
        TongSanPham = donHang.TongSanPham,
        TienGiam = donHang.TienGiam,
        PhiVanChuyen = donHang.PhiVanChuyen,
        TongTien = donHang.TongTien,
        MaKH = donHang.MaKH,
        HoTen = donHang.HoTen,
        DiaChi = donHang.DiaChi,
        SDT = donHang.SDT,
        Email = donHang.Email,
        PhuongThucThanhToan = donHang.PhuongThucThanhToan,
        GhiChu = donHang.GhiChu,
        ChiTiet = donHang.ChiTiet.Select(ct => new DonHangChiTietDto
        {
            MaSP = ct.MaSP.Trim(),
            TenSP = ct.SanPham != null ? ct.SanPham.TenSP : "",
            SoLuong = ct.SoLuong,
            DonGia = ct.DonGia
        }).ToList()
    };

    return Ok(dto);
}
```

## 7. Endpoint - Lấy đơn hàng theo khách hàng

```csharp
// GET: api/DonHang/khachhang/KH001
[HttpGet("khachhang/{maKH}")]
public async Task<IActionResult> GetByMaKH(string maKH)
{
    var data = await _db.DonHangs
        .Where(d => d.MaKH == maKH)
        .Include(d => d.ChiTiet)
            .ThenInclude(ct => ct.SanPham)
        .Select(d => new DonHangDto
        {
            MaDH = d.MaDH.Trim(),
            NgayDat = d.NgayDat,
            TrangThai = d.TrangThai,
            TongSanPham = d.TongSanPham,
            TienGiam = d.TienGiam,
            PhiVanChuyen = d.PhiVanChuyen,
            TongTien = d.TongTien,
            MaKH = d.MaKH == null ? null : d.MaKH.Trim(),
            HoTen = d.HoTen,
            DiaChi = d.DiaChi,
            SDT = d.SDT,
            Email = d.Email,
            PhuongThucThanhToan = d.PhuongThucThanhToan,
            GhiChu = d.GhiChu,
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
```

## 8. Migration - Thêm các cột mới

```bash
dotnet ef migrations add AddOrderFields
dotnet ef database update
```

hoặc tạo SQL script:

```sql
ALTER TABLE DonHangs
ADD TongSanPham INT NULL,
    TienGiam INT NULL,
    PhiVanChuyen INT NULL,
    PhuongThucThanhToan NVARCHAR(50) NULL,
    GhiChu NVARCHAR(500) NULL;
```

## 📋 Tóm tắt thay đổi

| Thay đổi | Mục đích |
|---------|---------|
| Model: +4 trường | Lưu đầy đủ thông tin chi phí |
| DTO: +4 trường | Nhận/trả về dữ liệu chi phí |
| POST: Lưu từ DTO | Backend không tính lại, dùng giá trị frontend |
| GET: Trả về all | Include tất cả các trường |
| Migration | Tạo cột trong database |

## ⚠️ Điều quan trọng

**KHÔNG** tính lại `TongTien` ở backend!  
Backend chỉ **LƯU** giá trị mà frontend gửi lên:
```csharp
TongTien = dto.TongTien,  // ✅ LƯU ĐÚNG
// KHÔNG LÀM: TongTien = tongSanPham - tienGiam + phiVanChuyen;
```

Điều này đảm bảo tính nhất quán giữa frontend (tính toán) và backend (lưu trữ).
