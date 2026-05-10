#!/bin/bash
#
# XNode - V2board Node Installer (multi-language: VI / EN / ZH)
# Install V2board node (V2bX / v2node / XrayR) - panel-driven
#

set -o pipefail

# ===== Colors =====
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[0;36m'; W='\033[1m'; D='\033[2m'; N='\033[0m'
ok()   { echo -e "${G}[✓]${N} $1"; }
err()  { echo -e "${R}[✗]${N} $1"; }
warn() { echo -e "${Y}[!]${N} $1"; }
info() { echo -e "${B}[i]${N} $1"; }
step() { echo -e "${W}▸${N} $1"; }

# ===== Root check =====
[[ $EUID -ne 0 ]] && { echo -e "${R}[✗]${N} Need root / 需要root / Cần root: sudo bash $0"; exit 1; }

# ===== Banner =====
clear
echo -e "${B}"
cat <<'EOF'
 ═╗ ╦╔╗╔╔═╗╔╦╗╔═╗
  ╔╩╦╝║║║║ ║ ║║║╣
 ╩ ╚═╝╝╚╝╚═╝═╩╝╚═╝
   Node Installer v3.0
EOF
echo -e "${N}"

# =====================================================================
#  LANGUAGE SELECTION
# =====================================================================
echo "  Select language / 选择语言 / Chọn ngôn ngữ:"
echo "    1) Tiếng Việt"
echo "    2) English"
echo "    3) 中文 (简体)"
read -rp "  > " lang_choice
case $lang_choice in
    2) LANG_CODE="en" ;;
    3) LANG_CODE="zh" ;;
    *) LANG_CODE="vi" ;;
esac
export LANG_CODE

# ===== Translation function =====
# Usage: t key_name
t() {
    local key=$1
    local val
    case $LANG_CODE in
        en) val="${EN[$key]}" ;;
        zh) val="${ZH[$key]}" ;;
        *)  val="${VI[$key]}" ;;
    esac
    echo "$val"
}

# Declare associative arrays for 3 languages
declare -A VI EN ZH

# ===== Vietnamese =====
VI[step1_title]="=== Bước 1/4: Kiểm tra & sửa lỗi hệ thống ==="
VI[step2_title]="=== Bước 2/4: Chọn core ==="
VI[step3_title]="=== Bước 3/4: Thông tin Panel & Node ==="
VI[step4_title]="=== Bước 4/4: Cài đặt core ==="
VI[time_sync]="Đồng bộ thời gian..."
VI[locale_check]="Kiểm tra locale..."
VI[locale_ok]="Locale OK"
VI[dns_check]="Kiểm tra DNS resolver..."
VI[dns_fix]="Sửa DNS → 1.1.1.1"
VI[dns_ok]="DNS OK"
VI[deps_install]="Cài dependencies..."
VI[deps_ok]="Dependencies OK"
VI[swap_low]="RAM thấp → tạo swap 1GB..."
VI[swap_ok]="Swap 1GB sẵn sàng"
VI[choose_core]="  ${G}1)${N} ${W}V2bX${N}    - Đa core, mạnh nhất, cấu hình node tại server\n  ${G}2)${N} ${W}v2node${N}  - Xray-core thuần, ${G}đơn giản nhất${N} - panel quản lý 100%\n  ${G}3)${N} ${W}XrayR${N}   - Cổ điển, cấu hình Reality/cert ngay tại node"
VI[prompt_core]="Chọn [1-3]: "
VI[invalid_choice]="Lựa chọn không hợp lệ"
VI[core_set]="Sẽ cài"
VI[panel_url]="Panel URL [https://vpnnga.com]: "
VI[invalid_url]="URL không hợp lệ"
VI[panel_check]="Kiểm tra panel reachable..."
VI[panel_ok]="Panel reachable"
VI[panel_unreachable]="Không kết nối được panel"
VI[continue_anyway]="Vẫn tiếp tục? (y/N): "
VI[api_key]="API Key (token): "
VI[api_key_short]="API Key tối thiểu 8 ký tự"
VI[node_id]="Node ID (số): "
VI[node_id_invalid]="Phải là số"
VI[v2node_info1]="v2node: panel quản lý toàn bộ cấu hình node (giao thức, Reality, cert, port)"
VI[v2node_info2]="→ Đảm bảo node đã được tạo và cấu hình đầy đủ trên panel admin"
VI[node_type]="Loại node:"
VI[type_trojan_tls]="(luôn dùng TLS)"
VI[type_no_tls]="(không cần TLS)"
VI[type_hy2]="(luôn TLS, V2bX/v2node only)"
VI[xrayr_no_hy2]="XrayR không hỗ trợ Hysteria2"
VI[vless_subtype]="VLESS dùng kiểu nào?"
VI[vless_reality]="(không cần domain/cert, panel push key)"
VI[vless_tls]="(cần domain + cert)"
VI[vmess_subtype]="Vmess dùng transport nào?"
VI[vmess_ws]="(cần domain + cert, qua CDN được)"
VI[vmess_raw]="(không cần TLS - không khuyến nghị)"
VI[ws_path]="WebSocket path [/vmess]: "
VI[ws_invalid]="Sai"
VI[domain_prompt]="Domain (ví dụ: node.vpnnga.com): "
VI[domain_required]="Cần domain"
VI[cert_method]="Cách xin cert SSL:"
VI[cert_http]="HTTP challenge   - cần port 80 free + domain trỏ A về IP server"
VI[cert_dns]="DNS challenge    - cần API key DNS provider (linh hoạt hơn)"
VI[cert_file]="File             - đã có cert sẵn"
VI[email_le_default]="Email LE [admin@vpnnga.com]: "
VI[email_le]="Email LE: "
VI[email_required]="Cần email"
VI[provider_choice]="  1) Cloudflare   2) Aliyun   3) GoDaddy   4) Khác"
VI[provider_prompt]="Provider [1-4]: "
VI[cf_email]="  CF Email: "
VI[cf_key]="  CF Global API Key: "
VI[al_id]="  Access Key ID: "
VI[al_secret]="  Access Key Secret: "
VI[gd_key]="  GoDaddy API Key: "
VI[gd_secret]="  GoDaddy API Secret: "
VI[provider_name]="  Provider name: "
VI[env_name1]="  Env 1 name: "
VI[env_val1]="  Env 1 value: "
VI[env_name2]="  Env 2 name (Enter để skip): "
VI[env_val2]="  Env 2 value: "
VI[place_cert_at]="Hãy đặt cert tại"
VI[install_failed]="Cài thất bại"
VI[download_failed]="Không tải được"
VI[install_done]="đã cài"
VI[start_service]="Khởi động"
VI[service_running]="đang chạy"
VI[service_failed]="không khởi động được. Đang chẩn đoán..."
VI[bbr_install]="Cài BBR + tối ưu mạng..."
VI[manager_install]="Cài XNode Manager (lệnh: xnode)..."
VI[manager_ok]="Đã cài lệnh: xnode"
VI[manager_skip]="Không tải được xnode.sh — bỏ qua menu manager"
VI[install_complete]="CÀI ĐẶT HOÀN TẤT"
VI[summary_core]="Core:"
VI[summary_config]="Config:"
VI[summary_ip]="Server IP:"
VI[summary_panel]="Panel:"
VI[summary_node_id]="Node ID:"
VI[summary_node_type]="Loại node:"
VI[summary_domain]="Domain:"
VI[quick_mgmt]="💡 Quản lý nhanh:"
VI[mgmt_menu]="# mở menu quản lý đẹp"
VI[mgmt_start]="# bật service"
VI[mgmt_restart]="# restart"
VI[mgmt_log]="# xem log realtime"
VI[mgmt_backup]="# backup config"
VI[mgmt_help]="# xem tất cả lệnh"
VI[orig_cmd]="Lệnh gốc của tác giả core (nếu thích):"
VI[err_port_busy]="Lỗi: Port đã bị chiếm"
VI[err_port_busy_proc]="Process đang chiếm port:"
VI[err_port_busy_hint]="→ Dừng process đó, hoặc đổi port trong panel"
VI[err_api]="Lỗi: API Key sai"
VI[err_api_hint]="→ Kiểm tra lại token trong panel admin"
VI[err_node_notfound]="Lỗi: Node ID không tồn tại"
VI[err_node_hint]="→ Vào panel admin → Node Management → kiểm tra ID"
VI[err_cert]="Lỗi: Cert có vấn đề"
VI[err_cert_hint1]="→ Kiểm tra domain trỏ về IP server:"
VI[err_cert_hint2]="→ Kiểm tra port 80 (HTTP challenge) hoặc API key DNS provider"
VI[err_conn]="Lỗi: Không kết nối được panel"
VI[err_conn_hint1]="→ Test:"
VI[err_conn_hint2]="→ Có thể firewall hosting/VPS chặn outbound"
VI[err_json]="Lỗi: Config sai cú pháp"
VI[err_json_hint]="→ Xem"
VI[err_unknown]="Lỗi không xác định. Xem log đầy đủ:"
VI[note_reality_xrayr]="→ Copy publicKey ở trên vào panel"

