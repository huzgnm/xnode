# XNode

> **The unified node installer for V2bX / v2node / XrayR**

> **🇻🇳 Tiếng Việt** | [🇬🇧 English](#english) | [🇨🇳 中文](#中文)

```
 ═╗ ╦╔╗╔╔═╗╔╦╗╔═╗
  ╔╩╦╝║║║║ ║ ║║║╣
 ╩ ╚═╝╝╚╝╚═╝═╩╝╚═╝
```

Một script duy nhất cài đặt node V2board cho cả **V2bX**, **v2node**, và **XrayR**, với auto-fix lỗi hệ thống và menu quản lý đẹp. Hỗ trợ **3 ngôn ngữ**: Tiếng Việt / English / 中文.

## ⚡ Cài đặt nhanh

```bash
bash <(curl -Ls https://raw.githubusercontent.com/huzgnm/xnode/main/install.sh)
```

Hoặc dùng `wget`:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/huzgnm/xnode/main/install.sh)
```

Khi script chạy sẽ hỏi chọn ngôn ngữ:
```
Select language / 选择语言 / Chọn ngôn ngữ:
  1) Tiếng Việt
  2) English
  3) 中文 (简体)
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
  - `Hysteria2` → luôn TLS (V2bX/v2node only)

- **3 cách xin SSL cert:**
  - HTTP challenge (cần port 80 free)
  - DNS challenge (Cloudflare / Aliyun / GoDaddy / khác)
  - File (đã có cert sẵn)

- **Auto-fix tự động:**
  - Sync time (NTP) — chống lỗi TLS handshake
  - Locale (`en_US.UTF-8`) — chống crash script gốc
  - DNS resolver — fallback Cloudflare 1.1.1.1
  - Cài deps: `curl wget jq unzip socat ca-certificates`
  - Tạo swap 1GB nếu RAM < 768MB
  - Bật BBR + tối ưu mạng (qua `sh.kinako.one`)

- **Chẩn đoán lỗi sau cài:**
  - Port bị chiếm → chỉ ra process
  - API key sai (401/403)
  - Node ID không tồn tại
  - Cert lỗi → check domain trỏ đúng IP
  - Connection refused → test panel reachable

## 🛠 Quản lý sau khi cài

Script tự cài lệnh **`xnode`**:

```bash
xnode              # mở menu
xnode start        # bật service
xnode stop         # tắt service
xnode restart      # restart
xnode status       # trạng thái
xnode log          # log realtime
xnode monitor      # theo dõi RAM/CPU
xnode add          # thêm node mới
xnode config       # xem config
xnode edit         # sửa config (nano)
xnode update       # cập nhật core
xnode backup       # backup config
xnode restore      # khôi phục backup
xnode bbr          # bật BBR
xnode ports        # xem port đang mở
xnode uninstall    # gỡ toàn bộ
xnode help         # xem hướng dẫn
```

## 📜 License

MIT

---

<a name="english"></a>
## 🇬🇧 English

> **The unified node installer for V2bX / v2node / XrayR**

A single script to install V2board nodes for **V2bX**, **v2node**, and **XrayR**, with system auto-fix and beautiful management menu. Supports **3 languages**: Vietnamese / English / Chinese.

### ⚡ Quick install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/huzgnm/xnode/main/install.sh)
```

When the script runs, you'll be asked to choose language:
```
Select language / 选择语言 / Chọn ngôn ngữ:
  1) Tiếng Việt
  2) English
  3) 中文 (简体)
```

### 🎯 Features

- **3 supported cores:** V2bX (multi-core), v2node (simplest), XrayR (classic)
- **5 node types** with smart TLS detection:
  - VLESS → Reality (no cert) or Vision/TLS (with cert)
  - Vmess → WS+TLS (with cert) or raw (no TLS)
  - Trojan → always TLS
  - Shadowsocks → no TLS
  - Hysteria2 → always TLS (V2bX/v2node only)
- **3 SSL cert methods:** HTTP challenge / DNS challenge / File
- **Auto-fix:** time sync, locale, DNS, deps, swap, BBR
- **Error diagnosis:** port conflict, wrong API key, missing Node ID, cert issues, connection refused

### 🛠 Post-install management

```bash
xnode              # open menu
xnode start | stop | restart | status | log | monitor
xnode add          # add new node
xnode config       # view config
xnode edit         # edit config
xnode update       # update core
xnode backup | restore | bbr | ports | uninstall
xnode help
```

---

<a name="中文"></a>
## 🇨🇳 中文

> **统一的 V2bX / v2node / XrayR 节点安装器**

一个脚本安装 V2board 节点 (**V2bX**, **v2node**, **XrayR**), 带系统自动修复和漂亮的管理菜单. 支持 **3 种语言**: 越南语 / 英语 / 中文.

### ⚡ 快速安装

```bash
bash <(curl -Ls https://raw.githubusercontent.com/huzgnm/xnode/main/install.sh)
```

脚本运行时会提示选择语言:
```
Select language / 选择语言 / Chọn ngôn ngữ:
  1) Tiếng Việt
  2) English
  3) 中文 (简体)
```

### 🎯 功能

- **支持 3 个内核:** V2bX (多核心), v2node (最简单), XrayR (经典)
- **5 种节点类型**, 智能判断是否需要 TLS:
  - VLESS → Reality (无证书) 或 Vision/TLS (带证书)
  - Vmess → WS+TLS (带证书) 或 raw (无 TLS)
  - Trojan → 必须 TLS
  - Shadowsocks → 无 TLS
  - Hysteria2 → 必须 TLS (仅限 V2bX/v2node)
- **3 种 SSL 证书申请方式:** HTTP 验证 / DNS 验证 / 文件
- **自动修复:** 时间同步, locale, DNS, 依赖, swap, BBR
- **错误诊断:** 端口占用, API key 错误, 节点 ID 不存在, 证书问题, 连接失败

### 🛠 安装后管理

```bash
xnode              # 打开菜单
xnode start | stop | restart | status | log | monitor
xnode add          # 添加新节点
xnode config       # 查看配置
xnode edit         # 编辑配置
xnode update       # 更新内核
xnode backup | restore | bbr | ports | uninstall
xnode help
```

---

## 🙏 Credits

XNode is built on top of these excellent projects:

- [V2bX](https://github.com/wyx2685/V2bX) by wyx2685
- [v2node](https://github.com/wyx2685/v2node) by wyx2685
- [XrayR](https://github.com/XrayR-project/XrayR) by XrayR-project
- [Xray-core](https://github.com/XTLS/Xray-core) by XTLS team
- BBR optimizer: [sh.kinako.one](https://sh.kinako.one)
