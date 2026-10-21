using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace sanphamapi.Models
{
    [Table("KhuyenMai")]
    public class KhuyenMai
    {
        [Key]
        public string MaKM { get; set; } = null!;

        public string TenCT { get; set; } = null!;
        public DateTime NgayBD { get; set; }
        public DateTime NgayKT { get; set; }
        public string LoaiKM { get; set; } = null!;
        public string MoTa { get; set; } = null!;

        public ICollection<ChiTietKM_SP> ChiTietSanPham { get; set; } = new List<ChiTietKM_SP>();
    }
}
