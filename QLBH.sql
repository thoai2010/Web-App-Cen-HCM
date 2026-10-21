--USE master;
--GO
--ALTER DATABASE QLBHHC SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--DROP DATABASE QLBHHC;
--GO


--CREATE DATABASE QLBHHC;
--GO
--USE QLBHHC;
--GO


CREATE TABLE TaiKhoan (
    TenDangNhap NVARCHAR(50) PRIMARY KEY,
    MatKhau NVARCHAR(100) NOT NULL CHECK(LEN(MatKhau) >= 6),
    VaiTro NVARCHAR(50) NOT NULL CHECK(VaiTro IN (N'Admin', N'NhanVien', N'KhachHang')),
	TrangThai NVARCHAR(20) DEFAULT N'Hoạt động' CHECK (TrangThai IN (N'Hoạt động', N'Khóa', N'Ngừng sử dụng'))
);

CREATE TABLE NhaCungCap (
    MaNCC CHAR(10) PRIMARY KEY,
    TenNCC NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(255),
    SDT VARCHAR(15) CHECK(SDT LIKE '[0-9]%')
);

CREATE TABLE LoaiSanPham (
    MaLoai CHAR(10) PRIMARY KEY,
    TenLoai NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE SanPham (
    MaSP CHAR(10) PRIMARY KEY,
    TenSP NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(MAX),
    DonViTinh NVARCHAR(20),
    GiaBan INT CHECK(GiaBan > 0),
    SLTon INT CHECK(SLTon >= 0),
	Hinh NVARCHAR(255) NULL,
    MaLoai CHAR(10) NOT NULL,
    FOREIGN KEY (MaLoai) REFERENCES LoaiSanPham(MaLoai)
);

CREATE TABLE NhanVien (
    MaNV CHAR(10) PRIMARY KEY,
    TenNV NVARCHAR(100) NOT NULL,
    ChucVu NVARCHAR(50),
    Email NVARCHAR(100) UNIQUE CHECK(Email LIKE '%@%.%'),
    SDT VARCHAR(15) CHECK(SDT LIKE '[0-9]%'),
    TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
	AnhDaiDien NVARCHAR(255) NULL,
    FOREIGN KEY (TenDangNhap) REFERENCES TaiKhoan(TenDangNhap)
);

CREATE TABLE KhachHang (
    MaKH CHAR(10) PRIMARY KEY,
    TenKH NVARCHAR(100) NOT NULL,
    DiaChi NVARCHAR(255),
    Email NVARCHAR(100) UNIQUE CHECK(Email LIKE '%@%.%'),
    SDT VARCHAR(15) CHECK(SDT LIKE '[0-9]%'),
    TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
	AnhDaiDien NVARCHAR(255) NULL,
    FOREIGN KEY (TenDangNhap) REFERENCES TaiKhoan(TenDangNhap)
);

CREATE TABLE DonHang (
    MaDH CHAR(10) PRIMARY KEY,
    NgayDat DATETIME DEFAULT GETDATE(),
    TrangThai NVARCHAR(50) CHECK (TrangThai IN (N'Đang xử lý', N'Đang giao hàng', N'Hoàn thành', N'Đã hủy')),
    TongTien INT CHECK (TongTien >= 0),
	MaKH CHAR(10) NULL,
	HoTen NVARCHAR(100),
    DiaChi NVARCHAR(255),
    SDT VARCHAR(15),
    Email NVARCHAR(100),
    PhuongThucThanhToan NVARCHAR(100),
    CONSTRAINT FK_DonHang_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);

CREATE TABLE CT_DonHang_SP (
    MaDH CHAR(10) NOT NULL,
    MaSP CHAR(10) NOT NULL,
    SoLuong INT CHECK(SoLuong > 0),
    DonGia INT CHECK(DonGia > 0),
    PRIMARY KEY (MaDH, MaSP),
    CONSTRAINT FK_CTDonHang_DonHang FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH),
    CONSTRAINT FK_CTDonHang_SanPham FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
);

CREATE TABLE HoaDon (
    MaHD CHAR(10) PRIMARY KEY,
    NgayLap DATE DEFAULT GETDATE(),
    SoTien INT CHECK (SoTien >= 0),
    MaDH CHAR(10) NOT NULL UNIQUE,
    MaKH CHAR(10) NOT NULL,                     
   
    FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH),
    CONSTRAINT FK_HoaDon_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);

CREATE TABLE CT_HoaDon (
    MaHD CHAR(10) NOT NULL,              
    MaSP CHAR(10) NOT NULL,             
    SoLuong INT ,     
    DonGia INT ,     
    CONSTRAINT PK_CT_HoaDon PRIMARY KEY (MaHD, MaSP),  
    CONSTRAINT FK_CT_HoaDon_HoaDon FOREIGN KEY (MaHD) REFERENCES HoaDon(MaHD),
    CONSTRAINT FK_CT_HoaDon_SanPham FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
);

CREATE TABLE DanhGia (
    MaDG CHAR(10) PRIMARY KEY,
    MaKH CHAR(10) NOT NULL,
    MaSP CHAR(10) NOT NULL,
    MaDH CHAR(10) NOT NULL,
    SoSao INT NOT NULL CHECK (SoSao BETWEEN 1 AND 5),
    NoiDung NVARCHAR(500),
    NgayDG DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_DanhGia_SanPham FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP),
    CONSTRAINT FK_DanhGia_DonHang FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH),

    -- Khách chỉ đánh giá sản phẩm này 1 lần trong 1 đơn hàng
    CONSTRAINT UQ_DanhGia UNIQUE (MaKH, MaSP, MaDH)
);

CREATE TABLE PhieuNhapHang (
    MaPNH CHAR(10) PRIMARY KEY,
    NgayNhap DATE DEFAULT GETDATE(),
    TongTien INT CHECK(TongTien >= 0),
    MaNV CHAR(10) NOT NULL,
    MaNCC CHAR(10) NOT NULL,
    FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV),
    FOREIGN KEY (MaNCC) REFERENCES NhaCungCap(MaNCC)
);

CREATE TABLE CT_PhieuNhapHang (
    MaPNH CHAR(10) NOT NULL,
    MaSP CHAR(10) NOT NULL,
    SoLuong INT CHECK(SoLuong > 0),
    DonGia INT CHECK(DonGia > 0),
    PRIMARY KEY (MaPNH, MaSP),
    FOREIGN KEY (MaPNH) REFERENCES PhieuNhapHang(MaPNH),
    FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
);

CREATE TABLE PhieuXuLyDH (
    MaPX CHAR(12) PRIMARY KEY,         
    MaDH CHAR(10) NOT NULL,            
    LoaiXuLy NVARCHAR(20) NOT NULL,    
    TrangThaiPX NVARCHAR(30) DEFAULT N'Chờ xử lý',  -- 'Chờ xử lý', 'Đã duyệt', 'Từ chối'
    LyDo NVARCHAR(255) NULL,
    GhiChu NVARCHAR(500) NULL,
    NgayLap DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_PX_DonHang FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH)
);

CREATE TABLE CT_PhieuXuLy (
    MaPX CHAR(12) NOT NULL,
    MaSP CHAR(10) NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia INT NOT NULL CHECK (DonGia >= 0),
    PRIMARY KEY (MaPX, MaSP),
    CONSTRAINT FK_CTPX_PX FOREIGN KEY (MaPX) REFERENCES PhieuXuLyDH(MaPX),
    CONSTRAINT FK_CTPX_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
);

CREATE TABLE KhuyenMai (
    MaKM CHAR(10) PRIMARY KEY,
    TenCT NVARCHAR(100),
    NgayBD DATE NOT NULL,
    NgayKT DATE NOT NULL,
    LoaiKM NVARCHAR(20),          -- 'Tien' hoặc 'PhanTram'
    MoTa NVARCHAR(255)
);

CREATE TABLE ChiTietKM_SP (
    MaKM CHAR(10) NOT NULL,
    MaSP CHAR(10) NOT NULL,
    SoLuongToiThieu INT NOT NULL,
    TriGia DECIMAL(12,2) NOT NULL,    -- số tiền hoặc %
    PRIMARY KEY (MaKM, MaSP),
    FOREIGN KEY (MaKM) REFERENCES KhuyenMai(MaKM),
    FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP)
);


CREATE TABLE BaoCao (
    MaBC CHAR(10) PRIMARY KEY,
    NoiDung NVARCHAR(255),
    NgayLap DATE DEFAULT GETDATE(),
    MaNV CHAR(10) NOT NULL,
    FOREIGN KEY (MaNV) REFERENCES NhanVien(MaNV)
);
GO


--  TẠO ROLE PHÂN QUYỀN

CREATE ROLE admin;
CREATE ROLE nhanvien;
CREATE ROLE khachhang;
GO


-- TẠO LOGIN VÀ USER CHO ROLE

-- ===========================================
-- TẠO LOGIN + USER CHO ROLE: ADMIN
-- ===========================================
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'admin_login')
    CREATE LOGIN admin_login WITH PASSWORD = '123456';
GO

USE QLBHHC;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'admin_user')
    CREATE USER admin_user FOR LOGIN admin_login;
GO

EXEC sp_addrolemember 'admin', 'admin_user';
GO

-- ===========================================
-- NHÂN VIÊN
-- ===========================================
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'nv_login')
    CREATE LOGIN nv_login WITH PASSWORD = '123456';
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'nv_user')
    CREATE USER nv_user FOR LOGIN nv_login;
GO

EXEC sp_addrolemember 'nhanvien', 'nv_user';
GO

-- ===========================================
-- KHÁCH HÀNG
-- ===========================================
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'kh_login')
    CREATE LOGIN kh_login WITH PASSWORD = '123456';
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'kh_user')
    CREATE USER kh_user FOR LOGIN kh_login;
GO

EXEC sp_addrolemember 'khachhang', 'kh_user';
GO


-- PHÂN QUYỀN

GRANT SELECT, INSERT, UPDATE, DELETE ON DATABASE::QLBHHC TO admin;
GRANT CONTROL ON DATABASE::QLBHHC TO admin;

GRANT SELECT, INSERT, UPDATE ON SanPham TO nhanvien;
GRANT SELECT, INSERT, UPDATE ON DonHang TO nhanvien;
GRANT SELECT, INSERT, UPDATE ON PhieuNhapHang TO nhanvien;
GRANT SELECT, INSERT, UPDATE ON BaoCao TO nhanvien;

GRANT SELECT ON SanPham TO khachhang;
GRANT SELECT ON KhuyenMai TO khachhang;
GRANT INSERT ON DonHang TO khachhang;
GRANT INSERT ON CT_DonHang_SP TO khachhang;
GO



USE QLBHHC;
GO

/***********************
1) NHÀ CUNG CẤP (10)
************************/
INSERT INTO NhaCungCap (MaNCC, TenNCC, DiaChi, SDT) VALUES
('NCC001', N'Công ty Hóa Chất ABC', N'12 Nguyễn Trãi, HCM', '0908123456'),
('NCC002', N'Công ty Hóa Chất Bắc Hà', N'45 Lý Thường Kiệt, HN', '0912333444'),
('NCC003', N'TM Hóa Chất Miền Trung', N'23 CMT8, ĐN', '0909777666'),
('NCC004', N'Hóa Chất An Phát', N'78 Trần Phú, ĐN', '0988999000'),
('NCC005', N'Việt Hóa Supply', N'15 Nguyễn Huệ, Cần Thơ', '0977554433'),
('NCC006', N'Hóa Chất Minh Anh', N'21 Võ Văn Kiệt, HCM', '0909778899'),
('NCC007', N'Dung Môi Á Đông', N'56 Trần Hưng Đạo, HN', '0935667788'),
('NCC008', N'Vật Tư Hóa Chất Đông Nam', N'12 Phan Chu Trinh, Đồng Nai', '0908009009'),
('NCC009', N'Dược Phẩm Hóa Chất Sài Gòn', N'34 Điện Biên Phủ, TP.HCM', '0907666555'),
('NCC010', N'Hóa Chất Toàn Quốc', N'99 Trần Hưng Vượng, HCM', '0911222333');
GO


/***********************
2) LOẠI SẢN PHẨM (13)
************************/
INSERT INTO LoaiSanPham (MaLoai, TenLoai) VALUES
('LSP001', N'Dung môi hữu cơ'),
('LSP002', N'Axit vô cơ'),
('LSP003', N'Bazơ'),
('LSP004', N'Muối vô cơ'),
('LSP005', N'Hóa chất thí nghiệm'),
('LSP006', N'Hóa chất tẩy rửa'),
('LSP007', N'Hóa chất công nghiệp'),
('LSP008', N'Hóa chất tinh khiết'),
('LSP009', N'Dung dịch đệm'),
('LSP010', N'Dung dịch chuẩn'),
('LSP011', N'Polymer & phụ gia'),
('LSP012', N'Hóa chất nông nghiệp'),
('LSP013', N'Khoáng & phụ gia');
GO