# ===== English =====
EN[step1_title]="=== Step 1/4: System check & auto-fix ==="
EN[step2_title]="=== Step 2/4: Choose core ==="
EN[step3_title]="=== Step 3/4: Panel & Node info ==="
EN[step4_title]="=== Step 4/4: Install core ==="
EN[time_sync]="Syncing time..."
EN[locale_check]="Checking locale..."
EN[locale_ok]="Locale OK"
EN[dns_check]="Checking DNS resolver..."
EN[dns_fix]="Fixing DNS → 1.1.1.1"
EN[dns_ok]="DNS OK"
EN[deps_install]="Installing dependencies..."
EN[deps_ok]="Dependencies OK"
EN[swap_low]="Low RAM → creating 1GB swap..."
EN[swap_ok]="Swap 1GB ready"
EN[choose_core]="  ${G}1)${N} ${W}V2bX${N}    - Multi-core, most powerful, configure node at server\n  ${G}2)${N} ${W}v2node${N}  - Pure Xray-core, ${G}simplest${N} - panel manages 100%\n  ${G}3)${N} ${W}XrayR${N}   - Classic, configure Reality/cert at node"
EN[prompt_core]="Choose [1-3]: "
EN[invalid_choice]="Invalid choice"
EN[core_set]="Will install"
EN[panel_url]="Panel URL [https://vpnnga.com]: "
EN[invalid_url]="Invalid URL"
EN[panel_check]="Checking panel reachable..."
EN[panel_ok]="Panel reachable"
EN[panel_unreachable]="Cannot reach panel"
EN[continue_anyway]="Continue anyway? (y/N): "
EN[api_key]="API Key (token): "
EN[api_key_short]="API Key must be at least 8 chars"
EN[node_id]="Node ID (number): "
EN[node_id_invalid]="Must be a number"
EN[v2node_info1]="v2node: panel manages all node config (protocol, Reality, cert, port)"
EN[v2node_info2]="→ Make sure the node is created and configured on panel admin"
EN[node_type]="Node type:"
EN[type_trojan_tls]="(always TLS)"
EN[type_no_tls]="(no TLS needed)"
EN[type_hy2]="(always TLS, V2bX/v2node only)"
EN[xrayr_no_hy2]="XrayR does not support Hysteria2"
EN[vless_subtype]="VLESS variant?"
EN[vless_reality]="(no domain/cert needed, panel pushes keys)"
EN[vless_tls]="(needs domain + cert)"
EN[vmess_subtype]="Vmess transport?"
EN[vmess_ws]="(needs domain + cert, CDN-friendly)"
EN[vmess_raw]="(no TLS - not recommended)"
EN[ws_path]="WebSocket path [/vmess]: "
EN[ws_invalid]="Wrong"
EN[domain_prompt]="Domain (e.g. node.vpnnga.com): "
EN[domain_required]="Domain required"
EN[cert_method]="SSL cert method:"
EN[cert_http]="HTTP challenge   - port 80 free + domain A record → server IP"
EN[cert_dns]="DNS challenge    - DNS provider API key (more flexible)"
EN[cert_file]="File             - cert already prepared"
EN[email_le_default]="LE Email [admin@vpnnga.com]: "
EN[email_le]="LE Email: "
EN[email_required]="Email required"
EN[provider_choice]="  1) Cloudflare   2) Aliyun   3) GoDaddy   4) Other"
EN[provider_prompt]="Provider [1-4]: "
EN[cf_email]="  CF Email: "
EN[cf_key]="  CF Global API Key: "
EN[al_id]="  Access Key ID: "
EN[al_secret]="  Access Key Secret: "
EN[gd_key]="  GoDaddy API Key: "
EN[gd_secret]="  GoDaddy API Secret: "
EN[provider_name]="  Provider name: "
EN[env_name1]="  Env 1 name: "
EN[env_val1]="  Env 1 value: "
EN[env_name2]="  Env 2 name (Enter to skip): "
EN[env_val2]="  Env 2 value: "
EN[place_cert_at]="Place cert at"
EN[install_failed]="Install failed"
EN[download_failed]="Download failed"
EN[install_done]="installed"
EN[start_service]="Starting"
EN[service_running]="running"
EN[service_failed]="failed to start. Diagnosing..."
EN[bbr_install]="Installing BBR + network tuning..."
EN[manager_install]="Installing XNode Manager (command: xnode)..."
EN[manager_ok]="Command installed: xnode"
EN[manager_skip]="Cannot download xnode.sh — skipping manager menu"
EN[install_complete]="INSTALLATION COMPLETE"
EN[summary_core]="Core:"
EN[summary_config]="Config:"
EN[summary_ip]="Server IP:"
EN[summary_panel]="Panel:"
EN[summary_node_id]="Node ID:"
EN[summary_node_type]="Node type:"
EN[summary_domain]="Domain:"
EN[quick_mgmt]="💡 Quick management:"
EN[mgmt_menu]="# open beautiful management menu"
EN[mgmt_start]="# start service"
EN[mgmt_restart]="# restart"
EN[mgmt_log]="# view realtime log"
EN[mgmt_backup]="# backup config"
EN[mgmt_help]="# show all commands"
EN[orig_cmd]="Original command from core author (if you prefer):"
EN[err_port_busy]="Error: Port is in use"
EN[err_port_busy_proc]="Process using port:"
EN[err_port_busy_hint]="→ Stop that process, or change port on panel"
EN[err_api]="Error: API Key is wrong"
EN[err_api_hint]="→ Re-check token in panel admin"
EN[err_node_notfound]="Error: Node ID does not exist"
EN[err_node_hint]="→ Go to panel admin → Node Management → check ID"
EN[err_cert]="Error: Cert problem"
EN[err_cert_hint1]="→ Check domain points to server IP:"
EN[err_cert_hint2]="→ Check port 80 (HTTP) or DNS provider API key"
EN[err_conn]="Error: Cannot reach panel"
EN[err_conn_hint1]="→ Test:"
EN[err_conn_hint2]="→ Hosting/VPS firewall may block outbound"
EN[err_json]="Error: Config syntax error"
EN[err_json_hint]="→ See"
EN[err_unknown]="Unknown error. Full log:"
EN[note_reality_xrayr]="→ Copy publicKey above into the panel"

