using sanphamapi.DTOs;

namespace sanphamapi.Services
{
    public class CartService
    {
        public List<CartItemDto> Items { get; } = new();
        public int TongTien => Items.Sum(x => x.SoLuong * x.DonGia);
    }
}
