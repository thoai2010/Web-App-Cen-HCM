using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("KhachHang")]
    public class KhachHang
    {
        [Key]
        public string MaKH { get; set; } = null!;
        public string TenKH { get; set; } = null!;
        public string DiaChi { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string SDT { get; set; } = null!;

        // ✅ FK đúng: KhachHang.TenDangNhap -> TaiKhoan.TenDangNhap
        public string TenDangNhap { get; set; } = null!;
        public string? AnhDaiDien { get; set; }

        public TaiKhoan? TaiKhoan { get; set; }
    }
}
