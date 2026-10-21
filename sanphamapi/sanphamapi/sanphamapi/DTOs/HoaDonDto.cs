namespace sanphamapi.DTOs
{
    public class HoaDonDto
    {
        public string MaHD { get; set; } = "";
        public DateTime NgayLap { get; set; }
        public int SoTien { get; set; }
        public string PhuongThucThanhToan { get; set; } = "";
        public List<HoaDonChiTietDto> ChiTiet { get; set; } = new();
    }

    public class HoaDonChiTietDto
    {
        public string MaSP { get; set; } = "";
        public string TenSP { get; set; } = "";
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
    }

    public class ThanhToanDto
    {
        public string MaDH { get; set; } = "";
        public string PhuongThucThanhToan { get; set; } = "";
    }
}
