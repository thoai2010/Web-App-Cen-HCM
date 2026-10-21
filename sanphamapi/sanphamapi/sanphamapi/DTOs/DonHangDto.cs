namespace sanphamapi.DTOs
{
    // ===== TẠO ĐƠN =====
    public class TaoDonHangDto
    {
        public string? MaKH { get; set; }
        public string HoTen { get; set; } = "";
        public string DiaChi { get; set; } = "";
        public string SDT { get; set; } = "";
        public string Email { get; set; } = "";

        public string? PhuongThucThanhToan { get; set; } = "COD";

        public int TongSanPham { get; set; }
        public int TienGiam { get; set; }
        public int PhiVanChuyen { get; set; }
        public int TongTien { get; set; }

        public List<DonHangItemDto> Items { get; set; } = new();
    }

    public class DonHangItemDto
    {
        public string MaSP { get; set; } = "";
        public int SoLuong { get; set; }
    }

    // ===== TRẢ VỀ =====
    public class DonHangDto
    {
        public string MaDH { get; set; } = "";
        public DateTime NgayDat { get; set; }
        public string TrangThai { get; set; } = "";
        public int TongTien { get; set; }

        public string? MaKH { get; set; }
        public string HoTen { get; set; } = "";
        public string DiaChi { get; set; } = "";
        public string SDT { get; set; } = "";
        public string Email { get; set; } = "";

        public string? PhuongThucThanhToan { get; set; } = "COD";
        public List<DonHangChiTietDto> ChiTiet { get; set; } = new();
    }

    public class DonHangChiTietDto
    {
        public string MaSP { get; set; } = "";
        public string TenSP { get; set; } = "";
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
    }
}
