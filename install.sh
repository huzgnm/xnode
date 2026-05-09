#!/bin/bash
#
# VPNNGA Node Installer
# Cài node V2board (V2bX / v2node / XrayR) - panel-driven config
# Các tham số Reality, Cert đều quản lý ở panel, node chỉ cần khai báo loại
#

set -o pipefail

# ===== Màu sắc =====
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'; B='\033[0;36m'; W='\033[1m'; N='\033[0m'
ok()   { echo -e "${G}[✓]${N} $1"; }
err()  { echo -e "${R}[✗]${N} $1"; }
warn() { echo -e "${Y}[!]${N} $1"; }
info() { echo -e "${B}[i]${N} $1"; }
step() { echo -e "${W}▸${N} $1"; }

# ===== Kiểm tra root =====
[[ $EUID -ne 0 ]] && { err "Phải chạy bằng root: sudo bash $0"; exit 1; }

clear
echo -e "${B}"
cat <<'EOF'
 ╦  ╦╔═╗╔╗╔╔╗╔╔═╗╔═╗  ╔╗╔┌─┐┌┬┐┌─┐
 ╚╗╔╝╠═╝║║║║║║║ ╦╠═╣  ║║║│ │ ││├┤
  ╚╝ ╩  ╝╚╝╝╚╝╚═╝╩ ╩  ╝╚╝└─┘─┴┘└─┘
       Node Installer v2.0
EOF
echo -e "${N}"

# ===== Phát hiện OS =====
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID; OS_VER=${VERSION_ID%%.*}
else
    err "Không xác định được OS"; exit 1
fi
info "OS:    $PRETTY_NAME"
info "Arch:  $(uname -m)"

# =====================================================================
#  PHẦN 1: AUTO-FIX HỆ THỐNG TRƯỚC KHI CÀI
# =====================================================================
echo ""; echo -e "${W}=== Bước 1/4: Kiểm tra & sửa lỗi hệ thống ===${N}"

# Sync time (TLS/Reality fail nếu sai giờ)
step "Đồng bộ thời gian..."
if command -v timedatectl &>/dev/null; then
    if ! timedatectl 2>/dev/null | grep -q "synchronized: yes"; then
        timedatectl set-ntp true 2>/dev/null
        systemctl restart systemd-timesyncd 2>/dev/null
        sleep 2
    fi
fi
ok "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# Locale
step "Kiểm tra locale..."
if ! locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
    apt-get install -y -qq locales &>/dev/null
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen 2>/dev/null
    locale-gen en_US.UTF-8 &>/dev/null
fi
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ok "Locale OK"

# DNS resolver
step "Kiểm tra DNS resolver..."
if ! getent hosts github.com &>/dev/null; then
    warn "Sửa DNS → 1.1.1.1"
    if [[ -f /etc/systemd/resolved.conf ]]; then
        sed -i 's/^#\?DNS=.*/DNS=1.1.1.1 1.0.0.1/' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved 2>/dev/null
    else
        chattr -i /etc/resolv.conf 2>/dev/null
        echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
    fi
fi
ok "DNS OK"

# Dependencies
step "Cài dependencies..."
case $OS in
    debian|ubuntu)
        apt-get update -qq 2>/dev/null
        apt-get install -y -qq curl wget unzip tar socat ca-certificates jq cron &>/dev/null
        update-ca-certificates &>/dev/null ;;
    centos|rhel|almalinux|rocky)
        yum install -y -q curl wget unzip tar socat ca-certificates jq cronie &>/dev/null ;;
esac
ok "Deps OK"

# Swap (RAM thấp)
mem_mb=$(free -m | awk '/^Mem:/{print $2}')
swap_mb=$(free -m | awk '/^Swap:/{print $2}')
info "RAM: ${mem_mb}MB | Swap: ${swap_mb}MB"
if [[ $mem_mb -lt 768 && $swap_mb -lt 512 && ! -f /swapfile ]]; then
    warn "RAM thấp → tạo swap 1GB..."
    fallocate -l 1G /swapfile && chmod 600 /swapfile \
        && mkswap /swapfile &>/dev/null && swapon /swapfile \
        && echo '/swapfile none swap sw 0 0' >> /etc/fstab
    ok "Swap 1GB sẵn sàng"
fi

# =====================================================================
#  PHẦN 2: CHỌN CORE
# =====================================================================
echo ""; echo -e "${W}=== Bước 2/4: Chọn core ===${N}"
cat <<EOF

  ${G}1)${N} ${W}V2bX${N}    - Đa core, mạnh nhất, cấu hình node tại server (Cores+CertConfig)
  ${G}2)${N} ${W}v2node${N}  - Xray-core thuần, ${G}đơn giản nhất${N} - panel quản lý 100% (chỉ cần API info)
  ${G}3)${N} ${W}XrayR${N}   - Cổ điển, cấu hình Reality/cert ngay tại node