# ===== Chinese =====
ZH[step1_title]="=== 步骤 1/4: 系统检查 & 自动修复 ==="
ZH[step2_title]="=== 步骤 2/4: 选择内核 ==="
ZH[step3_title]="=== 步骤 3/4: 面板 & 节点信息 ==="
ZH[step4_title]="=== 步骤 4/4: 安装内核 ==="
ZH[time_sync]="同步时间..."
ZH[locale_check]="检查 locale..."
ZH[locale_ok]="Locale 正常"
ZH[dns_check]="检查 DNS 解析..."
ZH[dns_fix]="修复 DNS → 1.1.1.1"
ZH[dns_ok]="DNS 正常"
ZH[deps_install]="安装依赖..."
ZH[deps_ok]="依赖就绪"
ZH[swap_low]="内存不足 → 创建 1GB swap..."
ZH[swap_ok]="Swap 1GB 已创建"
ZH[choose_core]="  ${G}1)${N} ${W}V2bX${N}    - 多内核, 功能最全, 在服务器配置节点\n  ${G}2)${N} ${W}v2node${N}  - 纯 Xray-core, ${G}最简单${N} - 面板管理 100%\n  ${G}3)${N} ${W}XrayR${N}   - 经典, 在节点配置 Reality/cert"
ZH[prompt_core]="选择 [1-3]: "
ZH[invalid_choice]="无效选项"
ZH[core_set]="将安装"
ZH[panel_url]="面板地址 [https://vpnnga.com]: "
ZH[invalid_url]="无效URL"
ZH[panel_check]="检查面板可达性..."
ZH[panel_ok]="面板可达"
ZH[panel_unreachable]="无法连接面板"
ZH[continue_anyway]="仍要继续吗? (y/N): "
ZH[api_key]="API Key (令牌): "
ZH[api_key_short]="API Key 至少需要 8 个字符"
ZH[node_id]="节点 ID (数字): "
ZH[node_id_invalid]="必须为数字"
ZH[v2node_info1]="v2node: 面板全权管理节点配置 (协议, Reality, 证书, 端口)"
ZH[v2node_info2]="→ 请确保已在面板管理后台创建并配置好节点"
ZH[node_type]="节点类型:"
ZH[type_trojan_tls]="(必须 TLS)"
ZH[type_no_tls]="(无需 TLS)"
ZH[type_hy2]="(必须 TLS, 仅限 V2bX/v2node)"
ZH[xrayr_no_hy2]="XrayR 不支持 Hysteria2"
ZH[vless_subtype]="VLESS 类型?"
ZH[vless_reality]="(无需域名/证书, 面板下发密钥)"
ZH[vless_tls]="(需要域名 + 证书)"
ZH[vmess_subtype]="Vmess 传输方式?"
ZH[vmess_ws]="(需要域名 + 证书, 支持 CDN)"
ZH[vmess_raw]="(无 TLS - 不推荐)"
ZH[ws_path]="WebSocket 路径 [/vmess]: "
ZH[ws_invalid]="错误"
ZH[domain_prompt]="域名 (例: node.vpnnga.com): "
ZH[domain_required]="必须填写域名"
ZH[cert_method]="证书申请方式:"
ZH[cert_http]="HTTP 验证       - 需要 80 端口空闲 + 域名 A 记录指向服务器 IP"
ZH[cert_dns]="DNS 验证        - 需要 DNS 服务商 API key (更灵活)"
ZH[cert_file]="文件            - 已有证书"
ZH[email_le_default]="LE 邮箱 [admin@vpnnga.com]: "
ZH[email_le]="LE 邮箱: "
ZH[email_required]="必须填写邮箱"
ZH[provider_choice]="  1) Cloudflare   2) Aliyun   3) GoDaddy   4) 其他"
ZH[provider_prompt]="服务商 [1-4]: "
ZH[cf_email]="  CF 邮箱: "
ZH[cf_key]="  CF Global API Key: "
ZH[al_id]="  AccessKey ID: "
ZH[al_secret]="  AccessKey Secret: "
ZH[gd_key]="  GoDaddy API Key: "
ZH[gd_secret]="  GoDaddy API Secret: "
ZH[provider_name]="  服务商名: "
ZH[env_name1]="  环境变量 1 名: "
ZH[env_val1]="  环境变量 1 值: "
ZH[env_name2]="  环境变量 2 名 (回车跳过): "
ZH[env_val2]="  环境变量 2 值: "
ZH[place_cert_at]="请将证书放至"
ZH[install_failed]="安装失败"
ZH[download_failed]="下载失败"
ZH[install_done]="已安装"
ZH[start_service]="启动"
ZH[service_running]="运行中"
ZH[service_failed]="启动失败. 诊断中..."
ZH[bbr_install]="安装 BBR + 网络优化..."
ZH[manager_install]="安装 XNode Manager (命令: xnode)..."
ZH[manager_ok]="已安装命令: xnode"
ZH[manager_skip]="无法下载 xnode.sh — 跳过管理菜单"
ZH[install_complete]="安装完成"
ZH[summary_core]="内核:"
ZH[summary_config]="配置:"
ZH[summary_ip]="服务器 IP:"
ZH[summary_panel]="面板:"
ZH[summary_node_id]="节点 ID:"
ZH[summary_node_type]="节点类型:"
ZH[summary_domain]="域名:"
ZH[quick_mgmt]="💡 快速管理:"
ZH[mgmt_menu]="# 打开漂亮的管理菜单"
ZH[mgmt_start]="# 启动服务"
ZH[mgmt_restart]="# 重启"
ZH[mgmt_log]="# 实时日志"
ZH[mgmt_backup]="# 备份配置"
ZH[mgmt_help]="# 查看所有命令"
ZH[orig_cmd]="原作者命令 (如需要):"
ZH[err_port_busy]="错误: 端口被占用"
ZH[err_port_busy_proc]="占用端口的进程:"
ZH[err_port_busy_hint]="→ 停止该进程, 或在面板更换端口"
ZH[err_api]="错误: API Key 错误"
ZH[err_api_hint]="→ 检查面板后台的令牌"
ZH[err_node_notfound]="错误: 节点 ID 不存在"
ZH[err_node_hint]="→ 进入面板后台 → 节点管理 → 检查 ID"
ZH[err_cert]="错误: 证书问题"
ZH[err_cert_hint1]="→ 检查域名是否指向服务器 IP:"
ZH[err_cert_hint2]="→ 检查 80 端口(HTTP) 或 DNS 服务商 API key"
ZH[err_conn]="错误: 无法连接面板"
ZH[err_conn_hint1]="→ 测试:"
ZH[err_conn_hint2]="→ 主机商/VPS 防火墙可能阻止出站"
ZH[err_json]="错误: 配置语法错误"
ZH[err_json_hint]="→ 查看"
ZH[err_unknown]="未知错误. 完整日志:"
ZH[note_reality_xrayr]="→ 将上方的 publicKey 复制到面板"

