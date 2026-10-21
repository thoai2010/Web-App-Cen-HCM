using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QLBH.Models
{
    public class DonHang
    {
        public string MaDH { get; set; }
        public DateTime? NgayDat { get; set; }
        public string TrangThai { get; set; }
        public int TongTien { get; set; }
        public string MaKH { get; set; }
    }
}