EOF
read -rp "Chọn [1-3]: " core_choice

case $core_choice in
    1) CORE="v2bx";   SVC="V2bX";   CFG_DIR="/etc/V2bX" ;;
    2) CORE="v2node"; SVC="v2node"; CFG_DIR="/etc/v2node" ;;
    3) CORE="xrayr";  SVC="XrayR";  CFG_DIR="/etc/XrayR" ;;
    *) err "Lựa chọn không hợp lệ"; exit 1 ;;
esac
ok "Sẽ cài: $CORE → $CFG_DIR"

# =====================================================================
#  PHẦN 3: NHẬP THÔNG TIN PANEL & NODE
# =====================================================================
echo ""; echo -e "${W}=== Bước 3/4: Thông tin Panel & Node ===${N}"

while true; do
    read -rp "Panel URL [https://vpnnga.com]: " PANEL_URL
    PANEL_URL=${PANEL_URL:-https://vpnnga.com}
    [[ "$PANEL_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]] && break
    err "URL không hợp lệ"
done

step "Kiểm tra panel reachable..."
if curl -fsS --max-time 8 -o /dev/null -w "%{http_code}" "$PANEL_URL" | grep -qE "^(200|301|302|403)$"; then
    ok "Panel reachable"
else
    warn "Không kết nối được panel"
    read -rp "Vẫn tiếp tục? (y/N): " ans
    [[ ! "$ans" =~ ^[Yy]$ ]] && exit 1
fi

while true; do
    read -rp "API Key (token): " PANEL_KEY
    [[ ${#PANEL_KEY} -ge 8 ]] && break
    err "API Key tối thiểu 8 ký tự"
done

while true; do
    read -rp "Node ID (số): " NODE_ID
    [[ "$NODE_ID" =~ ^[0-9]+$ ]] && break
    err "Phải là số"
done

# Với v2node: panel quản lý mọi thứ (giao thức, Reality, cert, port...) → skip phần hỏi
if [[ "$CORE" == "v2node" ]]; then
    info "v2node: panel quản lý toàn bộ cấu hình node (giao thức, Reality, cert, port)"
    info "→ Đảm bảo node đã được tạo và cấu hình đầy đủ trên panel admin"
    NODE_TYPE="auto"; VARIANT="auto"; NEED_CERT=0
else
    # V2bX và XrayR cần biết loại node để ghi config tương ứng
    echo ""
    info "Loại node (chỉ chọn loại - tham số chi tiết quản lý ở panel):"
    echo "  1) VLESS + Reality      ${B}(không cần domain, panel push key)${N}"
    echo "  2) VLESS + Vision/TLS   ${B}(cần domain + cert)${N}"
    echo "  3) Trojan + TLS         ${B}(cần domain + cert)${N}"
    echo "  4) Shadowsocks(-2022)   ${B}(không cần domain)${N}"
    echo "  5) Vmess + WS + TLS     ${B}(cần domain + cert)${N}"
    echo "  6) Hysteria2            ${B}(V2bX only, cần domain + cert)${N}"
    read -rp "Chọn [1-6]: " proto

    case $proto in
        1) NODE_TYPE="vless";       VARIANT="reality";    NEED_CERT=0 ;;
        2) NODE_TYPE="vless";       VARIANT="vision_tls"; NEED_CERT=1 ;;
        3) NODE_TYPE="trojan";      VARIANT="tls";        NEED_CERT=1 ;;
        4) NODE_TYPE="shadowsocks"; VARIANT="ss";         NEED_CERT=0 ;;
        5) NODE_TYPE="vmess";       VARIANT="ws_tls";     NEED_CERT=1 ;;
        6) NODE_TYPE="hysteria2";   VARIANT="hy2";        NEED_CERT=1
           [[ "$CORE" == "xrayr" ]] && { err "XrayR không hỗ trợ Hysteria2"; exit 1; } ;;
        *) err "Lựa chọn không hợp lệ"; exit 1 ;;
    esac

    # Hỏi cert config nếu cần
    if [[ $NEED_CERT -eq 1 ]]; then
        read -rp "Domain: " DOMAIN
        [[ -z "$DOMAIN" ]] && { err "Cần domain"; exit 1; }

        [[ "$VARIANT" == "ws_tls" ]] && { read -rp "WebSocket path [/vmess]: " WS_PATH; WS_PATH=${WS_PATH:-/vmess}; }

        echo ""
        info "Cách xin cert SSL:"
        echo "  1) HTTP challenge   - cần port 80 free + domain trỏ A về IP server"
        echo "  2) DNS challenge    - cần API key DNS provider (linh hoạt hơn)"
        echo "  3) File             - đã có cert sẵn"
        read -rp "Chọn [1-3]: " cm

        case $cm in
            1)
                CERT_MODE="http"
                read -rp "Email LE [admin@vpnnga.com]: " CERT_EMAIL
                CERT_EMAIL=${CERT_EMAIL:-admin@vpnnga.com}
                ;;
            2)
                CERT_MODE="dns"
                read -rp "Email LE: " CERT_EMAIL
                [[ -z "$CERT_EMAIL" ]] && { err "Cần email"; exit 1; }
                echo "  1) Cloudflare   2) Aliyun   3) GoDaddy   4) Khác"
                read -rp "Provider [1-4]: " dp
                case $dp in
                    1) DNS_PROVIDER="cloudflare"
                       read -rp "  CF Email: " V1; read -rp "  CF Global API Key: " V2
                       K1="CLOUDFLARE_EMAIL"; K2="CLOUDFLARE_API_KEY" ;;
                    2) DNS_PROVIDER="aliyun"
                       read -rp "  Access Key ID: " V1; read -rp "  Access Key Secret: " V2
                       K1="ALICLOUD_ACCESS_KEY"; K2="ALICLOUD_SECRET_KEY" ;;
                    3) DNS_PROVIDER="gandi"
                       read -rp "  GoDaddy API Key: " V1; read -rp "  GoDaddy API Secret: " V2
                       K1="GODADDY_API_KEY"; K2="GODADDY_API_SECRET" ;;
                    4) read -rp "  Provider name: " DNS_PROVIDER
                       read -rp "  Env 1 name: " K1; read -rp "  Env 1 value: " V1
                       read -rp "  Env 2 name (Enter để skip): " K2
                       [[ -n "$K2" ]] && read -rp "  Env 2 value: " V2 ;;
                    *) err "Sai"; exit 1 ;;
                esac
                ;;
            3) CERT_MODE="file"; mkdir -p "$CFG_DIR/cert"
               warn "Hãy đặt cert tại $CFG_DIR/cert/${DOMAIN}.crt và .key" ;;
            *) err "Sai"; exit 1 ;;
        esac
    fi
