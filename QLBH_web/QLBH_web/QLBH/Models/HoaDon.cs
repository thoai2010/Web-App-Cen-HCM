using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QLBH.Models
{
    [Table("HoaDon")]
    public class HoaDon
    {
        [Key]
        [StringLength(10)]
        public string MaHD { get; set; }

        [DataType(DataType.Date)]
        public DateTime? NgayLap { get; set; }

        [Range(0, int.MaxValue)]
        public int SoTien { get; set; }

        public string PhuongThucThanhToan { get; set; }
        public string MaDH { get; set; }

        [NotMapped] public string TenKH { get; set; }

        public List<ChiTietSPViewModel> ChiTietSP { get; set; }
    }

    public class ChiTietSPViewModel
    {
        public string TenSP { get; set; }
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
    }
}
