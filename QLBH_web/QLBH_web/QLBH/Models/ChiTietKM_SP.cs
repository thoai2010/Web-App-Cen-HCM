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

        [Display(Name = "Số lượng tối thiểu")]
        public int SoLuongToiThieu { get; set; }

        [Display(Name = "Trị giá khuyến mãi")]
        public decimal TriGia { get; set; }

        public string TenCT { get; set; }
        public string TenSP { get; set; }
    }
}
