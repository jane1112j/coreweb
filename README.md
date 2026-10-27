# Metanode FinSDK Monorepo

Metanode FinSDK là bộ công cụ phát triển phần mềm (SDK) toàn diện hỗ trợ người dùng và các doanh nghiệp thao tác, tích hợp và tương tác trực tiếp với **SMC Core Chain** (Mạng lưới Blockchain doanh nghiệp Metanode).

---

## 📌 Tổng quan hệ thống (System Architecture)

Dự án được xây dựng dưới dạng **Monorepo** quản lý bởi **Turborepo** và sử dụng trình quản lý gói **pnpm workspaces**. Kiến trúc hệ thống bao gồm các ứng dụng và các gói thư viện chuyên biệt:

### 📁 Các gói thư viện (Packages)

- **`packages/fiai-sdk` (`@metanodejs/fiai-sdk`)**: Thư viện SDK chính chịu trách nhiệm quản lý kết nối, giao tiếp thông qua cơ chế Client-Host Frame (`FrameClient`, `FiaiSDK`), xử lý các hành động (`Action Handlers`), cung cấp các tiện ích mã hóa/giải mã thông tin (`cryptoUtils`), và quản lý sự kiện.
- **`packages/bls-crypto`**: Gói xử lý mật mã học BLS (Boneh-Lynn-Shacham), hỗ trợ tạo khóa, ký số và xác thực chữ ký số phục vụ cho SMC Core Chain.
- **`packages/meta-proto`**: Định nghĩa và biên dịch các tệp cấu trúc Protocol Buffers (protobuf) để chuẩn hóa định dạng dữ liệu truyền thông điệp giữa SDK và các node trong mạng lưới SMC Core Chain.

### 📁 Ứng dụng tích hợp (Apps)

- **`apps/connect-wallet`**: Ứng dụng web mẫu đóng vai trò giao diện trực quan cho phép người dùng kết nối ví và kiểm thử các tính năng của Metanode FinSDK tương tác trực tiếp với mạng SMC.

### 🌐 Tài liệu trực tuyến các Frame (Frame Online Docs)

Bạn có thể truy cập trực tiếp các địa chỉ sau để xem tài liệu chi tiết và môi trường demo của từng Frame:

- <a href="https://crypto-vault.fi.ai/" target="_self"><strong>Crypto Vault Frame</strong></a>: Quản lý lưu trữ khóa bảo mật, mật mã học và bảo mật ví tài sản.
- <a href="https://blockchain-bridge.fi.ai/" target="_self"><strong>Blockchain Bridge Frame</strong></a>: Cầu nối blockchain hỗ trợ chuyển đổi dữ liệu và tài sản giữa các chuỗi.
- <a href="https://file-processor.fi.ai/" target="_self"><strong>File Processor Frame</strong></a>: Quản lý tệp tin, trích xuất gói ứng dụng, xử lý ảnh và lưu trữ ngoại tuyến (offline cache).

---

## ⚡ Cài đặt nhanh (Quick Start & Setup)

Hệ thống cung cấp sẵn các tệp kịch bản tự động kiểm tra phiên bản Node.js, thiết lập file môi trường `.env` từ cấu hình mẫu, cài đặt các gói phụ thuộc và tự động biên dịch thư viện SDK.

### 🍏 Trên macOS & Linux

1. Mở Terminal tại thư mục gốc của dự án.
2. Cấp quyền thực thi cho script (chỉ thực hiện một lần duy nhất):
   ```bash
   chmod +x setup.sh
   ```
3. Chạy script cài đặt:
   ```bash
   ./setup.sh
   ```

### 💻 Trên Windows

> **Quan trọng:** Chỉ dùng **pnpm**. Không chạy `npm install` / `yarn` — sẽ tạo `node_modules/.ignored` và lỗi `EPERM` trên Windows.

1. Mở Command Prompt (`cmd`) hoặc PowerShell tại thư mục gốc của dự án.
2. Chạy file batch:
   ```cmd
   setup.bat
   ```
   _Mẹo:_ Bạn cũng có thể click đúp trực tiếp vào tệp `setup.bat` từ trình quản lý thư mục Windows File Explorer.

Nếu gặp `EPERM ... .ignored`: đóng Cursor, xóa `apps\connect-wallet\node_modules`, rồi chạy lại `setup.bat` (không dùng npm).

---

## 🚀 Các lệnh phát triển & Vận hành

Sau khi quá trình setup hoàn tất, bạn có thể thực thi các lệnh sau từ thư mục gốc để quản lý dự án:

### Chạy chế độ lập trình (Development)

Khởi động máy chủ phát triển cho tất cả các ứng dụng và gói thư viện:

```bash
pnpm dev
```

### Biên dịch dự án (Build)

Biên dịch toàn bộ ứng dụng và các thư viện trong Monorepo:

```bash
pnpm build
```

### Kiểm tra lỗi cú pháp & Code Style (Linting)

Thực thi kiểm tra mã nguồn bằng ESLint trên toàn bộ hệ thống:

```bash
pnpm lint
```
