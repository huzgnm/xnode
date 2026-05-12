#!/bin/bash
#
# XNode Manager - Menu quản lý node sau khi cài
# Lệnh: xnode
#

# ===== Màu sắc =====
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[0;36m'
W='\033[1m'; D='\033[2m'; N='\033[0m'

ok()   { echo -e "${G}[✓]${N} $1"; }
err()  { echo -e "${R}[✗]${N} $1"; }
warn() { echo -e "${Y}[!]${N} $1"; }
info() { echo -e "${B}[i]${N} $1"; }
step() { echo -e "${W}▸${N} $1"; }

# ===== Check root =====
[[ $EUID -ne 0 ]] && { err "Cần root: sudo xnode"; exit 1; }

VERSION="1.0.0"
LOCK_FILE="/etc/xnode/installed.lock"
BACKUP_DIR="/root/xnode-backups"
INSTALLER_URL="https://raw.githubusercontent.com/huzgnm/xnode/main/install.sh"

# ===== Phát hiện core đã cài =====
detect_core() {
    if [[ -f /usr/local/V2bX/V2bX ]]; then
        echo "v2bx"
    elif [[ -f /usr/local/v2node/v2node ]]; then
        echo "v2node"
    elif [[ -f /usr/local/XrayR/XrayR ]]; then
        echo "xrayr"
    else
        echo "none"
    fi
}

# ===== Lấy tên service systemd =====
get_service() {
    case $1 in
        v2bx)   echo "V2bX" ;;
        v2node) echo "v2node" ;;
        xrayr)  echo "XrayR" ;;
    esac
}

# ===== Lấy đường dẫn config =====
get_config() {
    case $1 in
        v2bx)   echo "/etc/V2bX/config.json" ;;
        v2node) echo "/etc/v2node/config.json" ;;
        xrayr)  echo "/etc/XrayR/config.yml" ;;
    esac
}

get_config_dir() {
    case $1 in
        v2bx)   echo "/etc/V2bX" ;;
        v2node) echo "/etc/v2node" ;;
        xrayr)  echo "/etc/XrayR" ;;
    esac
}

# ===== Trạng thái service (text với màu) =====
status_str() {
    local svc=$1
    [[ -z "$svc" ]] && { echo -e "${D}N/A${N}"; return; }
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "${G}đang chạy${N}"
    else
        echo -e "${R}đã dừng${N}"
    fi
}

# ===== Banner =====
show_banner() {
    clear
    echo -e "${B}"
    cat <<'EOF'
 ═╗ ╦╔╗╔╔═╗╔╦╗╔═╗  ╔╦╗╔═╗╔╗╔╔═╗╔═╗╔═╗╦═╗
  ╔╩╦╝║║║║ ║ ║║║╣   ║║║╠═╣║║║╠═╣║ ╦║╣ ╠╦╝
 ╩ ╚═╝╝╚╝╚═╝═╩╝╚═╝  ╩ ╩╩ ╩╝╚╝╩ ╩╚═╝╚═╝╩╚═
EOF
    echo -e "${N}"

    local core=$(detect_core)
    if [[ "$core" == "none" ]]; then
        echo -e "  Core:    ${R}Chưa cài${N}"
        echo -e "  Trạng thái: ${R}--${N}"
    else
        local svc=$(get_service "$core")
        echo -e "  Core:    ${W}$core${N}  ($(get_config $core))"
        echo -e "  Trạng thái: $(status_str $svc)"
        # Hiện uptime nếu đang chạy
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            local since=$(systemctl show -p ActiveEnterTimestamp --value "$svc" 2>/dev/null | awk '{print $2, $3}')
            [[ -n "$since" ]] && echo -e "  Khởi động: ${D}$since${N}"
        fi
    fi
    local ip=$(curl -s4 --max-time 3 ifconfig.me 2>/dev/null || echo "...")
    echo -e "  IP server: ${W}$ip${N}"
    echo ""
}

