# t7-sec-firmware

Qihoo 360T7（MT7981B）网络安全实验特化固件编译仓库，基于**官方 immortalwrt stable**（默认 `openwrt-25.12` 分支，dispatch 时可传任意 ref）。

## 为什么独立建仓
原仓库（Action-237-immortalwrt-mt798x-24.10）的源码树用 MTK 专有 mt_wifi 驱动
（接口 ra0/rax0，无 cfg80211/radiotap），airmon-ng/airodump-ng/mdk4 无法驱动
板载无线。官方 immortalwrt 的 360T7 走 kmod-mt7915e → mt76 → mac80211，
monitor/radiotap/hostapd-nl80211 原生可用。

## 使用
- Actions → Build 360T7 Evil-Twin Sec Firmware → Run workflow
  - `ref` 留空 = 跟随 openwrt-25.12 stable 点版本；填 tag（如 v25.12.2）钉死
- 产物在 Release（`*.squashfs-sysupgrade.itb`）

## 内容
- `evil-twin.config`：手写精简 seed（只列非默认项）
- `custom-packages/`：官方 feed 淘汰包的自写配方（mdk4/cowpatty/ettercap/fluxion/airgeddon）
- `diy-part2-sec.sh`：service 壳、stub、airmon-ng、uci-defaults（LuCI 403 修复）
- 无 passwall/mwan3；保留 zerotier

## 刷机
跨自 mt798x-SDK 固件时 sysupgrade 会拒收（board 元数据不同），用 uboot 恢复模式强刷或 `sysupgrade -F`。
