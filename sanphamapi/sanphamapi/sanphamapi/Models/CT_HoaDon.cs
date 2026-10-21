using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("CT_HoaDon")]
    public class CT_HoaDon
    {
        public string MaHD { get; set; } = null!;
        public string MaSP { get; set; } = null!;
        public int SoLuong { get; set; }
        public int DonGia { get; set; }

        [ForeignKey("MaHD")]
        public HoaDon? HoaDon { get; set; }

        [ForeignKey("MaSP")]
        public SanPham? SanPham { get; set; }
    }
}
