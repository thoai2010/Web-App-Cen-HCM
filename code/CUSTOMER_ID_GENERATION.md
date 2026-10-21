# 🔧 Hướng Dẫn Tạo Mã Khách Hàng Tự Động

## 📋 Yêu Cầu
- Format: `KH` + số thứ tự (ví dụ: `KH001`, `KH002`, `KH003`, ...)
- Số cuối cùng + 1 cho khách hàng tiếp theo

## 🛠️ Triển Khai trong C# Backend

### 1️⃣ **Cập Nhật Model `KhachHang.cs`**

```csharp
public class KhachHang
{
    public string MaKH { get; set; }  // ✅ Primary Key, auto-generated
    public string TenKH { get; set; }
    public string Email { get; set; }
    public string SDT { get; set; }
    public string DiaChi { get; set; }
    public string AnhDaiDien { get; set; }
    public string TenDangNhap { get; set; }  // ✅ Link đến TaiKhoan
    public DateTime NgayTao { get; set; } = DateTime.Now;
    public string TrangThai { get; set; } = "Hoạt động";
    
    // ... other properties
}
```

### 2️⃣ **Helper Class - Tạo File `KhachHangIdGenerator.cs`**

```csharp
public static class KhachHangIdGenerator
{
    /// <summary>
    /// Sinh mã khách hàng tiếp theo
    /// Format: KH + số thứ tự (KH001, KH002, ...)
    /// </summary>
    public static string GenerateNextMaKH(ApplicationDbContext context)
    {
        try
        {
            // Lấy tất cả mã KH từ database
            var allMaKH = context.KhachHang
                .AsNoTracking()
                .Select(k => k.MaKH)
                .ToList();

            if (!allMaKH.Any())
            {
                return "KH001";  // ✅ Khách hàng đầu tiên
            }

            // Tìm số lớn nhất từ các mã KH hiện có
            var maxNumber = allMaKH
                .Where(m => m.StartsWith("KH") && m.Length >= 5)
                .Select(m =>
                {
                    if (int.TryParse(m.Substring(2), out var num))
                        return num;
                    return 0;
                })
                .DefaultIfEmpty(0)
                .Max();

            // Tính mã tiếp theo
            var nextNumber = maxNumber + 1;
            return $"KH{nextNumber:D3}";  // ✅ Format: KH + 3 chữ số (KH001, KH002, ...)
        }
        catch (Exception ex)
        {
            // Log lỗi nếu cần
            Console.WriteLine($"Lỗi khi sinh mã KH: {ex.Message}");
            return $"KH{DateTime.Now.Ticks % 1000000:D6}";  // ✅ Fallback: dùng timestamp
        }
    }
}
```

### 3️⃣ **Controller - POST /api/KhachHang**

```csharp
[ApiController]
[Route("api/[controller]")]
public class KhachHangController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public KhachHangController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpPost]
    public async Task<IActionResult> CreateKhachHang([FromBody] CreateKhachHangDto dto)
    {
        try
        {
            // ✅ Validation
            if (string.IsNullOrWhiteSpace(dto.TenKH))
                return BadRequest(new { message = "Tên khách hàng không được để trống" });

            if (string.IsNullOrWhiteSpace(dto.Email))
                return BadRequest(new { message = "Email không được để trống" });

            if (string.IsNullOrWhiteSpace(dto.SDT))
                return BadRequest(new { message = "Số điện thoại không được để trống" });

            if (string.IsNullOrWhiteSpace(dto.DiaChi))
                return BadRequest(new { message = "Địa chỉ không được để trống" });

            // ✅ Sinh mã KH tự động
            var maKH = KhachHangIdGenerator.GenerateNextMaKH(_context);

            // ✅ Tạo đối tượng khách hàng
            var khachHang = new KhachHang
            {
                MaKH = maKH,
                TenKH = dto.TenKH.Trim(),
                Email = dto.Email.Trim(),
                SDT = dto.SDT.Trim(),
                DiaChi = dto.DiaChi.Trim(),
                AnhDaiDien = dto.AnhDaiDien ?? "",
                TenDangNhap = dto.TenDangNhap?.Trim() ?? "",
                NgayTao = DateTime.Now,
                TrangThai = "Hoạt động"
            };

            // ✅ Lưu vào database
            _context.KhachHang.Add(khachHang);
            await _context.SaveChangesAsync();

            // ✅ Return response với maKH mới được tạo
            return Ok(new
            {
                message = "Tạo khách hàng thành công",
                maKH = maKH,
                tenKH = khachHang.TenKH,
                email = khachHang.Email,
                sdt = khachHang.SDT,
                diaChi = khachHang.DiaChi
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
        }
    }

    [HttpPut("{maKH}")]
    public async Task<IActionResult> UpdateKhachHang(string maKH, [FromBody] UpdateKhachHangDto dto)
    {
        try
        {
            var khachHang = await _context.KhachHang.FindAsync(maKH);
            if (khachHang == null)
                return NotFound(new { message = "Khách hàng không tìm thấy" });

            // ✅ Cập nhật các trường được phép
            if (!string.IsNullOrWhiteSpace(dto.TenKH))
                khachHang.TenKH = dto.TenKH.Trim();

            if (!string.IsNullOrWhiteSpace(dto.Email))
                khachHang.Email = dto.Email.Trim();

            if (!string.IsNullOrWhiteSpace(dto.SDT))
                khachHang.SDT = dto.SDT.Trim();

            if (!string.IsNullOrWhiteSpace(dto.DiaChi))
                khachHang.DiaChi = dto.DiaChi.Trim();

            if (!string.IsNullOrWhiteSpace(dto.AnhDaiDien))
                khachHang.AnhDaiDien = dto.AnhDaiDien.Trim();

            _context.KhachHang.Update(khachHang);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Cập nhật khách hàng thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
        }
    }

    [HttpGet("{maKH}")]
    public async Task<IActionResult> GetKhachHangByMaKH(string maKH)
    {
        try
        {
            var khachHang = await _context.KhachHang.FindAsync(maKH);
            if (khachHang == null)
                return NotFound(new { message = "Khách hàng không tìm thấy" });

            return Ok(new
            {
                maKH = khachHang.MaKH,
                tenKH = khachHang.TenKH,
                email = khachHang.Email,
                sdt = khachHang.SDT,
                diaChi = khachHang.DiaChi,
                anhDaiDien = khachHang.AnhDaiDien
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
        }
    }
}
```