# ===== OS detection =====
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID; OS_VER=${VERSION_ID%%.*}
else
    err "Cannot detect OS"; exit 1
fi
info "OS:    $PRETTY_NAME"
info "Arch:  $(uname -m)"

# =====================================================================
#  STEP 1: AUTO-FIX
# =====================================================================
echo ""; echo -e "${W}$(t step1_title)${N}"

step "$(t time_sync)"
if command -v timedatectl &>/dev/null; then
    if ! timedatectl 2>/dev/null | grep -q "synchronized: yes"; then
        timedatectl set-ntp true 2>/dev/null
        systemctl restart systemd-timesyncd 2>/dev/null
        sleep 2
    fi
fi
ok "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"

step "$(t locale_check)"
if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
    apt-get install -y -qq locales &>/dev/null
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen 2>/dev/null
    locale-gen en_US.UTF-8 &>/dev/null
fi
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ok "$(t locale_ok)"

step "$(t dns_check)"
if ! getent hosts github.com &>/dev/null; then
    warn "$(t dns_fix)"
    if [[ -f /etc/systemd/resolved.conf ]]; then
        sed -i 's/^#\?DNS=.*/DNS=1.1.1.1 1.0.0.1/' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved 2>/dev/null
    else
        chattr -i /etc/resolv.conf 2>/dev/null
        echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
    fi
fi
ok "$(t dns_ok)"

step "$(t deps_install)"
case $OS in
    debian|ubuntu)
        apt-get update -qq 2>/dev/null
        apt-get install -y -qq curl wget unzip tar socat ca-certificates jq cron &>/dev/null
        update-ca-certificates &>/dev/null ;;
    centos|rhel|almalinux|rocky)
        yum install -y -q curl wget unzip tar socat ca-certificates jq cronie &>/dev/null ;;
esac
ok "$(t deps_ok)"

mem_mb=$(free -m | awk '/^Mem:/{print $2}')
swap_mb=$(free -m | awk '/^Swap:/{print $2}')
info "RAM: ${mem_mb}MB | Swap: ${swap_mb}MB"
if [[ $mem_mb -lt 768 && $swap_mb -lt 512 && ! -f /swapfile ]]; then
    warn "$(t swap_low)"
    fallocate -l 1G /swapfile && chmod 600 /swapfile \
        && mkswap /swapfile &>/dev/null && swapon /swapfile \
        && echo '/swapfile none swap sw 0 0' >> /etc/fstab
    ok "$(t swap_ok)"
fi

# =====================================================================
#  STEP 2: CHOOSE CORE
# =====================================================================
echo ""; echo -e "${W}$(t step2_title)${N}"
echo ""
echo -e "$(t choose_core)"
echo ""
read -rp "$(t prompt_core)" core_choice

case $core_choice in
    1) CORE="v2bx";   SVC="V2bX";   CFG_DIR="/etc/V2bX" ;;
    2) CORE="v2node"; SVC="v2node"; CFG_DIR="/etc/v2node" ;;
    3) CORE="xrayr";  SVC="XrayR";  CFG_DIR="/etc/XrayR" ;;
    *) err "$(t invalid_choice)"; exit 1 ;;
esac
ok "$(t core_set): $CORE → $CFG_DIR"

# =====================================================================
#  STEP 3: PANEL & NODE INFO
# =====================================================================
echo ""; echo -e "${W}$(t step3_title)${N}"

