using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace QLBH.Models
{
    [Table("HoaDon")]
    public class HoaDon
    {
        [Key]
        [StringLength(10)]
        [Display(Name = "Mã hóa đơn")]
        public string MaHD { get; set; }

        [Display(Name = "Ngày lập")]
        [DataType(DataType.Date)]
        public DateTime? NgayLap { get; set; }

        [Display(Name = "Số tiền")]
        [Range(0, int.MaxValue, ErrorMessage = "Số tiền không hợp lệ")]
        public int SoTien { get; set; }

        [Display(Name = "Phương thức thanh toán")]
        public string PhuongThucThanhToan { get; set; }

        [Display(Name = "Mã nhân viên")]
        public string MaNV { get; set; }

        [Display(Name = "Mã đơn hàng")]
        public string MaDH { get; set; }

        // Các thuộc tính hiển thị thêm
        [NotMapped]
        [Display(Name = "Tên nhân viên")]
        public string TenNV { get; set; }

        [NotMapped]
        [Display(Name = "Tên khách hàng")]
        public string TenKH { get; set; }
        public List<ChiTietSPViewModel> ChiTietSP { get; set; }
    }

    public class ChiTietSPViewModel
    {
        public string TenSP { get; set; }
        public int SoLuong { get; set; }
        public int DonGia { get; set; }
    }
}
