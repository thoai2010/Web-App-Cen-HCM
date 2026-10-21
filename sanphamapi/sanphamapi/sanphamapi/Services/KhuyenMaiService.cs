using Microsoft.EntityFrameworkCore;
using sanphamapi.Data;
using sanphamapi.DTOs;

namespace sanphamapi.Services
{
    public class KhuyenMaiService
    {
        private readonly AppDbContext _db;
        public KhuyenMaiService(AppDbContext db) => _db = db;

        public async Task<ApplyKhuyenMaiResultDto> ApplyAllAsync(string maSP, int soLuong, int donGia)
        {
            var now = DateTime.Now;

            var list = await _db.ChiTietKM_SPs
                .Include(x => x.KhuyenMai)
                .Where(x =>
                    x.MaSP == maSP &&
                    soLuong >= x.SoLuongToiThieu &&
                    x.KhuyenMai!.NgayBD <= now &&
                    x.KhuyenMai.NgayKT >= now
                )
                .OrderBy(x => x.SoLuongToiThieu) // không quan trọng, vì áp tất cả
                .ToListAsync();

            var tongGoc = soLuong * donGia;
            var tienConLai = tongGoc;

            var applied = new List<AppliedKmDto>();

            foreach (var ct in list)
            {
                var km = ct.KhuyenMai!;
                int giamThem = 0;

                if (km.LoaiKM == "Tien")
                {
                    giamThem = (int)ct.TriGia;
                }
                else if (km.LoaiKM == "PhanTram")
                {
                    // % tính trên số tiền còn lại tại thời điểm áp
                    giamThem = (int)Math.Round(tienConLai * ((int)ct.TriGia) / 100.0);
                }

                if (giamThem <= 0) continue;

                // chặn âm
                if (giamThem > tienConLai) giamThem = tienConLai;

                tienConLai -= giamThem;

                applied.Add(new AppliedKmDto
                {
                    MaKM = km.MaKM.Trim(),
                    TenCT = km.TenCT,
                    LoaiKM = km.LoaiKM,
                    SoLuongToiThieu = ct.SoLuongToiThieu,
                    TriGia = (int)ct.TriGia,
                    SoTienGiam = giamThem
                });

                if (tienConLai <= 0) break;
            }

            return new ApplyKhuyenMaiResultDto
            {
                TongGoc = tongGoc,
                ThanhTien = tienConLai,
                Giam = tongGoc - tienConLai,
                Applied = applied
            };
        }
    }
}
