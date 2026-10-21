using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("CT_DonHang_SP")]
    public class CT_DonHang_SP
    {
        public string MaDH { get; set; } = null!;
        public string MaSP { get; set; } = null!;
        public int SoLuong { get; set; }
        public int DonGia { get; set; }

        [ForeignKey("MaDH")]
        public DonHang? DonHang { get; set; }

        [ForeignKey("MaSP")]
        public SanPham? SanPham { get; set; }
    }
}