# =====================================================================
#  CÁC HÀNH ĐỘNG
# =====================================================================

action_start() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    step "Đang bật $svc..."
    systemctl start "$svc" && ok "$svc đã chạy" || err "Khởi động thất bại"
}

action_stop() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    step "Đang tắt $svc..."
    systemctl stop "$svc" && ok "$svc đã dừng" || err "Dừng thất bại"
}

action_restart() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    step "Đang restart $svc..."
    systemctl restart "$svc"
    sleep 2
    if systemctl is-active --quiet "$svc"; then
        ok "$svc đã restart"
    else
        err "Restart thất bại — xem log:"
        journalctl -u "$svc" -n 20 --no-pager
    fi
}

action_status() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    systemctl status "$svc" --no-pager -l | head -20
}

action_log() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    info "Log $svc realtime — Ctrl+C để thoát"
    sleep 1
    journalctl -u "$svc" -f --no-pager
}

action_monitor() {
    local svc=$(get_service $(detect_core))
    [[ -z "$svc" ]] && { err "Chưa cài core nào"; return; }
    local pid=$(systemctl show -p MainPID --value "$svc")
    [[ "$pid" == "0" || -z "$pid" ]] && { err "$svc chưa chạy"; return; }
    info "RAM/CPU của $svc (PID $pid) — Ctrl+C để thoát"
    sleep 1
    top -p "$pid"
}

action_add_node() {
    info "Mở installer để thêm node mới..."
    sleep 1
    bash <(curl -Ls "$INSTALLER_URL")
}

action_view_config() {
    local cfg=$(get_config $(detect_core))
    [[ -z "$cfg" || ! -f "$cfg" ]] && { err "Không tìm thấy config"; return; }
    echo -e "${B}=== $cfg ===${N}"
    cat "$cfg"
}

action_edit_config() {
    local cfg=$(get_config $(detect_core))
    [[ -z "$cfg" || ! -f "$cfg" ]] && { err "Không tìm thấy config"; return; }

    # Backup trước khi sửa
    local bak="${cfg}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$cfg" "$bak"
    info "Đã backup: $bak"

    local editor=${EDITOR:-nano}
    command -v nano &>/dev/null || editor=vi
    "$editor" "$cfg"

    # Hỏi restart
    read -rp "Restart service để áp dụng? [Y/n]: " ans
    [[ ! "$ans" =~ ^[Nn]$ ]] && action_restart
}

action_update_core() {
    local core=$(detect_core)
    [[ "$core" == "none" ]] && { err "Chưa cài core nào"; return; }

    case $core in
        v2bx)
            info "Cập nhật V2bX..."
            wget -qO /tmp/upd.sh https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh
            bash /tmp/upd.sh
            rm -f /tmp/upd.sh
            ;;
        v2node)
            info "Cập nhật v2node..."
            wget -qO /tmp/upd.sh https://raw.githubusercontent.com/wyx2685/v2node/master/script/install.sh
            bash /tmp/upd.sh
            rm -f /tmp/upd.sh
            ;;
        xrayr)
            info "Cập nhật XrayR..."
            bash <(curl -Ls https://raw.githubusercontent.com/krililrify/kkk/master/install.sh)
            ;;
    esac
}

action_backup() {
    local core=$(detect_core)
    [[ "$core" == "none" ]] && { err "Chưa cài core nào"; return; }

    mkdir -p "$BACKUP_DIR"
    local stamp=$(date +%Y%m%d_%H%M%S)
    local file="$BACKUP_DIR/xnode-${core}-${stamp}.tar.gz"

    local cfg_dir=$(get_config_dir $core)
    step "Backup $cfg_dir → $file"
    tar czf "$file" "$cfg_dir" 2>/dev/null
    ok "Backup xong: $file ($(du -h "$file" | cut -f1))"
}