while true; do
    read -rp "$(t panel_url)" PANEL_URL
    PANEL_URL=${PANEL_URL:-https://vpnnga.com}
    [[ "$PANEL_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]] && break
    err "$(t invalid_url)"
done

step "$(t panel_check)"
if curl -fsS --max-time 8 -o /dev/null -w "%{http_code}" "$PANEL_URL" | grep -qE "^(200|301|302|403)$"; then
    ok "$(t panel_ok)"
else
    warn "$(t panel_unreachable)"
    read -rp "$(t continue_anyway)" ans
    [[ ! "$ans" =~ ^[Yy]$ ]] && exit 1
fi

while true; do
    read -rp "$(t api_key)" PANEL_KEY
    [[ ${#PANEL_KEY} -ge 8 ]] && break
    err "$(t api_key_short)"
done

while true; do
    read -rp "$(t node_id)" NODE_ID
    [[ "$NODE_ID" =~ ^[0-9]+$ ]] && break
    err "$(t node_id_invalid)"
done

# v2node: panel manages everything
if [[ "$CORE" == "v2node" ]]; then
    info "$(t v2node_info1)"
    info "$(t v2node_info2)"
    NODE_TYPE="auto"; VARIANT="auto"; NEED_CERT=0
else
    echo ""
    info "$(t node_type)"
    echo "  1) VLESS"
    echo "  2) Vmess"
    echo -e "  3) Trojan         ${B}$(t type_trojan_tls)${N}"
    echo -e "  4) Shadowsocks    ${B}$(t type_no_tls)${N}"
    echo -e "  5) Hysteria2      ${B}$(t type_hy2)${N}"
    read -rp "$(t prompt_core | sed 's/1-3/1-5/')" proto

    case $proto in
        1) NODE_TYPE="vless" ;;
        2) NODE_TYPE="vmess" ;;
        3) NODE_TYPE="trojan" ;;
        4) NODE_TYPE="shadowsocks" ;;
        5) NODE_TYPE="hysteria2"
           [[ "$CORE" == "xrayr" ]] && { err "$(t xrayr_no_hy2)"; exit 1; } ;;
        *) err "$(t invalid_choice)"; exit 1 ;;
    esac

    NEED_CERT=0
    VARIANT="$NODE_TYPE"

    case $NODE_TYPE in
        trojan|hysteria2) NEED_CERT=1; VARIANT="$NODE_TYPE" ;;
        shadowsocks)      NEED_CERT=0; VARIANT="ss" ;;
        vless)
            echo ""
            info "$(t vless_subtype)"
            echo -e "  1) Reality        ${B}$(t vless_reality)${N}"
            echo -e "  2) TLS (Vision)   ${B}$(t vless_tls)${N}"
            read -rp "$(t prompt_core | sed 's/1-3/1-2/')" vsub
            case $vsub in
                1) VARIANT="reality"; NEED_CERT=0 ;;
                2) VARIANT="vision_tls"; NEED_CERT=1 ;;
                *) err "$(t ws_invalid)"; exit 1 ;;
            esac
            ;;
        vmess)
            echo ""
            info "$(t vmess_subtype)"
            echo -e "  1) WebSocket + TLS ${B}$(t vmess_ws)${N}"
            echo -e "  2) TCP raw          ${B}$(t vmess_raw)${N}"
            read -rp "$(t prompt_core | sed 's/1-3/1-2/')" vmsub
            case $vmsub in
                1) VARIANT="ws_tls"; NEED_CERT=1
                   read -rp "$(t ws_path)" WS_PATH
                   WS_PATH=${WS_PATH:-/vmess} ;;
                2) VARIANT="raw"; NEED_CERT=0 ;;
                *) err "$(t ws_invalid)"; exit 1 ;;
            esac
            ;;
    esac

    if [[ $NEED_CERT -eq 1 ]]; then
        read -rp "$(t domain_prompt)" DOMAIN
        [[ -z "$DOMAIN" ]] && { err "$(t domain_required)"; exit 1; }

        echo ""
        info "$(t cert_method)"
        echo "  1) $(t cert_http)"
        echo "  2) $(t cert_dns)"
        echo "  3) $(t cert_file)"
        read -rp "$(t prompt_core | sed 's/1-3/1-3/')" cm

        case $cm in
            1)
                CERT_MODE="http"
                read -rp "$(t email_le_default)" CERT_EMAIL
                CERT_EMAIL=${CERT_EMAIL:-admin@vpnnga.com}
                ;;
            2)
                CERT_MODE="dns"
                read -rp "$(t email_le)" CERT_EMAIL
                [[ -z "$CERT_EMAIL" ]] && { err "$(t email_required)"; exit 1; }
                echo "$(t provider_choice)"
                read -rp "$(t provider_prompt)" dp
                case $dp in
                    1) DNS_PROVIDER="cloudflare"
                       read -rp "$(t cf_email)" V1; read -rp "$(t cf_key)" V2
                       K1="CLOUDFLARE_EMAIL"; K2="CLOUDFLARE_API_KEY" ;;
                    2) DNS_PROVIDER="aliyun"
                       read -rp "$(t al_id)" V1; read -rp "$(t al_secret)" V2
                       K1="ALICLOUD_ACCESS_KEY"; K2="ALICLOUD_SECRET_KEY" ;;
                    3) DNS_PROVIDER="gandi"
                       read -rp "$(t gd_key)" V1; read -rp "$(t gd_secret)" V2
                       K1="GODADDY_API_KEY"; K2="GODADDY_API_SECRET" ;;
                    4) read -rp "$(t provider_name)" DNS_PROVIDER
                       read -rp "$(t env_name1)" K1; read -rp "$(t env_val1)" V1
                       read -rp "$(t env_name2)" K2
                       [[ -n "$K2" ]] && read -rp "$(t env_val2)" V2 ;;
                    *) err "$(t ws_invalid)"; exit 1 ;;
                esac
                ;;
            3) CERT_MODE="file"; mkdir -p "$CFG_DIR/cert"
               warn "$(t place_cert_at) $CFG_DIR/cert/${DOMAIN}.crt + .key" ;;
            *) err "$(t ws_invalid)"; exit 1 ;;
        esac
    fi
fi

# =====================================================================
#  STEP 4: INSTALL CORE
# =====================================================================
echo ""; echo -e "${W}$(t step4_title): $CORE${N}"

