using System.ComponentModel.DataAnnotations;

namespace sanphamapi.Models
{
    public class DonHang
    {
        [Key] // ✅ thêm
        public string MaDH { get; set; } = "";

        public DateTime NgayDat { get; set; }
        public string TrangThai { get; set; } = "";
        public int TongTien { get; set; }

        public string? MaKH { get; set; }
        public string HoTen { get; set; } = "";
        public string DiaChi { get; set; } = "";
        public string SDT { get; set; } = "";
        public string Email { get; set; } = "";

        public string PhuongThucThanhToan { get; set; } = "COD";
        public ICollection<CT_DonHang_SP> ChiTiet { get; set; } = new List<CT_DonHang_SP>();
    }
}
