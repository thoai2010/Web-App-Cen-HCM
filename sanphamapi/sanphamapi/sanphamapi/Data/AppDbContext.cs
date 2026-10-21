using Microsoft.EntityFrameworkCore;
using sanphamapi.Models;

namespace sanphamapi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<TaiKhoan> TaiKhoans { get; set; }
        public DbSet<KhachHang> KhachHangs { get; set; }
        public DbSet<SanPham> SanPhams { get; set; }
        public DbSet<KhuyenMai> KhuyenMais { get; set; }
        public DbSet<DanhGia> DanhGias { get; set; }
        public DbSet<ChiTietKM_SP> ChiTietKM_SPs { get; set; }
        public DbSet<DonHang> DonHangs { get; set; }
        public DbSet<CT_DonHang_SP> CT_DonHang_SPs { get; set; }
        public DbSet<HoaDon> HoaDons { get; set; }
        public DbSet<CT_HoaDon> CT_HoaDons { get; set; }
        public DbSet<LoaiSanPham> LoaiSanPhams { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // ✅ MAP ĐÚNG TÊN BẢNG
            modelBuilder.Entity<DonHang>().ToTable("DonHang");
            modelBuilder.Entity<CT_DonHang_SP>().ToTable("CT_DonHang_SP");
            modelBuilder.Entity<HoaDon>().ToTable("HoaDon");
            modelBuilder.Entity<CT_HoaDon>().ToTable("CT_HoaDon");
            modelBuilder.Entity<SanPham>().ToTable("SanPham");
            modelBuilder.Entity<LoaiSanPham>().ToTable("LoaiSanPham");
            modelBuilder.Entity<TaiKhoan>().ToTable("TaiKhoan");
            modelBuilder.Entity<KhachHang>().ToTable("KhachHang");
            modelBuilder.Entity<KhuyenMai>().ToTable("KhuyenMai");
            modelBuilder.Entity<DanhGia>().ToTable("DanhGia");
            modelBuilder.Entity<ChiTietKM_SP>().ToTable("ChiTietKM_SP");

            // =========================
            // ✅ SỬA QUAN HỆ TAIKHOAN - KHACHHANG (1-1) THEO TenDangNhap
            // =========================

            // KhachHang.TenDangNhap phải unique (vì là 1-1)
            modelBuilder.Entity<KhachHang>()
                .HasIndex(k => k.TenDangNhap)
                .IsUnique();

            // TaiKhoan (PK TenDangNhap) <-> KhachHang (FK TenDangNhap)
            modelBuilder.Entity<TaiKhoan>()
                .HasOne(t => t.KhachHang)
                .WithOne(kh => kh.TaiKhoan)
                .HasForeignKey<KhachHang>(kh => kh.TenDangNhap)
                .HasPrincipalKey<TaiKhoan>(t => t.TenDangNhap);

            // ✅ KEY DonHang
            modelBuilder.Entity<DonHang>().HasKey(x => x.MaDH);

            // ====== CT_DonHang_SP ======
            modelBuilder.Entity<CT_DonHang_SP>()
                .HasKey(x => new { x.MaDH, x.MaSP });

            modelBuilder.Entity<CT_DonHang_SP>()
                .HasOne(x => x.SanPham)
                .WithMany()
                .HasForeignKey(x => x.MaSP);

            modelBuilder.Entity<CT_DonHang_SP>()
                .HasOne(x => x.DonHang)
                .WithMany(x => x.ChiTiet)
                .HasForeignKey(x => x.MaDH);

            // ====== CT_HoaDon ======
            modelBuilder.Entity<CT_HoaDon>()
                .HasKey(x => new { x.MaHD, x.MaSP });

            modelBuilder.Entity<CT_HoaDon>()
                .HasOne(x => x.SanPham)
                .WithMany()
                .HasForeignKey(x => x.MaSP);

            // ====== ChiTietKM_SP ======
            modelBuilder.Entity<ChiTietKM_SP>()
                .HasKey(x => new { x.MaKM, x.MaSP });

            modelBuilder.Entity<ChiTietKM_SP>()
                .HasOne(x => x.SanPham)
                .WithMany()
                .HasForeignKey(x => x.MaSP);

            // ✅ SanPham - LoaiSanPham
            modelBuilder.Entity<SanPham>()
                .HasOne(sp => sp.LoaiSanPham)
                .WithMany(l => l.SanPhams)
                .HasForeignKey(sp => sp.MaLoai);

            base.OnModelCreating(modelBuilder);
        }
    }
}