fi

# =====================================================================
#  PHẦN 4: CÀI CORE
# =====================================================================
echo ""; echo -e "${W}=== Bước 4/4: Cài $CORE ===${N}"

case $CORE in
    v2bx)
        step "Tải V2bX install script..."
        wget -qO /tmp/v2bx-install.sh https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh \
            || { err "Không tải được"; exit 1; }
        # 'n' để skip phần generate config (mình tự gen)
        echo "n" | bash /tmp/v2bx-install.sh
        rm -f /tmp/v2bx-install.sh
        ;;
    v2node)
        step "Tải v2node install script..."
        wget -qO /tmp/v2node-install.sh https://raw.githubusercontent.com/wyx2685/v2node/master/script/install.sh \
            || { err "Không tải được"; exit 1; }
        # v2node script gốc hỗ trợ flag CLI - truyền thẳng panel info, không cần interactive
        # Script gốc sẽ tự ghi config.json và start service
        bash /tmp/v2node-install.sh \
            --api-host "$PANEL_URL" \
            --node-id "$NODE_ID" \
            --api-key "$PANEL_KEY"
        rm -f /tmp/v2node-install.sh
        ;;
    xrayr)
        step "Cài XrayR..."
        bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh) \
            || { err "Cài thất bại"; exit 1; }
        ;;
