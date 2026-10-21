using System;
using System.Collections.Generic;

namespace QLBH.Models
{
    public class DonHangViewModel
    {
        public string MaDH { get; set; }
        public DateTime NgayDat { get; set; }
        public string TrangThai { get; set; }
        public int TongTien { get; set; }
        public string MaKH { get; set; }

        public string HoTen { get; set; }
        public string DiaChi { get; set; }
        public string SDT { get; set; }
        public string Email { get; set; }

        public List<ChiTietDonHang> ChiTiet { get; set; }
    }

    public class ChiTietDonHang
    {
        public string MaSP { get; set; }
        public string TenSP { get; set; }
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
        public int ThanhTien => SoLuong * DonGia;
    }
}
