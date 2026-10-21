using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QLBH.Models
{
    [Table("DanhGia")]
    public class DanhGia
    {
        [Key]
        [StringLength(10)]
        public string MaDG { get; set; }

        [Required]
        [StringLength(10)]
        public string MaKH { get; set; }

        [Required]
        [StringLength(10)]
        public string MaSP { get; set; }

        [Required]
        [StringLength(10)]
        public string MaDH { get; set; }

        [Required]
        [Range(1, 5)]
        public int SoSao { get; set; }

        [StringLength(500)]
        public string NoiDung { get; set; }

        public DateTime NgayDG { get; set; }

        // -----------------------
        // KHÓA NGOẠI
        // -----------------------
        [ForeignKey("MaKH")]
        public virtual KhachHangViewModel KhachHang { get; set; }

        [ForeignKey("MaSP")]
        public virtual SanPham SanPham { get; set; }

        [ForeignKey("MaDH")]
        public virtual DonHangViewModel DonHang { get; set; }
    }
}