case $CORE in
    v2bx)
        step "Downloading V2bX install script..."
        wget -qO /tmp/v2bx-install.sh https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh \
            || { err "$(t download_failed)"; exit 1; }
        echo "n" | bash /tmp/v2bx-install.sh
        rm -f /tmp/v2bx-install.sh
        ;;
    v2node)
        step "Downloading v2node install script..."
        wget -qO /tmp/v2node-install.sh https://raw.githubusercontent.com/wyx2685/v2node/master/script/install.sh \
            || { err "$(t download_failed)"; exit 1; }
        # Upstream installer is interactive (no CLI flags) - feed "n" to skip
        # config wizard; we write /etc/v2node/config.json ourselves below.
        echo "n" | bash /tmp/v2node-install.sh
        rm -f /tmp/v2node-install.sh
        ;;
    xrayr)
        step "Installing XrayR..."
        bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh) \
            || { err "$(t install_failed)"; exit 1; }
        ;;
esac

[[ ! -d "$CFG_DIR" ]] && { err "$(t install_failed) - missing $CFG_DIR"; exit 1; }
ok "$CORE $(t install_done)"
mkdir -p "$CFG_DIR"

# =====================================================================
#  Write config V2bX/v2node
# =====================================================================
write_config_v2bx_style() {
    local cert_block
    case $VARIANT in
        reality)
            cert_block='"CertConfig": { "CertMode": "reality" }'
            ;;
        ss|raw)
            cert_block=""
            ;;
        vision_tls|trojan|ws_tls|hysteria2)
            case $CERT_MODE in
                http)
                    cert_block=$(cat <<EOF
"CertConfig": {
                "CertMode": "http",
                "CertDomain": "$DOMAIN",
                "CertFile": "$CFG_DIR/cert/${DOMAIN}.crt",
                "KeyFile": "$CFG_DIR/cert/${DOMAIN}.key",
                "Email": "$CERT_EMAIL",
                "Provider": "letsencrypt"
            }
EOF
)
                    ;;
                dns)
                    local dns_env_lines="                    \"$K1\": \"$V1\""
                    [[ -n "$K2" ]] && dns_env_lines+=$',\n                    "'"$K2"'": "'"$V2"'"'
                    cert_block=$(cat <<EOF
"CertConfig": {
                "CertMode": "dns",
                "CertDomain": "$DOMAIN",
                "CertFile": "$CFG_DIR/cert/${DOMAIN}.crt",
                "KeyFile": "$CFG_DIR/cert/${DOMAIN}.key",
                "Email": "$CERT_EMAIL",
                "Provider": "$DNS_PROVIDER",
                "DNSEnv": {
$dns_env_lines
                }
            }
EOF
)
                    ;;
                file)
                    cert_block=$(cat <<EOF
"CertConfig": {
                "CertMode": "file",
                "CertDomain": "$DOMAIN",
                "CertFile": "$CFG_DIR/cert/${DOMAIN}.crt",
                "KeyFile": "$CFG_DIR/cert/${DOMAIN}.key"
            }
EOF
)
                    ;;
            esac
            ;;
    esac

    local core_type="xray"
    [[ "$VARIANT" == "hysteria2" ]] && core_type="hysteria2"

    [[ -f "$CFG_DIR/config.json" ]] && cp "$CFG_DIR/config.json" "$CFG_DIR/config.json.bak.$(date +%s)"

    local node_block
    if [[ -z "$cert_block" ]]; then
        node_block=$(cat <<EOF
{
            "Core": "$core_type",
            "ApiHost": "$PANEL_URL",
            "ApiKey": "$PANEL_KEY",
            "NodeID": $NODE_ID,
            "NodeType": "$NODE_TYPE",
            "Timeout": 30,
            "ListenIP": "::",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "TCPFastOpen": true,
            "SniffEnabled": false,
            "EnableProxyProtocol": false
        }
EOF
)
    else
        node_block=$(cat <<EOF
{
            "Core": "$core_type",
            "ApiHost": "$PANEL_URL",
            "ApiKey": "$PANEL_KEY",
            "NodeID": $NODE_ID,
            "NodeType": "$NODE_TYPE",
            "Timeout": 30,
            "ListenIP": "::",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "TCPFastOpen": true,
            "SniffEnabled": false,
            "EnableProxyProtocol": false,
            $cert_block
        }
EOF
)
    fi

    local cores_section
    if [[ "$VARIANT" == "hysteria2" ]]; then
        cores_section=$(cat <<EOF
[
        {
            "Type": "xray",
            "Log": { "Level": "none", "ErrorPath": "/dev/null", "AccessPath": "/dev/null" },
            "OutboundConfigPath": "$CFG_DIR/custom_outbound.json",
            "RouteConfigPath": "$CFG_DIR/route.json"
        },
        {
            "Type": "hysteria2",
            "Log": { "Level": "warn" }
        }
    ]
EOF
)
    else
        cores_section=$(cat <<EOF
[
        {
            "Type": "xray",
            "Log": { "Level": "none", "ErrorPath": "/dev/null", "AccessPath": "/dev/null" },
            "OutboundConfigPath": "$CFG_DIR/custom_outbound.json",
            "RouteConfigPath": "$CFG_DIR/route.json"
        }
    ]
EOF
)
    fi

    cat > "$CFG_DIR/config.json" <<EOF
{
    "Log": {
        "Level": "none",
        "Output": ""
    },
    "Cores": $cores_section,
    "Nodes": [
        $node_block
    ]
}
EOF

    cat > "$CFG_DIR/custom_outbound.json" <<'EOF'
[
    {
        "tag": "IPv4_out",
        "protocol": "freedom",
        "settings": { "domainStrategy": "UseIPv4" }
    },
    {
        "tag": "IPv6_out",
        "protocol": "freedom",
        "settings": { "domainStrategy": "UseIPv6" }
    },
    {
        "tag": "block",
        "protocol": "blackhole"
    }
]
EOF

    cat > "$CFG_DIR/route.json" <<'EOF'
{
    "domainStrategy": "AsIs",
    "rules": [
        { "type": "field", "outboundTag": "block", "ip": ["geoip:private"] },
        { "type": "field", "outboundTag": "block", "protocol": ["bittorrent"] },
        { "type": "field", "outboundTag": "IPv4_out", "network": "tcp,udp" }
    ]
}
EOF

    cat > "$CFG_DIR/dns.json" <<'EOF'
{
    "servers": ["1.1.1.1", "8.8.8.8", "localhost"]
}
EOF

    ok "Config: $CFG_DIR/config.json"

    if ! jq empty "$CFG_DIR/config.json" 2>/dev/null; then
        err "$(t err_json)"
        return 1
    fi
    ok "JSON valid"
}

