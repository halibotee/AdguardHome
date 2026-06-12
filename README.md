# AdGuardHome (Asuswrt-Merlin)

在 Asuswrt-Merlin 路由器上安装 AdGuardHome。

## 一行命令

```sh
curl -fsSL -O https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh installer master; rm -f installer
```

菜单选 `1) Install/Update`，按提示交互配置。

## 前置条件

- Asuswrt-Merlin 固件，JFFS 已启用
- Entware 已安装到 `/opt`
- 密码哈希: `opkg install python3 python3-bcrypt column`

## 卸载

```sh
curl -fsSL -O https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh installer master uninstall; rm -f installer
```

## 离线安装

资产目录包含 `AdGuardHome_linux_<arch>.tar.gz`、`AdGuardHome.sh`、`S99AdGuardHome`、`rc.func.AdGuardHome`，可选 `tzdata`、`AdGuardHome.yaml`：

```sh
AGH_OFFLINE_DIR=/path sh installer master install
```
