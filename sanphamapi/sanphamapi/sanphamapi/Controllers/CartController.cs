using Microsoft.AspNetCore.Mvc;
using sanphamapi.Services;
using sanphamapi.DTOs;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CartController : ControllerBase
    {
        private static CartService cart = new();

        [HttpPost("add")]
        public IActionResult Add(AddToCartDto dto)
        {
            cart.Items.Add(new CartItemDto
            {
                MaSP = dto.MaSP,
                SoLuong = dto.SoLuong,
                DonGia = 10000
            });

            return Ok(cart);
        }

        [HttpGet]
        public IActionResult Get() => Ok(cart);
    }
}
