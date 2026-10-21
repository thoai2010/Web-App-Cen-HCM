using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("HoaDon")]
    public class HoaDon
    {
        [Key]
        public string MaHD { get; set; } = null!;

        public DateTime NgayLap { get; set; }
        public int SoTien { get; set; }
        public string MaDH { get; set; } = null!;
        public string PhuongThucThanhToan { get; set; } = null!;

        [ForeignKey("MaDH")]
        public DonHang? DonHang { get; set; }

        public ICollection<CT_HoaDon> ChiTiet { get; set; } = new List<CT_HoaDon>();
    }
}