# =====================================================================
#  Write config XrayR
# =====================================================================
write_config_xrayr() {
    local cfg="$CFG_DIR/config.yml"
    [[ -f "$cfg" ]] && cp "$cfg" "${cfg}.bak.$(date +%s)"
    mkdir -p "$CFG_DIR/cert"

    local xrayr_node_type
    case $NODE_TYPE in
        vless|vmess) xrayr_node_type="V2ray" ;;
        trojan)      xrayr_node_type="Trojan" ;;
        shadowsocks) xrayr_node_type="Shadowsocks" ;;
    esac

    cat > "$cfg" <<EOF
Log:
  Level: warning
  AccessPath: $CFG_DIR/access.log
  ErrorPath: $CFG_DIR/error.log

DnsConfigPath: $CFG_DIR/dns.json
RouteConfigPath: $CFG_DIR/route.json

ConnectionConfig:
  Handshake: 8
  ConnIdle: 30
  UplinkOnly: 2
  DownlinkOnly: 4
  BufferSize: 0
  DisableIPv6: true

Nodes:
  - PanelType: "NewV2board"
    ApiConfig:
      ApiHost: "$PANEL_URL"
      ApiKey: "$PANEL_KEY"
      NodeID: $NODE_ID
      NodeType: $xrayr_node_type
      Timeout: 30
      SpeedLimit: 0
      DeviceLimit: 0
      DisableCustomConfig: false
EOF

    if [[ "$NODE_TYPE" == "vless" ]]; then
        # Reality + Vision-TLS yêu cầu flow xtls-rprx-vision; raw VLESS-TLS để rỗng
        local xrayr_flow=""
        [[ "$VARIANT" == "reality" || "$VARIANT" == "vision_tls" ]] && xrayr_flow="xtls-rprx-vision"
        cat >> "$cfg" <<EOF
      EnableVless: true
      VlessFlow: "$xrayr_flow"
EOF
    fi

    cat >> "$cfg" <<EOF

    ControllerConfig:
      ListenIP: 0.0.0.0
      SendIP: 0.0.0.0
      UpdatePeriodic: 60
      EnableDNS: false
      DNSType: UseIPv4
      EnableProxyProtocol: false
      EnableFallback: false
EOF

    if [[ "$VARIANT" == "reality" ]]; then
        warn "XrayR needs Reality keys at node — generating now..."
        local arch=$(uname -m)
        case $arch in
            x86_64) arch="64" ;;
            aarch64) arch="arm64-v8a" ;;
        esac
        wget -qO /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${arch}.zip"
        unzip -qq -o /tmp/xray.zip -d /tmp/xray-bin
        local kp=$(/tmp/xray-bin/xray x25519)
        local priv=$(echo "$kp" | grep -i "private" | awk '{print $NF}')
        local pub=$(echo "$kp" | grep -i "public" | awk '{print $NF}')
        rm -rf /tmp/xray.zip /tmp/xray-bin

        read -rp "Reality SNI [www.microsoft.com]: " SNI; SNI=${SNI:-www.microsoft.com}
        read -rp "Reality dest port [443]: " DPORT; DPORT=${DPORT:-443}

        info "Reality publicKey: ${G}$pub${N}"

        cat >> "$cfg" <<EOF
      EnableREALITY: true
      REALITYConfigs:
        Show: false
        Dest: "${SNI}:${DPORT}"
        Xver: 0
        ServerNames:
          - "$SNI"
        PrivateKey: "$priv"
        ShortIds:
          - ""
          - "$(head -c 4 /dev/urandom | xxd -p)"
EOF
    elif [[ $NEED_CERT -eq 1 ]]; then
        cat >> "$cfg" <<EOF
      CertConfig:
        CertMode: $CERT_MODE
        CertDomain: "$DOMAIN"
EOF
        if [[ "$CERT_MODE" == "http" || "$CERT_MODE" == "dns" ]]; then
            local prov="letsencrypt"
            [[ "$CERT_MODE" == "dns" ]] && prov="$DNS_PROVIDER"
            cat >> "$cfg" <<EOF
        Provider: $prov
        Email: $CERT_EMAIL
EOF
        fi
        if [[ "$CERT_MODE" == "dns" ]]; then
            cat >> "$cfg" <<EOF
        DNSEnv:
          $K1: "$V1"
EOF
            if [[ -n "$K2" ]]; then
                cat >> "$cfg" <<EOF
          $K2: "$V2"
