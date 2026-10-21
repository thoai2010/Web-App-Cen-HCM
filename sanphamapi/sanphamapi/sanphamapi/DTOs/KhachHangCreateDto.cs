using System.ComponentModel.DataAnnotations;

namespace sanphamapi.DTOs
{
    public class KhachHangCreateDto
    {
        // ❌ KHÔNG REQUIRED → backend tự sinh
        public string? MaKH { get; set; }

        [Required]
        public string TenKH { get; set; } = "";

        [Required]
        public string DiaChi { get; set; } = "";

        [Required, EmailAddress]
        public string Email { get; set; } = "";

        [Required]
        public string SDT { get; set; } = "";

        [Required]
        public string TenDangNhap { get; set; } = "";

        public string? AnhDaiDien { get; set; }
    }
}
