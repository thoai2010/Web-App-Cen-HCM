using System.ComponentModel.DataAnnotations;

namespace sanphamapi.DTOs
{
    public class KhachHangUpdateDto
    {
        [Required]
        public string MaKH { get; set; } = "";

        [Required]
        public string TenKH { get; set; } = "";

        [Required]
        public string DiaChi { get; set; } = "";

        [Required, EmailAddress]
        public string Email { get; set; } = "";

        [Required]
        public string SDT { get; set; } = "";

        public string? AnhDaiDien { get; set; }
    }
}
