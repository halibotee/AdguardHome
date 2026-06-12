# AdGuardHome 安装包 (Asuswrt-Merlin)

在 Asuswrt-Merlin 路由器上安装 AdGuardHome，支持在线安装和离线安装两种模式。

基于 [jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer](https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer) 改造。

---

## 快速开始

### 一键自动安装（推荐）
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/halibotee/AdguardHome/main/install.sh)"
```

### 交互式安装
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/halibotee/AdguardHome/main/install.sh)" "" install
```

WebUI 默认监听 `http://192.168.50.1:14711/`。

---

## 前置条件

| 项目 | 要求 |
|------|------|
| 固件 | Asuswrt-Merlin |
| JFFS | 已启用且脚本可执行 |
| Entware | 已安装到 `/opt` |
| 架构 | aarch64 / armv7 / armv5 |
| 空间 | `/opt` 剩余 ≥ 200 MB |

**预装 Python + bcrypt**（用于密码哈希）:
```sh
opkg install python3 python3-bcrypt column
```

---

## 使用方式

### 在线安装（默认）
`install.sh` 是引导脚本，自动从 GitHub 下载安装器并运行：

```sh
sh install.sh                    # 交互式菜单
sh install.sh install            # 一键自动安装
sh install.sh update             # 一键更新
sh install.sh uninstall          # 一键卸载
```

安装器在线模式下会从 GitHub 下载以下内容：
- AdGuardHome 二进制（来自 AdGuard 官方发布）
- 管理脚本 (`AdGuardHome.sh`, `S99AdGuardHome`, `rc.func.AdGuardHome`)
- 时区数据 (`tzdata`)

### 离线安装
在联网机器上预先下载所有资产，上传到路由器后运行：

```sh
AGH_OFFLINE_DIR=/path/to/assets sh installer master install
```

离线目录需要包含：
```
AdGuardHome_linux_<arch>.tar.gz   AdGuardHome 二进制
AdGuardHome.sh                      管理脚本
S99AdGuardHome                      启动脚本
rc.func.AdGuardHome                 工具库
tzdata-2021e-1-<arch>.pkg.tar.bz2   时区数据（可选）
AdGuardHome.yaml                    自定义配置（可选）
AdguardHome_Upstreams.txt           上游 DNS 列表（可选）
```

---

## 主要修改

| 修改 | 说明 |
|------|------|
| DNS 拦截修复 | `AdGuardHome.sh` 新增主 dispatch，`dnsmasq.postconf` 调用 `dnsmasq_params` 正常生效 |
| S99 调度修复 | 末尾追加 `ACTION="$1"; . /opt/etc/init.d/rc.func.AdGuardHome` |
| 时区自动检测 | 从 `/etc/localtime` symlink 或 `/etc/TZ` 自动识别，支持 15+ 常见时区 |
| 在线/离线双模式 | `AGH_OFFLINE_DIR` 触发离线，默认在线 |

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `installer` | 主安装器，支持在线/离线双模式 |
| `install.sh` | 在线引导脚本，下载并运行 installer |
| `AdGuardHome.sh` | 管理脚本，含 DNS 配置、防火墙、监控等 |
| `S99AdGuardHome` | SysV 启动脚本（已修复调度问题） |
| `rc.func.AdGuardHome` | SysV 工具库 |
| `AdGuardHome.yaml` | 离线模式自定义配置模板 |
