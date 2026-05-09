# VPNNGA Node Installer

Script cài đặt node V2board tự động cho **V2bX**, **v2node**, và **XrayR** với auto-fix lỗi hệ thống.

## ⚡ Cài đặt nhanh

```bash
bash <(curl -Ls https://raw.githubusercontent.com/huzgnm/vpn-installer/main/install.sh)
```

Hoặc nếu server không có `curl`:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/huzgnm/vpn-installer/main/install.sh)
```

## 🎯 Tính năng

- **3 cores hỗ trợ:**
  - `V2bX` — đa core, mạnh nhất, panel push Reality/Cert
  - `v2node` — Xray-core thuần, **đơn giản nhất** (panel quản lý 100%)
  - `XrayR` — cổ điển, cấu hình Reality/cert ngay tại node

- **5 loại node với logic hỏi TLS thông minh:**
  - `VLESS` → hỏi tiếp Reality (no cert) hay Vision/TLS (có cert)
  - `Vmess` → hỏi tiếp WS+TLS (có cert) hay raw (no cert)
  - `Trojan` → luôn TLS (hỏi cert)
  - `Shadowsocks` → không TLS, không hỏi cert
  - `Hysteria2` → luôn TLS (hỏi cert, V2bX/v2node only)

- **3 cách xin SSL cert:**
  - HTTP challenge (cần port 80 free)
  - DNS challenge (Cloudflare / Aliyun / GoDaddy / khác)
  - File (đã có cert sẵn)

- **Auto-fix tự động:**
  - Sync time (NTP) — chống lỗi TLS handshake
  - Locale (`en_US.UTF-8`) — chống crash script gốc
  - DNS resolver — fallback Cloudflare 1.1.1.1
  - Cài deps: `curl wget jq unzip socat ca-certificates cron`
  - Tạo swap 1GB nếu RAM < 768MB
  - Bật BBR + fq_codel + TCP fastopen

- **Chẩn đoán lỗi sau cài:**
  - Port bị chiếm → chỉ ra process
  - API key sai (401/403)
  - Node ID không tồn tại
  - Cert lỗi → check domain trỏ đúng IP
  - Connection refused → test panel reachable
  - JSON syntax error → cảnh báo file nào

## 📋 Yêu cầu

- Hệ điều hành: **Debian 11/12** (đã test), Ubuntu 20.04+, CentOS 7+, AlmaLinux 9
- Quyền: **root** hoặc `sudo`
- Mạng: kết nối được tới `github.com` và panel của bạn

## 🚀 Hướng dẫn sử dụng

### Bước 1: Tạo node trên panel admin
1. Đăng nhập panel admin (vd: `https://vpnnga.com/admin`)
2. **Node Management** → **Add Node**
3. Cấu hình loại node, port, Reality settings (nếu có)... → **Save**
4. Ghi nhớ **Node ID**

### Bước 2: SSH vào server và chạy 1 lệnh

```bash
bash <(curl -Ls https://raw.githubusercontent.com/huzgnm/vpn-installer/main/install.sh)
```

### Bước 3: Trả lời các câu hỏi của script

Ví dụ với **v2node** (đơn giản nhất, chỉ 3 câu hỏi):

```
Chọn [1-3]: 2

Panel URL [https://vpnnga.com]: https://kaielp93a.vpnnga.com
API Key (token): hungyeuhoivahoiyeuhung
Node ID (số): 27

▸ Tải v2node install script...
▸ [tự cài + sinh config + start service]
[✓] v2node đang chạy
```

Ví dụ với **V2bX + Trojan + Cloudflare DNS**:

```
Chọn [1-3]: 1

Panel URL: https://cutchomeo.mosvpn.ru
API Key: nguyenmanhhung2005
Node ID: 5

Loại node:
  3) Trojan + TLS
Chọn [1-6]: 3

Domain: deca.11223344.io.vn

Cách xin cert SSL:
  2) DNS challenge
Chọn [1-3]: 2

Email LE: nmhung149@gmail.com

Provider [1-4]: 1
  CF Email: nmhung149@gmail.com
  CF Global API Key: d4a35a671e8cf6...
```

## 🛠 Quản lý sau khi cài

Script tự động cài luôn lệnh **`vpnnga`** — gõ là vào menu quản lý đẹp:

```bash
vpnnga              # mở menu
vpnnga start        # bật service
vpnnga stop         # tắt service
vpnnga restart      # restart
vpnnga status       # xem trạng thái
vpnnga log          # log realtime
vpnnga monitor      # theo dõi RAM/CPU
vpnnga add          # thêm node mới (chạy lại installer)
vpnnga config       # xem config
vpnnga edit         # sửa config (nano)
vpnnga update       # cập nhật core
vpnnga backup       # backup config → /root/vpnnga-backups/
vpnnga restore      # khôi phục từ backup
vpnnga bbr          # bật BBR + tối ưu mạng
vpnnga ports        # xem IP & port đang mở
vpnnga uninstall    # gỡ toàn bộ
vpnnga help         # xem hướng dẫn
```

Hoặc dùng lệnh gốc của tác giả core:

```bash
# V2bX
V2bX start | stop | restart | status | log | x25519 | update

# v2node
v2node start | stop | restart | status | log | update | generate

# XrayR
xrayr start | stop | restart | status | log
```

## 📁 Đường dẫn config

| Core | Config file |
|------|-------------|
| V2bX | `/etc/V2bX/config.json` |
| v2node | `/etc/v2node/config.json` |
| XrayR | `/etc/XrayR/config.yml` |

## ❓ Troubleshooting

### Service không start được
```bash
journalctl -u V2bX -n 50    # hoặc v2node / XrayR
```

### Test panel reachable
```bash
curl -v https://your-panel.com
```

### Reality không kết nối từ client
- Kiểm tra port server đã mở: `ss -tlnp | grep <port>`
- Kiểm tra cấu hình Reality trên panel khớp với client
- Xem firewall: `ufw status` / `iptables -L INPUT -n`

### Cert xin lỗi (HTTP challenge)
- Port 80 phải free: `ss -tlnp | grep ':80 '`
- Domain phải trỏ A record về IP server: `dig your-domain.com`

### Cert xin lỗi (DNS challenge)
- Kiểm tra API key của DNS provider
- Cloudflare phải dùng **Global API Key** (không phải API Token)

## 📜 License

MIT — sử dụng và sửa đổi tự do.

## 🙏 Credits

- [V2bX](https://github.com/wyx2685/V2bX) by wyx2685
- [v2node](https://github.com/wyx2685/v2node) by wyx2685
- [XrayR](https://github.com/XrayR-project/XrayR) by XrayR-project
- [Xray-core](https://github.com/XTLS/Xray-core) by XTLS team