esac

[[ ! -d "$CFG_DIR" ]] && { err "Cài thất bại - thiếu $CFG_DIR"; exit 1; }
ok "$CORE đã cài"
mkdir -p "$CFG_DIR"

# =====================================================================
#  GHI CONFIG cho V2bX / v2node
# =====================================================================
write_config_v2bx_style() {
    # CertConfig theo variant
    local cert_block
    case $VARIANT in
        reality)
            cert_block='"CertConfig": { "CertMode": "reality" }'
            ;;
        ss)
            # Shadowsocks không cần CertConfig
            cert_block=""
            ;;
        vision_tls|tls|ws_tls|hy2)
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

    # Core type: xray cho vless/vmess/trojan, sing cho ss-2022/hy2 (V2bX khuyến nghị)
    local core_type="xray"
    [[ "$VARIANT" == "hy2" ]] && core_type="hysteria2"

    # Backup config cũ
    [[ -f "$CFG_DIR/config.json" ]] && cp "$CFG_DIR/config.json" "$CFG_DIR/config.json.bak.$(date +%s)"

    # Build node block
    local node_block
    if [[ -z "$cert_block" ]]; then
        # SS không có CertConfig
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

    # Cores section: chỉ xray nếu không có hy2, có cả xray+hysteria2 nếu cần
    local cores_section
    if [[ "$VARIANT" == "hy2" ]]; then
        cores_section=$(cat <<'EOF'
[
        {
            "Type": "xray",
            "Log": { "Level": "none", "ErrorPath": "/dev/null", "AccessPath": "/dev/null" },
            "OutboundConfigPath": "/etc/V2bX/custom_outbound.json",
            "RouteConfigPath": "/etc/V2bX/route.json"
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

    # Ghi config.json chính
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

    # Outbound: dual-stack IPv4/IPv6 + block
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

    # Route: chặn private IP + bittorrent, traffic đi qua IPv4_out
    cat > "$CFG_DIR/route.json" <<'EOF'
{
    "domainStrategy": "AsIs",
    "rules": [
        {
            "type": "field",
            "outboundTag": "block",
            "ip": ["geoip:private"]
        },
        {
            "type": "field",
            "outboundTag": "block",
            "protocol": ["bittorrent"]
        },
        {
            "type": "field",
            "outboundTag": "IPv4_out",
            "network": "tcp,udp"
        }
    ]
}
EOF

    # DNS
    cat > "$CFG_DIR/dns.json" <<'EOF'
{
    "servers": [
        "1.1.1.1",
        "8.8.8.8",
        "localhost"
    ]
}
EOF

    ok "Config: $CFG_DIR/config.json"

    # Validate JSON
    if ! jq empty "$CFG_DIR/config.json" 2>/dev/null; then
        err "JSON config bị lỗi cú pháp! Xem $CFG_DIR/config.json"
        return 1
    fi
    ok "JSON valid"
}

# =====================================================================
#  GHI CONFIG cho XrayR (YAML, panel cũ - phải config Reality tại node)
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

    [[ "$NODE_TYPE" == "vless" ]] && cat >> "$cfg" <<EOF
      EnableVless: true
      VlessFlow: ""
EOF

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
        # XrayR cần config Reality ngay tại node
        warn "XrayR cần khai báo Reality keys ngay tại node — sinh keys ngay..."
        # Tải xray binary tạm để gen keys
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

        info "Reality publicKey (copy vào panel): ${G}$pub${N}"

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

    # DNS + Route
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

case $CORE in
    v2bx)        write_config_v2bx_style ;;
    v2node)
        # v2node script gốc đã tự ghi /etc/v2node/config.json với panel info
        # Không cần làm gì thêm - panel quản lý mọi thứ
        ok "v2node config đã được sinh tự động bởi script gốc"
        info "Mọi cấu hình (Reality, cert, port, route) quản lý trên panel"
        # Verify config tồn tại
        if [[ -f /etc/v2node/config.json ]]; then
            ok "Config: /etc/v2node/config.json"
        else
            err "Không tìm thấy /etc/v2node/config.json"
            exit 1
        fi
        ;;
    xrayr)       write_config_xrayr ;;
esac

