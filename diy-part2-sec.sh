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

# 自带源码包（官方 feed 已淘汰，配方在仓库 custom-packages/ 下）
rm -rf package/custom
mkdir -p package/custom
cp -af "$GITHUB_WORKSPACE/custom-packages/." package/custom/

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
