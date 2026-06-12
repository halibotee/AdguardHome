#!/bin/sh
###############################################################################
# AdGuardHome 一键安装/交互安装脚本 (在线模式)
#
# 用法:
#   sh install.sh                    # 交互式菜单安装
#   sh install.sh install            # 一键自动安装
#   sh install.sh update             # 一键自动更新
#   sh install.sh uninstall          # 一键卸载
#   sh install.sh {branch} {action}  # 指定分支和动作
#
# 依赖: curl, Entware (/opt), 已开启 JFFS
###############################################################################

set -e

REPO_BASE="https://raw.githubusercontent.com/halibotee/AdguardHome/main"
INSTALL_DIR="${INSTALL_DIR:-/tmp/agh_install}"

# 检查依赖
for cmd in curl nvram nvram; do
    command -v "$cmd" >/dev/null 2>&1 && break
done
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required."; exit 1
fi
if [ ! -d "/opt/etc" ] || [ ! -x "/opt/bin/opkg" ]; then
    echo "Error: Entware not detected. Install Entware first."; exit 1
fi

mkdir -p "$INSTALL_DIR"
echo "Downloading installer from $REPO_BASE ..."
curl -fsSL "$REPO_BASE/installer" -o "$INSTALL_DIR/installer" || { echo "Download failed."; exit 1; }
chmod +x "$INSTALL_DIR/installer"

echo "Starting AdGuardHome Installer..."
echo ""
cd "$INSTALL_DIR"
sh installer master "$@"
