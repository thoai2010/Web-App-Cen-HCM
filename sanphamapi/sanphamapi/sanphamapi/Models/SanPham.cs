using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;



namespace sanphamapi.Models
{
    [Table("SanPham")]
    public class SanPham
    {
        [Key] 
        public string MaSP { get; set; }

        public string TenSP { get; set; }
        public int GiaBan { get; set; }
        public string Hinh { get; set; }
        public int SLTon { get; set; }
        public string MoTa { get; set; }
        public string MaLoai { get; set; }
        public LoaiSanPham? LoaiSanPham { get; set; }
    }
}
