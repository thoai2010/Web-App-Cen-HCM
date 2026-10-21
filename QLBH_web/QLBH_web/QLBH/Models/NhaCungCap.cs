using System;
using System.ComponentModel.DataAnnotations;

namespace QLBH.Models
{
    public class NhaCungCap
    {
        [Key]
        [Display(Name = "Mã nhà cung cấp")]
        public string MaNCC { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập tên nhà cung cấp")]
        [Display(Name = "Tên nhà cung cấp")]
        public string TenNCC { get; set; }

        [Display(Name = "Địa chỉ")]
        public string DiaChi { get; set; }

        [Display(Name = "Số điện thoại")]
        [RegularExpression(@"^0\d{9,10}$", ErrorMessage = "Số điện thoại không hợp lệ")]
        public string SDT { get; set; }
    }
}
