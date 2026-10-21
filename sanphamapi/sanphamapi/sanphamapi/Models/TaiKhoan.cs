using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("TaiKhoan")]
    public class TaiKhoan
    {
        [Key]
        [Required]
        public string TenDangNhap { get; set; }

        [Required]
        public string MatKhau { get; set; }

        public string VaiTro { get; set; }
        public string TrangThai { get; set; }
        public KhachHang? KhachHang { get; set; }
    }
}