action_restore() {
    [[ ! -d "$BACKUP_DIR" ]] && { err "Không có backup tại $BACKUP_DIR"; return; }

    echo -e "${W}Backup có sẵn:${N}"
    local i=1
    local files=()
    for f in "$BACKUP_DIR"/*.tar.gz; do
        [[ -f "$f" ]] || continue
        files+=("$f")
        echo "  $i. $(basename "$f")  ($(du -h "$f" | cut -f1))"
        i=$((i+1))
    done

    [[ ${#files[@]} -eq 0 ]] && { err "Không có file backup"; return; }

    read -rp "Chọn số (Enter để hủy): " idx
    [[ -z "$idx" ]] && return
    [[ ! "$idx" =~ ^[0-9]+$ ]] || [[ $idx -lt 1 ]] || [[ $idx -gt ${#files[@]} ]] && { err "Số không hợp lệ"; return; }

    local chosen=${files[$((idx-1))]}
    read -rp "Khôi phục từ $(basename "$chosen")? Sẽ ghi đè config hiện tại! [y/N]: " ans
    [[ ! "$ans" =~ ^[Yy]$ ]] && { info "Đã hủy"; return; }

    local svc=$(get_service $(detect_core))
    [[ -n "$svc" ]] && systemctl stop "$svc" 2>/dev/null

    tar xzf "$chosen" -C / && ok "Khôi phục xong" || err "Khôi phục thất bại"

    [[ -n "$svc" ]] && systemctl start "$svc"
}

action_bbr() {
    local current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    info "Hiện tại: tcp_congestion_control = ${W}$current${N}"

    if [[ "$current" == "bbr" ]]; then
        warn "BBR đã bật rồi"
        return
    fi

    step "Bật BBR + fq_codel..."
    # Xóa cấu hình cũ nếu có
    sed -i '/^# xnode tuning/,/^# end xnode/d' /etc/sysctl.conf

    cat >> /etc/sysctl.conf <<'EOF'

# xnode tuning
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
# end xnode
EOF
    sysctl -p &>/dev/null
    local new=$(sysctl -n net.ipv4.tcp_congestion_control)
    [[ "$new" == "bbr" ]] && ok "BBR đã bật" || err "Bật BBR thất bại (kernel cũ?)"
}

action_check_ports() {
    local svc=$(get_service $(detect_core))
    info "IP server: ${W}$(curl -s4 ifconfig.me)${N}"
    echo ""
    info "Port đang lắng nghe:"
    ss -tlnp 2>/dev/null | grep -E "$svc|V2bX|v2node|XrayR" || warn "Service không lắng nghe port nào"
    echo ""
    info "Tất cả port TCP đang mở:"
    ss -tlnp 2>/dev/null | tail -n +2 | awk '{print "  " $4}' | sort -u
}

action_uninstall() {
    echo -e "${R}${W}⚠️  CẢNH BÁO: Sẽ gỡ TOÀN BỘ V2bX/v2node/XrayR + config${N}"
    echo -e "${R}Hành động này KHÔNG thể hoàn tác (trừ khi có backup)${N}"
    read -rp "Gõ 'YES' để xác nhận: " confirm
    [[ "$confirm" != "YES" ]] && { info "Đã hủy"; return; }

    read -rp "Backup config trước khi xóa? [Y/n]: " do_bk
    [[ ! "$do_bk" =~ ^[Nn]$ ]] && action_backup

    step "Dừng services..."
    systemctl stop V2bX v2node XrayR 2>/dev/null
    systemctl disable V2bX v2node XrayR 2>/dev/null

    step "Xóa V2bX..."
    rm -rf /etc/V2bX /usr/local/V2bX
    rm -f /etc/systemd/system/V2bX.service /usr/bin/V2bX /usr/bin/v2bx /usr/local/bin/V2bX

    step "Xóa v2node..."
    rm -rf /etc/v2node /usr/local/v2node
    rm -f /etc/systemd/system/v2node.service /usr/bin/v2node /usr/local/bin/v2node

    step "Xóa XrayR..."
    rm -rf /etc/XrayR /usr/local/XrayR
    rm -f /etc/systemd/system/XrayR.service /usr/bin/xrayr /usr/bin/XrayR

    systemctl daemon-reload
    ok "Đã gỡ sạch"
    info "Để gỡ luôn lệnh xnode: rm /usr/local/bin/xnode"
}

# =====================================================================
#  CLI MODE — gọi trực tiếp: xnode start | stop | restart | log...
# =====================================================================
if [[ -n "$1" ]]; then
    case $1 in
        start)     action_start ;;
        stop)      action_stop ;;
        restart)   action_restart ;;
        status)    action_status ;;
        log)       action_log ;;
        monitor)   action_monitor ;;
        add)       action_add_node ;;
        config)    action_view_config ;;
        edit)      action_edit_config ;;
        update)    action_update_core ;;
        backup)    action_backup ;;
        restore)   action_restore ;;
        bbr)       action_bbr ;;
        ports)     action_check_ports ;;
        uninstall) action_uninstall ;;
        version|-v|--version) echo "xnode v$VERSION" ;;
        help|-h|--help)
            cat <<EOF
XNode Manager v$VERSION

Cách dùng:
  xnode                    # mở menu
  xnode start | stop       # bật/tắt service
  xnode restart | status   # restart hoặc xem trạng thái
  xnode log                # xem log realtime
  xnode monitor            # theo dõi RAM/CPU
  xnode add                # thêm node mới
  xnode config             # xem config
  xnode edit               # sửa config (nano/vi)
  xnode update             # cập nhật core
  xnode backup             # backup config
  xnode restore            # khôi phục backup
  xnode bbr                # bật BBR
  xnode ports              # xem port đang mở
  xnode uninstall          # gỡ toàn bộ
  xnode version            # xem version
EOF
            ;;
        *) err "Lệnh không biết: $1 (chạy 'xnode help' để xem)"; exit 1 ;;
    esac
    exit $?
fi

# =====================================================================
#  MENU INTERACTIVE
# =====================================================================
while true; do
    show_banner

    printf '%b\n' "${W}🚀 QUẢN LÝ SERVER${N}"
    echo "   1. Bật"
    echo "   2. Tắt"
    echo "   3. Khởi động lại"
    echo "   4. Xem trạng thái"
    echo "   5. Xem log realtime"
    echo "   6. Theo dõi RAM/CPU"
    echo ""
    printf '%b\n' "${W}⚙️  CẤU HÌNH NODE${N}"
    echo "   7. Thêm node mới"
    echo "   8. Xem config hiện tại"
    echo "   9. Sửa config (nano)"
    echo ""
    printf '%b\n' "${W}🔧 HỆ THỐNG${N}"
    echo "   10. Cập nhật core"
    printf '%b\n' "   11. ${G}Backup config${N}"
    printf '%b\n' "   12. ${Y}Khôi phục backup${N}"
    echo "   13. ⚡ Bật BBR + tối ưu mạng"
    echo "   14. Xem IP & port đang mở"
    echo ""
    printf '%b\n' "   ${R}99. ⚠️  Gỡ toàn bộ${N}"
    echo "    0. Thoát"
    echo ""
    read -rp "Chọn [0-14, 99]: " c
    echo ""
    case $c in
        1)  action_start ;;
        2)  action_stop ;;
        3)  action_restart ;;
        4)  action_status ;;
        5)  action_log ;;
        6)  action_monitor ;;
        7)  action_add_node ;;
        8)  action_view_config ;;
        9)  action_edit_config ;;
        10) action_update_core ;;
        11) action_backup ;;
        12) action_restore ;;
        13) action_bbr ;;
        14) action_check_ports ;;
        99) action_uninstall ;;
        0)  echo -e "${G}Tạm biệt!${N}"; exit 0 ;;
        *)  err "Lựa chọn không hợp lệ" ;;
    esac
    echo ""
    read -rp "Nhấn Enter để quay lại menu..." _
done
