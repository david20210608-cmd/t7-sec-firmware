#
# Fluxion 6.38（FluxionNetwork/fluxion master f064d246；上游自 v6.32 起不再打
# tag，版本号只在主线递进，N1 侧同源）。纯脚本树，免编译：整棵装
# /usr/share/fluxion，/usr/bin/fluxion 是 wrapper（进出场挂 evil-twin-mon 的
# monitor 口保障）。运行时写自己目录（握手 .cap、iptables 备份、
# preferences.conf）——OpenWrt overlayfs copy-up 落到 rootfs_data，直接可用。
#
include $(TOPDIR)/rules.mk

PKG_NAME:=fluxion
PKG_VERSION:=6.38
PKG_RELEASE:=7

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/FluxionNetwork/fluxion.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_VERSION:=f064d246a020a50fa4ded8cd440427e30c7a3818
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/fluxion
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+bash +evil-twin-mon
  TITLE:=Wireless security auditing and evil twin attack suite
  URL:=https://github.com/FluxionNetwork/fluxion
endef

define Package/fluxion/description
  Fluxion 6.38: evil twin attack suite (captive portal phishing).
  Dependencies (aircrack-ng/cowpatty/kea/lighttpd/php8-cgi/mdk4 等) 由本固件
  其余包提供；7zr/dsniff/rfkill 为固件内 stub（攻击流程不调用）。
endef

# busybox grep 无 PCRE：patches/002 覆盖无空格路径的 3 个文件；这两个
# attack.sh 路径带空格，GNU patch/quilt 的 -p1 头部解析吃不下，改构建期 sed。
# 刻意用 cut 而非 awk 取字段——替换文本里不能有 $（会被 make/shell 展开吃掉）
define Build/Prepare
	$(call Build/Prepare/Default)
	$(SED) "s#grep -oP 'type \\\\K\\\\w+'#grep -oE 'type [a-zA-Z0-9]+' | cut -d' ' -f2#" '$(PKG_BUILD_DIR)/attacks/Captive Portal/attack.sh'
	$(SED) "s#grep -oP 'type \\\\K\\\\w+'#grep -oE 'type [a-zA-Z0-9]+' | cut -d' ' -f2#" '$(PKG_BUILD_DIR)/attacks/Handshake Snooper/attack.sh'
	# t7: Handshake Snooper 加 hcxpcapngtool 验证器（SAE/WPA3 可判）+ PMF 提示。
	# sed 程序含 $，define 体经 eval/call 双重展开（$$ -> $ 再被当变量展开为空、
	# 行尾 $ 锚+分隔符 $@/$# 被吃），70e56b4 首编即死于 unterminated s command
	# ——必须放脚本文件，脚本内容不经过 make 展开。
	sh ./files/patch-handshake-snooper.sh '$(PKG_BUILD_DIR)'
endef

define Build/Compile
endef

define Package/fluxion/install
	$(INSTALL_DIR) $(1)/usr/share/fluxion $(1)/usr/bin
	# .pkgdir 在 PKG_BUILD_DIR 里，cp . 会"拷进自己"（cp: cannot copy a directory
	# into itself），改 tar 管道并排除构建戳与 ipkg 打包暂存（2026-10-21 发现设备
	# /usr/share/fluxion/ipkg-aarch64_cortex-a53/ 是这份残留）
	(cd $(PKG_BUILD_DIR) && tar --exclude=./.pkgdir --exclude=./*.pkgdir --exclude='./ipkg-*' --exclude='.prepared*' --exclude='.configured*' --exclude='.built*' -cf - .) | (cd $(1)/usr/share/fluxion && tar -xf -)
	# wrapper 而非 symlink：进出场时挂 evil-twin-mon 的 monitor 口保障
	$(INSTALL_BIN) ./files/fluxion $(1)/usr/bin/
	# Handshake Snooper 的 PMF 检测助手（由构建期 sed 注入 arbiter 调用）
	$(INSTALL_BIN) ./files/pmf-detect $(1)/usr/bin/
endef

$(eval $(call BuildPackage,fluxion))
