using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("DanhGia")]
    public class DanhGia
    {
        [Key]
        public string MaDG { get; set; } = null!;

        public string MaKH { get; set; } = null!;
        public string MaSP { get; set; } = null!;
        public string MaDH { get; set; } = null!;

        public int SoSao { get; set; }
        public string? NoiDung { get; set; }
        public DateTime NgayDG { get; set; }

        [ForeignKey("MaKH")]
        public KhachHang? KhachHang { get; set; }

        [ForeignKey("MaSP")]
        public SanPham? SanPham { get; set; }

        [ForeignKey("MaDH")]
        public DonHang? DonHang { get; set; }
    }
}
