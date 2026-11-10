# AGENTS.md — Surface JP Doctor (`C:\surface-jp-doctor`)

Bạn đang chạy trực tiếp trên một chiếc **Microsoft Surface Laptop hàng nội địa Nhật (Japanese JIS 106/109-key keyboard)** chạy Windows 10/11.
Người dùng phản ánh: **"Bàn phím bị lỗi vài phím chỗ `()=`"**, máy đấu giá (bid) từ Nhật về và cần kiểm tra tổng thể + sửa dứt điểm lỗi cụm phím `()=`.

## ⚡ Khi người dùng gõ `"khám"`, `"fix"`, `"tiếp"` hoặc dán prompt bất kỳ:
Thực hiện **ngay lập tức** theo thứ tự 4 bước sau (không hỏi lại các bước kỹ thuật, tự chạy lệnh PowerShell và báo cáo tiếng Việt ngắn gọn):

### Bước 1: Chạy chẩn đoán tự động toàn máy (Bàn phím, Pin, Chu kỳ sạc, SSD, Driver)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\diagnose.ps1
```
Đọc file `C:\surface-jp-doctor\diagnosis.json` vừa sinh ra để nắm:
- **Model máy, Serial, BIOS/UEFI**
- **Driver bàn phím trong Registry** (`HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters` → `LayerDriver JPN` đang là `kbd101.dll` hay `kbd106.dll`, `OverrideKeyboardIdentifier`, `OverrideKeyboardSubtype`, `Scancode Map`)
- **Độ chai pin Surface (% Wear) & Số chu kỳ sạc (`CycleCount`)**
- **Sức khỏe ổ cứng SSD (`HealthStatus`, `PowerOnHours`, `Temperature`)**
- **Thiết bị lỗi trong Device Manager (`ConfigManagerErrorCode -ne 0`)**

### Bước 2: Mở bảng Test Phím Trực Quan (`index.html`) để phân biệt Lệch Layout vs Liệt Vật Lý
```powershell
Start-Process .\index.html
```
Giải thích ngắn gọn cho chủ máy hiểu nguyên nhân gốc rễ:
1. **Trường hợp 1 (90% máy Surface nội địa Nhật tại VN — Phím sống 100%, chỉ lệch chuẩn Layout Nhật JIS ↔ Mỹ US):**
   - Trên mặt phím **Nhật (JIS 106/109 phím)**:
     - Dấu `(` in trên phím số **8** (`Shift + 8`)
     - Dấu `)` in trên phím số **9** (`Shift + 9`)
     - Dấu `=` in trên phím **`-`** (`Shift + -`), còn phím cạnh Backspace là `^` và `¥`.
   - Khi cài Windows tiếng Anh/Việt (mặc định nạp driver **Mỹ US `kbd101.dll`**):
     - Bấm `Shift + 8` lại ra `*`
     - Bấm `Shift + 9` lại ra `(`
     - Bấm `Shift + -` lại ra `_`
     → Người dùng nhìn mặt phím Nhật gõ sẽ thấy toàn bộ cụm `()=` bị nhảy sai ký tự!
2. **Trường hợp 2 (Liệt mạch phím vật lý cụm `8`, `9`, `0`, `-` trên mâm phím Surface):**
   - Khi bấm phím `8`, `9`, `0`, `-` trong `index.html` mà ô phím không sáng đèn (không có tín hiệu `ScanCode`).

### Bước 3: Áp dụng bản vá tức thì (Tác dụng NGAY LẬP TỨC, không cần khởi động lại máy!)
- **Nếu các phím `8`, `9`, `0`, `-` đều sáng đèn khi bấm trong `index.html` (Trường hợp 1):**
  Chạy ngay chế độ **Lai Thông Minh (`HybridInstant`)**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\fix-layout.ps1 -Mode HybridInstant
  ```
  *(Chế độ này biên dịch & chạy ngầm `SurfaceKeyFixer.exe` chỉ 15KB ngay trong Startup: giúp bấm `Shift+8` ra `(`, `Shift+9` và `Shift+0` đều ra `)`, `Shift+-` và phím cạnh `-` đều ra `=`, giữ `+` ra `+`, phím `_` cạnh Shift phải ra `_` **ngay lập tức không cần reboot**!)*
  - Nếu chủ máy muốn đổi toàn bộ 100% bàn phím về chuẩn Nhật gốc (`kbd106.dll`):
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\scripts\fix-layout.ps1 -Mode JIS106
    ```
  - Nếu chủ máy muốn đổi toàn bộ về chuẩn Mỹ gốc (`kbd101.dll`):
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\scripts\fix-layout.ps1 -Mode US101
    ```

- **Nếu có bất kỳ phím nào trong cụm `8`, `9`, `0`, `-` bị liệt mạch vật lý (Trường hợp 2):**
  Chạy ngay chế độ **Cứu Phím Liệt Vật Lý (`DeadKeyRescue`)**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\fix-layout.ps1 -Mode DeadKeyRescue
  ```
  *(Tận dụng các phím thừa đặc sản của bàn phím Nhật nằm ngay cạnh phím Space và dãy F9–F12 để gõ thay thế mà không cần bung máy thay mâm phím Surface):*
  - Phím **`無変換` (bên trái Space)** hoặc **`F9`** → Gõ **`(`** (Giữ `Shift` ra số **`8`**)
  - Phím **`変換` (bên phải Space)** hoặc **`F10`** → Gõ **`)`** (Giữ `Shift` ra số **`9`**)
  - Phím **`カタカナ` / `¥`** hoặc **`F11`** → Gõ **`=`** (Giữ `Shift` ra dấu **`+`**)
  - Phím **`_` (cạnh Shift phải)** hoặc **`F12`** → Gõ **`-`** (Giữ `Shift` ra dấu **`_`**)

### Bước 4: Báo cáo tổng kết ngắn gọn, dễ hiểu
In bảng tóm tắt:
1. Kết quả sửa cụm phím `()=` (mời gõ thử ngay vào Notepad/Zalo).
2. Tình trạng sức khỏe máy đấu giá Nhật: Pin còn bao nhiêu %, đã sạc bao nhiêu lần, ổ cứng SSD chạy bao nhiêu giờ, có driver nào thiếu không.
3. Nhắc lệnh dọn tài khoản `agy` trước khi rời quán:
   ```powershell
   irm https://tsennguyen.github.io/surface-jp-doctor/agy-clean.ps1 | iex
   ```
