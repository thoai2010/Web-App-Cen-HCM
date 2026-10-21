using System;
using System.Collections.Generic;

namespace QLBH.Models.ViewModels
{
    public class PhieuXuLyViewModel
    {
        public string MaPX { get; set; }
        public string MaDH { get; set; }
        public string TenKhachHang { get; set; }
        public string LoaiXuLy { get; set; }
        public string LyDo { get; set; }
        public string GhiChu { get; set; }
        public string TrangThaiPX { get; set; }
        public DateTime NgayLap { get; set; }

        public string SoDienThoai { get; set; }
        public string DiaChi { get; set; }

        public List<CTPhieuXuLyVM> ChiTiet { get; set; } = new List<CTPhieuXuLyVM>();
    }

    public class CTPhieuXuLyVM
    {
        public string MaSP { get; set; }
        public string TenSanPham { get; set; }
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
    }
}
