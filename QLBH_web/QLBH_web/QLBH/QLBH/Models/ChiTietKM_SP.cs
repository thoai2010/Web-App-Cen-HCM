using System;
using System.ComponentModel.DataAnnotations;

namespace QLBH.Models
{
    public class ChiTietKM_SP
    {
        [Required]
        public string MaKM { get; set; }

        [Required]
        public string MaSP { get; set; }

        [Required]
        [Display(Name = "Trị giá")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Trị giá phải lớn hơn 0.")]
        public decimal TriGia { get; set; }

        [Display(Name = "Loại trị giá")]
        public string LoaiTriGia { get; set; }

        // Dữ liệu hiển thị thêm
        public string TenCT { get; set; }
        public string TenSP { get; set; }
    }
}