# =====================================================================
#  KHỞI ĐỘNG + AUTO-FIX LỖI
# =====================================================================
echo ""
step "Khởi động $SVC..."
systemctl daemon-reload
systemctl enable "$SVC" &>/dev/null
systemctl restart "$SVC"
sleep 4

if systemctl is-active --quiet "$SVC"; then
    ok "$SVC đang chạy"
else
    err "$SVC không khởi động được. Đang chẩn đoán..."
    echo ""
    journalctl -u "$SVC" -n 30 --no-pager
    echo ""

    LOG=$(journalctl -u "$SVC" -n 50 --no-pager 2>/dev/null)

    if echo "$LOG" | grep -qi "address already in use"; then
        err "Lỗi: Port đã bị chiếm"
        warn "Process đang chiếm port:"
        ss -tlnp 2>/dev/null | grep -E ":(443|80|8080|8388) "
        warn "→ Dừng process đó, hoặc đổi port trong panel"
    elif echo "$LOG" | grep -qiE "401|403|unauthorized|invalid.*key|invalid.*token"; then
        err "Lỗi: API Key sai"
        warn "→ Kiểm tra lại token trong panel admin"
    elif echo "$LOG" | grep -qi "node.*not.*found\|invalid node"; then
        err "Lỗi: Node ID $NODE_ID không tồn tại"
        warn "→ Vào panel admin → Node Management → kiểm tra ID"
    elif echo "$LOG" | grep -qi "certificate\|cert\|tls handshake"; then
        err "Lỗi: Cert có vấn đề"
        warn "→ Kiểm tra domain trỏ về IP server: $(curl -s4 ifconfig.me)"
        warn "→ Kiểm tra port 80 (HTTP challenge) hoặc API key DNS provider"
    elif echo "$LOG" | grep -qiE "connection refused|timeout|dial.*tcp"; then
        err "Lỗi: Không kết nối được panel"
        warn "→ Test: curl -v $PANEL_URL"
        warn "→ Có thể firewall hosting/VPS chặn outbound"
    elif echo "$LOG" | grep -qi "json.*syntax\|unmarshal\|yaml"; then
        err "Lỗi: Config sai cú pháp"
        warn "→ Xem $CFG_DIR/config.* và sửa thủ công"
    else
        warn "Lỗi không xác định. Xem log đầy đủ: journalctl -u $SVC -n 100"
    fi
    exit 1
fi

# =====================================================================
#  BBR
# =====================================================================
step "Bật BBR..."
if ! sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
    cat >> /etc/sysctl.conf <<'EOF'

# vpnnga tuning
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
EOF
    sysctl -p &>/dev/null
fi
ok "BBR: $(sysctl -n net.ipv4.tcp_congestion_control)"

# =====================================================================
#  TÓM TẮT
# =====================================================================
SERVER_IP=$(curl -s4 --max-time 5 ifconfig.me 2>/dev/null || echo "unknown")
echo ""
echo -e "${G}╔═══════════════════════════════════════════╗${N}"
echo -e "${G}║         CÀI ĐẶT HOÀN TẤT                  ║${N}"
echo -e "${G}╚═══════════════════════════════════════════╝${N}"
echo ""
echo -e "  Core:        ${W}$CORE${N} ($(systemctl is-active "$SVC"))"
echo -e "  Config:      ${W}$CFG_DIR${N}"
echo -e "  Server IP:   ${W}$SERVER_IP${N}"
echo -e "  Panel:       ${W}$PANEL_URL${N}"
echo -e "  Node ID:     ${W}$NODE_ID${N}"
echo -e "  Loại node:   ${W}$NODE_TYPE / $VARIANT${N}"
[[ -n "$DOMAIN" ]] && echo -e "  Domain:      ${W}$DOMAIN${N}"
echo ""
echo -e "  Lệnh quản lý:"
case $CORE in
    v2bx)   echo -e "    ${B}V2bX${N} {start|stop|restart|status|log}" ;;
    v2node) echo -e "    ${B}v2node${N} {start|stop|restart|status|log}" ;;
    xrayr)  echo -e "    ${B}XrayR${N} {start|stop|restart|status|log}" ;;
esac
echo ""
[[ "$VARIANT" == "reality" && "$CORE" == "xrayr" ]] && warn "→ Copy publicKey ở trên vào panel"
echo ""
