# AdGuardHome 安装包 (Asuswrt-Merlin)

在 Asuswrt-Merlin 路由器上安装 AdGuardHome，支持在线/离线双模式。

基于 [jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer](https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer) 改造。

---

## 快速开始

### 一行命令（交互菜单 → 选安装模式）
```sh
curl -fsSL -o /tmp/agh-installer https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh /tmp/agh-installer master; rm -f /tmp/agh-installer
```

进入菜单选 `1` 后，选择：
- **`1) Auto Install`** — 默认配置，一键安装
- **`2) Manual Config`** — 原版交互式配置

### 一键自动（跳过菜单）
```sh
curl -fsSL -o /tmp/agh-installer https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh /tmp/agh-installer master auto-install; rm -f /tmp/agh-installer
```

WebUI 默认 `http://192.168.50.1:14711/`（用户名 `admin`，密码安装时打印）。

---

## 前置条件

| 项目 | 要求 |
|------|------|
| 固件 | Asuswrt-Merlin，JFFS 已启用 |
| Entware | 已安装到 `/opt` |
| 架构 | aarch64 / armv7 / armv5 |
| 空间 | `/opt` ≥ 200 MB |

**预装密码哈希**:
```sh
opkg install python3 python3-bcrypt column
```

---

## 安装模式

| 方式 | 命令 | 说明 |
|------|------|------|
| 交互菜单 | `sh installer master` | 菜单 → 选 `1` → 选 Auto/Manual |
| 自动安装 | `sh installer master auto-install` | 默认配置，无交互 |
| 手动安装 | `sh installer master install` | 菜单 → 选 Manual Config |
| 更新 | `sh installer master update` | 保留配置，更新二进制 |
| 卸载 | `sh installer master uninstall` | 清理所有文件 |

### 离线安装
```sh
AGH_OFFLINE_DIR=/path/to/assets sh installer master install
```

离线目录需包含 `AdGuardHome_linux_<arch>.tar.gz`、`AdGuardHome.sh`、`S99AdGuardHome`、`rc.func.AdGuardHome`，可选 `tzdata-*.pkg.tar.bz2`、`AdGuardHome.yaml`。

### Auto Install 默认值
- 端口: 14711，用户: admin，密码: 随机生成
- 上游 DNS: 9.9.9.9 / 8.8.8.8
- DNS 重定向: 全部 → AdGuardHome，本地缓存: 开启
- 分支: release

---

## 主要修改

| 修改 | 说明 |
|------|------|
| DNS 拦截修复 | `AdGuardHome.sh` 新增主 dispatch，`dnsmasq.postconf` 生效 |
| S99 调度修复 | 末尾追加 `ACTION="$1"; . /opt/etc/init.d/rc.func.AdGuardHome` |
| 时区自动检测 | 从 `/etc/localtime` 或 `/etc/TZ` 自动识别 |
| 安装模式二选一 | 菜单选 Auto Install 或 Manual Config |
| 在线/离线双模式 | `AGH_OFFLINE_DIR` 触发离线 |

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `installer` | 主安装器（在线/离线/自动/手动） |
| `install.sh` | 3 行引导脚本，`curl + run + rm` |
| `AdGuardHome.sh` | 管理脚本（DNS 配置、防火墙、监控） |
| `S99AdGuardHome` | SysV 启动脚本（已修复） |
| `rc.func.AdGuardHome` | SysV 工具库 |
