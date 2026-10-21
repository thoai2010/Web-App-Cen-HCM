namespace sanphamapi.DTOs
{
    public class DanhGiaDto
    {
        public string MaDG { get; set; } = "";
        public string MaSP { get; set; } = "";
        public int SoSao { get; set; }
        public string? NoiDung { get; set; }
        public DateTime NgayDG { get; set; }
    }
}
