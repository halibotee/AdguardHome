# AdGuardHome 离线安装包 (Asuswrt-Merlin)

在 **完全离线** 的环境下, 把 AdGuardHome 安装到运行 Asuswrt-Merlin (KoolShare) 固件的路由器上.
本包是对 [jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer](https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer) 的离线改造版, 兼容原版在线安装器, 但运行时**不依赖任何网络访问**.

---

## 目录

- [快速开始](#快速开始)
- [前置条件](#前置条件)
- [离线包内容](#离线包内容)
- [使用说明](#使用说明)
  - [Step 1. 在联网机器上准备离线包](#step-1-在联网机器上准备离线包)
  - [Step 2. 上传到路由器](#step-2-上传到路由器)
  - [Step 3. 在路由器上执行安装](#step-3-在路由器上执行安装)
  - [Step 4. 验证](#step-4-验证)
- [配置文件](#配置文件)
- [卸载](#卸载)
- [常见问题](#常见问题)
- [文件说明](#文件说明)
- [修改记录](#修改记录)

---

## 快速开始

### 一行命令 (推荐)

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/halibotee/AdguardHome/main/install.sh)"
```

或者先下载到本地再执行:

```sh
curl -fsSL https://raw.githubusercontent.com/halibotee/AdguardHome/main/install.sh -o /tmp/install.sh
sh /tmp/install.sh
```

`install.sh` 会:
1. 检测架构 (aarch64 / armv7 / armv5)
2. 检查 Entware + python3-bcrypt + column 是否预装
3. 下载所有必需文件到 `/tmp/AdguardHome_setup/` (默认)
4. 自动启动离线安装器

### 手动方式

如果你已经拿到了离线包 (例如 `/mnt/sda1/AdguardHome_setup/`), 直接 SSH 登录路由器:

```sh
sh /mnt/sda1/AdguardHome_setup/installer master install
```

或显式指定离线目录:

```sh
AGH_OFFLINE_DIR=/mnt/sda1/AdguardHome_setup sh /mnt/sda1/AdguardHome_setup/installer master install
```

WebUI 默认监听 `http://192.168.50.1:14711/login.html` (用户名 `AX86U`, 密码见你的 `AdGuardHome.yaml`).

---

## 前置条件

### 硬件
- **CPU 架构**: 仅支持 `aarch64` (armv8) / `armv7` / `armv5` 三种 ARM 架构
- **可用空间**: `/opt` 分区至少 200 MB (用于二进制 + 帮助脚本)
- **内存**: 至少 1 GB 可用 (AdGuardHome 进程会占用 ~50 MB)

### 软件 (在路由器上预装)
- **固件**: Asuswrt-Merlin (KoolShare 修改版)
- **JFFS**: 已启用且脚本可执行
- **Entware**: 必须安装, 且 `/opt` 软链指向 Entware
- **Python 3 + bcrypt** (用于密码哈希):
  ```sh
  opkg install python3 python3-bcrypt column
  ```
  如果没有 `python3-bcrypt`, 安装备选 `bcrypt-tool`:
  ```sh
  opkg install go
  # 或
  opkg install go_nohf  # 旧版
  # 然后用脚本里的 bcrypt-tool 路径
  ```

### 离线包内必须的文件
- `AdGuardHome_linux_<arch>.tar.gz` — AdGuardHome 二进制 (从 GitHub release 下载)
- `AdGuardHome.sh` — 管理脚本 (从 upstream 同步)
- `S99AdGuardHome` — SysV 启动脚本 (从 upstream 同步, **已修复调度问题**)
- `rc.func.AdGuardHome` — SysV 工具库 (从 upstream 同步)
- `tzdata-2021e-1-<arch>.pkg.tar.bz2` — 时区数据 (可选, 缺失则跳过)
- `AdGuardHome.yaml` — **你的自定义配置** (新增加载, 详见 [配置文件](#配置文件))
- `installer` — 本离线安装器 (主入口)

---

## 离线包内容

运行 `ls -la <离线包目录>/` 应看到:

```
AdGuardHome.sh                   25,884  字节  库/管理脚本
AdGuardHome.yaml                   4,646  字节  ★ 你的自定义配置
AdGuardHome_linux_arm64.tar.gz   10.4 MB     aarch64 二进制 (RT-AX86U 等)
AdGuardHome_linux_armv5.tar.gz   11 MB       armv5 二进制
AdGuardHome_linux_armv7.tar.gz   11 MB       armv7 二进制
AdguardHome_Upstreams.txt         3.6 MB     ★ 你的上游 DNS 列表 (YAML 引用)
S99AdGuardHome                    2,453  字节  SysV 启动脚本 (已修复)
installer                        54,911  字节  主安装器
prepare-offline.sh                6,338  字节  离线包准备工具
rc.func.AdGuardHome               3,877  字节  SysV 工具库
tzdata-2021e-1-aarch64.pkg.tar.bz2  616 KB  aarch64 时区
tzdata-2021e-1-arm.pkg.tar.bz2     616 KB   arm 时区
```

带 ★ 的文件是 **离线模式专有**, 跟 upstream 默认包不一样:
- `AdGuardHome.yaml` — 你的自定义配置 (替代安装器交互式生成)
- `AdguardHome_Upstreams.txt` — 上游 DNS 列表 (在 `AdGuardHome.yaml` 中通过 `upstream_dns_file` 引用, 安装器会自动复制)

---

## 使用说明

### Step 1. 在联网机器上准备离线包

如果你还没有离线包, 在一台有互联网的 Mac/Linux 上执行:

```sh
cd /Users/jinjun/works/DEV/AdguardHome
sh prepare-offline.sh /path/to/output
```

将下载:
- upstream 的 `AdGuardHome.sh` / `S99AdGuardHome` / `rc.func.AdGuardHome`
- 最新版 AdGuardHome 全部 4 个架构的 tar.gz
- tzdata 两种架构

然后把你自定义的 `AdGuardHome.yaml` 和 (可选) `AdguardHome_Upstreams.txt` 放到同一目录.

### Step 2. 上传到路由器

把整个目录复制到路由器的 USB 盘 (推荐) 或 jffs:

```sh
# macOS 本地 → 路由器 (假设 SSH 端口 2233, 用户名 AX86U)
scp -P 2233 -r /Users/jinjun/works/DEV/AdguardHome AX86U@192.168.50.1:/tmp/mnt/sda1/

# 或者用 tar+ssh (scp 不可用时):
tar czf - -C /Users/jinjun/works/DEV/AdguardHome . | ssh -p 2233 AX86U@192.168.50.1 "cat > /tmp/sda1/AdguardHome_setup.tgz && tar xzf /tmp/sda1/AdguardHome_setup.tgz -C /mnt/sda1/AdguardHome_setup/"
```

最终在路由器上的位置 (推荐): `/mnt/sda1/AdguardHome_setup/`

### Step 3. 在路由器上执行安装

#### 方式 A: 交互式 (推荐首次使用)

```sh
ssh AX86U@192.168.50.1 -p 2233
sh /mnt/sda1/AdguardHome_setup/installer master
```

然后在菜单里选 `1) Install/Update`.

#### 方式 B: 非交互式 (适合脚本化)

```sh
printf "y\n1\nq\n" | AGH_OFFLINE_DIR=/mnt/sda1/AdguardHome_setup sh /mnt/sda1/AdguardHome_setup/installer master install
```

输入含义:
- `y` — 确认执行安装
- `1` — 选择 release 通道 (1=Release, 2=Beta, 3=Edge)
- `q` — 安装完成后退出菜单 (因为 `end_op_message` 会 `exec` 重启, 留 `q` 让重启后的菜单直接退出)

#### 方式 C: 卸载

```sh
printf "y\n" | AGH_OFFLINE_DIR=/mnt/sda1/AdguardHome_setup sh /mnt/sda1/AdguardHome_setup/installer master uninstall
```

### Step 4. 验证

```sh
# 进程
pidof AdGuardHome

# 监听端口
netstat -nlp 2>/dev/null | grep -E ":(53|14711) "

# WebUI
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.50.1:14711/login.html
# 期望: 200

# DNS 解析
nslookup github.com 127.0.0.1
# 期望: 看到 Address 1 = ... (实际 IP)
```

打开浏览器访问 `http://192.168.50.1:14711/login.html`, 用 `AdGuardHome.yaml` 里配置的用户名和密码登录.

---

## 配置文件

### 离线模式的 YAML 加载

在离线模式下, 安装器会:
1. 读取 `${AGH_OFFLINE_DIR}/AdGuardHome.yaml`
2. 复制到 `/opt/etc/AdGuardHome/AdGuardHome.yaml` (运行时) 和 `.AdGuardHome.yaml.ori` (原始模板)
3. 从 `http.address: 0.0.0.0:<port>` 提取 WebUI 端口, 写入 `.config`
4. 扫描 YAML 中所有 `*_file:` 和 `*_path:` 字段, 在 `${AGH_OFFLINE_DIR}/` 里找对应文件并复制到正确位置
5. 预创建 `data/filters/`, `data/querylog/`, `data/stats/` 子目录 (避免 `set_url` API 写临时文件失败)

### 离线模式不支持的 YAML 字段

- `dns.upstream_dns_file` — 离线模式仍支持 (会自动复制引用的文件)
- `filtering.engines` — 任何引用远程 URL 的过滤器, 离线模式不会下载 (需要在 WebUI 里手动更新或预下载)
- `tls.*` — 证书相关不受影响

### 自定义 YAML 示例

参考 `AdGuardHome.yaml`. 关键字段:
- `http.address: 0.0.0.0:14711` — WebUI 端口 (必须在 1024-65535 之间)
- `dns.port: 53` — DNS 端口 (与 dnsmasq 冲突, 由 `S99` 自动处理)
- `users[].name` 和 `users[].password` — bcrypt 哈希过的密码

### 重要: 权限

`/opt/etc/AdGuardHome/` 由 `nvram get http_username` 决定的所有者拥有, 模式 `755`.
`/opt/etc/AdGuardHome/data/` 及子目录 (filters, querylog, stats) 模式 `755`, AdGuardHome 启动后会改为 `700` (这是正常的, AdGuardHome 的安全默认).

---

## 卸载

```sh
printf "y\n" | AGH_OFFLINE_DIR=/mnt/sda1/AdguardHome_setup sh /mnt/sda1/AdguardHome_setup/installer master uninstall
```

或手动:

```sh
# 停止 AdGuardHome
/opt/etc/init.d/S99AdGuardHome stop 2>/dev/null
pkill -9 AdGuardHome

# 删除文件
rm -rf /opt/etc/AdGuardHome \
       /opt/etc/init.d/S99AdGuardHome \
       /opt/etc/init.d/rc.func.AdGuardHome \
       /jffs/addons/AdGuardHome.d

# 删除软链
rm -f /opt/sbin/AdGuardHome

# 清理 jffs 脚本 (如果不再使用)
/jffs/scripts/firewall-start  # 删除包含 AdGuardHome 的行
/jffs/scripts/init-start      # 同上
# 等等

# 重启 dnsmasq
service restart_dnsmasq
```

---

## 常见问题

### Q1: 安装时报 "Timed out waiting for start" / "Timed out waiting for stop"

这是因为 **AdGuardHome 监控进程会立即重启被杀掉的 AGH**, 所以 `pkill` 后 1-2 秒 AGH 又出现.

**这是正常的**. 验证 AGH 实际状态:
```sh
pidof AdGuardHome  # 期望: 一个 PID
netstat -nlp 2>/dev/null | grep -E ":(53|14711) " | grep AdGuardHome  # 期望: 2 行 (TCP+UDP 53) + 1 行 (14711)
```

### Q2: WebUI `set_url` 报错 `no such file or directory`

路径错误已修复. 安装器现在会预创建:
- `/opt/etc/AdGuardHome/data/filters/`
- `/opt/etc/AdGuardHome/data/querylog/`
- `/opt/etc/AdGuardHome/data/stats/`

如果还是报错, 检查:
```sh
ls -la /opt/etc/AdGuardHome/data/
# 期望看到 filters/ querylog/ stats/ 三个子目录
```

### Q3: 路径是 `/tmp/mnt/sda1/entware/etc/AdGuardHome/...` 而不是 `/opt/etc/...`

正常! `/opt` 是符号链接指向 `/tmp/mnt/sda1/entware/`. 内核错误信息会显示真实路径, 但两者指向同一目录, 不影响功能.

### Q4: 时区 (timezone) 怎么改?

离线模式默认设为 `Europe/Moscow` (UTC+3, 编号 311). 改时区:
1. WebUI → Settings → General → Time Zone
2. 或手动替换 `/jffs/addons/AdGuardHome.d/localtime`:
   ```sh
   ln -sf /usr/share/zoneinfo/Asia/Tokyo /jffs/addons/AdGuardHome.d/localtime
   ```

### Q5: 怎么升级 AdGuardHome?

1. 在联网机器上重跑 `prepare-offline.sh` (会拉取最新 release)
2. 把新离线包传到路由器
3. 重跑安装: `sh /mnt/sda1/AdguardHome_setup/installer master install`

### Q6: 与原版 (online) 兼容吗?

完全兼容. 原版脚本 `jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer/installer` 加上 offline 改造后, 同时支持:
- `AGH_OFFLINE_DIR=...` 设置时, 走离线路径
- 不设置 `AGH_OFFLINE_DIR` 且有网络时, 走原版在线路径

---

## 文件说明

| 文件 | 来源 | 行数 | 用途 |
|---|---|---|---|
| `installer` | 改造自 upstream | 874 | 主安装器, 支持 offline + online |
| `AdGuardHome.sh` | upstream | 932 | AdGuardHome 管理脚本 (start/stop/restart/firewall/etc) |
| `S99AdGuardHome` | upstream + **本包修复** | 74 | SysV 启动脚本 |
| `rc.func.AdGuardHome` | upstream | 159 | SysV 通用工具库 (start/stop 函数) |
| `prepare-offline.sh` | 本包新增 | 164 | 离线包准备工具 |

### S99AdGuardHome 修复说明

upstream 的 `S99AdGuardHome` 在第 71 行结束 (`[ -z "${SCRIPT_LOC}" ] && . /jffs/addons/AdGuardHome.d/AdGuardHome.sh`), **缺少动作分派**.

本包在末尾追加两行:
```sh
ACTION="$1"
. /opt/etc/init.d/rc.func.AdGuardHome
```

这样 `service start_AdGuardHome` 才会真正调用 `rc.func` 里的 `start` 函数, 进而启动 AdGuardHome 进程.

### installer 关键修改

1. **line 802**: `inst_AdGuardHome "install"` — 显式传 "install" 参数, 避免 `${1:-RESTORE}` 默认把空 `$1` 当作 RESTORE 跳过整个安装
2. **line 584-614**: 离线 YAML 配置块, 包括数据子目录预创建
3. **line 92-110**: 离线模式下载覆盖, 从 `OFFLINE_DIR` 读取文件
4. **line 623-653**: 时区设置, 离线模式自动用 Asia/Shanghai

---

## 修改记录

### v2.2.3-offline (本版本)

基于 upstream v2.2.3 添加:

| 类别 | 修改 |
|---|---|
| **新功能** | 离线模式 (`AGH_OFFLINE_DIR` 触发) |
| **新功能** | 自定义 `AdGuardHome.yaml` 加载 |
| **新功能** | 自动复制 YAML 引用的 `*_file` (如 `upstream_dns_file`) |
| **新功能** | 预创建 `data/filters/` 等子目录 |
| **Bug 修复** | S99AdGuardHome 缺动作分派 (`ACTION="$1" && . rc.func`) |
| **Bug 修复** | `inst_AdGuardHome` 无参调用时被误判为 RESTORE |
| **Bug 修复** | 离线模式 `set_timezone` 仍要求交互 (现自动 Europe/Moscow / UTC+3) |
| **Bug 修复** | `write_conf` 缺 `mkdir -p` 父目录 |
| **Bug 修复** | 离线模式下载目录路径冗余, 简化为单一查找路径 |
| **新文件** | `prepare-offline.sh` (离线包准备工具) |
| **新文件** | `README.md` (本文件) |

### 已验证的兼容性
- RT-AX86U (aarch64) ✓
- Asuswrt-Merlin 384.x (KoolShare 修改版) ✓
- AdGuardHome v0.107.77 ✓
- Entware ≥ 0.9 ✓

### 已知限制
- 离线模式只支持 `AGH_OFFLINE_DIR` 环境变量或自动检测
- 离线模式假设 `Europe/Moscow` (UTC+3) 为默认时区 (可手动修改)
- 离线模式不会下载过滤器列表 (filter URLs), 需在 WebUI 内手动更新
- 离线模式不会下载 DoH/DoT 证书, 假设本地 `ca-bundle` 已就绪

---

## 联系 / 反馈

本离线改造包的问题, 请在本仓库提 issue.

upstream 项目: https://github.com/jumpsmm7/Asuswrt-Merlin-AdGuardHome-Installer

---

## 附录 A: 完整安装日志示例

```text
[1m Info: [0m OFFLINE MODE - Assets: /mnt/sda1/AdguardHome_setup
[1m Info: [0m Installing AdGuardHome...
[1m => [0m Proceed? [1m[y/n][0m: [1m Info: [0m Choose AdGuardHome build:
  1) Release
  2) Beta
  3) Edge
[1m => [0m Select mode, [1m[1-3][0m: [1m Info: [0m Copying AdGuardHome_linux_arm64.tar.gz from offline bundle
./AdGuardHome/
./AdGuardHome/AdGuardHome
./AdGuardHome/CHANGELOG.md
./AdGuardHome/AdGuardHome.sig
./AdGuardHome/LICENSE.txt
./AdGuardHome/README.md
[TAR_EXIT=0]
[1m Info: [0m Copying AdGuardHome.sh from offline bundle
[1m Info: [0m Copying S99AdGuardHome from offline bundle
[1m Info: [0m Copying rc.func.AdGuardHome from offline bundle
[1m Info: [0m Provisioning offline AdGuardHome.yaml config
[1m Info: [0m Copied offline asset: AdguardHome_Upstreams.txt
[1m Info: [0m Pre-created data subdirectories: filters, querylog, stats
[1m Info: [0m Using local tzdata.
[1m Info: [0m Setting default timezone Asia/Shanghai (change via WebUI).
[1m Info: [0m Configuring AdGuardHome...
[1m Info: [0m Using existing config (offline mode).
[1m Info: [0m Checking AdGuardHome configuration...
[1m Info: [0m Starting AdGuardHome...
[1;37m Checking AdGuardHome...             [1;32m alive. [m
[1m Info: [0m Performing final check.
[1m Info: [0m AdGuardHome setup complete.
[1m Info: [0m Operation completed.
```

(出现 `Timed out waiting for stop` 是监控进程自动重启 AGH 导致, **不影响功能**, 看 [Q1](#q1-安装时报-timed-out-waiting-for-start--timed-out-waiting-for-stop))

---

## 附录 B: 文件权限表

| 路径 | 所有者 | 模式 | 说明 |
|---|---|---|---|
| `/opt/etc/AdGuardHome/` | `http_username` | 755 | 安装目录 |
| `/opt/etc/AdGuardHome/AdGuardHome` | `http_username` | 755 | 二进制 |
| `/opt/etc/AdGuardHome/AdGuardHome.yaml` | `http_username` | 644 | 配置文件 |
| `/opt/etc/AdGuardHome/.AdGuardHome.yaml.ori` | `http_username` | 644 | 原始配置模板 |
| `/opt/etc/AdGuardHome/.config` | `http_username` | 644 | 安装器配置 |
| `/opt/etc/AdGuardHome/data/` | `http_username` | 700 (AGH 改) | 运行时数据 |
| `/opt/etc/AdGuardHome/data/filters/` | `http_username` | 700 (AGH 改) | 过滤器缓存 |
| `/opt/etc/AdGuardHome/AdguardHome_Upstreams.txt` | `http_username` | 644 | 上游 DNS 列表 |
| `/opt/sbin/AdGuardHome` | - | 777 | 软链 → `/opt/etc/AdGuardHome/AdGuardHome` |
| `/opt/etc/init.d/S99AdGuardHome` | root | 755 | SysV 启动脚本 |
| `/opt/etc/init.d/rc.func.AdGuardHome` | root | 755 | SysV 工具库 |
| `/jffs/addons/AdGuardHome.d/AdGuardHome.sh` | root | 755 | 管理脚本 |
| `/jffs/addons/AdGuardHome.d/localtime` | root | 644 (或软链) | 时区文件 |
| `/jffs/scripts/dnsmasq.postconf` | root | 755 | dnsmasq 配置钩子 |

---

## 附录 C: 故障排查流程

```
+-- AdGuardHome 不工作
    |
    +-- pidof AdGuardHome 返回空?
    |   |
    |   +-- 是 → 检查 /tmp/syslog.log 或 dmesg 找启动错误
    |   |        常见: bcrypt-tool 缺失 / 端口冲突 / 配置文件错误
    |   |
    |   +-- 否 → 进程在跑但 WebUI 不通
    |            检查: netstat | grep 14711
    |
    +-- DNS 解析失败?
    |   |
    |   +-- 127.0.0.1 解析失败 → AdGuardHome 没监听 53 端口
    |   |
    |   +-- 192.168.50.1 解析失败 → allowed_clients 配置问题
    |                       (用户 YAML 的 allowed_clients 列表)
    |
    +-- WebUI 502 / 404?
        |
        +-- 检查 AdGuardHome 进程是否在跑
        +-- 检查 http.address 端口 (默认 14711)
        +-- 检查 .config 里 ADGUARD_WEBUI_PORT 是否匹配
```

### 抓取详细启动日志

```sh
# 手动启动 (前台) 抓日志
env TZ=/etc/localtime GOGC=40 GOMAXPROCS=1 \
  /opt/etc/AdGuardHome/AdGuardHome \
  -s run -c /opt/etc/AdGuardHome/AdGuardHome.yaml \
  -w /opt/etc/AdGuardHome --no-check-update \
  -l /tmp/agh-debug.log 2>&1
```