/***********************
3) SẢN PHẨM (190)
************************/
INSERT INTO SanPham (MaSP, TenSP, MoTa, DonViTinh, GiaBan, SLTon, MaLoai, Hinh) VALUES
('SP001', N'Ethanol 99.9% tinh khiết phân tích',
N'Dung môi hữu cơ có độ tinh khiết cao, bay hơi nhanh và không để lại cặn.
Thường được sử dụng để rửa sạch dụng cụ thí nghiệm và khử trùng bề mặt.
Ứng dụng trong dược phẩm, mỹ phẩm, công nghiệp thực phẩm và phòng thí nghiệm.
Sản phẩm đạt tiêu chuẩn phân tích AR (Analytical Reagent) với độ tinh khiết ≥99.9%.
Bảo quản nơi khô ráo, thoáng mát, tránh nguồn nhiệt và ánh sáng trực tiếp.
Khi thao tác cần sử dụng găng tay và khẩu trang để tránh hít phải hơi cồn.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Chai 500ml', 120000, 100, 'LSP001',  N'sp001.png'),

('SP002', N'Toluene (C₆H₅CH₃) dung môi công nghiệp',
N'Dung môi hydrocacbon thơm, không tan trong nước nhưng tan tốt trong dung môi hữu cơ.
Được dùng phổ biến trong sơn, vecni, keo dán và tổng hợp hữu cơ.
Có khả năng hòa tan nhựa, cao su và sáp, rất quan trọng trong ngành hóa dầu.
Đạt tiêu chuẩn công nghiệp GR với độ tinh khiết cao, thích hợp cho phân tích hóa học.
Bảo quản nơi thoáng mát, tránh ánh nắng và nguồn phát lửa.
Khi thao tác cần mang khẩu trang, găng tay và làm việc nơi thông gió tốt.
Xuất xứ: Hàn Quốc / Singapore.', 
N'Chai 1L', 145000, 120, 'LSP001',   N'sp002.png'),

('SP003', N'Xylene (C₈H₁₀) dung môi',
N'Dung môi hữu cơ không màu, có mùi đặc trưng, dễ bay hơi và bắt cháy.
Được sử dụng trong sơn, mực in, nhựa epoxy và xử lý mẫu mô học trong y tế.
Có khả năng hòa tan tốt các hợp chất hữu cơ, đặc biệt là nhựa tự nhiên và tổng hợp.
Đạt tiêu chuẩn kỹ thuật GR, phù hợp cho công nghiệp và phòng thí nghiệm.
Bảo quản nơi mát, tránh ánh nắng, đậy nắp kín khi không sử dụng.
Sử dụng nơi thông thoáng, tránh hít phải hơi dung môi trong thời gian dài.
Xuất xứ: Nhật Bản / Trung Quốc.', 
N'Chai 1L', 150000, 90, 'LSP001',   N'sp003.png'),

('SP004', N'Dichloromethane (CH₂Cl₂)',
N'Dung môi halogen hóa có mùi đặc trưng, không cháy và bay hơi nhanh.
Dùng trong chiết tách, tẩy rửa và tách pha hữu cơ trong thí nghiệm hóa học.
Ứng dụng trong công nghiệp sơn, dược phẩm và sản xuất keo dán.
Sản phẩm đạt tiêu chuẩn phân tích AR, thích hợp cho nghiên cứu hóa học.
Bảo quản kín, nơi khô mát, tránh tiếp xúc với ánh nắng trực tiếp.
Khi thao tác nên làm việc trong tủ hút và đeo găng chống hóa chất.
Xuất xứ: Đức / Trung Quốc.', 
N'Chai 500ml', 160000, 70, 'LSP001',  N'sp004.png'),
('SP005', N'Benzene tinh khiết',
N'Dung môi hydrocacbon thơm, trong suốt, không màu và dễ cháy.
Được sử dụng trong tổng hợp hóa chất, sản xuất cao su và dược phẩm.
Có khả năng hòa tan nhiều hợp chất hữu cơ không phân cực.
Sản phẩm đạt tiêu chuẩn GR (General Reagent), dùng trong nghiên cứu và công nghiệp.
Bảo quản nơi thoáng mát, tránh ánh sáng và nguồn nhiệt cao.
Khi thao tác cần sử dụng tủ hút, găng tay và khẩu trang chống hơi độc.
Xuất xứ: Singapore / Ấn Độ.', 
N'Chai 1L', 175000, 60, 'LSP001',   N'sp005.png'),

('SP006', N'Methyl Ethyl Ketone (MEK)',
N'Dung môi hữu cơ dễ bay hơi, có mùi nhẹ, dùng phổ biến trong sơn và keo dán.
Có khả năng hòa tan nhựa, cao su và polymer, thích hợp cho sản xuất công nghiệp.
Dễ cháy, nên được bảo quản xa nguồn nhiệt và ánh nắng trực tiếp.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, dùng cho ứng dụng kỹ thuật và thí nghiệm.
Cần thao tác nơi thông thoáng, tránh hít phải hơi dung môi trong thời gian dài.
Xuất xứ: Hàn Quốc / Việt Nam.', 
N'Chai 1L', 135000, 80, 'LSP001',   N'sp006.png'),

('SP007', N'Tetrahydrofuran (THF)',
N'Dung môi phân cực mạnh, không màu, dễ cháy và bay hơi nhanh.
Dùng rộng rãi trong tổng hợp polymer, sản xuất nhựa và phản ứng hữu cơ.
Có khả năng hòa tan PVC, polyvinylidene chloride và các hợp chất hữu cơ phức tạp.
Đạt tiêu chuẩn phân tích AR, đảm bảo độ tinh khiết cao cho nghiên cứu.
Bảo quản trong chai kín, tránh hơi ẩm và nguồn nhiệt.
Sử dụng trong tủ hút và đeo găng chống dung môi khi thao tác.
Xuất xứ: Nhật Bản / Đức.', 
N'Chai 500ml', 185000, 65, 'LSP001',  N'sp007.png'),

('SP008', N'Cyclohexane',
N'Dung môi hydrocacbon không phân cực, không màu, có mùi nhẹ, dễ cháy.
Dùng trong chiết tách, phân tích hóa học và tinh chế hợp chất hữu cơ.
Ứng dụng trong sản xuất nhựa, sơn và làm dung môi phản ứng.
Sản phẩm đạt tiêu chuẩn GR (General Reagent) dùng trong thí nghiệm.
Bảo quản nơi mát, khô ráo và tránh nguồn phát nhiệt.
Khi thao tác cần mang kính bảo hộ và găng tay cao su.
Xuất xứ: Trung Quốc / Hàn Quốc.', 
N'Chai 1L', 130000, 100, 'LSP001',   N'sp008.png'),

('SP009', N'Formic Acid (HCOOH) 85%',
N'Axit hữu cơ mạnh, không màu, có mùi hăng, tan tốt trong nước và ethanol.
Dùng làm dung môi và chất xúc tác trong tổng hợp hữu cơ.
Ứng dụng trong công nghiệp thuộc da, xử lý dệt nhuộm và bảo quản thực phẩm.
Đạt tiêu chuẩn công nghiệp GR với độ tinh khiết ≥85%.
Bảo quản nơi khô ráo, tránh ánh nắng, đậy kín sau khi sử dụng.
Khi thao tác cần tránh tiếp xúc trực tiếp với da và hít phải hơi axit.
Xuất xứ: Ấn Độ / Trung Quốc.', 
N'Chai 500ml', 95000, 80, 'LSP001',  N'sp009.png'),

('SP010', N'Ethylene Glycol (C₂H₆O₂)',
N'Chất lỏng không màu, nhớt, tan trong nước, có vị ngọt nhẹ.
Được sử dụng trong chất chống đông, công nghiệp nhựa polyester và dung môi.
Có khả năng hòa tan tốt nhiều hợp chất hữu cơ và vô cơ.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, thích hợp dùng trong nghiên cứu và sản xuất.
Bảo quản nơi thoáng mát, tránh ánh sáng trực tiếp và đậy kín sau khi dùng.
Tránh tiếp xúc với da vì có thể gây kích ứng nhẹ.
Xuất xứ: Hàn Quốc / Trung Quốc.', 
N'Chai 1L', 125000, 110, 'LSP001',   N'sp010.png'),

('SP011', N'Axit Sulfurous (H₂SO₃)',
N'Axit yếu chứa lưu huỳnh, có tính khử, tan tốt trong nước.
Dùng làm chất tẩy trắng và khử khuẩn trong công nghiệp thực phẩm.
Ứng dụng trong tổng hợp hóa học và xử lý nước thải công nghiệp.
Sản phẩm đạt tiêu chuẩn GR (General Reagent), tinh khiết cho thí nghiệm.
Bảo quản nơi khô ráo, đậy kín tránh bay hơi và ánh sáng.
Khi thao tác cần đeo găng và kính bảo hộ, tránh tiếp xúc trực tiếp.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Chai 500ml', 90000, 60, 'LSP002',  N'sp011.png'),

('SP012', N'Axit Formic (HCOOH) 85%',
N'Axit hữu cơ mạnh, không màu, tan hoàn toàn trong nước.
Dùng trong công nghiệp thuộc da, tẩy rửa và tổng hợp hữu cơ.
Được sử dụng trong sản xuất dệt, giấy và chất xúc tác phản ứng hóa học.
Đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥85%.
Bảo quản trong bình kín, tránh tiếp xúc ánh sáng và nhiệt độ cao.
Sử dụng nơi thoáng gió, tránh hít hơi đậm đặc.
Xuất xứ: Trung Quốc / Đức.', 
N'Chai 500ml', 110000, 80, 'LSP002',   N'sp012.png'),

('SP013', N'Axit Lactic (C₃H₆O₃)',
N'Axit hữu cơ tự nhiên, có vị chua nhẹ, tan hoàn toàn trong nước.
Ứng dụng trong dược phẩm, mỹ phẩm và công nghiệp thực phẩm.
Được dùng trong sản xuất polymer PLA và tổng hợp hóa chất sinh học.
Sản phẩm đạt tiêu chuẩn FCC/USP cho ngành thực phẩm và dược.
Bảo quản nơi thoáng mát, tránh ánh sáng và nhiệt độ cao.
Không để tiếp xúc với kim loại mạnh hoặc bazơ mạnh.
Xuất xứ: Nhật Bản / Hàn Quốc.', 
N'Chai 500ml', 130000, 70, 'LSP002',   N'sp013.png'),

('SP014', N'Axit Tartaric (C₄H₆O₆)',
N'Axit hữu cơ tự nhiên có trong nho, dùng trong công nghiệp thực phẩm và dược phẩm.
Dùng làm chất điều chỉnh pH và chất tạo vị chua nhẹ.
Ứng dụng trong chuẩn độ hóa học, phân tích và chế biến thực phẩm.
Đạt tiêu chuẩn FCC/USP cho thực phẩm và dược phẩm.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh sáng trực tiếp.
Tránh hít phải bụi axit và tiếp xúc lâu với da.
Xuất xứ: Ấn Độ / Trung Quốc.', 
N'Kg', 140000, 90, 'LSP002',   N'sp014.png'),

('SP015', N'Axit Benzoic (C₆H₅COOH)',
N'Axit hữu cơ tinh thể trắng, có tính kháng khuẩn và chống nấm mạnh.
Được dùng phổ biến trong bảo quản thực phẩm và mỹ phẩm.
Ứng dụng trong tổng hợp dược phẩm và chất hóa học trung gian.
Đạt tiêu chuẩn FCC, tinh khiết ≥99.5%.
Bảo quản kín, nơi thoáng mát, tránh ánh sáng trực tiếp.
Khi thao tác cần tránh hít bụi và tiếp xúc trực tiếp với mắt.
Xuất xứ: Trung Quốc / Đức.', 
N'Kg', 150000, 80, 'LSP002',   N'sp015.png'),

('SP016', N'Natri Hydroxit (NaOH) dung dịch 1M',
N'Bazơ mạnh, không màu, tan hoàn toàn trong nước, có tính ăn mòn cao.
Dùng trong trung hòa axit, xử lý nước và sản xuất xà phòng.
Ứng dụng trong công nghiệp hóa chất, dệt nhuộm và dược phẩm.
Sản phẩm đạt tiêu chuẩn phân tích AR, nồng độ chính xác 1M.
Bảo quản nơi khô ráo, tránh ẩm và đậy kín nắp chai.
Khi thao tác cần dùng găng tay, kính bảo hộ và tủ hút.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Chai 1L', 85000, 100, 'LSP003',   N'sp016.png'),

('SP017', N'Kali Hydroxit (KOH) tinh khiết',
N'Bazơ mạnh, dạng rắn màu trắng, hút ẩm nhanh, tan tốt trong nước.
Được dùng trong sản xuất xà phòng, pin kiềm và phản ứng trung hòa axit.
Đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Ứng dụng trong dược phẩm, mỹ phẩm và công nghiệp hóa chất.
Bảo quản trong bình kín, tránh ánh sáng và ẩm mốc.
Tránh tiếp xúc trực tiếp với da, gây ăn mòn và kích ứng.
Xuất xứ: Nhật Bản / Trung Quốc.', 
N'Kg', 95000, 120, 'LSP003',   N'sp017.png'),

('SP018', N'Amoni Hydroxit (NH₄OH) 25%',
N'Dung dịch bazơ yếu, có mùi khai đặc trưng, tan tốt trong nước.
Dùng trong phân tích hóa học, tẩy rửa và xử lý nước.
Ứng dụng trong công nghiệp dệt và thuộc da.
Đạt tiêu chuẩn công nghiệp GR, nồng độ ổn định 25%.
Bảo quản nơi thoáng mát, tránh nhiệt độ cao và ánh sáng.
Khi thao tác cần dùng tủ hút và đeo găng chống hóa chất.
Xuất xứ: Trung Quốc / Việt Nam.', 
N'Chai 1L', 80000, 90, 'LSP003',   N'sp018.png'),

('SP019', N'Canxi Hydroxit (Ca(OH)₂) công nghiệp',
N'Bột trắng, tan nhẹ trong nước, có tính kiềm yếu.
Dùng trong xử lý nước thải, xây dựng và công nghiệp giấy.
Ứng dụng làm chất trung hòa axit trong phản ứng hóa học.
Sản phẩm đạt tiêu chuẩn kỹ thuật công nghiệp.
Bảo quản nơi khô ráo, tránh tiếp xúc không khí ẩm.
Khi thao tác cần tránh hít bụi và đeo khẩu trang bảo hộ.
Xuất xứ: Việt Nam.', 
N'Kg', 65000, 120, 'LSP003',   N'sp019.png'),

('SP020', N'Bari Hydroxit (Ba(OH)₂)',
N'Bazơ mạnh, dạng tinh thể trắng, hút ẩm nhanh, tan trong nước.
Dùng trong phân tích hóa học, chuẩn độ và xử lý khí CO₂.
Ứng dụng trong sản xuất chất ổn định PVC và dầu bôi trơn.
Đạt tiêu chuẩn phân tích AR, tinh khiết ≥98%.
Bảo quản nơi khô ráo, kín khí, tránh tiếp xúc không khí.
Khi thao tác cần đeo găng, kính và tránh hít bụi hóa chất.
Xuất xứ: Trung Quốc.', 
N'Kg', 88000, 70, 'LSP003',   N'sp020.png'),

('SP021', N'Natri Carbonat nhẹ (Na₂CO₃)',
N'Bột trắng, tan tốt trong nước, có tính kiềm yếu, được gọi là soda ash light.
Dùng trong sản xuất thủy tinh, chất tẩy rửa, và xử lý nước thải.
Ứng dụng trong công nghiệp giấy, dệt nhuộm và sản xuất hóa chất vô cơ.
Sản phẩm đạt tiêu chuẩn công nghiệp kỹ thuật GR với độ tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ẩm, tránh tiếp xúc với axit mạnh.
Khi thao tác cần đeo găng, kính bảo hộ để tránh kích ứng da và mắt.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Kg', 75000, 200, 'LSP004',  N'sp021.png'),

('SP022', N'Natri Clorua (NaCl) công nghiệp',
N'Muối trắng tinh thể, tan hoàn toàn trong nước, không mùi và vị mặn đặc trưng.
Dùng trong sản xuất hóa chất, chế biến thực phẩm và phòng thí nghiệm.
Ứng dụng trong điều chế dung dịch đệm, điện phân và xử lý nước.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥99%.
Bảo quản nơi khô thoáng, tránh nhiễm ẩm hoặc tạp chất.
Không để tiếp xúc với axit hoặc chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Ấn Độ.', 
N'Kg', 60000, 180, 'LSP004',  N'sp022.png'),

('SP023', N'Canxi Carbonat (CaCO₃)',
N'Bột trắng mịn, không mùi, không tan trong nước, tan trong axit loãng.
Dùng trong công nghiệp nhựa, sơn, giấy và cao su làm chất độn.
Ứng dụng trong sản xuất dược phẩm, thực phẩm bổ sung canxi.
Sản phẩm đạt tiêu chuẩn kỹ thuật GR, độ tinh khiết cao.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.
Khi thao tác nên mang khẩu trang tránh hít bụi mịn.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Kg', 65000, 160, 'LSP013',   N'sp023.png'),

('SP024', N'Magie Clorua (MgCl₂)',
N'Tinh thể trắng hoặc không màu, tan mạnh trong nước và ethanol.
Dùng trong xử lý nước, công nghiệp dệt nhuộm và sản xuất xi măng magnesia.
Ứng dụng trong tổng hợp hóa chất và sản xuất phụ gia thực phẩm.
Sản phẩm đạt tiêu chuẩn kỹ thuật công nghiệp, tinh khiết ≥98%.
Bảo quản nơi khô ráo, tránh ẩm vì dễ hút nước.
Khi thao tác cần tránh hít bụi hoặc để tiếp xúc với mắt.
Xuất xứ: Trung Quốc / Việt Nam.', 
N'Kg', 90000, 90, 'LSP004',   N'sp024.png'),

('SP025', N'Kẽm Clorua (ZnCl₂)',
N'Tinh thể trắng trong suốt, tan mạnh trong nước, có tính hút ẩm cao.
Dùng trong công nghiệp xi mạ, chất kết dính và keo gỗ.
Ứng dụng trong dệt, xử lý nước, và điều chế pin điện hóa.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥98%.
Bảo quản nơi khô ráo, tránh ánh sáng và đậy kín nắp.
Khi thao tác tránh hít bụi và đeo găng chống hóa chất.
Xuất xứ: Trung Quốc / Đức.', 
N'Kg', 120000, 70, 'LSP004',   N'sp025.png'),

('SP026', N'Nhôm Sunfat (Al₂(SO₄)₃)',
N'Tinh thể trắng ngà hoặc dạng hạt, tan trong nước, có tính axit nhẹ.
Dùng làm chất keo tụ trong xử lý nước sinh hoạt và công nghiệp.
Ứng dụng trong sản xuất giấy, dệt nhuộm và tổng hợp hóa chất.
Sản phẩm đạt tiêu chuẩn kỹ thuật công nghiệp, tinh khiết ≥98%.
Bảo quản nơi khô thoáng, tránh ánh sáng và độ ẩm cao.
Tránh tiếp xúc với da hoặc hít phải bụi hóa chất.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Kg', 85000, 100, 'LSP004',   N'sp026.png'),

('SP027', N'Natri Thiosunfat (Na₂S₂O₃)',
N'Tinh thể trắng trong, tan tốt trong nước, có vị hơi ngọt.
Dùng làm chất khử trong phân tích iot và xử lý nước.
Ứng dụng trong nhiếp ảnh, y học và công nghiệp hóa chất.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản kín, tránh ánh sáng và không khí ẩm.
Không trộn với chất oxy hóa mạnh như Cl₂ hoặc KMnO₄.
Xuất xứ: Trung Quốc / Ấn Độ.', 
N'Kg', 90000, 120, 'LSP004',   N'sp027.png'),

('SP028', N'Silica Gel',
N'Hạt hút ẩm màu trắng hoặc xanh, không mùi, không độc hại.
Dùng trong đóng gói sản phẩm, bảo quản hóa chất, thuốc và linh kiện điện tử.
Có khả năng hấp thụ hơi ẩm rất mạnh, tái sử dụng sau khi sấy khô.
Sản phẩm đạt tiêu chuẩn công nghiệp, độ hấp thụ ẩm ≥30%.
Bảo quản nơi khô ráo, tránh ánh sáng và không khí ẩm.
Khi sử dụng không được ăn hoặc để tiếp xúc trực tiếp với thực phẩm.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Kg', 130000, 140, 'LSP007',   N'sp028.png'),

('SP029', N'Activated Carbon',
N'Chất rắn màu đen, dạng hạt hoặc bột, có cấu trúc xốp với diện tích bề mặt lớn.
Dùng trong lọc nước, xử lý khí và hấp phụ hóa chất độc hại.
Ứng dụng trong y học, công nghiệp thực phẩm và hóa dầu.
Sản phẩm đạt tiêu chuẩn kỹ thuật công nghiệp, độ hấp phụ cao.
Bảo quản nơi khô ráo, tránh ánh sáng trực tiếp và nguồn nhiệt.
Không để tiếp xúc với dung môi hoặc chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Indonesia.',
N'Kg', 100000, 160, 'LSP007',   N'sp029.png'),

('SP030', N'Titanium Dioxide (TiO₂)',
N'Bột trắng siêu mịn, không tan trong nước, có độ che phủ và phản quang cao.
Dùng trong sơn, nhựa, mỹ phẩm, giấy và cao su.
Ứng dụng trong sản xuất chất nhuộm và chất chống tia UV.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ánh nắng và nhiệt độ cao.
Tránh hít bụi mịn khi thao tác trong môi trường kín.
Xuất xứ: Trung Quốc / Nhật Bản.', 
N'Kg', 180000, 90, 'LSP013',   N'sp030.png'),

('SP031', N'Methyl Blue',
N'Thuốc nhuộm màu xanh đậm, tan tốt trong nước, dùng trong phân tích mô học.
Ứng dụng trong nhuộm vi sinh vật, tế bào và kiểm tra pH dung dịch.
Sản phẩm đạt tiêu chuẩn phân tích AR, độ tinh khiết ≥98%.
Dùng phổ biến trong giảng dạy, nghiên cứu và y học.
Bảo quản kín, tránh ánh sáng và độ ẩm.
Không để thuốc nhuộm tiếp xúc với da và mắt.
Xuất xứ: Ấn Độ / Trung Quốc.', 
N'Chai 100ml', 95000, 100, 'LSP005',  N'sp031.png'),

('SP032', N'Congo Red',
N'Thuốc nhuộm màu đỏ, tan trong nước, được dùng làm chỉ thị pH và trong mô học.
Chuyển màu từ đỏ sang xanh lam ở pH 3.0–5.0.
Ứng dụng trong phân tích axit-bazơ và phát hiện amyloid trong y học.
Đạt tiêu chuẩn phân tích AR, độ tinh khiết ≥98%.
Bảo quản nơi khô, tránh ánh sáng trực tiếp.
Khi thao tác cần đeo găng và kính bảo hộ.
Xuất xứ: Ấn Độ / Trung Quốc.', 
N'Chai 100ml', 120000, 80, 'LSP005',  N'sp032.png'),

('SP033', N'Bromothymol Blue',
N'Chất chỉ thị pH đổi màu trong khoảng 6.0–7.6, từ vàng sang xanh.
Dùng trong chuẩn độ axit-bazơ và kiểm tra dung dịch sinh học.
Ứng dụng trong nghiên cứu vi sinh và môi trường.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥98%.
Bảo quản kín, tránh ánh sáng và nơi ẩm thấp.
Khi thao tác tránh tiếp xúc trực tiếp với mắt.
Xuất xứ: Đức / Trung Quốc.', 
N'Chai 100ml', 130000, 90, 'LSP005',   N'sp033.png'),

('SP034', N'Phenolphthalein dung dịch 1%',
N'Chất chỉ thị axit-bazơ, không màu trong môi trường axit và hồng trong kiềm.
Dùng trong các phép chuẩn độ hóa học và giảng dạy thí nghiệm.
Đạt tiêu chuẩn phân tích AR, nồng độ 1% chính xác.
Bảo quản nơi khô ráo, tránh ánh sáng mạnh và nhiệt độ cao.
Không để tiếp xúc trực tiếp với da hoặc uống nhầm.
Xuất xứ: Trung Quốc / Ấn Độ.', 
N'Chai 100ml', 115000, 70, 'LSP005',   N'sp034.png'),

('SP035', N'Methyl Orange dung dịch 1%',
N'Chỉ thị axit-bazơ có vùng chuyển màu pH 3.1–4.4, từ đỏ sang vàng.
Dùng trong chuẩn độ axit mạnh với bazơ mạnh.
Đạt tiêu chuẩn phân tích AR, thích hợp cho giáo dục và nghiên cứu.
Bảo quản nơi thoáng mát, tránh ánh nắng trực tiếp.
Tránh hít hơi dung dịch hoặc tiếp xúc lâu với da.
Xuất xứ: Trung Quốc / Việt Nam.', 
N'Chai 100ml', 100000, 80, 'LSP005',   N'sp035.png'),

('SP036', N'Bromocresol Green',
N'Chất chỉ thị pH có vùng chuyển màu từ vàng sang xanh ở pH 3.8–5.4.
Dùng trong chuẩn độ và kiểm tra tính axit của dung dịch.
Sản phẩm đạt tiêu chuẩn AR, thích hợp cho nghiên cứu và phân tích.
Bảo quản trong lọ kín, tránh ánh sáng và nơi ẩm thấp.
Không để tiếp xúc trực tiếp với da hoặc hít phải bụi chỉ thị.
Xuất xứ: Đức / Trung Quốc.', 
N'Chai 100ml', 125000, 70, 'LSP005',   N'sp036.png'),

('SP037', N'Hydrogen Peroxide 6%',
N'Dung dịch không màu, có tính oxy hóa mạnh, dùng trong tẩy trắng và khử trùng.
Ứng dụng trong y học, dệt nhuộm và công nghiệp thực phẩm.
Đạt tiêu chuẩn công nghiệp GR, nồng độ 6% ổn định.
Bảo quản trong chai tối màu, tránh ánh sáng và nguồn nhiệt.
Không được uống hoặc tiếp xúc trực tiếp với da.
Xuất xứ: Việt Nam / Hàn Quốc.', 
N'Chai 1L', 95000, 120, 'LSP006',   N'sp037.png'),

('SP038', N'Natri Hypochlorite 5%',
N'Dung dịch có tính oxy hóa mạnh, mùi clo đặc trưng, dùng trong tẩy rửa và khử khuẩn.
Ứng dụng trong xử lý nước, vệ sinh công nghiệp và y tế.
Đạt tiêu chuẩn công nghiệp, nồng độ clo hoạt tính 5%.
Bảo quản nơi tối, thoáng mát, tránh tiếp xúc với ánh sáng trực tiếp.
Không trộn với axit hoặc chất khử để tránh sinh khí độc.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Chai 1L', 90000, 90, 'LSP006',   N'sp038.png'),

('SP039', N'Natri Metabisulfite (Na₂S₂O₅)',
N'Bột trắng có mùi SO₂ nhẹ, tan tốt trong nước, có tính khử mạnh.
Dùng trong tẩy trắng, bảo quản thực phẩm và xử lý nước thải.
Ứng dụng trong nhiếp ảnh, dệt nhuộm và hóa chất công nghiệp.
Đạt tiêu chuẩn thực phẩm E223 và kỹ thuật công nghiệp.
Bảo quản kín, tránh ánh sáng và độ ẩm cao.
Tránh hít hơi hoặc bụi có thể gây kích ứng hô hấp.
Xuất xứ: Việt Nam / Trung Quốc.', 
N'Kg', 88000, 100, 'LSP006',   N'sp039.png'),

('SP040', N'EDTA 2Na 0.1M dung dịch chuẩn',
N'Dung dịch chuẩn độ phức chất dùng trong phân tích hóa học và xác định ion kim loại.
Ứng dụng trong kiểm tra độ cứng nước và chuẩn độ Ca²⁺, Mg²⁺.
Sản phẩm đạt tiêu chuẩn phân tích AR, nồng độ chính xác 0.1M.
Bảo quản nơi khô ráo, tránh ánh sáng và nhiệt độ cao.
Đậy kín sau khi sử dụng, tránh bay hơi dung môi.
Xuất xứ: Trung Quốc / Việt Nam.', 
N'Chai 250ml', 130000, 80, 'LSP010',   N'sp040.png'),
('SP041', N'SDS (Sodium Dodecyl Sulfate)',
N'Chất hoạt động bề mặt anion dạng bột trắng, tan hoàn toàn trong nước.
Dùng trong điện di protein SDS-PAGE, tách màng tế bào và làm sạch protein.
Ứng dụng trong sinh học phân tử, dược phẩm và công nghiệp tẩy rửa.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản kín, nơi khô thoáng, tránh ánh sáng trực tiếp và độ ẩm cao.
Khi thao tác cần đeo khẩu trang, găng tay và kính bảo hộ.
Xuất xứ: Đức / Trung Quốc.',
N'Gói 500g', 150000, 100, 'LSP008',  N'sp041.png'),

('SP042', N'PVP (Polyvinylpyrrolidone)',
N'Polymer tan trong nước, dạng bột trắng, không mùi, không độc hại.
Dùng làm chất ổn định keo, tá dược trong dược phẩm và chất kết dính.
Ứng dụng trong công nghiệp mỹ phẩm, thuốc mỡ và dung dịch sát khuẩn.
Sản phẩm đạt tiêu chuẩn USP/BP, độ tinh khiết ≥99%.
Bảo quản nơi khô ráo, thoáng mát, tránh ẩm mốc.
Khi thao tác tránh hít bụi và tránh để dính vào mắt.
Xuất xứ: Đức / Trung Quốc.',
N'Gói 500g', 180000, 90, 'LSP008',  N'sp042.png'),

('SP043', N'Tween-80 (Polysorbate 80)',
N'Chất nhũ hóa không ion, dạng lỏng nhớt màu vàng nhạt, tan tốt trong nước.
Dùng trong thực phẩm, dược phẩm, mỹ phẩm và sinh học phân tử.
Ứng dụng trong nhũ hóa tinh dầu, vitamin và dung dịch đệm.
Sản phẩm đạt tiêu chuẩn USP/EP, độ tinh khiết cao.
Bảo quản nơi thoáng mát, tránh ánh sáng và nhiệt độ cao.
Không để tiếp xúc với kim loại nặng hoặc chất oxy hóa mạnh.
Xuất xứ: Malaysia / Đức.',
N'Chai 500ml', 160000, 110, 'LSP008',   N'sp043.png'),

('SP044', N'Triton X-100',
N'Chất hoạt động bề mặt không ion, dạng lỏng nhớt, không màu hoặc vàng nhạt.
Dùng trong tách protein, phá vỡ màng tế bào và rửa dụng cụ phòng thí nghiệm.
Ứng dụng trong sinh học phân tử, hóa sinh và y học.
Sản phẩm đạt tiêu chuẩn phân tích AR, độ tinh khiết ≥99%.
Bảo quản nơi khô thoáng, tránh ánh nắng và nhiệt độ cao.
Không được trộn với chất oxy hóa mạnh hoặc axit đậm đặc.
Xuất xứ: Mỹ / Trung Quốc.',
N'Chai 500ml', 170000, 70, 'LSP008',   N'sp044.png'),

('SP045', N'DMSO (Dimethyl Sulfoxide)',
N'Dung môi phân cực mạnh, không màu, có khả năng hòa tan nhiều hợp chất hữu cơ.
Dùng phổ biến trong sinh học, dược phẩm và bảo quản tế bào sống.
Ứng dụng trong công nghệ dược, nghiên cứu enzyme và phản ứng hữu cơ.
Đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.9%.
Bảo quản kín, nơi khô ráo, tránh ánh sáng và nguồn nhiệt.
Khi thao tác tránh hít hơi dung môi và tiếp xúc lâu với da.
Xuất xứ: Nhật Bản / Trung Quốc.',
N'Chai 500ml', 200000, 80, 'LSP008',   N'sp045.png'),

('SP046', N'Polyethylene Glycol (PEG-400)',
N'Polymer tan trong nước, không màu, không mùi, dùng làm chất mang trong dược phẩm.
Ứng dụng trong mỹ phẩm, thực phẩm và tổng hợp hóa học.
Có tính bôi trơn, ổn định và tương thích sinh học cao.
Sản phẩm đạt tiêu chuẩn USP, tinh khiết ≥99%.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh sáng mặt trời.
Không được đun nóng quá 80°C hoặc tiếp xúc với kim loại nặng.
Xuất xứ: Mỹ / Trung Quốc.',
N'Chai 500ml', 180000, 90, 'LSP011',   N'sp046.png'),

('SP047', N'EVA Resin 25kg',
N'Hạt polymer đàn hồi, màu trắng sữa, dùng trong sản xuất keo nóng chảy và đế giày.
Có độ mềm dẻo cao, kháng tia UV và chịu lạnh tốt.
Ứng dụng trong ngành nhựa, điện tử và bao bì.
Đạt tiêu chuẩn kỹ thuật công nghiệp GR, hàm lượng vinyl acetate 18–28%.
Bảo quản nơi khô ráo, tránh nhiệt độ cao và ánh nắng trực tiếp.
Tránh để gần nguồn nhiệt hoặc dung môi hữu cơ mạnh.
Xuất xứ: Hàn Quốc / Việt Nam.',
N'Bao 25kg', 900000, 60, 'LSP011',   N'sp047.png'),

('SP048', N'PVC Resin K67',
N'Hạt polymer trắng, dùng trong sản xuất ống nhựa, màng co, và vật liệu cách điện.
Có tính bền cơ học cao, kháng hóa chất và dễ gia công.
Ứng dụng rộng rãi trong công nghiệp nhựa, xây dựng và điện.
Sản phẩm đạt tiêu chuẩn kỹ thuật công nghiệp GR.
Bảo quản nơi thoáng mát, tránh ánh nắng và hơi ẩm.
Không để tiếp xúc trực tiếp với dung môi hoặc dầu mỡ.
Xuất xứ: Việt Nam / Thái Lan.',
N'Bao 25kg', 850000, 70, 'LSP011',   N'sp048.png'),

('SP049', N'Silicone Oil 1000cSt',
N'Dầu silicone nhớt cao, không màu, không mùi, kháng nhiệt và chống tĩnh điện tốt.
Dùng trong chống bọt, bôi trơn khuôn, làm chất cách điện.
Ứng dụng trong mỹ phẩm, cao su và y tế.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, độ nhớt 1000cSt ±5%.
Bảo quản nơi khô ráo, tránh ánh sáng mạnh và nguồn nhiệt.
Không được đốt cháy hoặc để gần tia lửa điện.
Xuất xứ: Đức / Hàn Quốc.',
N'Chai 1L', 260000, 60, 'LSP011',   N'sp049.png'),

('SP050', N'Propylene Glycol USP',
N'Dung môi không độc, tan tốt trong nước, không mùi và vị ngọt nhẹ.
Dùng trong mỹ phẩm, dược phẩm và công nghiệp thực phẩm.
Ứng dụng làm dung môi cho hương liệu, chất tạo ẩm và tá dược.
Sản phẩm đạt tiêu chuẩn USP/BP, tinh khiết ≥99.5%.
Bảo quản kín, nơi khô thoáng, tránh ánh sáng trực tiếp.
Không để gần nguồn nhiệt hoặc hóa chất oxy hóa.
Xuất xứ: Mỹ / Việt Nam.',
N'Chai 1L', 135000, 100, 'LSP001',   N'sp050.png'),

('SP051', N'Axeton (C₃H₆O) tinh khiết 99.5%',
N'Dung môi hữu cơ trong suốt, bay hơi nhanh, dùng phổ biến trong làm sạch và chiết tách.
Ứng dụng trong sản xuất nhựa, cao su, keo dán và sơn công nghiệp.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.5%.
Không để gần ngọn lửa, tia lửa hoặc nguồn nhiệt.
Bảo quản nơi thoáng mát, đậy kín, tránh ánh sáng mặt trời.
Khi thao tác nên sử dụng trong tủ hút và mang đồ bảo hộ.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 500ml', 95000, 120, 'LSP001',  N'sp051.png'),

('SP052', N'Ethyl Acetate (CH₃COOC₂H₅) dung môi hữu cơ',
N'Dung môi este không màu, mùi thơm nhẹ, bay hơi nhanh.
Dùng trong sơn, mực in, keo dán và chiết tách tự nhiên.
Ứng dụng trong dược phẩm, tinh dầu và phân tích hóa học.
Sản phẩm đạt tiêu chuẩn GR, tinh khiết ≥99.8%.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh sáng và nhiệt độ cao.
Không để gần nguồn lửa hoặc tia lửa điện.
Xuất xứ: Trung Quốc / Việt Nam.',
N'Chai 500ml', 130000, 100, 'LSP001', N'sp052.png'),

('SP053', N'Methanol (CH₃OH) công nghiệp 99.8%',
N'Dung môi phân cực mạnh, không màu, mùi đặc trưng, dễ bay hơi.
Dùng trong tổng hợp hóa chất, sản xuất formaldehyde và chất chống đông.
Ứng dụng làm nhiên liệu sạch và dung môi công nghiệp.
Sản phẩm đạt tiêu chuẩn kỹ thuật GR, tinh khiết ≥99.8%.
Bảo quản kín, nơi thoáng mát, tránh nguồn nhiệt và tia lửa.
Tránh hít hơi và tránh để dính vào da.
Xuất xứ: Việt Nam / Malaysia.',
N'Chai 1L', 110000, 150, 'LSP001',   N'sp053.png'),

('SP054', N'Axit Axetic (CH₃COOH) tinh khiết 99.7%',
N'Axit hữu cơ yếu, không màu, có mùi chua đặc trưng, tan tốt trong nước.
Dùng trong sản xuất nhựa, dược phẩm, và công nghiệp thực phẩm.
Ứng dụng trong tẩy rửa, tổng hợp hóa chất và dung môi phản ứng.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.7%.
Bảo quản kín, nơi khô ráo, tránh ánh sáng và nhiệt độ cao.
Không để gần kim loại hoặc bazơ mạnh.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 500ml', 115000, 120, 'LSP002',   N'sp054.png'),

('SP055', N'Axit Citric khan (C₆H₈O₇)',
N'Axit hữu cơ yếu, tinh thể trắng, có vị chua dịu, tan trong nước.
Dùng trong thực phẩm, dược phẩm, mỹ phẩm và dung dịch đệm.
Ứng dụng làm chất chống oxy hóa và điều chỉnh pH.
Đạt tiêu chuẩn thực phẩm E330 và dược phẩm USP.
Bảo quản nơi khô ráo, thoáng mát, tránh ẩm mốc.
Không để gần kiềm hoặc chất oxy hóa mạnh.
Xuất xứ: Thái Lan / Trung Quốc.',
N'Kg', 130000, 130, 'LSP002',   N'sp055.png'),

('SP056', N'Glycerin (C₃H₈O₃) tinh khiết dược phẩm',
N'Chất lỏng trong suốt, nhớt nhẹ, vị ngọt, tan hoàn toàn trong nước.
Dùng trong mỹ phẩm, dược phẩm, thực phẩm và dung dịch đệm.
Ứng dụng làm dung môi, chất giữ ẩm và tá dược thuốc mỡ.
Sản phẩm đạt tiêu chuẩn USP/BP, tinh khiết ≥99.5%.
Bảo quản nơi khô thoáng, tránh ánh sáng và đậy kín sau khi dùng.
Không để gần axit mạnh hoặc chất oxy hóa.
Xuất xứ: Việt Nam / Indonesia.',
N'Chai 1L', 125000, 120, 'LSP001',   N'sp056.png'),

('SP057', N'Propylene Glycol (C₃H₈O₂)',
N'Dung môi không độc, không màu, tan tốt trong nước, có độ nhớt nhẹ.
Dùng trong thực phẩm, mỹ phẩm và công nghiệp điện tử.
Ứng dụng làm dung môi hòa tan hương liệu, chất tạo ẩm và chất ổn định.
Sản phẩm đạt tiêu chuẩn USP, tinh khiết ≥99.5%.
Bảo quản kín, tránh ánh sáng và nhiệt độ cao.
Không để gần nguồn lửa hoặc axit mạnh.
Xuất xứ: Mỹ / Việt Nam.',
N'Chai 1L', 130000, 100, 'LSP001',   N'sp057.png'),

('SP058', N'Butanol (C₄H₁₀O) dung môi công nghiệp',
N'Dung môi hữu cơ không màu, mùi nhẹ, tan trong hầu hết dung môi hữu cơ.
Dùng trong sơn, nhựa, keo dán và sản xuất plasticizer.
Ứng dụng trong tổng hợp hóa chất và dược phẩm.
Đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥99%.
Bảo quản nơi thoáng mát, tránh ánh nắng và nguồn nhiệt.
Khi thao tác cần thông gió tốt và tránh hít hơi dung môi.
Xuất xứ: Việt Nam / Malaysia.',
N'Chai 1L', 140000, 90, 'LSP001',   N'sp058.png'),

('SP059', N'Isoamyl Alcohol (C₅H₁₂O) dung môi chiết tách',
N'Dung môi hữu cơ mùi mạnh, tan trong ethanol và chloroform.
Dùng trong chiết tách tinh dầu, tổng hợp este và nghiên cứu sinh học.
Ứng dụng trong phân tích DNA và dược phẩm.
Sản phẩm đạt tiêu chuẩn AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh nguồn nhiệt và ánh sáng.
Tránh hít hơi dung môi hoặc tiếp xúc lâu với da.
Xuất xứ: Trung Quốc / Đức.',
N'Chai 500ml', 150000, 80, 'LSP001',   N'sp059.png'),

('SP060', N'Chloroform (CHCl₃) dung môi tẩy rửa phòng thí nghiệm',
N'Dung môi không màu, dễ bay hơi, có khả năng hòa tan nhiều hợp chất hữu cơ.
Dùng trong chiết tách, phân tích hóa học và tẩy rửa dụng cụ.
Ứng dụng trong dược phẩm, nhựa và công nghiệp cao su.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.5%.
Bảo quản nơi khô ráo, tránh ánh sáng, đậy kín sau khi mở.
Tránh hít hơi dung môi vì có thể gây ức chế thần kinh.
Xuất xứ: Đức / Trung Quốc.',
N'Chai 500ml', 155000, 70, 'LSP001',   N'sp060.png'),

('SP061', N'Axit Nitric (HNO₃) 68%',
N'Axit vô cơ mạnh, không màu, có tính oxy hóa cao và ăn mòn mạnh.
Dùng trong sản xuất phân bón, thuốc nổ, chất tẩy kim loại và phân tích hóa học.
Ứng dụng trong xử lý bề mặt kim loại, tinh chế vàng và bạc.
Sản phẩm đạt tiêu chuẩn phân tích AR, nồng độ 68 ±1%.
Bảo quản kín trong chai thủy tinh hoặc nhựa HDPE, tránh ánh sáng và nhiệt.
Không để gần bazơ, kim loại hoặc dung môi hữu cơ dễ cháy.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 500ml', 120000, 100, 'LSP002',  N'sp061.png'),

('SP062', N'Axit Phosphoric (H₃PO₄) 85%',
N'Axit trung bình, dạng chất lỏng nhớt không màu, tan hoàn toàn trong nước.
Dùng trong công nghiệp thực phẩm, sản xuất phân bón, và xử lý kim loại.
Ứng dụng làm chất điều chỉnh pH, chất tẩy rửa và dung dịch điện phân.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥85%.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh sáng và nguồn nhiệt.
Không để gần bazơ hoặc chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Hàn Quốc.',
N'Chai 500ml', 90000, 90, 'LSP002',    N'sp062.png'),

('SP063', N'Axit Hydrochloric (HCl) 37%',
N'Dung dịch axit vô cơ mạnh, không màu, có mùi xốc, tan hoàn toàn trong nước.
Dùng trong làm sạch kim loại, trung hòa bazơ, và tổng hợp hóa chất.
Ứng dụng trong ngành thực phẩm, phân bón và xử lý nước.
Sản phẩm đạt tiêu chuẩn AR, tinh khiết 36–38%.
Bảo quản trong chai nhựa HDPE, tránh ánh sáng và nguồn nhiệt.
Khi thao tác cần dùng trong tủ hút, mang găng tay và kính bảo hộ.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 500ml', 85000, 80, 'LSP002',   N'sp063.png'),

('SP064', N'Axit Sulfuric (H₂SO₄) 98%',
N'Axit vô cơ mạnh, dạng lỏng nhớt, không màu, hút ẩm mạnh và ăn mòn cao.
Dùng trong tổng hợp hóa chất, sản xuất pin, phân bón và dầu mỏ.
Ứng dụng trong làm sạch kim loại, phân tích định lượng và hóa học cơ bản.
Sản phẩm đạt tiêu chuẩn AR, tinh khiết ≥98%.
Bảo quản trong chai thủy tinh hoặc nhựa chịu axit, tránh nơi ẩm.
Không trộn với nước hoặc chất hữu cơ khi chưa kiểm soát nhiệt.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 1L', 95000, 100, 'LSP002',   N'sp064.png'),

('SP065', N'Axit Oxalic (C₂H₂O₄·2H₂O) tinh khiết',
N'Axit hữu cơ yếu, dạng tinh thể trắng, tan tốt trong nước.
Dùng trong tẩy rửa, loại bỏ gỉ sét và làm chất khử trong hóa học.
Ứng dụng trong công nghiệp da, dệt, sơn và dược phẩm.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.5%.
Bảo quản nơi khô ráo, thoáng mát, tránh ẩm ướt và ánh sáng.
Tránh hít bụi và không để dính vào da trong khi thao tác.
Xuất xứ: Trung Quốc / Ấn Độ.',
N'Kg', 100000, 90, 'LSP002',   N'sp065.png'),
('SP066', N'Kali Permanganat (KMnO₄)',
N'Tinh thể tím đen, tan trong nước, có tính oxy hóa mạnh.
Dùng trong chuẩn độ hóa học, xử lý nước và khử trùng.
Ứng dụng trong y học, môi trường và tổng hợp hữu cơ.
Sản phẩm đạt tiêu chuẩn AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ánh sáng và chất dễ cháy.
Không để gần glycerin hoặc dung môi hữu cơ.
Xuất xứ: Trung Quốc / Ấn Độ.',
N'Gói 500g', 95000, 70, 'LSP004',   N'sp066.png'),

('SP067', N'Natri Carbonat (Na₂CO₃) tinh khiết',
N'Bột trắng, có tính kiềm nhẹ, tan trong nước tạo dung dịch kiềm.
Dùng trong sản xuất thủy tinh, xà phòng, giấy và hóa phẩm tẩy rửa.
Ứng dụng trong phòng thí nghiệm để chuẩn độ và trung hòa axit.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.5%.
Bảo quản nơi khô ráo, tránh ẩm và axit mạnh.
Không để gần dung dịch axit hoặc chất oxy hóa.
Xuất xứ: Việt Nam / Thái Lan.',
N'Kg', 75000, 200, 'LSP004',   N'sp067.png'),

('SP068', N'Natri Bicarbonat (NaHCO₃)',
N'Muối vô cơ dạng bột trắng, tan tốt trong nước, có tính kiềm nhẹ.
Dùng trong thực phẩm, dược phẩm và xử lý môi trường.
Ứng dụng trong trung hòa axit, hấp phụ khí và sản xuất bột nở.
Sản phẩm đạt tiêu chuẩn thực phẩm E500 và phân tích AR.
Bảo quản nơi khô thoáng, tránh ẩm và ánh sáng.
Không để gần axit hoặc dung dịch có tính ăn mòn.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 65000, 180, 'LSP004',   N'sp068.png'),

('SP069', N'Natri Clorua (NaCl) tinh khiết phân tích',
N'Muối tinh thể trắng, tan hoàn toàn trong nước, không mùi.
Dùng trong phân tích hóa học, dung dịch đệm và công nghiệp thực phẩm.
Ứng dụng trong sinh học, dung dịch muối sinh lý và chế biến thực phẩm.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.8%.
Bảo quản nơi khô ráo, tránh ẩm và ánh sáng trực tiếp.
Không để gần dung dịch axit mạnh hoặc kim loại dễ oxy hóa.
Xuất xứ: Việt Nam / Ấn Độ.',
N'Kg', 50000, 200, 'LSP004',   N'sp069.png'),

('SP070', N'Natri Hydroxit (NaOH) dạng viên 99%',
N'Bazơ mạnh, dạng viên trắng, hút ẩm nhanh, tan trong nước tỏa nhiệt.
Dùng trong xử lý nước, sản xuất xà phòng, giấy, và dệt nhuộm.
Ứng dụng trong trung hòa axit, tổng hợp hóa chất và hóa vô cơ.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản nơi khô thoáng, tránh ánh sáng và không khí ẩm.
Không để gần axit, nhôm hoặc kẽm vì có thể sinh khí hydro.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 85000, 150, 'LSP003',   N'sp070.png'),

('SP071', N'Kali Clorua (KCl) tinh khiết',
N'Muối tinh thể trắng, tan tốt trong nước, vị hơi mặn.
Dùng trong dung dịch đệm, môi trường nuôi cấy và phân tích hóa học.
Ứng dụng trong y học, thực phẩm và dung dịch điện giải.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.5%.
Bảo quản nơi khô ráo, thoáng mát, tránh ẩm và ánh sáng.
Không để gần bazơ hoặc axit mạnh.
Xuất xứ: Đức / Việt Nam.',
N'Kg', 70000, 170, 'LSP004',  N'sp071.png'),

('SP072', N'Bari Clorua (BaCl₂·2H₂O)',
N'Muối tinh thể trắng, tan trong nước, có tính độc nhẹ nếu nuốt phải.
Dùng trong phân tích hóa học để xác định ion sunfat và sản xuất muối bari khác.
Ứng dụng trong công nghiệp luyện kim, sơn và thuốc nhuộm.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ẩm và nguồn nhiệt cao.
Khi thao tác cần tránh hít bụi và đeo găng tay bảo hộ.
Xuất xứ: Trung Quốc / Ấn Độ.',
N'Kg', 85000, 120, 'LSP004',    N'sp072.png'),

('SP073', N'Canxi Clorua (CaCl₂) khan',
N'Muối hút ẩm mạnh, dạng hạt trắng, tan tốt trong nước.
Dùng trong làm khô khí, sản xuất bê tông và xử lý nước.
Ứng dụng trong công nghiệp giấy, cao su và thực phẩm.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥94%.
Bảo quản trong bao kín, nơi khô thoáng, tránh ẩm mốc.
Không để gần nước hoặc dung dịch axit mạnh.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 95000, 100, 'LSP004',   N'sp073.png'),

('SP074', N'Kẽm Sunfat (ZnSO₄·7H₂O)',
N'Muối tinh thể trắng xanh, tan trong nước, không cháy.
Dùng trong sản xuất dược phẩm, thuốc trừ sâu và mạ kẽm.
Ứng dụng trong xử lý nước, dệt nhuộm và nông nghiệp.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ánh sáng và độ ẩm.
Tránh để gần bazơ hoặc chất khử mạnh.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 70000, 100, 'LSP004',   N'sp074.png'),

('SP075', N'Sắt (III) Clorua (FeCl₃) 40%',
N'Dung dịch màu nâu vàng, có tính axit, tan hoàn toàn trong nước.
Dùng trong xử lý nước thải, tách photphat và tổng hợp hóa chất.
Ứng dụng làm chất keo tụ và chất oxy hóa trong công nghiệp.
Sản phẩm đạt tiêu chuẩn kỹ thuật GR, nồng độ 40 ±2%.
Bảo quản kín, tránh ánh sáng và môi trường ẩm.
Không để gần bazơ hoặc kim loại dễ oxy hóa.
Xuất xứ: Việt Nam / Malaysia.',
N'Chai 1L', 90000, 100, 'LSP004',   N'sp075.png'),

('SP076', N'Đồng Sunfat (CuSO₄·5H₂O)',
N'Tinh thể màu xanh lam, tan trong nước, có tính hút ẩm nhẹ.
Dùng trong phân tích hóa học, diệt nấm và xử lý nước.
Ứng dụng trong nông nghiệp, điện mạ và giáo dục.
Sản phẩm đạt tiêu chuẩn AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, thoáng mát, tránh ánh sáng.
Không để gần bazơ hoặc chất khử.
Xuất xứ: Việt Nam / Ấn Độ.',
N'Gói 500g', 80000, 120, 'LSP004',   N'sp076.png'),

('SP077', N'Magie Sunfat (MgSO₄·7H₂O)',
N'Tinh thể không màu, tan tốt trong nước, vị hơi đắng.
Dùng trong y học, phân bón và xử lý nước.
Ứng dụng trong dệt, thuộc da và tổng hợp hóa chất.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ẩm và ánh sáng.
Không để gần bazơ hoặc dung dịch kiềm mạnh.
Xuất xứ: Việt Nam / Thái Lan.',
N'Kg', 85000, 150, 'LSP004',   N'sp077.png'),

('SP078', N'Nhôm Sunfat (Al₂(SO₄)₃·18H₂O)',
N'Tinh thể trắng, tan tốt trong nước, có tính axit yếu.
Dùng trong xử lý nước, sản xuất giấy và dệt nhuộm.
Ứng dụng làm chất keo tụ và chất ổn định pH.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥98%.
Bảo quản nơi khô ráo, tránh ẩm và ánh sáng trực tiếp.
Không để gần bazơ hoặc chất khử mạnh.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 85000, 140, 'LSP004',   N'sp078.png'),

('SP079', N'Amoni Clorua (NH₄Cl) tinh khiết',
N'Muối tinh thể trắng, tan hoàn toàn trong nước, không mùi.
Dùng trong sản xuất pin khô, phân bón và thuốc ho.
Ứng dụng trong dung dịch điện phân và tổng hợp hóa học.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Bảo quản nơi khô ráo, tránh ánh sáng và độ ẩm cao.
Không để gần bazơ mạnh hoặc chất oxy hóa.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Kg', 90000, 130, 'LSP004',   N'sp079.png'),

('SP080', N'Amoni Sunfat ((NH₄)₂SO₄)',
N'Muối vô cơ trắng, tan trong nước, không mùi, không cháy.
Dùng làm phân bón, chất ổn định pH và xử lý nước.
Ứng dụng trong công nghiệp thực phẩm và môi trường.
Sản phẩm đạt tiêu chuẩn công nghiệp GR, tinh khiết ≥99%.
Bảo quản nơi khô thoáng, tránh ẩm ướt và ánh sáng mạnh.
Không để gần bazơ hoặc axit đậm đặc.
Xuất xứ: Việt Nam / Ấn Độ.',
N'Kg', 95000, 120, 'LSP004',   N'sp080.png'),

('SP081', N'Dung dịch đệm pH 4.0 tiêu chuẩn',
N'Dung dịch chuẩn màu đỏ cam, được sử dụng để hiệu chuẩn máy đo pH trong phòng thí nghiệm.
Được pha chế chính xác từ các dung dịch axit chuẩn và đạt tiêu chuẩn NIST.
Thích hợp cho các ứng dụng phân tích hóa học, môi trường và thực phẩm.
Dung dịch ổn định pH lâu dài, có thể bảo quản đến 12 tháng nếu đậy kín.
Bảo quản nơi khô ráo, tránh ánh sáng trực tiếp và nhiệt độ cao.
Trước khi sử dụng cần kiểm tra nắp kín và không lẫn tạp chất.
Xuất xứ: Việt Nam / Đức.',
N'Chai 250ml', 70000, 100, 'LSP009',  N'sp081.png'),

('SP082', N'Dung dịch đệm pH 7.0 tiêu chuẩn',
N'Dung dịch đệm trung tính, được sử dụng để kiểm định độ chính xác của điện cực pH.
Đạt tiêu chuẩn quốc tế NIST với sai số ±0.01 đơn vị pH.
Ứng dụng trong hiệu chuẩn máy đo pH trong phòng thí nghiệm và công nghiệp thực phẩm.
Dung dịch ổn định pH trong thời gian dài, không bị bay hơi nhanh.
Bảo quản nơi thoáng mát, tránh ánh sáng trực tiếp và nhiệt độ cao.
Không để dung dịch tiếp xúc không khí trong thời gian dài.
Xuất xứ: Việt Nam / Nhật Bản.',
N'Chai 250ml', 75000, 120, 'LSP009',    N'sp082.png'),

('SP083', N'Dung dịch đệm pH 10.0 tiêu chuẩn',
N'Dung dịch đệm kiềm, dùng trong hiệu chuẩn cảm biến pH cho môi trường bazơ.
Pha chế từ muối vô cơ đạt tiêu chuẩn NIST, đảm bảo độ ổn định cao.
Ứng dụng trong công nghiệp dược, xử lý nước và sản xuất hóa chất.
Dung dịch có tuổi thọ cao, bảo quản tốt trong điều kiện khô mát.
Không để tiếp xúc ánh sáng hoặc hơi ẩm trong thời gian dài.
Khi mở nắp, nên sử dụng trong vòng 30 ngày để đảm bảo độ chính xác.
Xuất xứ: Việt Nam / Đức.',
N'Chai 250ml', 75000, 80, 'LSP009',   N'sp083.png'),

('SP084', N'Dung dịch chuẩn AgNO₃ 0.1M',
N'Dung dịch bạc nitrat chuẩn, dùng trong chuẩn độ xác định ion clorua và halogen.
Đạt tiêu chuẩn phân tích chuẩn độ Titrimetric Reagent.
Ứng dụng trong kiểm nghiệm nước, phân tích hóa học và giảng dạy.
Dung dịch có độ tinh khiết cao, được pha sẵn với nồng độ chính xác 0.1M ±0.001.
Bảo quản trong chai tối màu, tránh ánh sáng và nhiệt độ cao.
Không để gần vật liệu dễ oxy hóa hoặc dung môi hữu cơ.
Xuất xứ: Việt Nam / Đức.',
N'Chai 250ml', 130000, 80, 'LSP010',   N'sp084.png'),

('SP085', N'Dung dịch chuẩn Na₂S₂O₃ 0.1M',
N'Dung dịch chuẩn natri thiosunfat 0.1M, được dùng trong các phép chuẩn độ iod.
Đạt tiêu chuẩn phân tích Titrimetric Reagent với độ chính xác cao.
Ứng dụng trong kiểm nghiệm hóa học, môi trường và dược phẩm.
Dung dịch ổn định nếu bảo quản trong tối, tránh oxy và ánh sáng trực tiếp.
Cần kiểm tra nồng độ định kỳ để đảm bảo độ chính xác.
Khi thao tác cần dùng pipet sạch và không lẫn tạp chất kim loại.
Xuất xứ: Việt Nam / Nhật Bản.',
N'Chai 250ml', 130000, 80, 'LSP010',   N'sp085.png'),

('SP086', N'Phenolphthalein chỉ thị màu',
N'Chất chỉ thị pH phổ biến, đổi màu từ không sang hồng trong môi trường kiềm (pH 8.2–10.0).
Dạng dung dịch trong ethanol, dùng trong chuẩn độ axit-bazơ.
Đạt tiêu chuẩn phân tích GR, độ tinh khiết ≥99%.
Ứng dụng trong phân tích định lượng, giảng dạy và nghiên cứu.
Bảo quản nơi khô ráo, tránh ánh sáng và nhiệt độ cao.
Khi thao tác nên tránh tiếp xúc trực tiếp với da và mắt.
Xuất xứ: Việt Nam / Đức.',
N'Chai 100ml', 120000, 90, 'LSP005',   N'sp086.png'),

('SP087', N'Methyl Orange chỉ thị pH',
N'Chất chỉ thị axit-bazơ, chuyển màu từ đỏ sang vàng trong khoảng pH 3.1–4.4.
Dùng trong các phép chuẩn độ axit mạnh – bazơ yếu.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Ứng dụng trong phòng thí nghiệm, nghiên cứu hóa học và giảng dạy.
Bảo quản nơi khô ráo, tránh ánh sáng và ẩm ướt.
Không để gần dung môi hữu cơ hoặc chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Chai 100ml', 100000, 90, 'LSP005',   N'sp087.png'),

('SP088', N'Methyl Blue thuốc nhuộm phân tích',
N'Thuốc nhuộm màu xanh lam đậm, tan tốt trong nước và ethanol.
Dùng trong nhuộm mô học, phân tích tế bào và vi sinh vật.
Đạt tiêu chuẩn phân tích GR, độ tinh khiết ≥98%.
Ứng dụng trong sinh học, y học và hiển vi học.
Bảo quản kín, nơi khô ráo, tránh ánh sáng trực tiếp.
Khi thao tác cần đeo găng tay và khẩu trang.
Xuất xứ: Việt Nam / Ấn Độ.',
N'Chai 100ml', 95000, 90, 'LSP005',   N'sp088.png'),

('SP089', N'Sudan III thuốc nhuộm lipid',
N'Thuốc nhuộm đỏ cam, không tan trong nước, tan trong dung môi hữu cơ.
Dùng để phát hiện lipid trong mô sinh học và kính hiển vi.
Đạt tiêu chuẩn sinh học GR, tinh khiết ≥98%.
Ứng dụng trong nghiên cứu y học, mô học và sinh hóa học.
Bảo quản nơi khô, tránh ánh sáng và hơi ẩm.
Tránh hít bụi và tiếp xúc trực tiếp với da.
Xuất xứ: Việt Nam / Đức.',
N'Chai 100ml', 95000, 90, 'LSP005',   N'sp089.png'),

('SP090', N'Cresol Red chỉ thị màu pH',
N'Chất chỉ thị màu có vùng chuyển màu từ vàng sang đỏ trong khoảng pH 7.2–8.8.
Dùng trong các phản ứng hóa học, sinh học và dung dịch đệm.
Sản phẩm đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Ứng dụng trong nghiên cứu hóa phân tích và môi trường.
Bảo quản nơi khô ráo, tránh ánh sáng trực tiếp.
Không để gần bazơ mạnh hoặc dung môi dễ bay hơi.
Xuất xứ: Việt Nam / Nhật Bản.',
N'Chai 100ml', 120000, 80, 'LSP005',   N'sp090.png'),

('SP091', N'Ethidium Bromide dung dịch 10mg/ml',
N'Thuốc nhuộm huỳnh quang đỏ cam, dùng phát hiện DNA trong điện di agarose.
Có độ nhạy cao, phát sáng mạnh dưới tia UV 302 nm.
Ứng dụng trong sinh học phân tử và nghiên cứu gen.
Cần thao tác cẩn thận vì có tính đột biến DNA.
Bảo quản trong tối, nhiệt độ 2–8°C và tránh tiếp xúc trực tiếp.
Khi đổ thải phải theo quy trình an toàn sinh học cấp II.
Xuất xứ: Mỹ / Nhật Bản.',
N'Chai 10ml', 250000, 60, 'LSP005',  N'sp091.png'),
('SP092', N'SDS (Sodium Dodecyl Sulfate) tinh khiết',
N'Tác nhân hoạt động bề mặt anion, dùng trong điện di protein SDS-PAGE.
Dạng bột trắng, tan hoàn toàn trong nước, tạo bọt cao.
Đạt tiêu chuẩn phân tích GR, tinh khiết ≥99%.
Ứng dụng trong sinh học, dược phẩm và làm sạch protein.
Bảo quản nơi khô ráo, tránh ẩm và ánh sáng trực tiếp.
Không để gần axit hoặc chất oxy hóa mạnh.
Xuất xứ: Trung Quốc / Nhật Bản.',
N'Gói 500g', 150000, 80, 'LSP008',    N'sp092.png'),

('SP093', N'EDTA (Ethylenediaminetetraacetic Acid)',
N'Tác nhân tạo phức với ion kim loại, dùng ổn định dung dịch hóa chất và dược phẩm.
Dạng tinh thể trắng, tan trong nước và ethanol.
Đạt tiêu chuẩn phân tích AR, tinh khiết ≥99%.
Ứng dụng trong hóa học, y học và môi trường.
Bảo quản nơi khô ráo, tránh ẩm và ánh sáng.
Không để gần axit mạnh hoặc chất oxy hóa.
Xuất xứ: Việt Nam / Trung Quốc.',
N'Gói 500g', 180000, 90, 'LSP008',   N'sp093.png'),

('SP094', N'PVP (Polyvinylpyrrolidone)',
N'Polymer tan trong nước, có khả năng ổn định keo và tạo màng mịn.
Dùng trong dược phẩm, mỹ phẩm và chế phẩm sinh học.
Đạt tiêu chuẩn USP / BP, tinh khiết ≥99%.
Ứng dụng làm chất kết dính, tá dược và chất ổn định.
Bảo quản nơi khô ráo, tránh ánh sáng và nhiệt độ cao.
Không để gần dung môi hữu cơ hoặc bazơ mạnh.
Xuất xứ: Việt Nam / Hàn Quốc.',
N'Gói 500g', 185000, 80, 'LSP008',   N'sp094.png'),

('SP095', N'Tween 80 (Polysorbate 80)',
N'Chất nhũ hóa không ion, tan trong nước, tạo dung dịch trong suốt.
Dùng trong thực phẩm, dược phẩm, và công nghệ sinh học.
Đạt tiêu chuẩn USP / EP, tinh khiết ≥99%.
Ứng dụng làm chất hòa tan, chất ổn định và tá dược.
Bảo quản nơi khô mát, tránh ánh sáng trực tiếp.
Không để gần chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Mỹ.',
N'Chai 500ml', 160000, 100, 'LSP008',   N'sp095.png'),

('SP096', N'Triton X-100 chất hoạt động bề mặt',
N'Chất hoạt động bề mặt không ion, dùng phá màng tế bào và tách protein.
Dạng dung dịch nhớt, tan trong nước và ethanol.
Đạt tiêu chuẩn sinh học GR, tinh khiết ≥99%.
Ứng dụng trong sinh học phân tử, hóa sinh và vi sinh vật học.
Bảo quản nơi khô ráo, tránh nhiệt độ cao.
Không để gần chất oxy hóa hoặc dung môi mạnh.
Xuất xứ: Đức / Việt Nam.',
N'Chai 500ml', 170000, 90, 'LSP008',   N'sp096.png'),

('SP097', N'Hydrogen Peroxide (H₂O₂) 3% dung dịch tẩy rửa',
N'Dung dịch oxy hóa nhẹ, không màu, có khả năng khử trùng và tẩy trắng hiệu quả.
Dùng làm dung dịch sát khuẩn, tẩy vết bẩn và khử mùi.
Đạt tiêu chuẩn dược phẩm USP, nồng độ 3% ±0.2%.
Ứng dụng trong y tế, thực phẩm và phòng thí nghiệm.
Bảo quản trong chai tối màu, tránh ánh sáng và nhiệt độ cao.
Không để gần dung môi hữu cơ hoặc kim loại dễ oxy hóa.
Xuất xứ: Việt Nam / Nhật Bản.',
N'Chai 1L', 85000, 120, 'LSP006',   N'sp097.png'),

('SP098', N'Axetonitrile (CH₃CN) dung môi sắc ký',
N'Dung môi hữu cơ phân cực cao, bay hơi nhanh, không màu và mùi nhẹ.
Dùng trong sắc ký lỏng hiệu năng cao (HPLC) và phân tích dược phẩm.
Đạt tiêu chuẩn HPLC Grade, tinh khiết ≥99.9%.
Ứng dụng trong tổng hợp hữu cơ và hóa sinh học.
Bảo quản nơi thoáng mát, tránh ánh sáng và nguồn nhiệt.
Không để gần chất oxy hóa hoặc bazơ mạnh.
Xuất xứ: Đức / Nhật Bản.',
N'Chai 500ml', 180000, 100, 'LSP001',   N'sp098.png'),

('SP099', N'Dimethyl Sulfoxide (DMSO) dung môi phân tích',
N'Dung môi phân cực mạnh, không bay hơi nhanh, trộn lẫn với nước và ethanol.
Dùng trong sinh học, dược phẩm, và hóa học phân tích.
Đạt tiêu chuẩn phân tích AR, tinh khiết ≥99.9%.
Ứng dụng làm dung môi hòa tan hợp chất hữu cơ và bảo quản tế bào.
Bảo quản nơi khô ráo, tránh ánh sáng và nhiệt độ cao.
Không để gần chất oxy hóa hoặc axit mạnh.
Xuất xứ: Đức / Mỹ.',
N'Chai 500ml', 190000, 90, 'LSP001',   N'sp099.png'),

('SP100', N'Isopropanol (C₃H₈O) tinh khiết 99.9%',
N'Dung môi bay hơi nhanh, không để lại cặn, tan tốt trong nước và ethanol.
Dùng trong tẩy rửa, khử trùng, và chiết tách hữu cơ.
Đạt tiêu chuẩn công nghiệp HPLC Grade, tinh khiết ≥99.9%.
Ứng dụng trong sản xuất điện tử, dược phẩm và thí nghiệm.
Bảo quản kín, nơi khô thoáng, tránh ánh sáng và nguồn nhiệt.
Không để gần ngọn lửa hoặc chất oxy hóa mạnh.
Xuất xứ: Việt Nam / Nhật Bản.',
N'Chai 1L', 130000, 120, 'LSP001',   N'sp100.png'),

('SP101', N'Axit Sunfuric 98%', 
N'Dung dịch axit sunfuric đậm đặc ≥98%, dạng lỏng hơi vàng, độ ăn mòn cao. 
Ứng dụng trong xử lý nước, luyện kim, mạ điện và sản xuất phân bón. 
Khi pha loãng phải đổ axit vào nước để tránh bắn tóe. 
Bảo quản nơi thoáng mát, tránh ánh nắng.', 
N'Can 30kg', 720000, 120, 'LSP007',  N'sp101.png'),

('SP102', N'Xút Vảy NaOH 99%', 
N'Xút vảy trắng tinh khiết ≥99%, tan mạnh trong nước, tạo nhiệt nhiều. 
Dùng trong tẩy rửa công nghiệp, sản xuất xà phòng, giấy và xử lý nước.
Bảo quản kín trong bao để tránh hút ẩm.', 
N'Bao 25kg', 365000, 180, 'LSP007',  N'sp102.png'),

('SP103', N'Kali Hydroxit KOH 90%', 
N'KOH dạng hạt trắng, hàm lượng 90%, dễ hòa tan trong nước và tạo dung dịch kiềm mạnh. 
Ứng dụng trong pin kiềm, phân bón, dược phẩm và các ngành công nghiệp hóa chất.
Khi tiếp xúc gây ăn mòn mạnh.', 
N'Bao 25kg', 690000, 95, 'LSP007',  N'sp103.png'),

('SP104', N'Acetone Công Nghiệp', 
N'Dung môi Acetone trong suốt, bay hơi nhanh, dùng trong tẩy dầu mỡ khuôn nhựa, pha sơn và làm sạch bề mặt. 
Dễ cháy nên cần tránh xa nguồn nhiệt. 
Hơi dung môi có thể gây chóng mặt nếu hít lâu.', 
N'Can 20L', 480000, 150, 'LSP007',   N'sp104.png'),

('SP105', N'Toluene Công Nghiệp', 
N'Dung môi Toluene tinh khiết, không màu, mùi nhẹ, tan tốt trong nhiều chất hữu cơ. 
Dùng trong sơn, mực in, cao su và sản xuất keo. 
Là chất dễ cháy, cần bảo quản xa nguồn nhiệt và thông gió tốt khi dùng.', 
N'Phuy 200L', 9800000, 20, 'LSP007',  N'sp105.png'),

('SP106', N'Xylene Công Nghiệp', 
N'Xylene là dung môi quan trọng trong ngành sơn và mực in. 
Dạng lỏng không màu, ít tan trong nước. Bay hơi nhanh, dễ cháy. 
Cần đeo mặt nạ hơi và găng tay khi sử dụng. 
Thường dùng trong công nghệ sơn PU.', 
N'Phuy 200L', 10100000, 18, 'LSP007',  N'sp106.png'),

('SP107', N'Ethyl Acetate (EA)', 
N'Dung môi EA màu trong, mùi dễ chịu, khả năng hòa tan cao. 
Ứng dụng trong mực in, sơn PU, sản xuất keo và công nghiệp da giày. 
Bay hơi nhanh nên dễ gây cháy.', 
N'Can 20L', 520000, 130, 'LSP007',  N'sp107.png'),

('SP108', N'Axit Photphoric 85%', 
N'Axit Photphoric dạng lỏng sánh, màu trong suốt. 
Dùng trong hóa chất tẩy rửa, xử lý kim loại và sản xuất phân bón. 
An toàn hơn các axit vô cơ mạnh nhưng vẫn gây ăn mòn nhẹ. 
Tránh tiếp xúc lâu với da.', 
N'Can 35kg', 760000, 75, 'LSP007', N'sp108.png'),

('SP109', N'KMnO₄ 99% (Thuốc tím)', 
N'Kristal KMnO₄ màu tím đậm, độ tinh khiết 99%, khả năng oxi hóa mạnh. 
Dùng trong xử lý nước cấp, nước thải, khử mùi và tẩy rửa công nghiệp. 
Bảo quản kín tránh ánh sáng vì dễ phân hủy.', 
N'Kg', 35000, 150, 'LSP007',  N'sp109.png'),

('SP110', N'Calcium Chloride CaCl₂ 95%', 
N'CaCl₂ dạng hạt trắng, hút ẩm rất mạnh. 
Dùng trong chống ẩm, xử lý nước, chống đóng băng đường và tăng độ cứng bê tông. 
Cần bảo quản trong bao nhiều lớp để tránh hút ẩm từ không khí.', 
N'Bao 25kg', 285000, 200, 'LSP007',   N'sp110.png'),

('SP111', N'Magie Sulfat MgSO₄ (Phân biệt dược – kỹ thuật)', 
N'MgSO₄ dạng tinh thể trắng, tan tốt trong nước. 
Dùng trong xử lý nước, dệt nhuộm, sản xuất phân bón và chất phụ gia. 
Không độc ở liều kỹ thuật nhưng có thể gây kích ứng mắt khi tiếp xúc trực tiếp. 
Bảo quản nơi khô ráo, tránh ánh sáng và độ ẩm. 
Xuất xứ: Trung Quốc.', 
N'Bao 25kg', 360000, 140, 'LSP007',  N'sp111.png'),

('SP112', N'Natri Nitrit NaNO₂ 99%',
N'NaNO₂ dạng bột trắng, hàm lượng ≥99 %. Ứng dụng trong xi mạ, xử lý nước và chất ổn định trong công nghiệp hóa chất. 
Độc tính cao khi uống phải, cần cất giữ tránh xa thực phẩm. 
Bảo quản nơi thoáng mát, bao bì kín.', 
N'Bao 25kg', 520000, 90, 'LSP007',  N'sp112.png'),

('SP113', N'Natri Sunfite Na₂SO₃ 97%', 
N'Na₂SO₃ dạng bột trắng, tan nhanh trong nước. 
Dùng trong tẩy trắng giấy, dệt, xử lý nước và công nghiệp thực phẩm (loại công nghiệp). 
Có tính khử mạnh, dễ phản ứng với acid tạo ra SO₂. 
Bảo quản tránh ẩm.', 
N'Bao 25kg', 340000, 180, 'LSP007',  N'sp113.png'),

('SP114', N'Đồng Sunfat CuSO₄ 98% (Phèn xanh)', 
N'CuSO₄ dạng tinh thể xanh lam, tan nhanh trong nước. 
Dùng trong xử lý nước, diệt nấm trong nông nghiệp và nhiều ứng dụng công nghiệp khác. 
Gây kích ứng da và mắt nếu tiếp xúc lâu. 
Bảo quản trong bao kín, tránh ẩm và ánh sáng.', 
N'Bao 25kg', 650000, 120, 'LSP007',  N'sp114.png'),

('SP115', N'Natri Cacbonat Na₂CO₃ (Soda Ash Light)', 
N'Na₂CO₃ dạng bột trắng, tan tốt trong nước. 
Ứng dụng trong thủy tinh, xử lý nước, sản xuất xà phòng và chất tẩy rửa. 
Không độc nhưng gây kích ứng nhẹ khi tiếp xúc da. 
Bảo quản nơi khô thoáng, tránh tiếp xúc trực tiếp với không khí ẩm.', 
N'Bao 50kg', 480000, 160, 'LSP007', N'sp115.png'),

('SP116', N'EDTA 4Na (Ethylenediaminetetraacetic acid 4Na)', 
N'EDTA 4Na dạng hạt trắng, dùng để tạo phức kim loại trong xử lý nước công nghiệp và dệt nhuộm. 
Tan tốt trong nước, ổn định hóa học cao. 
Cần bảo quản kín vì dễ hút ẩm. 
Không gây mùi, an toàn tương đối nếu thao tác đúng cách.', 
N'Bao 25kg', 880000, 75, 'LSP007',  N'sp116.png'),

('SP117', N'Chlorine Ca(OCl)₂ 70% (Canxi Hypoclorit)', 
N'Chlorine dạng bột hạt trắng ngà, hàm lượng 65–70%. Dùng khử trùng nước hồ bơi, xử lý nước cấp và nước thải. 
Có mùi mạnh, dễ gây kích ứng đường hô hấp. 
Bảo quản bao kín, tránh nguồn nhiệt và ẩm.', 
N'Bao 45kg', 1450000, 40, 'LSP007',  N'sp117.png'),

('SP118', N'Axit Clohydric HCl 32%', 
N'HCl 32% dạng lỏng trong suốt, mùi mạnh, ăn mòn cao. 
Dùng trong tẩy rỉ sét kim loại, xử lý nước và sản xuất PVC. 
Cần tránh hít hơi acid, nên dùng nơi thoáng khí. 
Đóng gói trong can nhựa đặc.', 
N'Can 30kg', 320000, 180, 'LSP007',  N'sp118.png'),

('SP119', N'Natri Hypochlorite NaClO 12%', 
N'NaClO dạng dung dịch vàng nhạt, có tính oxi hóa mạnh. 
Dùng sát khuẩn, khử trùng nước và tẩy trắng công nghiệp. 
Dễ phân hủy khi tiếp xúc ánh sáng mạnh. 
Nên bảo quản nơi mát và tối.', 
N'Can 30L', 240000, 210, 'LSP007',  N'sp119.png'),
('SP120', N'Butyl Acetate (BA) Dung môi công nghiệp', 
N'Butyl Acetate là dung môi quan trọng trong sơn, mực in và công nghiệp da giày. 
Mùi thơm nhẹ, độ bay hơi trung bình, dễ cháy khi gặp lửa. 
Cần thao tác trong điều kiện thông gió tốt. 
Đóng can hoặc phuy theo tiêu chuẩn.', 
N'Can 20L', 560000, 110, 'LSP007',   N'sp120.png'),

('SP121', N'Acid Oxalic (Axit Oxalic) 99%', 
N'Axit oxalic dạng tinh thể trắng, hàm lượng 99%, tan tốt trong nước. 
Dùng trong tẩy rỉ sét kim loại, làm sáng gỗ, giặt tẩy công nghiệp và xử lý bề mặt. 
Có tính ăn mòn nhẹ và gây kích ứng da. Khi thao tác cần mang găng tay và khẩu trang. 
Bảo quản nơi khô thoáng, tránh ánh sáng.', 
N'Bao 25kg', 720000, 95, 'LSP007',  N'sp121.png'),

('SP122', N'Sodium Bicarbonate NaHCO₃ (Muối nở kỹ thuật)', 
N'NaHCO₃ dạng bột trắng, độ tinh khiết cấp kỹ thuật. 
Dùng trong xử lý nước, trung hòa acid, công nghiệp dệt và sản xuất hóa chất. 
Tính ổn định cao, an toàn khi tiếp xúc nhẹ. 
Bảo quản trong bao kín để tránh ẩm.', 
N'Bao 25kg', 310000, 180, 'LSP007',  N'sp122.png'),

('SP123', N'Formalin 37% (Formaldehyde)', 
N'Dung dịch Formalin 37% dạng lỏng trong suốt có mùi mạnh, được dùng trong tẩy rửa, diệt khuẩn và sản xuất nhựa UF/MF. 
Hơi formaldehyde độc, cần dùng trong khu vực thông gió tốt. 
Tránh tiếp xúc trực tiếp với da. Bảo quản kín và xa nguồn nhiệt.', 
N'Can 30L', 450000, 120, 'LSP007',  N'sp123.png'),

('SP124', N'Sodium Lauryl Sulfate (SLS) 95%', 
N'SLS dạng bột trắng, là chất hoạt động bề mặt mạnh dùng trong sản xuất chất tẩy rửa, dầu gội và xà phòng công nghiệp. 
Tan nhanh trong nước, tạo bọt cao. 
Khi tiếp xúc trực tiếp có thể gây kích ứng da. 
Bảo quản trong bao kín tránh ẩm.', 
N'Bao 25kg', 820000, 160, 'LSP007',  N'sp124.png'),

('SP125', N'Sodium Benzoate (C6H5COONa) kỹ thuật', 
N'Chất bảo quản công nghiệp dạng bột trắng, tan nhanh trong nước. 
Ứng dụng trong sản xuất chất tẩy rửa, dệt nhuộm và một số ngành hóa chất. 
Ổn định ở nhiệt độ thường nhưng cần tránh ánh sáng mạnh. 
Bảo quản nơi khô ráo.', 
N'Bao 25kg', 890000, 60, 'LSP007',  N'sp125.png'),

('SP126', N'Decanol (C10H21OH)', 
N'Decanol là alcohol béo dạng lỏng không màu, mùi nhẹ. 
Thường dùng làm dung môi trong hương liệu, chất tẩy rửa và phụ gia công nghiệp. 
Không tan trong nước nhưng tan trong dung môi hữu cơ. 
Dễ cháy nên bảo quản xa nguồn nhiệt.', 
N'Can 20L', 1150000, 45, 'LSP007', N'sp126.png'),

('SP127', N'Acid Formic 85%', 
N'Axit formic dạng lỏng không màu, mùi hăng, tính acid mạnh.
Ứng dụng trong cao su, thuộc da, hóa chất nông nghiệp và phụ gia công nghiệp. 
Dễ bay hơi nên phải đậy kín khi bảo quản. 
Tiếp xúc trực tiếp gây bỏng nhẹ cho da.', 
N'Can 25kg', 680000, 110, 'LSP007',  N'sp127.png'),

('SP128', N'Perchloroethylene (PCE)', 
N'PCE dạng lỏng trong suốt, được dùng trong giặt khô công nghiệp, tẩy dầu mỡ kim loại và dung môi chuyên dụng. 
Không cháy nhưng hơi độc, cần dùng trong môi trường thông gió tốt. 
Hạn chế tiếp xúc lâu dài.', 
N'Can 20L', 1240000, 35, 'LSP007',   N'sp128.png'),

('SP129', N'MEK (Methyl Ethyl Ketone)', 
N'MEK là dung môi bay hơi nhanh, không màu, mùi nhẹ. 
Được dùng rộng rãi trong sơn PU, keo dán và tẩy dầu mỡ công nghiệp. 
Có khả năng cháy cao, tránh sử dụng gần nguồn lửa. 
Hít hơi lâu có thể gây đau đầu.', 
N'Can 20L', 650000, 150, 'LSP007',  N'sp129.png'),

('SP130', N'Styrene Monomer (SM)', 
N'Styrene dạng lỏng trong suốt, là monomer quan trọng dùng trong sản xuất nhựa PS, ABS, SBR, và cao su tổng hợp. 
Dễ bay hơi và cháy mạnh. 
Cần bảo quản trong phuy kín và thêm chất chống oxi hóa để ổn định. 
Dùng trong môi trường có thông gió tốt.', 
N'Phuy 200L', 9500000, 22, 'LSP007',  N'sp130.png'),

('SP131', N'Ammonium Bicarbonate NH₄HCO₃', 
N'NH₄HCO₃ dạng tinh thể trắng, dễ phân hủy khi tiếp xúc với nhiệt cao. 
Dùng trong sản xuất phân bón, xử lý nước và công nghiệp thực phẩm (cấp kỹ thuật). 
Hít phải bột có thể gây kích ứng nhẹ. 
Bảo quản nơi khô, thoáng và tránh ánh nắng trực tiếp. 
Bao bì cần kín để hạn chế bay hơi.', 
N'Bao 25kg', 390000, 160, 'LSP007',  N'sp131.png'),

('SP132', N'Ammonium Sulfate (Phân SA công nghiệp)', 
N'Phân SA dạng tinh thể trắng, hàm lượng 21% Nitơ và 24% lưu huỳnh. 
Dùng rộng rãi trong xử lý nước công nghiệp, dệt nhuộm và sản xuất phân bón. 
Ổn định hóa học, ít hút ẩm. 
Cần bảo quản nơi khô để tránh kết khối. 
Xuất xứ: Nhật Bản/Trung Quốc.', 
N'Bao 50kg', 610000, 140, 'LSP007',  N'sp132.png'),

('SP133', N'Boric Acid (Axit Boric) 99.5%', 
N'Axit Boric dạng bột trắng siêu mịn, độ tinh khiết cao, tan chậm trong nước lạnh nhưng tan nhanh trong nước nóng. 
Ứng dụng trong thủy tinh, gốm sứ, chất chống cháy và hóa chất bảo quản. 
Tính độc thấp nhưng không nên để tiếp xúc lâu với da. 
Bảo quản kín và tránh ẩm.', 
N'Bao 25kg', 920000, 80, 'LSP007',  N'sp133.png'),

('SP134', N'Aluminium Hydroxide Al(OH)₃', 
N'Al(OH)₃ dạng bột trắng, độ tinh khiết cao. 
Dùng trong sản xuất nhôm, chống cháy, nhựa composite và xử lý nước. 
Không độc nhưng có thể gây bụi khi thao tác.
Bảo quản nơi khô thoáng và tránh nguồn nhiệt cao.', 
N'Bao 25kg', 780000, 120, 'LSP007', N'sp134.png'),

('SP135', N'Calcium Carbonate CaCO₃ (Bột đá trắng)', 
N'CaCO₃ dạng bột mịn, được sử dụng làm phụ gia trong nhựa, sơn, cao su và xây dựng. 
Không tan trong nước, tính ổn định cao, an toàn khi sử dụng. 
Cần tránh để bụi bay khi đổ bao. 
Xuất xứ phổ biến: Nghệ An/Trung Quốc.', 
N'Bao 25kg', 110000, 260, 'LSP007',  N'sp135.png'),

('SP136', N'Bentonite Hạt Công Nghiệp', 
N'Bentonite dạng hạt màu nâu nhạt, có khả năng hút nước và trương nở mạnh. 
Dùng trong thức ăn chăn nuôi, xử lý nước, khoan dầu và ngành đúc. 
Không độc nhưng có bụi mịn. 
Bảo quản nơi khô để duy trì khả năng hút nước.', 
N'Bao 25kg', 170000, 200, 'LSP007',  N'sp136.png'),

('SP137', N'Kaolin (Đất Sét Trắng)', 
N'Kaolin dạng bột trắng, độ mịn cao, dùng trong gốm sứ, sơn, giấy và mỹ phẩm công nghiệp. 
Không tan trong nước và có tính ổn định cao. 
Không độc nhưng bụi có thể gây kích ứng mũi. 
Nên bảo quản nơi khô.', 
N'Bao 25kg', 155000, 180, 'LSP007',   N'sp137.png'),

('SP138', N'Triethanolamine (TEA) 99%', 
N'TEA dạng lỏng sánh không màu, tan tốt trong nước. 
Dùng sản xuất chất tẩy rửa, mỹ phẩm, sơn và phụ gia xi măng. 
Không dễ cháy nhưng có thể gây kích ứng da nhẹ. 
Bảo quản trong can kín, tránh ánh sáng mạnh.', 
N'Can 25kg', 950000, 70, 'LSP007',  N'sp138.png'),

('SP139', N'Diethylene Glycol (DEG)', 
N'DEG dạng lỏng trong suốt, không màu, tan trong nước và dung môi hữu cơ. 
Dùng trong sản xuất Polyme, tẩy rửa và dung môi công nghiệp. 
Nếu uống nhầm rất độc. 
Cần bảo quản tránh xa thực phẩm và thức uống.', 
N'Can 25kg', 720000, 90, 'LSP007',  N'sp139.png'),

('SP140', N'Propylene Glycol (PG)', 
N'Propylene Glycol dạng lỏng không màu, độ tinh khiết cao, ít mùi. 
Dùng trong thực phẩm, mỹ phẩm, dược phẩm và công nghiệp hóa chất. 
Tính an toàn cao hơn so với EG. 
Bảo quản nơi mát, tránh ánh nắng để tránh đổi màu.', 
N'Can 25kg', 980000, 65, 'LSP007',  N'sp140.png'),

('SP141', N'Ethylene Glycol (EG)', 
N'EG dạng lỏng không màu, nhớt nhẹ, tan hoàn toàn trong nước. 
Ứng dụng làm chất chống đông, phụ gia làm mát động cơ, dung môi và nguyên liệu sản xuất polymer. 
Độc tính cao nếu uống phải. 
Bảo quản nơi mát, tránh ánh sáng mạnh.', 
N'Can 25kg', 890000, 70, 'LSP007',  N'sp141.png'),

('SP142', N'Isopropyl Alcohol (IPA) 99.7%', 
N'IPA là dung môi sát khuẩn nhanh, không màu, bay hơi mạnh. 
Dùng trong điện tử, y tế, làm sạch linh kiện và pha loãng mực in.
Dễ cháy mạnh nên phải tránh nguồn nhiệt. 
Khi hít nhiều có thể gây chóng mặt.', 
N'Can 20L', 640000, 150, 'LSP007', N'sp142.png'),

('SP143', N'Butanol Công Nghiệp (C₄H₁₀O)', 
N'Butanol dạng lỏng trong suốt, mùi nhẹ, tan tốt trong dung môi hữu cơ. 
Dùng trong sản xuất nhựa alkyd, sơn và dung môi pha mực. 
Dễ cháy và bay hơi, nên sử dụng trong môi trường thông gió tốt. 
Tránh tiếp xúc với da lâu.', 
N'Can 20L', 710000, 90, 'LSP007',  N'sp143.png'),

('SP144', N'Isobutanol Công Nghiệp', 
N'Isobutanol là dung môi hữu cơ phổ biến trong sơn, nhựa và keo công nghiệp. 
Độ bay hơi trung bình, mùi nhẹ. 
Khi hít nhiều có thể gây đau đầu. 
Dễ cháy nên bảo quản xa nguồn đánh lửa.', 
N'Can 20L', 745000, 80, 'LSP007',  N'sp144.png'),

('SP145', N'Sorbitol 70% (Dung dịch)', 
N'Sorbitol dạng lỏng trong suốt, vị ngọt nhẹ, dùng trong mỹ phẩm, chất tẩy rửa và công nghiệp thực phẩm (loại kỹ thuật). 
Ổn định, ít bay hơi nhưng cần bảo quản nơi mát để tránh đổi màu. 
Không độc nhưng có thể gây kích ứng nhẹ.', 
N'Can 30kg', 560000, 100, 'LSP007',  N'sp145.png'),

('SP146', N'Sodium Gluconate (C₆H₁₁O₇Na)', 
N'Sodium Gluconate dạng bột trắng, tan trong nước, dùng làm chất ức chế ăn mòn trong bê tông, tẩy rửa công nghiệp và xử lý nước. 
Ổn định hóa học và không độc. 
Bảo quản trong bao kín để tránh ẩm.', 
N'Bao 25kg', 950000, 55, 'LSP007',  N'sp146.png'),

('SP147', N'Calcium Oxide (Vôi nung) CaO 90%', 
N'CaO dạng bột hoặc cục trắng, tỏa nhiệt mạnh khi tiếp xúc nước. Dùng trong xử lý nước, xây dựng, luyện kim và công nghiệp hóa chất. 
Bụi CaO gây kích ứng mắt và da. 
Bảo quản trong kho khô ráo, tránh hơi nước.', 
N'Bao 20kg', 95000, 300, 'LSP007',  N'sp147.png'),

('SP148', N'Sodium Metabisulfite (Na₂S₂O₅)', 
N'Na₂S₂O₅ dạng bột trắng, mùi nhẹ SO₂. 
Dùng trong xử lý nước, tẩy trắng giấy, dệt nhuộm và bảo quản công nghiệp. 
Dễ hút ẩm và phân hủy khi tiếp xúc không khí. 
Bảo quản bao kín, tránh ánh sáng và ẩm.', 
N'Bao 25kg', 420000, 140, 'LSP007',   N'sp148.png'),

('SP149', N'Sodium Thiosulfate Na₂S₂O₃·5H₂O', 
N'Na₂S₂O₃ dạng tinh thể trắng trong, tan nhanh trong nước. 
Dùng trong xử lý clo dư, nhiếp ảnh, mạ điện và dệt nhuộm. 
Ổn định ở điều kiện thường nhưng tránh ánh sáng mạnh để không phân hủy. 
Không độc khi tiếp xúc nhẹ.', 
N'Bao 25kg', 390000, 120, 'LSP007',  N'sp149.png'),

('SP150', N'Poly Aluminium Chloride PAC 30%', 
N'PAC dạng bột vàng nhạt, là chất keo tụ mạnh dùng trong xử lý nước sạch và nước thải công nghiệp. 
Tốc độ keo tụ nhanh hơn phèn nhôm truyền thống.
Không gây ăn mòn mạnh, an toàn khi thao tác đúng quy định. 
Bảo quản nơi khô, thoáng mát.', 
N'Bao 25kg', 265000, 220, 'LSP007', N'sp150.png'),

('SP151', N'Ure 46% (Đạm hạt trắng)', 
N'Ure 46% dạng hạt trắng, tan nhanh trong nước và có hàm lượng đạm cao nhất trong các loại phân. 
Dùng bón thúc cho lúa, rau màu và cây công nghiệp. 
Hiệu quả nhanh nhưng dễ bay hơi nếu bón sai cách. 
Nên vùi vào đất hoặc hòa nước tưới để tăng hiệu suất. 
Bảo quản nơi khô để tránh vón cục.', 
N'Bao 50kg', 610000, 300, 'LSP012',  N'sp151.png'),

('SP152', N'Kali Clorua KCl đỏ 61%', 
N'Kali đỏ dạng hạt, hàm lượng K₂O khoảng 60–61%, dùng tăng cứng cây, phát triển rễ và tăng năng suất trái. 
Thích hợp cho cây công nghiệp như cà phê, tiêu, điều. 
Cần tránh bón trực tiếp vào gốc vì có thể gây cháy rễ. 
Bảo quản nơi khô ráo.', 
N'Bao 50kg', 690000, 210, 'LSP012',  N'sp152.png'),

('SP153', N'DAP 18-46-0 (Phân hỗn hợp cao cấp)', 
N'DAP dạng hạt đen, chứa 18% Nitơ và 46% lân dễ tiêu. 
Giúp kích thích bộ rễ, thúc đẩy ra hoa và ổn định trái. 
Hạt tan chậm nên có hiệu quả lâu dài. 
Thường dùng bón lót hoặc bón thúc sớm. 
Bảo quản bao kín để tránh hút ẩm.', 
N'Bao 50kg', 1050000, 150, 'LSP012',  N'sp153.png'),

('SP154', N'NPK 16-16-8 (Hạt vàng)', 
N'NPK 16-16-8 dạng hạt vàng, cung cấp cân đối đạm – lân – kali. 
Dùng bón cho rau màu, cây ăn trái và cây cảnh. 
Giúp tăng trưởng tán lá và khỏe rễ. 
Tan đều và ít gây nóng cây. 
Nên bón xa gốc và tưới nước sau bón.', 
N'Bao 25kg', 380000, 190, 'LSP012',   N'sp154.png'),

('SP155', N'Phân Lân Super Lân Lâm Thao', 
N'Lân Super dạng bột mịn màu xám, chứa 16% P₂O₅ hữu hiệu. 
Dùng để cải tạo đất chua, kích thích bộ rễ phát triển mạnh, phù hợp hầu hết cây trồng. 
Không gây nóng cây và có tác dụng kéo dài. 
Bảo quản nơi khô, tránh mưa.', 
N'Bao 50kg', 265000, 240, 'LSP012',  N'sp155.png'),

('SP156', N'Phân Hữu Cơ Vi Sinh (Oganic)', 
N'Phân hữu cơ dạng viên màu nâu đen, chứa chất mùn, vi sinh vật có lợi và dưỡng chất tự nhiên. 
Cải tạo đất, giúp đất tơi xốp và tăng độ giữ nước. 
Thích hợp cho rau, hoa, cây ăn trái và cây công nghiệp. 
Không gây cháy lá. 
Bảo quản nơi thoáng.', 
N'Bao 25kg', 160000, 320, 'LSP012',  N'sp156.png'),

('SP157', N'MgSO₄ (Phân Magie Sulfat) hạt trắng', 
N'Magie sulfate dạng hạt trắng, tan nhanh, chứa Mg và S giúp tăng cường quang hợp, xanh lá và giúp cây hấp thu dinh dưỡng tốt hơn. 
Phù hợp cho rau, cà phê, tiêu và các cây thiếu Mg. 
Bón đúng liều để tránh vàng lá. 
Bảo quản kho khô.',
N'Bao 25kg', 360000, 110, 'LSP012', N'sp157.png'),

('SP158', N'Canxi Nitrate Ca(NO₃)₂', 
N'Ca(NO₃)₂ dạng hạt màu trắng, tan hoàn toàn trong nước. 
Cung cấp đồng thời Ca và NO₃ giúp cứng thân, tăng độ giòn trái và hạn chế nứt quả. 
Thường dùng cho cà chua, dưa leo, ớt và cây ăn trái. 
Không nên trộn chung với phân chứa phốt pho.', 
N'Bao 25kg', 680000, 95, 'LSP012',  N'sp158.png'),

('SP159', N'Vi lượng Chelate TE (Zn–Mn–Cu–B)', 
N'Hỗn hợp vi lượng dạng bột hòa tan, chứa Zn, Mn, Cu và Bo ở dạng chelate dễ hấp thụ. 
Giúp cây xanh lá, tăng đậu trái và chống vàng lá sinh lý. 
Phù hợp tất cả cây trồng. 
Hòa nước phun hoặc tưới gốc. 
Bảo quản kín sau khi mở bao.', 
N'Túi 1kg', 55000, 450, 'LSP012',  N'sp159.png'),

('SP160', N'Axit Humic dạng lỏng 12%', 
N'Humic Liquid màu nâu đậm, chiết xuất từ than bùn, chứa hàm lượng humic 12%. 
Giúp cải tạo đất, kích thích rễ, tăng giữ nước và thúc đẩy hấp thu dinh dưỡng. 
Dùng tưới gốc hoặc phun lá. 
Không độc và an toàn với môi trường.', 
N'Can 5L', 145000, 180, 'LSP012',  N'sp160.png'),

('SP161', N'Axit Amino Malonic AMAC 98%', 
N'Axit amino malonic dạng tinh thể trắng, hàm lượng ≥98%. 
Dùng trong tổng hợp hữu cơ, xúc tác hóa học và nghiên cứu hóa chất. 
Có tính ăn mòn nhẹ và cần bảo hộ khi thao tác. 
Bảo quản nơi khô ráo, tránh ánh sáng mạnh. 
Xuất xứ: Trung Quốc/Việt Nam.', 
N'Bao 25kg', 930000, 60, 'LSP007', N'sp161.png'),

('SP162', N'Natri Tetraborat Na₂B₄O₇·10H₂O (Borax kỹ thuật)', 
N'Borax dạng tinh thể trắng, kỹ thuật công nghiệp. 
Dùng trong sản xuất thủy tinh, xử lý nước và chất phụ trợ công nghiệp. 
Tan vừa phải, ổn định hóa học cao. 
Tránh để tiếp xúc lâu với da. 
Bảo quản bao kín, tránh ẩm.', 
N'Bao 25kg', 410000, 140, 'LSP007',   N'sp162.png'),

('SP163', N'Kẽm Oxit ZnO 99%', 
N'ZnO dạng bột trắng, độ tinh khiết ≥99 %. 
Dùng trong cao su, sơn bột, hóa chất màu và dược phẩm kỹ thuật. 
Không tan trong nước, có khả năng chống tia UV. 
Bảo quản nơi khô, tránh ánh sáng mạnh.', 
N'Bao 25kg', 340000, 130, 'LSP007',  N'sp163.png'),

('SP164', N'Kim loại Magnesium Mg bột công nghiệp', 
N'Mg dạng bột kim loại màu xám nhạt, dùng trong hợp kim, luyện kim và hóa chất đặc biệt. 
Dễ bắt lửa ở dạng bột mịn nên cần bảo quản kín chống ẩm. 
Tránh tiếp xúc nước hoặc hơi ẩm.', 
N'Bao 20kg', 1780000, 30, 'LSP007',  N'sp164.png'),

('SP165', N'Natri Hypochlorite NaClO 20%', 
N'Dung dịch NaClO 20% màu vàng nhạt, dùng khử trùng công nghiệp, xử lý nước thải và vệ sinh bề mặt. 
Có tính oxi hóa mạnh, cần bảo vệ mắt và da khi dùng.
Bảo quản nơi mát, tránh ánh sáng và nhiệt.', 
N'Can 30L', 450000, 120, 'LSP007',  N'sp165.png'),

('SP166', N'Iso Propyl Ether (Diisopropyl ether) Dipe', 
N'Dung môi hữu cơ không màu, mùi nhẹ, dùng trong ngành sơn, keo và nhiên liệu phụ trợ. 
Rất dễ bay hơi và dễ cháy, cần thông gió tốt khi sử dụng. 
Bảo quản can kín, tránh lửa.', 
N'Can 20L', 1220000, 50, 'LSP007',  N'sp166.png'),
('SP167', N'Axit Cacbonic tinh thể H₂CO₃ (kỹ thuật)', 
N'H₂CO₃ dạng tinh thể trắng, được dùng trong nghiên cứu, sản xuất chất phụ gia và xử lý kim loại. 
Tính acid nhẹ, ổn định hóa học tốt. 
Tránh tiếp xúc lâu với da khô. 
Bảo quản nơi khô ráo.', 
N'Bao 25kg', 820000, 70, 'LSP007',  N'sp167.png'),

('SP168', N'Alkyl Benzene Sulfonate LAS 90%', 
N'LAS dạng bột trắng kem, hàm lượng hoạt chất ≥90%. 
Dùng trong sản xuất chất tẩy rửa, xà phòng công nghiệp và phụ gia bọt. 
Tan tốt trong nước, tạo bọt mạnh. 
Bảo quản tránh ẩm và nhiễm bẩn.', 
N'Bao 50kg', 560000, 100, 'LSP007',  N'sp168.png'),

('SP169', N'Phốt pho đỏ P₂ équipé (Red Phosphorus) kỹ thuật', 
N'Phốt pho đỏ dạng bột đỏ nâu, dùng trong sản xuất hợp chất phospho, dây cháy và hợp chất công nghiệp. 
Có khả năng cháy chậm khi tiếp xúc mạnh, cần bảo quản trong thùng chống cháy và nơi mát.', 
N'Bao 10kg', 3250000, 15, 'LSP007',  N'sp169.png'),

('SP170', N'Xút Lỏng NaOH 32%', 
N'Dung dịch NaOH 32% màu trong tới vàng nhạt, dùng trong xử lý nước, sản xuất hóa chất và tẩy rửa công nghiệp. 
Có tính kiềm mạnh, ăn mòn cao. 
Bảo quản can kín, tránh tiếp xúc với da và mắt.', 
N'Can 30kg', 360000, 110, 'LSP007',  N'sp170.png'),

('SP171', N'Butadiene Monomer (C₄H₆) công nghiệp', 
N'Butadiene dạng khí hóa lỏng hoặc lỏng lạnh, dùng sản xuất cao su tổng hợp và polymer. 
Khí cực kỳ dễ cháy và nổ nên phải lưu trữ dưới áp suất và nhiệt độ thấp. 
Chỉ sử dụng trong môi trường chuyên nghiệp.', 
N'Phuy 250L', 15000000, 10, 'LSP007',  N'sp171.png'),

('SP172', N'Methacrylic Acid MAA 99%', 
N'MAA dạng lỏng trong suốt, dùng trong sản xuất nhựa acrylic, sơn và keo dán. 
Có tính acid và phản ứng polymer hóa mạnh. 
Khi thao tác cần có thiết bị chống cháy. 
Bảo quản nơi mát.', 
N'Can 20L', 1120000, 40, 'LSP007',   N'sp172.png'),

('SP173', N'Propylene Oxide PO 99%', 
N'PO dạng khí/nước lỏng, dùng sản xuất glycols, polyether và polyurethane. 
Khí rất phản ứng, dễ nổ khi gặp nhiệt độ cao. 
Cần bảo quản chuyên dụng.', 
N'Phuy 200L', 17200000, 8, 'LSP007',  N'sp173.png'),

('SP174', N'Fluorspar CaF₂ dạng bột',
N'CaF₂ dạng bột xám nhạt, dùng trong luyện thép, sản xuất acid flohydric và hóa chất fluor. 
Ổn định hóa học cao. Tránh tiếp xúc mạnh với acid. 
Bảo quản nơi khô.', 
N'Bao 25kg', 1350000, 60, 'LSP007',  N'sp174.png'),

('SP175', N'Diazinon Hỗn hợp kỹ thuật', 
N'Hỗn hợp kỹ thuật của chất hoạt hóa Diazinon, dùng trong sản xuất thuốc trừ sâu (chỉ công nghiệp/phụ trợ). 
Cần bảo vệ cá nhân nghiêm ngặt khi xử lý. 
Bảo quản nơi mát, tránh ánh sáng.', 
N'Can 20L', 2350000, 20, 'LSP007',  N'sp175.png'),

('SP176', N'Axit Peracetic 32%', 
N'Axit peracetic dạng dung dịch trong suốt, mạnh oxi hóa và khử trùng cao. 
Dùng trong xử lý nước thải, công nghiệp giấy và y tế. 
Cần tránh tiếp xúc da và mắt. 
Bảo quản lạnh và kín.', 
N'Can 20L', 1980000, 30, 'LSP007',  N'sp176.png'),

('SP177', N'Natri Chlorite NaClO₂ 80%', 
N'NaClO₂ dạng hạt trắng, dùng trong hóa chất xử lý nước, giấy và dệt.
Oxi hóa mạnh, cần bảo hộ cao khi thao tác. 
Bảo quản nơi khô và mát.', 
N'Bao 25kg', 1450000, 40, 'LSP007',  N'sp177.png'),

('SP178', N'Sodium Fluoride NaF kỹ thuật', 
N'NaF dạng bột trắng tinh khiết kỹ thuật, dùng trong thực phẩm, luyện kim và hóa chất. 
Có độc tính nếu hít lâu. 
Cần đeo khẩu trang bụi khi thao tác.', 
N'Bao 25kg', 820000, 55, 'LSP007',  N'sp178.png'),
('SP179', N'Ammonium Persulfate (APS) 98%', 
N'(NH₄)₂S₂O₈ dạng bột trắng, dùng làm chất khởi động hóa polymer, xử lý nước và khử màu. 
Tan tốt trong nước, phản ứng mạnh khi trộn với kiềm. 
Bảo quản tránh ánh sáng và nhiệt.', 
N'Bao 25kg', 960000, 35, 'LSP007',  N'sp179.png'),

('SP180', N'Alkyl Polyglucoside APG 50%', 
N'APG dạng dung dịch đậm đặc, hoạt chất bề mặt sinh học, dùng trong tẩy rửa xanh và mỹ phẩm công nghiệp. 
Hòa tan tốt, ít gây kích ứng. 
Bảo quản nơi mát và kín.', 
N'Can 20L', 530000, 120, 'LSP007',  N'sp180.png'),

('SP181', N'Polydiethanolamine (PDEA) kỹ thuật', 
N'PDEA dạng lỏng màu vàng nhạt, dùng trong ngành xăng dầu, xử lý nước và chất chống ăn mòn. 
Tan tốt trong nước. Có mùi amin mạnh, cần thông gió và đeo khẩu trang.', 
N'Can 20L', 650000, 60, 'LSP007',  N'sp181.png'),

('SP182', N'Polyvinyl Alcohol PVA 88%', 
N'PVA dạng bột hoặc hạt trắng, hòa tan trong nước nóng, dùng trong màng phim, sơn và keo. 
Không độc nhưng phải tránh bụi. 
Bảo quản nơi khô ráo.', 
N'Bao 25kg', 780000, 100, 'LSP007',   N'sp182.png'),

('SP183', N'Phenol Công Nghiệp 98%', 
N'Phenol dạng chất lỏng trong suốt hơi vàng, mùi đặc trưng mạnh, dùng trong nhựa phenolic, tẩy rửa và chất trung gian hóa học. 
Độc có thể gây bỏng và tổn thương da.
Bảo quản nơi mát và quen kiểm định.', 
N'Can 20L', 1450000, 45, 'LSP007',  N'sp183.png'),

('SP184', N'Sodium Silicate Na₂SiO₃ gốc nước 38%', 
N'Dung dịch Na₂SiO₃ 38% dạng lỏng trong suốt hơi xanh nhạt, dùng trong xử lý nước, gốm sứ và hóa chất phụ trợ. 
Phản ứng với acid tạo silika gel. 
Bảo quản nơi thông thoáng, tránh đóng băng.', 
N'Can 20L', 600000, 110, 'LSP007',  N'sp184.png'),

('SP185', N'Polyacrylamide PAM 90%', 
N'PAM dạng bột trắng/trắng kem, là polymer dùng trong xử lý nước, khoan dầu và giấy. 
Tan chậm, tạo nhớt cao, cần kết hợp ion hóa thích hợp. 
Bảo quản nơi khô.', 
N'Bao 25kg', 930000, 75, 'LSP007', N'sp185.png'),

('SP186', N'Calcium Hypochlorite Ca(ClO)₂ 65%', 
N'Ca(ClO)₂ dạng hạt trắng, hàm lượng 60–65%. 
Dùng khử trùng hồ bơi, xử lý nước và clơ hòa tan. 
Mùi nồng, cần tránh hít trực tiếp. 
Bảo quản kín, nơi khô.', 
N'Bao 25kg', 1200000, 50, 'LSP007',  N'sp186.png'),

('SP187', N'Tri-sodium Phosphate TSP kỹ thuật', 
N'TSP dạng bột trắng dễ tan, dùng trong dệt, tẩy rửa và xử lý nước. 
Có tính kiềm mạnh, có thể gây ăn mòn nhẹ. 
Bảo quản trong bao kín, tránh ẩm.', 
N'Bao 25kg', 420000, 130, 'LSP007',  N'sp187.png'),

('SP188', N'Barium Carbonate BaCO₃ 99%', 
N'BaCO₃ dạng bột trắng, độ tinh khiết ≥99%. 
Dùng sản xuất thủy tinh, vỏ súng điện và luyện kim. 
Tránh tiếp xúc với acid mạnh dễ sinh khí CO₂. 
Bảo quản nơi khô và xa phản ứng.', 
N'Bao 25kg', 1150000, 40, 'LSP007',  N'sp188.png'),

('SP189', N'Hexamethylenediamine HMDA 99%', 
N'HMDA dạng lỏng màu vàng nhạt, dùng trong sản xuất nylon, sơn epoxy và chất trung gian hóa học. 
Có mùi mạnh, dễ bay hơi. 
Khi hít lâu có thể gây kích ứng. 
Bảo quản nơi mát và kín.', 
N'Can 20L', 2120000, 35, 'LSP007',  N'sp189.png'),

('SP190', N'Polyethylene Glycol PEG-8000 hạt', 
N'PEG-8000 dạng hạt trắng, dùng trong dược phẩm, mỹ phẩm và hóa chất phụ trợ công nghiệp. 
Tan tốt trong nước ấm, ổn định hóa học cao. 
Bảo quản nơi khô ráo.', 
N'Bao 25kg', 850000, 90, 'LSP007',  N'sp190.png');
GO


/***********************
5) TÀI KHOẢN (admin + nv01..nv10 + kh001..kh020)

* MatKhau đơn giản (>=6 ký tự) theo schema hiện tại
* VaiTro phải là: N'Admin', N'NhanVien', N'KhachHang'
  ************************/
  INSERT INTO TaiKhoan (TenDangNhap, MatKhau, VaiTro, TrangThai) VALUES
	('admin',  'admin123', N'Admin', N'Hoạt động'),

	('nv01', '123456', N'NhanVien', N'Hoạt động'),
	('nv02', '123456', N'NhanVien', N'Hoạt động'),
	('nv03', '123456', N'NhanVien', N'Hoạt động'),
	('nv04', '123456', N'NhanVien', N'Hoạt động'),
	('nv05', '123456', N'NhanVien', N'Hoạt động'),
	('nv06', '123456', N'NhanVien', N'Hoạt động'),
	('nv07', '123456', N'NhanVien', N'Hoạt động'),
	('nv08', '123456', N'NhanVien', N'Hoạt động'),
	('nv09', '123456', N'NhanVien', N'Hoạt động'),
	('nv10', '123456', N'NhanVien', N'Hoạt động'),

	('kh001', '123456', N'KhachHang', N'Hoạt động'),
	('kh002', '123456', N'KhachHang', N'Hoạt động'),
	('kh003', '123456', N'KhachHang', N'Hoạt động'),
	('kh004', '123456', N'KhachHang', N'Hoạt động'),
	('kh005', '123456', N'KhachHang', N'Hoạt động'),
	('kh006', '123456', N'KhachHang', N'Hoạt động'),
	('kh007', '123456', N'KhachHang', N'Hoạt động'),
	('kh008', '123456', N'KhachHang', N'Hoạt động'),
	('kh009', '123456', N'KhachHang', N'Hoạt động'),
	('kh010', '123456', N'KhachHang', N'Hoạt động'),
	('kh011', '123456', N'KhachHang', N'Hoạt động'),
	('kh012', '123456', N'KhachHang', N'Hoạt động'),
	('kh013', '123456', N'KhachHang', N'Hoạt động'),
	('kh014', '123456', N'KhachHang', N'Hoạt động'),
	('kh015', '123456', N'KhachHang', N'Hoạt động'),
	('kh016', '123456', N'KhachHang', N'Hoạt động'),
	('kh017', '123456', N'KhachHang', N'Hoạt động'),
	('kh018', '123456', N'KhachHang', N'Hoạt động'),
	('kh019', '123456', N'KhachHang', N'Hoạt động'),
	('kh020', '123456', N'KhachHang', N'Hoạt động');
  GO

/***********************
6) NHÂN VIÊN (10)
************************/
INSERT INTO NhanVien (MaNV, TenNV, ChucVu, Email, SDT, TenDangNhap, AnhDaiDien) VALUES
('NV01', N'Nguyễn Văn An', N'Quản lý kho', 'an.nguyen@hoachat.vn', '0912345601', 'nv01', N'nv01.png'),
('NV02', N'Lê Thị Bình', N'Nhập hàng', 'binh.le@hoachat.vn', '0912345602', 'nv02', N'nv02.png'),
('NV03', N'Phạm Quốc Huy', N'Kiểm định', 'huy.pham@hoachat.vn', '0912345603', 'nv03', N'nv03.png'),
('NV04', N'Trần Văn Duy', N'Kế toán', 'duy.tran@hoachat.vn', '0912345604', 'nv04', N'nv04.png'),
('NV05', N'Hoàng Thị Nga', N'Báo cáo', 'nga.hoang@hoachat.vn', '0912345605', 'nv05', N'nv05.png'),
('NV06', N'Nguyễn Thị Hương', N'An toàn', 'huong.nguyen@hoachat.vn', '0912345606', 'nv06', N'nv06.png'),
('NV07', N'Phạm Đức Long', N'Quản lý bán hàng', 'long.pham@hoachat.vn', '0912345607', 'nv07', N'nv07.png'),
('NV08', N'Lưu Minh Tú', N'Vận chuyển', 'tu.luu@hoachat.vn', '0912345608', 'nv08', N'nv08.png'),
('NV09', N'Đặng Anh Vũ', N'Kỹ thuật', 'vu.dang@hoachat.vn', '0912345609', 'nv09', N'nv09.png'),
('NV10', N'Bùi Quang Hòa', N'Hỗ trợ KH', 'hoa.bui@hoachat.vn', '0912345610', 'nv10', N'nv10.png');
GO

/***********************
7) KHÁCH HÀNG (20)
************************/
INSERT INTO KhachHang (MaKH, TenKH, DiaChi, Email, SDT, TenDangNhap, AnhDaiDien) VALUES
('KH001', N'Nguyễn Văn A', N'Hà Nội', 'a@example.com', '0912000001', 'kh001', N'kh001.png'),
('KH002', N'Trần Thị B', N'Hải Phòng', 'b@example.com', '0912000002', 'kh002', N'kh002.png'),
('KH003', N'Lê Văn C', N'Đà Nẵng', 'c@example.com', '0912000003', 'kh003', N'kh003.png'),
('KH004', N'Phạm Thị D', N'Hồ Chí Minh', 'd@example.com', '0912000004', 'kh004', N'kh004.png'),
('KH005', N'Nguyễn Văn E', N'Hà Nội', 'e@example.com', '0912000005', 'kh005', N'kh005.png'),
('KH006', N'Đỗ Thị F', N'Huế', 'f@example.com', '0912000006', 'kh006', N'kh006.png'),
('KH007', N'Hoàng Văn G', N'HCM', 'g@example.com', '0912000007', 'kh007', N'kh007.png'),
('KH008', N'Phạm Thị H', N'HN', 'h@example.com', '0912000008', 'kh008', N'kh008.png'),
('KH009', N'Nguyễn Văn I', N'Đà Nẵng', 'i@example.com', '0912000009', 'kh009', N'kh009.png'),
('KH010', N'Lê Thị K', N'Hải Dương', 'k@example.com', '0912000010', 'kh010', N'kh010.png'),
('KH011', N'Bùi Văn L', N'Bắc Ninh', 'l@example.com', '0912000011', 'kh011', N'kh011.png'),
('KH012', N'Võ Thị M', N'Quảng Ninh', 'm@example.com', '0912000012', 'kh012', N'kh012.png'),
('KH013', N'Ngô Văn N', N'Bình Dương', 'n@example.com', '0912000013', 'kh013', N'kh013.png'),
('KH014', N'Phan Thị O', N'Hải Phòng', 'o@example.com', '0912000014', 'kh014', N'kh014.png'),
('KH015', N'Trương Văn P', N'Long An', 'p@example.com', '0912000015', 'kh015', N'kh015.png'),
('KH016', N'Nguyễn Thị Q', N'HCM', 'q@example.com', '0912000016', 'kh016', N'kh016.png'),
('KH017', N'Huỳnh Văn R', N'Cần Thơ', 'r@example.com', '0912000017', 'kh017', N'kh017.png'),
('KH018', N'Chu Thị S', N'Huế', 's@example.com', '0912000018', 'kh018', N'kh018.png'),
('KH019', N'Đỗ Văn T', N'Gia Lai', 't@example.com', '0912000019', 'kh019', N'kh019.png'),
('KH020', N'Lê Thị U', N'Quảng Ngãi', 'u@example.com', '0912000020', 'kh020', N'kh020.png');
GO

/***********************
8) PHIẾU NHẬP HÀNG (20) + CHI TIẾT NHẬP
************************/
INSERT INTO PhieuNhapHang (MaPNH, NgayNhap, TongTien, MaNV, MaNCC) VALUES
('PNH001','2025-09-01', 25000000, 'NV02', 'NCC001'),
('PNH002','2025-09-03', 18000000, 'NV01', 'NCC002'),
('PNH003','2025-09-05', 32000000, 'NV02', 'NCC003'),
('PNH004','2025-09-07', 27000000, 'NV03', 'NCC004'),
('PNH005','2025-09-10', 19500000, 'NV04', 'NCC005'),
('PNH006','2025-09-12', 35000000, 'NV05', 'NCC006'),
('PNH007','2025-09-15', 28000000, 'NV02', 'NCC007'),
('PNH008','2025-09-18', 31000000, 'NV03', 'NCC008'),
('PNH009','2025-09-20', 26000000, 'NV06', 'NCC009'),
('PNH010','2025-09-22', 23000000, 'NV01', 'NCC010'),
('PNH011','2025-09-25', 12000000, 'NV04', 'NCC001'),
('PNH012','2025-09-26', 15000000, 'NV05', 'NCC002'),
('PNH013','2025-09-27', 9000000, 'NV06', 'NCC003'),
('PNH014','2025-09-28', 22000000, 'NV07', 'NCC004'),
('PNH015','2025-09-29', 8000000, 'NV08', 'NCC005'),
('PNH016','2025-09-30', 6000000, 'NV09', 'NCC006'),
('PNH017','2025-10-01', 27000000, 'NV10', 'NCC007'),
('PNH018','2025-10-02', 14000000, 'NV02', 'NCC008'),
('PNH019','2025-10-03', 19000000, 'NV03', 'NCC009'),
('PNH020','2025-10-05', 21000000, 'NV01', 'NCC010');
GO

-- Chi tiết nhập
INSERT INTO CT_PhieuNhapHang (MaPNH, MaSP, SoLuong, DonGia) VALUES
('PNH001','SP001', 500, 220000),
('PNH001','SP002', 300, 200000),
('PNH002','SP003', 400, 90000),
('PNH002','SP004', 600, 85000),
('PNH003','SP005', 200, 80000),
('PNH003','SP006', 300, 78000),
('PNH004','SP007', 150, 100000),
('PNH005','SP008', 1000, 48000),
('PNH006','SP009', 500, 88000),
('PNH007','SP010', 200, 155000),
('PNH008','SP011', 120, 140000),
('PNH009','SP012', 700, 56000),
('PNH010','SP013', 100, 130000),
('PNH011','SP014', 90, 125000),
('PNH012','SP015', 80, 120000),
('PNH013','SP016', 300, 38000),
('PNH014','SP017', 250, 42000),
('PNH015','SP018', 180, 68000),
('PNH016','SP019', 100, 200000),
('PNH017','SP020', 220, 54000),
('PNH018','SP021', 150, 88000),
('PNH019','SP022', 160, 105000),
('PNH020','SP023', 50, 200000);
GO

/***********************
9) ĐƠN HÀNG (50) + CHI TIẾT ĐƠN HÀNG
************************/
INSERT INTO DonHang
(MaDH, NgayDat, TrangThai, TongTien, MaKH, HoTen, DiaChi, SDT, Email, PhuongThucThanhToan)
VALUES
('DH001','2025-10-01',N'Hoàn thành',370000,'KH001',N'Nguyễn Văn Hùng',N'12 Nguyễn Huệ, Quận 1, TP Hồ Chí Minh','0905123456','hung.nguyen@gmail.com',N'TienMat'),
('DH002','2025-10-02',N'Đang giao hàng',210000,'KH002',N'Trần Thị Minh Anh',N'25 Lê Duẩn, TP Thủ Đức, TP Hồ Chí Minh','0964123456','minhanh.tran@yahoo.com',N'ChuyenKhoan'),
('DH003','2025-10-03',N'Đang xử lý',210000,'KH003',N'Phạm Quốc Khánh',N'88 Nguyễn Trãi, Thanh Xuân, Hà Nội','0978234567','khanhpham@outlook.com',N'ChuyenKhoan'),
('DH004','2025-10-04',N'Đã hủy',180000,'KH004',N'Lê Thị Hồng Nhung',N'45 Võ Thị Sáu, Quận 3, TP Hồ Chí Minh','0935126789','nhungle@gmail.com',N'TienMat'),
('DH005','2025-10-05',N'Đang giao hàng',450000,'KH005',N'Nguyễn Hữu Tài',N'123 Hoàng Diệu, Hải Châu, TP Đà Nẵng','0905126899','tai.nguyen@fpt.vn',N'ChuyenKhoan'),
('DH006','2025-10-06',N'Hoàn thành',220000,'KH006',N'Đặng Thị Kim Yến',N'56 Nguyễn Tất Thành, TP Thủ Dầu Một, Bình Dương','0987456123','kimyen.dang@gmail.com',N'ChuyenKhoan'),
('DH007','2025-10-07',N'Đang xử lý',300000,'KH007',N'Vũ Đức Long',N'27 Trần Phú, TP Hạ Long, Quảng Ninh','0376123456','longvu.vn@gmail.com',N'TienMat'),
('DH008','2025-10-08',N'Đang giao hàng',340000,'KH008',N'Ngô Thanh Tú',N'14 Nguyễn Văn Cừ, Quận Long Biên, Hà Nội','0912345678','tungongo@outlook.com',N'ChuyenKhoan'),
('DH009','2025-10-09',N'Đang xử lý',150000,'KH009',N'Trần Hồng Phúc',N'78 Võ Nguyên Giáp, TP Huế, Thừa Thiên Huế','0898123456','phuc.tran@gmail.com',N'ChuyenKhoan'),
('DH010','2025-10-10',N'Hoàn thành',150000,'KH010',N'Lý Gia Bảo',N'9 Phạm Văn Đồng, TP Nha Trang, Khánh Hòa','0859123456','baoly.kt@gmail.com',N'ChuyenKhoan'),
('DH011','2025-10-11',N'Đang xử lý',480000,'KH011',N'Phan Thị Thu Trang',N'33 Nguyễn Văn Linh, TP Cần Thơ','0775123456','trangphan@gmail.com',N'TienMat'),
('DH012','2025-10-12',N'Đang giao hàng',1010000,'KH012',N'Tô Anh Dũng',N'88 Nguyễn Thị Minh Khai, TP Vinh, Nghệ An','0945123456','dungto@outlook.com',N'ChuyenKhoan'),
('DH013','2025-10-13',N'Hoàn thành',590000,'KH013',N'Đỗ Thị Ngọc Mai',N'10 Nguyễn Văn Cừ, TP Bắc Giang','0917456123','ngocmai.do@gmail.com',N'TienMat'),
('DH014','2025-10-14',N'Đã hủy',330000,'KH014',N'Lương Văn Thành',N'22 Điện Biên Phủ, Quận Bình Thạnh, TP Hồ Chí Minh','0988234567','thanh.luong@gmail.com',N'ChuyenKhoan'),
('DH015','2025-10-15',N'Hoàn thành',155000,'KH015',N'Phạm Thị Mỹ Linh',N'5 Phan Chu Trinh, TP Đà Lạt, Lâm Đồng','0909567123','mylinh.pham@gmail.com',N'ChuyenKhoan'),
('DH016','2025-10-16',N'Đang xử lý',250000,'KH016',N'Nguyễn Văn Toàn',N'99 Lê Lợi, TP Huế, Thừa Thiên Huế','0377456789','toan.nguyen@yahoo.com',N'ChuyenKhoan'),
('DH017','2025-10-17',N'Đang giao hàng',110000,'KH017',N'Lâm Thị Kiều Oanh',N'48 Hai Bà Trưng, TP Nha Trang, Khánh Hòa','0815123456','kieuoanh.lam@gmail.com',N'TienMat'),
('DH018','2025-10-18',N'Hoàn thành',670000,'KH018',N'Võ Quang Thịnh',N'25 Trường Chinh, TP Quy Nhơn, Bình Định','0868123456','thinhvo@outlook.com',N'ChuyenKhoan'),
('DH019','2025-10-19',N'Đang giao hàng',305000,'KH019',N'Hoàng Thị Thanh Tâm',N'27 Nguyễn Huệ, TP Vũng Tàu, Bà Rịa - Vũng Tàu','0936123456','tamhoang@gmail.com',N'ChuyenKhoan'),
('DH020','2025-10-20',N'Đang xử lý',340000,'KH020',N'Nguyễn Minh Đức',N'45 Lê Quang Định, TP Thủ Đức, TP Hồ Chí Minh','0976123456','ducminh.vn@gmail.com',N'ChuyenKhoan'),
('DH021','2025-10-21',N'Đang xử lý',170000,'KH007',N'Vũ Đức Long',N'27 Trần Phú, TP Hạ Long, Quảng Ninh','0376123456','longvu.vn@gmail.com',N'TienMat'),
('DH022','2025-10-22',N'Đang giao hàng',1010000,'KH014',N'Lương Văn Thành',N'22 Điện Biên Phủ, Quận Bình Thạnh, TP Hồ Chí Minh','0988234567','thanh.luong@gmail.com',N'ChuyenKhoan'),
('DH023','2025-10-23',N'Đã hủy',440000,'KH002',N'Trần Thị Minh Anh',N'25 Lê Duẩn, TP Thủ Đức, TP Hồ Chí Minh','0964123456','minhanh.tran@yahoo.com',N'ChuyenKhoan'),
('DH024','2025-10-24',N'Hoàn thành',220000,'KH011',N'Phan Thị Thu Trang',N'33 Nguyễn Văn Linh, TP Cần Thơ','0775123456','trangphan@gmail.com',N'ChuyenKhoan'),
('DH025','2025-10-25',N'Đang giao hàng',360000,'KH019',N'Hoàng Thị Thanh Tâm',N'27 Nguyễn Huệ, TP Vũng Tàu, Bà Rịa - Vũng Tàu','0936123456','tamhoang@gmail.com',N'TienMat'),
('DH026','2025-10-26',N'Hoàn thành',1030000,'KH001',N'Nguyễn Văn Hùng',N'12 Nguyễn Huệ, Quận 1, TP Hồ Chí Minh','0905123456','hung.nguyen@gmail.com',N'ChuyenKhoan'),
('DH027','2025-10-27',N'Đang xử lý',150000,'KH020',N'Nguyễn Minh Đức',N'45 Lê Quang Định, TP Thủ Đức, TP Hồ Chí Minh','0976123456','ducminh.vn@gmail.com',N'ChuyenKhoan'),
('DH028','2025-10-28',N'Hoàn thành',380000,'KH008',N'Ngô Thanh Tú',N'14 Nguyễn Văn Cừ, Quận Long Biên, Hà Nội','0912345678','tungongo@outlook.com',N'ChuyenKhoan'),
('DH029','2025-10-29',N'Đang giao hàng',190000,'KH005',N'Nguyễn Hữu Tài',N'123 Hoàng Diệu, Hải Châu, TP Đà Nẵng','0905126899','tai.nguyen@fpt.vn',N'TienMat'),
('DH030','2025-10-30',N'Hoàn thành',230000,'KH010',N'Lý Gia Bảo',N'9 Phạm Văn Đồng, TP Nha Trang, Khánh Hòa','0859123456','baoly.kt@gmail.com',N'ChuyenKhoan'),
('DH031','2025-10-31',N'Đang xử lý',150000,'KH003',N'Phạm Quốc Khánh',N'88 Nguyễn Trãi, Thanh Xuân, Hà Nội','0978234567','khanhpham@outlook.com',N'ChuyenKhoan'),
('DH032','2025-11-01',N'Đang giao hàng',339999,'KH017',N'Lâm Thị Kiều Oanh',N'48 Hai Bà Trưng, TP Nha Trang, Khánh Hòa','0815123456','kieuoanh.lam@gmail.com',N'TienMat'),
('DH033','2025-11-02',N'Hoàn thành',440000,'KH012',N'Tô Anh Dũng',N'88 Nguyễn Thị Minh Khai, TP Vinh, Nghệ An','0945123456','dungto@outlook.com',N'ChuyenKhoan'),
('DH034','2025-11-03',N'Đã hủy',300000,'KH016',N'Nguyễn Văn Toàn',N'99 Lê Lợi, TP Huế, Thừa Thiên Huế','0377456789','toan.nguyen@yahoo.com',N'ChuyenKhoan'),
('DH035','2025-11-04',N'Hoàn thành',510000,'KH006',N'Đặng Thị Kim Yến',N'56 Nguyễn Tất Thành, TP Thủ Dầu Một, Bình Dương','0987456123','kimyen.dang@gmail.com',N'ChuyenKhoan'),
('DH036','2025-11-05',N'Đang giao hàng',380000,'KH013',N'Đỗ Thị Ngọc Mai',N'10 Nguyễn Văn Cừ, TP Bắc Giang','0917456123','ngocmai.do@gmail.com',N'TienMat'),
('DH037','2025-11-06',N'Hoàn thành',80000,'KH009',N'Trần Hồng Phúc',N'78 Võ Nguyên Giáp, TP Huế, Thừa Thiên Huế','0898123456','phuc.tran@gmail.com',N'ChuyenKhoan'),
('DH038','2025-11-07',N'Đang xử lý',78000,'KH004',N'Lê Thị Hồng Nhung',N'45 Võ Thị Sáu, Quận 3, TP Hồ Chí Minh','0935126789','nhungle@gmail.com',N'ChuyenKhoan'),
('DH039','2025-11-08',N'Đang giao hàng',225000,'KH018',N'Võ Quang Thịnh',N'25 Trường Chinh, TP Quy Nhơn, Bình Định','0868123456','thinhvo@outlook.com',N'TienMat'),
('DH040','2025-11-09',N'Hoàn thành',170000,'KH015',N'Phạm Thị Mỹ Linh',N'5 Phan Chu Trinh, TP Đà Lạt, Lâm Đồng','0909567123','mylinh.pham@gmail.com',N'ChuyenKhoan'),
('DH041','2025-11-10',N'Đang xử lý',130000,'KH011',N'Phan Thị Thu Trang',N'33 Nguyễn Văn Linh, TP Cần Thơ','0775123456','trangphan@gmail.com',N'ChuyenKhoan'),
('DH042','2025-11-11',N'Đang giao hàng',290000,'KH020',N'Nguyễn Minh Đức',N'45 Lê Quang Định, TP Thủ Đức, TP Hồ Chí Minh','0976123456','ducminh.vn@gmail.com',N'ChuyenKhoan'),
('DH043','2025-11-12',N'Hoàn thành',2530000,'KH007',N'Vũ Đức Long',N'27 Trần Phú, TP Hạ Long, Quảng Ninh','0376123456','longvu.vn@gmail.com',N'TienMat'),
('DH044','2025-11-13',N'Đang xử lý',310000,'KH002',N'Trần Thị Minh Anh',N'25 Lê Duẩn, TP Thủ Đức, TP Hồ Chí Minh','0964123456','minhanh.tran@yahoo.com',N'ChuyenKhoan'),
('DH045','2025-11-14',N'Đang giao hàng',405000,'KH005',N'Nguyễn Hữu Tài',N'123 Hoàng Diệu, Hải Châu, TP Đà Nẵng','0905126899','tai.nguyen@fpt.vn',N'ChuyenKhoan'),
('DH046','2025-11-15',N'Đã hủy',410000,'KH001',N'Nguyễn Văn Hùng',N'12 Nguyễn Huệ, Quận 1, TP Hồ Chí Minh','0905123456','hung.nguyen@gmail.com',N'TienMat'),
('DH047','2025-11-16',N'Đang xử lý',470000,'KH008',N'Ngô Thanh Tú',N'14 Nguyễn Văn Cừ, Quận Long Biên, Hà Nội','0912345678','tungongo@outlook.com',N'ChuyenKhoan'),
('DH048','2025-11-17',N'Hoàn thành',210000,'KH012',N'Tô Anh Dũng',N'88 Nguyễn Thị Minh Khai, TP Vinh, Nghệ An','0945123456','dungto@outlook.com',N'ChuyenKhoan'),
('DH049','2025-11-18',N'Đang giao hàng',420000,'KH016',N'Nguyễn Văn Toàn',N'99 Lê Lợi, TP Huế, Thừa Thiên Huế','0377456789','toan.nguyen@yahoo.com',N'TienMat'),
('DH050','2025-11-19',N'Hoàn thành',480000,'KH010',N'Lý Gia Bảo',N'9 Phạm Văn Đồng, TP Nha Trang, Khánh Hòa','0859123456','baoly.kt@gmail.com',N'ChuyenKhoan');
GO

-- Chi tiết đơn hàng
INSERT INTO CT_DonHang_SP (MaDH, MaSP, SoLuong, DonGia) VALUES
('DH001','SP001',2,120000),
('DH001','SP002',1,100000),
('DH002','SP003',3,60000),
('DH003','SP004',2,90000),
('DH004','SP005',1,150000),
('DH005','SP006',2,210000),
('DH006','SP007',1,190000),
('DH007','SP008',3,90000),
('DH008','SP009',2,155000),
('DH009','SP010',1,120000),
('DH010','SP011',1,120000),
('DH011','SP012',3,150000),
('DH012','SP013',2,490000),
('DH013','SP014',4,140000),
('DH014','SP015',1,300000),
('DH015','SP016',5,25000),
('DH016','SP017',2,110000),
('DH017','SP018',1,80000),
('DH018','SP019',2,320000),
('DH019','SP020',1,275000),
('DH020','SP021',2,155000),
('DH021','SP022',1,140000),
('DH022','SP023',2,490000),
('DH023','SP024',1,410000),
('DH024','SP025',2,95000),
('DH025','SP026',1,330000),
('DH026','SP027',4,250000),
('DH027','SP028',1,120000),
('DH028','SP029',2,175000),
('DH029','SP030',1,160000),
('DH030','SP031',2,100000),
('DH031','SP032',1,120000),
('DH032','SP033',3,103333),
('DH033','SP034',2,205000),
('DH034','SP035',1,270000),
('DH035','SP036',2,240000),
('DH036','SP037',1,350000),
('DH037','SP038',10,5000),
('DH038','SP039',8,6000),
('DH039','SP040',3,65000),
('DH040','SP041',1,140000),
('DH041','SP042',1,100000),
('DH042','SP043',2,130000),
('DH043','SP044',1,2500000),
('DH044','SP045',2,140000),
('DH045','SP046',3,125000),
('DH046','SP047',4,95000),
('DH047','SP048',2,220000),
('DH048','SP049',1,180000),
('DH049','SP050',3,130000),
('DH050','SP051',1,450000);
GO

/***********************
10) KHUYẾN MÃI (10) + CHI TIẾT
************************/
INSERT INTO KhuyenMai (MaKM, TenCT, NgayBD, NgayKT, LoaiKM, MoTa)
VALUES
('KM01', N'Mua 5 giảm 5k',        '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 5.000 khi mua >= 5 sản phẩm'),
('KM02', N'Mua 10 giảm 10%',      '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 10% khi mua >= 10 sản phẩm'),
('KM03', N'Mua 15 giảm 20k',      '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 20.000 khi mua >= 15 sản phẩm'),
('KM04', N'Mua 2 giảm 50k',       '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 50.000 khi mua >= 2 sản phẩm'),
('KM05', N'Mua 3 giảm 10%',       '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 10% khi mua >= 3 sản phẩm'),
('KM06', N'Mua 1 giảm 5%',        '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 5% cho mọi đơn hàng có sản phẩm'),
('KM07', N'Mua 8 giảm 8k',        '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 8.000 khi mua >= 8 sản phẩm'),
('KM08', N'Mua 12 giảm 15%',      '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 15% khi mua >= 12 sản phẩm'),
('KM09', N'Mua 20 giảm 50k',      '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 50.000 khi mua >= 20 sản phẩm'),
('KM10', N'Mua 4 giảm 7k',        '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 7.000 khi mua >= 4 sản phẩm'),
('KM11', N'Mua 6 giảm 12%',       '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 12% khi mua >= 6 sản phẩm'),
('KM12', N'Mua 9 giảm 25k',       '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 25.000 khi mua >= 9 sản phẩm'),
('KM13', N'Mua 2 giảm 30k',       '2025-01-01', '2025-12-31', 'Tien',     N'Giảm 30.000 khi mua >= 2 sản phẩm'),
('KM14', N'Mua 3 giảm 8%',        '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 8% khi mua >= 3 sản phẩm'),
('KM15', N'Mua 1 giảm 3%',        '2025-01-01', '2025-12-31', 'PhanTram', N'Giảm 3% khi mua >= 1 sản phẩm');

--chi tiết khuyến mãi
INSERT INTO ChiTietKM_SP (MaKM, MaSP, SoLuongToiThieu, TriGia)
VALUES
('KM01','SP001',5,5000),
('KM01','SP002',5,5000),
('KM01','SP003',5,5000),
('KM02','SP004',10,10),
('KM02','SP005',10,10),
('KM02','SP006',10,10),
('KM03','SP007',15,20000),
('KM03','SP008',15,20000),
('KM03','SP009',15,20000),
('KM04','SP010',2,50000),
('KM04','SP011',2,50000),
('KM04','SP012',2,50000),
('KM05','SP013',3,10),
('KM05','SP014',3,10),
('KM05','SP015',3,10),
('KM06','SP101',1,5),
('KM06','SP102',1,5),
('KM06','SP103',1,5),
('KM07','SP104',8,8000),
('KM07','SP105',8,8000),
('KM07','SP106',8,8000),
('KM08','SP107',12,15),
('KM08','SP108',12,15),
('KM08','SP109',12,15),
('KM09','SP110',20,50000),
('KM09','SP111',20,50000),
('KM09','SP112',20,50000),
('KM10','SP113',4,7000),
('KM10','SP114',4,7000),
('KM10','SP115',4,7000),
('KM11','SP016',6,12),
('KM11','SP017',6,12),
('KM11','SP018',6,12),
('KM12','SP019',9,25000),
('KM12','SP020',9,25000),
('KM12','SP021',9,25000),
('KM13','SP022',2,30000),
('KM13','SP023',2,30000),
('KM13','SP024',2,30000),
('KM14','SP025',3,8),
('KM14','SP026',3,8),
('KM14','SP027',3,8),
('KM15','SP028',1,3),
('KM15','SP029',1,3),
('KM15','SP030',1,3);


/***********************
11) HÓA ĐƠN (50) + CHI TIẾT
************************/
INSERT INTO HoaDon (MaHD, NgayLap, SoTien, MaDH, MaKH) VALUES
('HD001','2025-10-01',370000,'DH001','KH001'),
('HD002','2025-10-02',210000,'DH002','KH002'),
('HD003','2025-10-03',210000,'DH003','KH003'),
('HD004','2025-10-04',180000,'DH004','KH004'),
('HD005','2025-10-05',450000,'DH005','KH005'),
('HD006','2025-10-06',220000,'DH006','KH006'),
('HD007','2025-10-07',300000,'DH007','KH007'),
('HD008','2025-10-08',340000,'DH008','KH008'),
('HD009','2025-10-09',150000,'DH009','KH009'),
('HD010','2025-10-10',150000,'DH010','KH010'),
('HD011','2025-10-11',480000,'DH011','KH011'),
('HD012','2025-10-12',1010000,'DH012','KH012'),
('HD013','2025-10-13',590000,'DH013','KH013'),
('HD014','2025-10-14',330000,'DH014','KH014'),
('HD015','2025-10-15',155000,'DH015','KH015'),
('HD016','2025-10-16',250000,'DH016','KH016'),
('HD017','2025-10-17',110000,'DH017','KH017'),
('HD018','2025-10-18',670000,'DH018','KH018'),
('HD019','2025-10-19',305000,'DH019','KH019'),
('HD020','2025-10-20',340000,'DH020','KH020'),
('HD021','2025-10-21',170000,'DH021','KH007'),
('HD022','2025-10-22',1010000,'DH022','KH014'),
('HD023','2025-10-23',440000,'DH023','KH002'),
('HD024','2025-10-24',220000,'DH024','KH011'),
('HD025','2025-10-25',360000,'DH025','KH019'),
('HD026','2025-10-26',1030000,'DH026','KH001'),
('HD027','2025-10-27',150000,'DH027','KH020'),
('HD028','2025-10-28',380000,'DH028','KH008'),
('HD029','2025-10-29',190000,'DH029','KH005'),
('HD030','2025-10-30',230000,'DH030','KH010'),
('HD031','2025-10-31',150000,'DH031','KH003'),
('HD032','2025-11-01',339999,'DH032','KH017'),
('HD033','2025-11-02',440000,'DH033','KH012'),
('HD034','2025-11-03',300000,'DH034','KH016'),
('HD035','2025-11-04',510000,'DH035','KH006'),
('HD036','2025-11-05',380000,'DH036','KH013'),
('HD037','2025-11-06',80000,'DH037','KH009'),
('HD038','2025-11-07',78000,'DH038','KH004'),
('HD039','2025-11-08',225000,'DH039','KH018'),
('HD040','2025-11-09',170000,'DH040','KH015'),
('HD041','2025-11-10',130000,'DH041','KH011'),
('HD042','2025-11-11',290000,'DH042','KH020'),
('HD043','2025-11-12',2530000,'DH043','KH007'),
('HD044','2025-11-13',310000,'DH044','KH002'),
('HD045','2025-11-14',405000,'DH045','KH005'),
('HD046','2025-11-15',410000,'DH046','KH001'),
('HD047','2025-11-16',470000,'DH047','KH008'),
('HD048','2025-11-17',210000,'DH048','KH012'),
('HD049','2025-11-18',420000,'DH049','KH016'),
('HD050','2025-11-19',480000,'DH050','KH010');
GO


--chi tiết hóa đơn
INSERT INTO CT_HoaDon (MaHD, MaSP, SoLuong, DonGia) VALUES
('HD001','SP001',2,120000),
('HD001','SP002',1,100000),
('HD002','SP003',3,60000),
('HD003','SP004',2,90000),
('HD004','SP005',1,150000),
('HD005','SP006',2,210000),
('HD006','SP007',1,190000),
('HD007','SP008',3,90000),
('HD008','SP009',2,155000),
('HD009','SP010',1,120000),
('HD010','SP011',1,120000),
('HD011','SP012',3,150000),
('HD012','SP013',2,490000),
('HD013','SP014',4,140000),
('HD014','SP015',1,300000),
('HD015','SP016',5,25000),
('HD016','SP017',2,110000),
('HD017','SP018',1,80000),
('HD018','SP019',2,320000),
('HD019','SP020',1,275000),
('HD020','SP021',2,155000),
('HD021','SP022',1,140000),
('HD022','SP023',2,490000),
('HD023','SP024',1,410000),
('HD024','SP025',2,95000),
('HD025','SP026',1,330000),
('HD026','SP027',4,250000),
('HD027','SP028',1,120000),
('HD028','SP029',2,175000),
('HD029','SP030',1,160000),
('HD030','SP031',2,100000),
('HD031','SP032',1,120000),
('HD032','SP033',3,103333),
('HD033','SP034',2,205000),
('HD034','SP035',1,270000),
('HD035','SP036',2,240000),
('HD036','SP037',1,350000),
('HD037','SP038',10,5000),
('HD038','SP039',8,6000),
('HD039','SP040',3,65000),
('HD040','SP041',1,140000),
('HD041','SP042',1,100000),
('HD042','SP043',2,130000),
('HD043','SP044',1,2500000),
('HD044','SP045',2,140000),
('HD045','SP046',3,125000),
('HD046','SP047',4,95000),
('HD047','SP048',2,220000),
('HD048','SP049',1,180000),
('HD049','SP050',3,130000),
('HD050','SP051',1,450000);
GO

/***********************
12) PHIẾU XỬ LÝ DƠN HỦY & CHI TIẾT (3)
************************/

INSERT INTO PhieuXuLyDH (MaPX, MaDH, LoaiXuLy, TrangThaiPX, LyDo, GhiChu)
VALUES
('PXH001', 'DH004', N'Hủy', N'Đã duyệt', N'Khách huỷ đơn', N'Tự động tạo từ DonHang'),
('PXH002', 'DH006', N'Hủy', N'Đã duyệt', N'Khách huỷ đơn', N'Tự động tạo từ DonHang'),
('PXH003', 'DH010', N'Hủy', N'Đã duyệt', N'Khách huỷ đơn', N'Tự động tạo từ DonHang');


INSERT INTO CT_PhieuXuLy (MaPX, MaSP, SoLuong, DonGia)
VALUES
-- DH004
('PXH001', 'SP007', 3, 15000),
('PXH001', 'SP008', 1, 45000),

-- DH006
('PXH002', 'SP010', 2, 50000),

-- DH010
('PXH003', 'SP012', 4, 30000);


/***********************
13) BÁO CÁO (10)
************************/
INSERT INTO BaoCao (MaBC, NoiDung, NgayLap, MaNV) VALUES
('BC001', N'Tổng hợp tồn cuối tháng 9', '2025-09-30', 'NV01'),
('BC002', N'Chi phí nhập 9/2025', '2025-09-30', 'NV02'),
('BC003', N'Kết quả QC lô 012', '2025-09-28', 'NV03'),
('BC004', N'Top SP bán chạy tháng 9', '2025-09-30', 'NV04'),
('BC005', N'Sự cố tràn nhỏ kho B', '2025-10-05', 'NV06'),
('BC006', N'Chi phí Q3', '2025-10-10', 'NV05'),
('BC007', N'Tổng hợp NCC chiến lược', '2025-10-07', 'NV02'),
('BC008', N'Danh sách SP dưới mức tối thiểu', '2025-10-08', 'NV01'),
('BC009', N'Danh sách SP sắp hết hạn', '2025-10-09', 'NV03'),
('BC010', N'Trạng thái đơn giao nhận', '2025-10-11', 'NV04');
GO

/***********************
14) ĐÁNH GIÁ (50)
************************/
INSERT INTO DanhGia (MaDG, MaKH, MaSP, MaDH, SoSao, NoiDung)
VALUES
('DG001','KH001','SP001','DH001',5,N'Hóa chất đạt độ tinh khiết cao, phản ứng ổn định.'),
('DG002','KH001','SP002','DH001',4,N'Hiệu suất phản ứng tốt, giao hàng nhanh.'),
('DG003','KH001','SP003','DH001',5,N'Chất lượng rất tốt, dùng cho phân tích đạt yêu cầu.'),
('DG004','KH002','SP004','DH002',3,N'Chất lượng ổn, phù hợp các thí nghiệm thông thường.'),
('DG005','KH002','SP005','DH002',5,N'Độ tinh khiết vượt mong đợi, kiểm định đạt chuẩn.'),
('DG006','KH003','SP006','DH003',4,N'Đóng gói chắc chắn, hạn sử dụng dài.'),
('DG007','KH003','SP007','DH003',2,N'Độ tinh khiết chưa như mong muốn.'),
('DG008','KH004','SP008','DH004',5,N'Hiệu quả rất cao khi dùng trong phản ứng hữu cơ.'),
('DG009','KH004','SP009','DH004',4,N'Chất lượng ổn định, giá hợp lý.'),
('DG010','KH005','SP010','DH005',3,N'Sử dụng tạm được cho nhu cầu cơ bản.'),

('DG011','KH006','SP011','DH006',5,N'Độ tinh sạch cao, phù hợp phân tích định lượng.'),
('DG012','KH007','SP012','DH007',4,N'Hoạt động tốt, không xuất hiện tạp chất.'),
('DG013','KH008','SP013','DH008',2,N'Có lắng cặn nhẹ, cần cải thiện.'),
('DG014','KH009','SP014','DH009',4,N'Chất lượng ổn định, độ phản ứng tốt.'),
('DG015','KH010','SP015','DH010',5,N'Rất phù hợp cho phòng thí nghiệm trường học.'),
('DG016','KH011','SP016','DH011',3,N'Chất lượng ở mức trung bình, phù hợp sử dụng thử nghiệm.'),
('DG017','KH012','SP017','DH012',4,N'Độ tinh khiết tốt, dễ thao tác.'),
('DG018','KH013','SP018','DH013',1,N'Không đạt yêu cầu kiểm định ban đầu.'),
('DG019','KH014','SP019','DH014',5,N'Hóa chất chất lượng cao, độ ổn định tốt.'),
('DG020','KH015','SP020','DH015',4,N'Đúng mô tả, dùng ổn trong phản ứng oxi hóa.'),

('DG021','KH016','SP021','DH016',5,N'Chất lượng vượt mong đợi, không lẫn tạp chất.'),
('DG022','KH017','SP022','DH017',3,N'Sử dụng ổn, nhưng cần cải thiện đóng gói.'),
('DG023','KH018','SP023','DH018',4,N'Màu sắc và độ tinh khiết đạt chuẩn phân tích.'),
('DG024','KH019','SP024','DH019',5,N'Hiệu suất phản ứng rất cao.'),
('DG025','KH020','SP025','DH020',3,N'Ổn định nhưng giá hơi cao so với thị trường.'),

('DG026','KH007','SP026','DH021',4,N'Hoạt tính tốt, phù hợp cho tổng hợp hữu cơ.'),
('DG027','KH014','SP027','DH022',2,N'Tinh khiết chưa đạt chuẩn như công bố.'),
('DG028','KH002','SP028','DH023',5,N'Đạt tiêu chuẩn phòng thí nghiệm, giao hàng nhanh.'),
('DG029','KH011','SP029','DH024',4,N'Chất lượng tốt, phản ứng đúng như mô tả kỹ thuật.'),
('DG030','KH019','SP030','DH025',3,N'Đạt chất lượng trung bình, chưa thật sự nổi bật.'),

('DG031','KH001','SP027','DH026',5,N'Độ tinh khiết ổn định, rất phù hợp cho thí nghiệm lặp lại.'),
('DG032','KH002','SP006','DH027',4,N'Độ ổn định tốt, ít bay hơi.'),
('DG033','KH003','SP029','DH028',3,N'Độ tinh khiết ở mức khá, cần tối ưu thêm.'),
('DG034','KH004','SP010','DH029',4,N'Lần mua thứ 2 vẫn giữ chất lượng tốt.'),
('DG035','KH005','SP012','DH030',5,N'Đạt chuẩn phân tích, rất đáng sử dụng.'),
('DG036','KH006','SP014','DH031',2,N'Không phù hợp với yêu cầu thí nghiệm đặc thù.'),
('DG037','KH007','SP016','DH032',4,N'Hóa chất hoạt động ổn định, phản ứng chính xác.'),
('DG038','KH008','SP018','DH033',5,N'Giá rẻ nhưng độ tinh khiết cao.'),
('DG039','KH009','SP038','DH037',3,N'Chất lượng ổn, phù hợp nhu cầu sử dụng thường xuyên.'),
('DG040','KH010','SP022','DH035',5,N'Rất đáng mua, chất lượng chuẩn kỹ thuật.'),

('DG041','KH011','SP024','DH036',4,N'Chất lượng tốt, đóng gói kín.'),
('DG042','KH012','SP026','DH037',5,N'Hóa chất đạt tiêu chuẩn ISO, rất uy tín.'),
('DG043','KH013','SP037','DH036',3,N'Được, nhưng giao hàng hơi chậm.'),
('DG044','KH014','SP030','DH039',4,N'Phản ứng ổn định, dễ bảo quản.'),
('DG045','KH015','SP001','DH040',5,N'Giá tốt và độ tinh khiết cao.'),
('DG046','KH016','SP002','DH041',2,N'Thực tế khác mô tả, cần cải thiện chất lượng.'),
('DG047','KH017','SP003','DH042',4,N'Hài lòng, dùng tốt trong thực hành.'),
('DG048','KH018','SP004','DH043',5,N'Chất lượng rất cao, phản ứng sạch.'),
('DG049','KH019','SP005','DH044',4,N'Hóa chất ổn định, độ bền tốt.'),
('DG050','KH020','SP006','DH045',3,N'Chất lượng chấp nhận được trong mức giá.');
GO

CREATE TRIGGER trg_NhapHang_TangTon
ON CT_PhieuNhapHang
AFTER INSERT
AS
BEGIN
    UPDATE SanPham
    SET SLTon = SLTon + i.SoLuong
    FROM inserted i
    WHERE SanPham.MaSP = i.MaSP;
END;
GO

CREATE TRIGGER trg_BanHang_TruTon
ON CT_DonHang_SP
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN SanPham sp ON sp.MaSP = i.MaSP
        WHERE sp.SLTon < i.SoLuong
    )
    BEGIN
        RAISERROR(N'Số lượng tồn kho không đủ!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE SanPham
    SET SLTon = SLTon - i.SoLuong
    FROM inserted i
    WHERE SanPham.MaSP = i.MaSP;
END;
GO

CREATE TRIGGER trg_XuLy_TangTon
ON CT_PhieuXuLy
AFTER INSERT
AS
BEGIN
    UPDATE SanPham
    SET SLTon = SLTon + i.SoLuong
    FROM inserted i
    WHERE SanPham.MaSP = i.MaSP;
END;
GO

CREATE TRIGGER trg_HuyDonHang_CapNhatTon
ON PhieuXuLyDH
AFTER INSERT
AS
BEGIN
    UPDATE sp
    SET sp.SLTon = sp.SLTon + ct.SoLuong
    FROM SanPham sp
    JOIN CT_PhieuXuLy ct ON sp.MaSP = ct.MaSP
    JOIN inserted i ON i.MaPX = ct.MaPX
    WHERE i.LoaiXuLy = N'HuyDon'
      AND i.TrangThaiPX = N'Đã duyệt';
END;
GO