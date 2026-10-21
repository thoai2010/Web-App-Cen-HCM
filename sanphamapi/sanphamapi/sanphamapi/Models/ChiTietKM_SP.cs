using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("ChiTietKM_SP")]
    public class ChiTietKM_SP
    {
        public string MaKM { get; set; } = null!;
        public string MaSP { get; set; } = null!;
        public int SoLuongToiThieu { get; set; }
        public decimal TriGia { get; set; }

        [ForeignKey("MaKM")]
        public KhuyenMai? KhuyenMai { get; set; }

        [ForeignKey("MaSP")]
        public SanPham? SanPham { get; set; }
    }
}
