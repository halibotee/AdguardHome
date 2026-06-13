# AdGuardHome (Asuswrt-Merlin)

在 Asuswrt-Merlin 路由器上一键安装 AdGuardHome，基于 [jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer](https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer)（MIT 协议），仅增加两项修改：

1. **自动时区** – 不再交互式选择时区，自动检测系统时区
2. **DNS 端口持久化** – 安装后创建 `/jffs/configs/dnsmasq.d/aghome.conf`（`port=553`），确保 dnsmasq 重启后不与 AdGuardHome 的 `:53` 冲突

## 一键脚本

```sh
curl -L -s -O https://raw.githubusercontent.com/halibotee/AdguardHome/main/installer && sh installer; rm installer
```

## 前置条件

- Asuswrt-Merlin 固件
- 已安装虚拟内存、USB2JFFS、Entware
