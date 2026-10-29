#!/bin/bash
#
# t7-sec-firmware 固件附加脚本（feeds 安装后在源码树根执行）
# 移植自 Action-237 仓库 diy-part2-eviltwin.sh（360t7-evil-twin 分支实测可用）
#

# fluxion 通过 `service xxx start/stop` 管理服务，OpenWrt（procd）没有 service
# 命令，垫一个转发到 /etc/init.d 的壳，避免逐处修改 fluxion 源码。
mkdir -p package/base-files/files/usr/bin
cat > package/base-files/files/usr/bin/service <<'SH'
#!/bin/sh
[ -x "/etc/init.d/$1" ] && exec /etc/init.d/"$1" "${2:-}"
echo "service: no such init script: $1" >&2
exit 1
SH
chmod +x package/base-files/files/usr/bin/service

# 内核 wext 兼容层（2026-10-20 实测）：25.12 generic config-6.12 把 WIRELESS_EXT
# 关了，CFG80211_WEXT 因依赖被连带隐藏 ⇒ aircrack-osdep 全军覆没（mdk4
# "Can't find wireless tools"、aireplay-ng ioctl(SIOCSIWMODE) failed）。
# mac80211 Makefile 无 WEXT 开关、Config-kernel.in 无通用符号透传，只能直接改
# target 配置种子。两个符号都要开：WEXT_CORE 依赖 WIRELESS_EXT，cfg80211 的
# wext 桥接由 CFG80211_WEXT 提供。
sed -i \
  -e 's|^# CONFIG_WIRELESS_EXT is not set|CONFIG_WIRELESS_EXT=y|' \
  target/linux/generic/config-6.12
grep -q '^CONFIG_CFG80211_WEXT=y' target/linux/generic/config-6.12 || \
  echo 'CONFIG_CFG80211_WEXT=y' >> target/linux/generic/config-6.12

# 自带源码包（官方 feed 已淘汰，配方在仓库 custom-packages/ 下）
rm -rf package/custom
mkdir -p package/custom
cp -af "$GITHUB_WORKSPACE/custom-packages/." package/custom/

# reaver/wash 官方 feed 包补丁：mt76（cfg80211-only）上 WEXT SIOCSIWFREQ 无效
# （内核 WEXT 兼容层已开但 monitor 口换信道仍不生效），信道不跳、wash 内部
# 信道号恒 0，airgeddon WPS 菜单探索/json 扫描因此一条目标都出不来（beacon
# 明明在抓包里）。补丁让 change_channel 在 WEXT 失败时回退 iw(nl80211)。
# 2026-10-29 已在 t7 热修实测：探索/-2 -5/--scan -j 三条路径均正常出目标。
mkdir -p feeds/packages/net/reaver/patches
cp -af "$GITHUB_WORKSPACE/custom-packages/reaver/patches/001-wext-iw-fallback-mt76.patch" \
  feeds/packages/net/reaver/patches/

# fluxion 依赖检查兜底 stub（只在依赖清单出现，攻击代码从不真正调用）：
#   rfkill —— mt76 没有 rfkill 设备，unblock all 本来就是 no-op，返回 0 即可
#   7zr    —— 仅 fluxion 的"更新安装器"用于打包备份，攻击流程不碰，触发即报错
#   dsniff —— 仅在依赖清单存在，源码中无任何调用点，触发即报错
cat > package/base-files/files/usr/bin/rfkill <<'SH'
#!/bin/sh
# stub: mt76 radios expose no rfkill devices; unblock is a no-op
exit 0
SH
for stub in 7zr dsniff; do
cat > "package/base-files/files/usr/bin/$stub" <<SH
#!/bin/sh
echo "$stub: not required by the evil-twin workflow" >&2
exit 1
SH
done
chmod +x package/base-files/files/usr/bin/rfkill \
         package/base-files/files/usr/bin/7zr \
         package/base-files/files/usr/bin/dsniff

# dnsspoof 垫片（2026-10-20 实攻翻车）：fluxion Captive Portal 的"DNS 服务"
# 就是 `dnsspoof -i <if> -f hosts`（attack.sh:2062）——当年 stub 掉 dsniff 的
# 理由（"仅依赖清单存在、源码无调用点"）是错的。dsniff 包 25.12 feed 里
# 已彻底消失（master 都没有），用固件自带的 dnsmasq-full 等效替代：
# 取 hosts 文件里的通配/首个地址做 address=/#/ 黑洞应答。
# 注意 address=/#/ 的 # 过双层 shell 会被吞，必须走配置文件。
mkdir -p package/base-files/files/usr/bin
cat > package/base-files/files/usr/bin/dnsspoof <<'SH'
#!/bin/sh
# dnsspoof shim: dsniff (and thus dnsspoof) is not packaged in 25.12.
# Emulates `dnsspoof [-i iface] [-f hostsfile]`: answers every query with
# the first spoofed address in the hosts file (a wildcard entry wins),
# falling back to the interface address. Backed by dnsmasq's catch-all
# `address=/#/`; runs in the foreground so the caller's process-group
# cleanup (tmux window kill) reaps it.
iface=""
hosts=""
while getopts "i:f:c:p:" o; do
	case "$o" in
	i) iface="$OPTARG" ;;
	f) hosts="$OPTARG" ;;
	esac