EOF
            fi
        fi
    fi

    cat > "$CFG_DIR/dns.json" <<'EOF'
{ "servers": ["1.1.1.1", "8.8.8.8"] }
EOF
    cat > "$CFG_DIR/route.json" <<'EOF'
{
  "domainStrategy": "AsIs",
  "rules": [
    { "type": "field",
      "ip": ["0.0.0.0/8","10.0.0.0/8","100.64.0.0/10","127.0.0.0/8",
             "169.254.0.0/16","172.16.0.0/12","192.168.0.0/16",
             "::1/128","fc00::/7","fe80::/10"],
      "outboundTag": "blocked" },
    { "type": "field", "protocol": ["bittorrent"], "outboundTag": "blocked" }
  ]
}
EOF

    rm -rf "$CFG_DIR/cert"/*
    ok "Config: $cfg"
}

# =====================================================================
#  Write config v2node (xray-only, panel-managed, Reality default)
# =====================================================================
write_config_v2node() {
    local cfg="$CFG_DIR/config.json"
    [[ -f "$cfg" ]] && cp "$cfg" "${cfg}.bak.$(date +%s)"

    cat > "$cfg" <<EOF
{
    "Log": {
        "Level": "none",
        "Output": ""
    },
    "Cores": [
        {
            "Type": "xray",
            "Log": { "Level": "none", "ErrorPath": "/dev/null", "AccessPath": "/dev/null" },
            "OutboundConfigPath": "$CFG_DIR/custom_outbound.json",
            "RouteConfigPath": "$CFG_DIR/route.json"
        }
    ],
    "Nodes": [
        {
            "Core": "xray",
            "ApiHost": "$PANEL_URL",
            "ApiKey": "$PANEL_KEY",
            "NodeID": $NODE_ID,
            "NodeType": "vless",
            "Timeout": 30,
            "ListenIP": "::",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "TCPFastOpen": true,
            "SniffEnabled": false,
            "EnableProxyProtocol": false,
            "CertConfig": { "CertMode": "reality" }
        }
    ]
}
EOF

    cat > "$CFG_DIR/custom_outbound.json" <<'EOF'
[
    {
        "tag": "IPv4_out",
        "protocol": "freedom",
        "settings": { "domainStrategy": "UseIPv4" }
    },
    {
        "tag": "IPv6_out",
        "protocol": "freedom",
        "settings": { "domainStrategy": "UseIPv6" }
    },
    {
        "tag": "block",
        "protocol": "blackhole"
    }
]
EOF

    cat > "$CFG_DIR/route.json" <<'EOF'
{
    "domainStrategy": "AsIs",
    "rules": [
        { "type": "field", "outboundTag": "block", "ip": ["geoip:private"] },
        { "type": "field", "outboundTag": "block", "protocol": ["bittorrent"] },
        { "type": "field", "outboundTag": "IPv4_out", "network": "tcp,udp" }
    ]
}
EOF

    cat > "$CFG_DIR/dns.json" <<'EOF'
{
    "servers": ["1.1.1.1", "8.8.8.8", "localhost"]
}
EOF

    ok "Config: $cfg"
    info "Default: NodeType=vless + Reality (panel push key). Đổi protocol bằng: xnode edit"

    if ! jq empty "$cfg" 2>/dev/null; then
        err "$(t err_json)"
        return 1
    fi
    ok "JSON valid"
}

case $CORE in
    v2bx)        write_config_v2bx_style ;;
    v2node)      write_config_v2node ;;
    xrayr)       write_config_xrayr ;;
esac

# =====================================================================
#  START SERVICE + AUTO DIAGNOSE
# =====================================================================
echo ""
step "$(t start_service) $SVC..."
systemctl daemon-reload
systemctl enable "$SVC" &>/dev/null
systemctl restart "$SVC"
sleep 4

if systemctl is-active --quiet "$SVC"; then
    ok "$SVC $(t service_running)"
else
    err "$SVC $(t service_failed)"
    echo ""
    journalctl -u "$SVC" -n 30 --no-pager
    echo ""

    LOG=$(journalctl -u "$SVC" -n 50 --no-pager 2>/dev/null)

    if echo "$LOG" | grep -qi "address already in use"; then
        err "$(t err_port_busy)"
        warn "$(t err_port_busy_proc)"
        ss -tlnp 2>/dev/null | grep -E ":(443|80|8080|8388) "
        warn "$(t err_port_busy_hint)"
    elif echo "$LOG" | grep -qiE "401|403|unauthorized|invalid.*key|invalid.*token"; then
        err "$(t err_api)"
        warn "$(t err_api_hint)"
    elif echo "$LOG" | grep -qi "node.*not.*found\|invalid node"; then
        err "$(t err_node_notfound) ($NODE_ID)"
        warn "$(t err_node_hint)"
    elif echo "$LOG" | grep -qi "certificate\|cert\|tls handshake"; then
        err "$(t err_cert)"
        warn "$(t err_cert_hint1) $(curl -s4 ifconfig.me)"
        warn "$(t err_cert_hint2)"
    elif echo "$LOG" | grep -qiE "connection refused|timeout|dial.*tcp"; then
        err "$(t err_conn)"
        warn "$(t err_conn_hint1) curl -v $PANEL_URL"
        warn "$(t err_conn_hint2)"
    elif echo "$LOG" | grep -qi "json.*syntax\|unmarshal\|yaml"; then
        err "$(t err_json)"
        warn "$(t err_json_hint) $CFG_DIR/config.*"
    else
        warn "$(t err_unknown) journalctl -u $SVC -n 100"
    fi
    exit 1
fi

# =====================================================================
#  BBR (using kinako script)
# =====================================================================
echo ""
step "$(t bbr_install)"
bash <(curl -L -s https://sh.kinako.one/inits.sh) || warn "BBR install skipped"

# =====================================================================
#  INSTALL VPNNGA MANAGER
# =====================================================================
step "$(t manager_install)"
if wget -qO /usr/local/bin/xnode \
    https://raw.githubusercontent.com/huzgnm/xnode/main/xnode.sh; then
    chmod +x /usr/local/bin/xnode
    ok "$(t manager_ok)"
else
    warn "$(t manager_skip)"
fi

# =====================================================================
#  SUMMARY
# =====================================================================
SERVER_IP=$(curl -s4 --max-time 5 ifconfig.me 2>/dev/null || echo "unknown")
echo ""
echo -e "${G}╔═══════════════════════════════════════════╗${N}"
echo -e "${G}║         $(t install_complete)         ║${N}"
echo -e "${G}╚═══════════════════════════════════════════╝${N}"
echo ""
echo -e "  $(t summary_core)        ${W}$CORE${N} ($(systemctl is-active "$SVC"))"
echo -e "  $(t summary_config)      ${W}$CFG_DIR${N}"
echo -e "  $(t summary_ip)   ${W}$SERVER_IP${N}"
echo -e "  $(t summary_panel)       ${W}$PANEL_URL${N}"
echo -e "  $(t summary_node_id)     ${W}$NODE_ID${N}"
echo -e "  $(t summary_node_type)   ${W}$NODE_TYPE / $VARIANT${N}"
[[ -n "$DOMAIN" ]] && echo -e "  $(t summary_domain)      ${W}$DOMAIN${N}"
echo ""
echo -e "${W}  $(t quick_mgmt)${N}"
echo -e "    ${G}xnode${N}            ${D}$(t mgmt_menu)${N}"
echo -e "    ${G}xnode start${N}      ${D}$(t mgmt_start)${N}"
echo -e "    ${G}xnode restart${N}    ${D}$(t mgmt_restart)${N}"
echo -e "    ${G}xnode log${N}        ${D}$(t mgmt_log)${N}"
echo -e "    ${G}xnode backup${N}     ${D}$(t mgmt_backup)${N}"
echo -e "    ${G}xnode help${N}       ${D}$(t mgmt_help)${N}"
echo ""
echo -e "  $(t orig_cmd)"
case $CORE in
    v2bx)   echo -e "    ${B}V2bX${N} {start|stop|restart|status|log|x25519|update}" ;;
    v2node) echo -e "    ${B}v2node${N} {start|stop|restart|status|log|update}" ;;
    xrayr)  echo -e "    ${B}xrayr${N} {start|stop|restart|status|log}" ;;
esac
echo ""
[[ "$VARIANT" == "reality" && "$CORE" == "xrayr" ]] && warn "$(t note_reality_xrayr)"
echo ""
