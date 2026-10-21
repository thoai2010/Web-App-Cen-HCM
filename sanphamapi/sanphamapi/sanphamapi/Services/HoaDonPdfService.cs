using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using sanphamapi.DTOs;

namespace sanphamapi.Services
{
    public class HoaDonPdfService
    {
        public byte[] Generate(HoaDonDto hoaDon)
        {
            var doc = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);
                    page.Size(PageSizes.A4);

                    page.Content().Column(col =>
                    {
                        col.Item().Text("HÓA ĐƠN BÁN HÀNG")
                            .FontSize(20)
                            .Bold()
                            .AlignCenter();

                        col.Item().Text($"Mã hóa đơn: {hoaDon.MaHD}");
                        col.Item().Text($"Ngày lập: {hoaDon.NgayLap:dd/MM/yyyy}");
                        col.Item().Text($"Thanh toán: {hoaDon.PhuongThucThanhToan}");
                        col.Item().Text($"Tổng tiền: {hoaDon.SoTien:N0} VNĐ");

                        col.Item().LineHorizontal(1);

                        col.Item().Table(table =>
                        {
                            table.ColumnsDefinition(c =>
                            {
                                c.RelativeColumn();
                                c.ConstantColumn(60);
                                c.ConstantColumn(80);
                            });

                            table.Header(h =>
                            {
                                h.Cell().Text("Sản phẩm").Bold();
                                h.Cell().Text("SL").Bold();
                                h.Cell().Text("Giá").Bold();
                            });

                            foreach (var ct in hoaDon.ChiTiet)
                            {
                                table.Cell().Text(ct.TenSP);
                                table.Cell().Text(ct.SoLuong.ToString());
                                table.Cell().Text(ct.DonGia.ToString("N0"));
                            }
                        });
                    });
                });
            });

            return doc.GeneratePdf();
        }
    }
}