done
ip=$(awk '$1 !~ /^#/ && $2 ~ /^\*/ {print $1; exit}' "$hosts" 2>/dev/null)
[ -n "$ip" ] || ip=$(awk '$1 !~ /^#/ {print $1; exit}' "$hosts" 2>/dev/null)
[ -n "$ip" ] || ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet /{split($2,a,"/");print a[1];exit}')
[ -n "$ip" ] || ip="127.0.0.1"
conf="/tmp/dnsspoof.$$.conf"
{
	echo "no-resolv"
	echo "no-hosts"
	echo "address=/#/$ip"
} > "$conf"
exec dnsmasq --keep-in-foreground \
	--conf-file="$conf" --port=53 --listen-address="$ip" \
	--bind-interfaces --pid-file="/tmp/dnsspoof.$$.pid" \
	--log-facility="/tmp/dnsspoof.$$.log"
SH
chmod +x package/base-files/files/usr/bin/dnsspoof

# airmon-ng：airgeddon 必需项。feed 里的 airmon-ng 子包依赖已淘汰的
# wireless-tools（25.12 feed 已无此包）装不上；它只是个脚本，直接从
# aircrack-ng 官方仓库按 tag 取（1.7，与固件内 aircrack-ng 版本一致）。
mkdir -p package/base-files/files/usr/sbin
curl -fsSL https://raw.githubusercontent.com/aircrack-ng/aircrack-ng/1.7/scripts/airmon-ng.linux \
  -o package/base-files/files/usr/sbin/airmon-ng
chmod +x package/base-files/files/usr/sbin/airmon-ng

# Web 层固化（Action-237 run 38742302041 实刷 LuCI 403 教训）：
#  1) lighttpd（captive portal 用）默认自启抢 IPv4:80 → 浏览器 403 是它发的；
#     攻击时 fluxion/airgeddon 会自行 start，平时禁用自启即可。
#  2) ucode 版 LuCI 需 uhttpd 的 ucode_prefix 派发 /cgi-bin/luci，清掉指向
#     不存在 Lua SGI 的残留 lua_prefix。
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-evil-twin-web <<'SH'
#!/bin/sh
/etc/init.d/lighttpd disable
# php8 包默认 doc_root="/www"，而 fluxion 门户的 docroot 在 /tmp/fluxspace；
# 不清掉则门户每个 PHP 页面都回 "No input file specified."（2026-10-20 实测）
sed -i 's|^doc_root = .*|doc_root =|' /etc/php.ini
uci -q delete uhttpd.main.lua_prefix
uci -q add_list uhttpd.main.ucode_prefix='/cgi-bin/luci=/usr/share/ucode/luci/uhttpd.uc'
uci -q commit uhttpd
exit 0
SH
chmod +x package/base-files/files/etc/uci-defaults/99-evil-twin-web

# 无线默认态（2026-10-18 实战）：出厂 radio 是 master mode（AP），airgeddon 只认
# Managed/Monitor、fluxion 按 USB 网卡思路处理内建 radio，两者都无法把 AP 口转
# monitor；monitor 口由 evil-twin-mon 包在开机/热插拔/工具进出场时自动挂好。
# 默认关掉 radio（LuCI 可随时开回），让固件一刷完就处于"可直接选 mon 口开打"的状态。
cat > package/base-files/files/etc/uci-defaults/99-evil-twin-radio <<'SH'
#!/bin/sh
uci -q set wireless.radio0.disabled='1'
uci -q set wireless.radio1.disabled='1'
uci -q commit wireless
exit 0
SH
chmod +x package/base-files/files/etc/uci-defaults/99-evil-twin-radio

# 终端 UTF-8（2026-10-18 实战）：LANG 空导致 tmux 客户端按非 UTF-8 渲染，
# 中文菜单/中文 SSID 逐字节变下划线（实测 4 个汉字→8 个 _）。musl 原生支持
# C.UTF-8，登录 shell 走 /etc/profile → profile.d。
mkdir -p package/base-files/files/etc/profile.d
cat > package/base-files/files/etc/profile.d/99-utf8.sh <<'SH'
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
SH
chmod +x package/base-files/files/etc/profile.d/99-utf8.sh
