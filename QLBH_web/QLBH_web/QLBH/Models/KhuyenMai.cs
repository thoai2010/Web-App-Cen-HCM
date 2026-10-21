using System;
using System.ComponentModel.DataAnnotations;

namespace QLBH.Models
{
    public class KhuyenMai
    {
        [Required(ErrorMessage = "Mã khuyến mãi là bắt buộc.")]
        public string MaKM { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập tên chương trình.")]
        [StringLength(100, ErrorMessage = "Tên chương trình không được quá 100 ký tự.")]
        public string TenCT { get; set; }

        public string MoTa { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày bắt đầu.")]
        [DataType(DataType.Date)]
        public DateTime NgayBD { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn ngày kết thúc.")]
        [DataType(DataType.Date)]
        public DateTime NgayKT { get; set; }

        [Required]
        public string LoaiKM { get; set; } 
    }
}