### 4️⃣ **DTOs - File `KhachHangDto.cs`**

```csharp
public class CreateKhachHangDto
{
    public string TenKH { get; set; }
    public string Email { get; set; }
    public string SDT { get; set; }
    public string DiaChi { get; set; }
    public string AnhDaiDien { get; set; }
    public string TenDangNhap { get; set; }  // ✅ Để link với TaiKhoan
}

public class UpdateKhachHangDto
{
    public string TenKH { get; set; }
    public string Email { get; set; }
    public string SDT { get; set; }
    public string DiaChi { get; set; }
    public string AnhDaiDien { get; set; }
}
```

### 5️⃣ **Database Migration (nếu bổ sung cột mới)**

```bash
# Terminal - chạy lệnh
dotnet ef migrations add AddKhachHangAutoId

dotnet ef database update
```

Hoặc manual SQL:

```sql
-- Nếu cột MaKH chưa là Primary Key
ALTER TABLE KhachHang
ADD CONSTRAINT PK_KhachHang PRIMARY KEY (MaKH);

-- Thêm cột NgayTao (nếu chưa có)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='KhachHang' AND COLUMN_NAME='NgayTao')
BEGIN
    ALTER TABLE KhachHang ADD NgayTao DATETIME DEFAULT GETDATE();
END

-- Thêm cột TrangThai (nếu chưa có)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='KhachHang' AND COLUMN_NAME='TrangThai')
BEGIN
    ALTER TABLE KhachHang ADD TrangThai NVARCHAR(50) DEFAULT N'Hoạt động';
END
```

## 🧪 Test API

### Request:
```bash
POST /api/KhachHang
Content-Type: application/json

{
    "tenKH": "Nguyễn Văn A",
    "email": "nguyenvana@gmail.com",
    "sdt": "0912345678",
    "diaChi": "Hà Nội",
    "anhDaiDien": "",
    "tenDangNhap": "user123"
}
```

### Response (200 OK):
```json
{
    "message": "Tạo khách hàng thành công",
    "maKH": "KH001",
    "tenKH": "Nguyễn Văn A",
    "email": "nguyenvana@gmail.com",
    "sdt": "0912345678",
    "diaChi": "Hà Nội"
}
```

## ✅ Checklist

- [ ] Tạo class `KhachHangIdGenerator.cs`
- [ ] Cập nhật `KhachHangController.cs` - POST CreateKhachHang
- [ ] Tạo DTOs: `CreateKhachHangDto`, `UpdateKhachHangDto`
- [ ] Cập nhật model `KhachHang.cs` (thêm MaKH nếu chưa có)
- [ ] Run migration: `dotnet ef migrations add` + `dotnet ef database update`
- [ ] Test API với Postman hoặc curl
- [ ] Kiểm tra database - xác nhân mã KH được sinh đúng (KH001, KH002, ...)

## 🎯 Lợi Ích

✅ Mã khách hàng tự động sinh → không cần user nhập  
✅ Format chuẩn: `KH001`, `KH002`, `KH003`, ...  
✅ Tự động tăng số thứ tự  
✅ Không bị trùng lặp  
✅ Dễ quản lý và theo dõi  

---

**Ghi chú:** Nếu có lỗi khi sinh mã, hãy check:
1. Database có dữ liệu KhachHang cũ?
2. Format MaKH cũ có đúng không? (phải là `KH` + số)
3. Kiểm tra constraint Unique/Primary Key
