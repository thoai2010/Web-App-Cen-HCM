using System.Collections.Generic;

namespace QLBH.Models
{
    public class ThongKeViewModel
    {
        // Tổng hợp
        public decimal TongDoanhThu { get; set; }
        public decimal TongCongNo { get; set; }
        public int SoLuongNhap { get; set; }          
        public int SoLuongTonKho { get; set; }      
        public int TongSanPham { get; set; }         
        public int TongKhachHang { get; set; }        

        // Dữ liệu biểu đồ cột (doanh thu & công nợ theo tháng)
        public List<string> Thang { get; set; } = new List<string>();
        public List<decimal> DoanhThuThang { get; set; } = new List<decimal>();
        public List<decimal> CongNoThang { get; set; } = new List<decimal>();

        // Dữ liệu biểu đồ tròn (tỷ lệ sản phẩm theo loại)
        public List<string> TenLoaiSP { get; set; } = new List<string>();
        public List<int> SoLuongTheoLoai { get; set; } = new List<int>();
    }
}
