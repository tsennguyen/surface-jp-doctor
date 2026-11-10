# 🛠️ Surface JP Doctor (`surface-jp-doctor`)

Bộ công cụ **Chẩn đoán & Sửa lỗi cụm phím `()=` cho Microsoft Surface Laptop Hàng Nội Địa Nhật (JIS 106/109 phím)** + Kiểm tra nhanh sức khỏe máy đấu giá Nhật (Pin Cycle Count, Độ chai pin, SSD SMART, Driver).

👉 **Giao diện Test Phím Trực Quan & Copy Lệnh 1-Chạm (không cần gõ ký tự đặc biệt):**  
🔗 **[https://tsennguyen.github.io/surface-jp-doctor/](https://tsennguyen.github.io/surface-jp-doctor/)**

---

## ⚡ CÁCH 1: SIÊU TỐC 10 GIÂY TẠI QUÁN CAFE (Khuyên dùng — Không cần cài `agy`, không cần login Google)

Mở **PowerShell (Run as Administrator)** trên máy Surface, dán lệnh sau rồi bấm `Enter`:

```powershell
irm https://tsennguyen.github.io/surface-jp-doctor/run.ps1 | iex
```

**Lệnh này sẽ tự động:**
1. Kiểm tra ngay Driver bàn phím hiện tại (`kbd101.dll` Mỹ hay `kbd106.dll` Nhật), % độ chai pin Surface, số lần sạc (`CycleCount`), ổ cứng SSD và lỗi Device Manager.
2. Mở bảng **Test Phím Trực Quan (`index.html`)** để bấm thử cụm `8 (`, `9 )`, `0`, `- =`, `^ ~`, `¥ |` (phân biệt ngay trong 3 giây là **lệch chuẩn phím Nhật/Mỹ** hay **đứt mạch phím vật lý**).
3. Cho phép chọn **4 chế độ sửa lỗi ăn ngay**:
   - **`[1]` Chế độ Lai Thông Minh (`HybridInstant` — Khuyên dùng, tác dụng NGAY không cần khởi động lại máy):**  
     Giữ nguyên thói quen gõ chuẩn quốc tế, nhưng tự động dịch đúng cụm phím in trên mặt máy Nhật:
     - `Shift + 8` → **`(`**
     - `Shift + 9` (hoặc `Shift + 0`) → **`)`**
     - `Shift + -` (hoặc phím cạnh `-`) → **`=`** (giữ `Shift` ở phím cạnh `-` ra **`+`**)
     - Phím `_` (cạnh Shift phải) → **`_`**
   - **`[2]` Chế độ Cứu Phím Liệt Vật Lý (`DeadKeyRescue` — Tác dụng NGAY không cần bung máy):**  
     Nếu phím số `8`, `9`, `0`, `-` bị liệt mạch thật, tự động gán sang các nút thừa đặc sản của bàn phím Nhật nằm ngay cạnh phím Space (và dãy `F9`–`F12`):
     - Nút **`無変換` (bên trái Space)** hoặc **`F9`** → **`(`** (Giữ `Shift` ra số **`8`**)
     - Nút **`変換` (bên phải Space)** hoặc **`F10`** → **`)`** (Giữ `Shift` ra số **`9`**)
     - Nút **`カタカナ` / `¥`** hoặc **`F11`** → **`=`** (Giữ `Shift` ra dấu **`+`**)
     - Nút **`_` (cạnh Shift phải)** hoặc **`F12`** → **`-`** (Giữ `Shift` ra dấu **`_`**)
   - **`[3]` Đổi Driver Windows sang chuẩn Nhật Gốc (`kbd106.dll` - JIS 106/109 phím)**
   - **`[4]` Đổi Driver Windows sang chuẩn Quốc Tế Mỹ Gốc (`kbd101.dll` - US 101/102 phím)**

---

## 🤖 CÁCH 2: TỰ CÀI ANTIGRAVITY CLI (`agy`) + TẢI REPO + MỞ AGENT

Nếu muốn dùng **Antigravity CLI (`agy`)** để Agent tự khám và xử lý mọi thứ:

### Bước 1: Mở PowerShell (Admin), dán 1 lệnh duy nhất:
```powershell
irm https://tsennguyen.github.io/surface-jp-doctor/agy-go.ps1 | iex
```
*(Lệnh này tự cài `agy` nếu máy chưa có, tự tải toàn bộ repo kèm `AGENTS.md` về `C:\surface-jp-doctor` mà không cần cài Git, tự copy sẵn câu Prompt vào Clipboard và mở thẳng `agy`!)*

*(Nếu chỉ muốn cài riêng `agy` chuẩn chính chủ Google trên Windows PowerShell):*
```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

### Bước 2: Khi đã vào trong `agy`
Chỉ cần bấm **`Ctrl + V` → `Enter`** (vì `agy-go.ps1` đã copy sẵn prompt vào Clipboard), hoặc gõ đúng 1 từ:
```text
khám
```
Hoặc nếu mở `agy` ở thư mục bất kỳ, dán câu prompt này:
```text
Chạy powershell: irm https://tsennguyen.github.io/surface-jp-doctor/run.ps1 -OutFile C:\run.ps1; đọc C:\surface-jp-doctor\AGENTS.md, chạy scripts\diagnose.ps1 và fix lỗi cụm phím ()= trên máy Surface Nhật này (chế độ HybridInstant hoặc DeadKeyRescue), rồi báo cáo Pin/SSD/Driver bằng tiếng Việt.
```

### Bước 3: Dọn sạch tài khoản `agy` trên máy khách trước khi về
Chạy lệnh này trong PowerShell để xoá toàn bộ phiên đăng nhập Google / `.gemini` / `agy` trên máy khách (nhưng **giữ nguyên 100% bộ fix bàn phím Surface**):
```powershell
irm https://tsennguyen.github.io/surface-jp-doctor/agy-clean.ps1 | iex
```
