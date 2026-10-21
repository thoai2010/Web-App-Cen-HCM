namespace QLBH.Models
{
    public class CartItem
    {
            public string MaSP { get; set; }
            public string TenSP { get; set; }
            public string DonViTinh { get; set; }
            public int GiaBan { get; set; }
            public int SoLuong { get; set; }
            public int SLTon { get; set; }
            public string HinhAnh { get; set; }
            public decimal KhuyenMai { get; set; }
            public decimal ThanhTienSauKM { get; set; }
            public bool IsSelected { get; set; } = true; 
            public decimal ThanhTien => GiaBan * SoLuong;
    }
}