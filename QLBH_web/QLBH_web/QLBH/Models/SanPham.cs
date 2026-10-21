using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace QLBH.Models
{
    public class SanPham
    {
        public string MaSP { get; set; }
        public string TenSP { get; set; }
        public string MoTa { get; set; }
        public string DonViTinh { get; set; }
        public int GiaBan { get; set; }
        public int SLTon { get; set; }
        public string Hinh { get; set; }
        public string MaLoai { get; set; }
        public string TenLoai { get; set; }

    }
    public class LoaiSanPham
    {
        public string MaLoai { get; set; }
        public string TenLoai { get; set; }
        public string MoTa { get; set; }
    }
}