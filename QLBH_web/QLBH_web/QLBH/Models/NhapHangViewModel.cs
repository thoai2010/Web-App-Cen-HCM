using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace QLBH.Models
{
    public class NhapHangViewModel
    {
        public string MaPNH { get; set; }
        public string MaNV { get; set; }
        public string TenNV { get; set; }
        public string MaNCC { get; set; }
        public string TenNCC { get; set; }
        public string MaSP { get; set; }
        public string TenSP { get; set; }
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
        public int? TongTien { get; set; }
        public decimal ThanhTien => SoLuong * DonGia;
        public string TrangThai { get; set; }
        public DateTime NgayNhap { get; set; }
    }
}