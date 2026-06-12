#!/bin/sh
###############################################################################
# AdGuardHome 一键安装脚本 (RT-AX86U / aarch64 离线)
#
# 用法:
#   sh install.sh                       # 默认安装到 /tmp/AdguardHome_setup
#   sh install.sh /opt/agh-setup       # 指定目录
#   INSTALL_DIR=/jffs/agh sh install.sh # 用环境变量
#
# 离线运行,无网络依赖. 自动:
#   1. 下载仓库所有文件
#   2. 设置可执行权限
#   3. 调用 installer 进入交互式安装
#
# 如果 Entware/python3-bcrypt/column 未预装, 会失败.
###############################################################################

set -e

REPO_BASE="https://raw.githubusercontent.com/halibotee/AdguardHome/main"
INSTALL_DIR="${1:-${INSTALL_DIR:-/tmp/AdguardHome_setup}}"

# 检查 git/curl
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed."
    exit 1
fi

# 检查 Entware (Asuswrt-Merlin 必需)
if [ ! -d "/opt/etc" ] || [ ! -x "/opt/bin/opkg" ]; then
    echo "Error: Entware not detected at /opt. Install Entware first."
    exit 1
fi

# 检查预装包
MISSING=""
for pkg in python3 column; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING="$MISSING $pkg"
    fi
done
if [ -n "$MISSING" ]; then
    echo "Error: missing required packages:$MISSING"
    echo "Run: opkg install$MISSING"
    exit 1
fi
if ! python3 -c 'import bcrypt' >/dev/null 2>&1 && [ ! -x /opt/bin/bcrypt-tool ]; then
    echo "Error: password hashing unavailable. Install python3-bcrypt or bcrypt-tool."
    echo "Run: opkg install python3-bcrypt"
    exit 1
fi

# 检测架构
ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64) TZ_ARCH="aarch64"; BIN_ARCH="arm64" ;;
    armv7l)        TZ_ARCH="arm";     BIN_ARCH="armv7" ;;
    armv7)         TZ_ARCH="arm";     BIN_ARCH="armv5" ;;
    *)
        echo "Warning: unknown arch $ARCH, assuming armv5/aarch64 fallback"
        TZ_ARCH="aarch64"; BIN_ARCH="arm64" ;;
esac

echo "=========================================================="
echo "  AdGuardHome Offline Installer"
echo "  Target: $INSTALL_DIR"
echo "  Arch:   $ARCH (bin=$BIN_ARCH tz=$TZ_ARCH)"
echo "=========================================================="

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 必要文件
FILES="installer
AdGuardHome.sh
S99AdGuardHome
rc.func.AdGuardHome
AdGuardHome.yaml
AdguardHome_Upstreams.txt
prepare-offline.sh
AdGuardHome_linux_${BIN_ARCH}.tar.gz
tzdata-2021e-1-${TZ_ARCH}.pkg.tar.bz2"

# 可选文件 (其他架构的二进制, 方便以后升级路由器)
OPTIONAL="AdGuardHome_linux_armv5.tar.gz
AdGuardHome_linux_armv7.tar.gz
tzdata-2021e-1-arm.pkg.tar.bz2"

# 下载
echo "[1/2] Downloading files..."
for f in $FILES; do
    if [ -f "$f" ] && [ -s "$f" ]; then
        echo "  [SKIP] $f"
        continue
    fi
    printf "  [FETCH] %s ... " "$f"
    if curl -fsSL "$REPO_BASE/$f" -o "$f"; then
        echo "OK"
    else
        echo "FAILED"
        exit 1
    fi
done

# 可选文件 (失败不致命)
for f in $OPTIONAL; do
    if [ -f "$f" ] && [ -s "$f" ]; then
        continue
    fi
    printf "  [OPT]   %s ... " "$f"
    if curl -fsSL "$REPO_BASE/$f" -o "$f" 2>/dev/null; then
        echo "OK"
    else
        echo "skipped"
        rm -f "$f"
    fi
done

# 权限
chmod +x installer S99AdGuardHome rc.func.AdGuardHome AdGuardHome.sh prepare-offline.sh 2>/dev/null

echo "[2/2] Starting installer..."
echo ""
echo "  After install, access WebUI at: http://$(nvram get lan_ipaddr 2>/dev/null || echo 192.168.50.1):14711/"
echo ""

# 启动安装器
AGH_OFFLINE_DIR="$(pwd)" sh installer master "$@"
