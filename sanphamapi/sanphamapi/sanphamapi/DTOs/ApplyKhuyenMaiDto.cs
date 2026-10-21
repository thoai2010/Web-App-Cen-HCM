namespace sanphamapi.DTOs
{
    public class ApplyKhuyenMaiResultDto
    {
        public int TongGoc { get; set; }
        public int ThanhTien { get; set; }
        public int Giam { get; set; }
        public List<AppliedKmDto> Applied { get; set; } = new();
    }

    public class AppliedKmDto
    {
        public string MaKM { get; set; } = "";
        public string TenCT { get; set; } = "";
        public string LoaiKM { get; set; } = ""; // Tien | PhanTram
        public int SoLuongToiThieu { get; set; }
        public int TriGia { get; set; }
        public int SoTienGiam { get; set; } // số tiền giảm thực tế của KM này
    }
}
