using Microsoft.AspNetCore.Mvc;
using sanphamapi.DTOs;
using sanphamapi.Services;

namespace sanphamapi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class KhuyenMaiController : ControllerBase
    {
        private readonly KhuyenMaiService _svc;
        public KhuyenMaiController(KhuyenMaiService svc) => _svc = svc;

        public class ApplyReq
        {
            public string MaSP { get; set; } = "";
            public int SoLuong { get; set; }
            public int DonGia { get; set; }
        }

        [HttpPost("apply")]
        public async Task<IActionResult> Apply([FromBody] ApplyReq req)
        {
            var result = await _svc.ApplyAllAsync(req.MaSP, req.SoLuong, req.DonGia);
            return Ok(result);
        }
    }
}
