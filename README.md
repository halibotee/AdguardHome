# AdGuardHome (Asuswrt-Merlin)

在 Asuswrt-Merlin 路由器上安装 AdGuardHome。基于 [jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer](https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer) 改造。

## 一行命令

```sh
curl -fsSL -O https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh installer master; rm -f installer
```

进入菜单选 `1) Install/Update`，按提示交互配置即可。

## 前置条件

固件 Asuswrt-Merlin，JFFS 已启用，Entware 已装。密码哈希:
```sh
opkg install python3 python3-bcrypt column
```

## 其它命令

| 命令 | 说明 |
|------|------|
| `sh installer master uninstall` | 卸载 |
| `AGH_OFFLINE_DIR=/path sh installer master install` | 离线安装 |

## 主要修改

- **DNS 拦截修复** — `AdGuardHome.sh` 新增主 dispatch，`dnsmasq.postconf` 生效
- **S99 调度修复** — 追加 `ACTION="$1"; . /opt/etc/init.d/rc.func.AdGuardHome`
- **时区自动检测** — 从 `/etc/localtime` 或 `/etc/TZ` 识别
