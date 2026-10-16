#
# Fluxion v6.32 官方 release（FluxionNetwork/fluxion tag v6.32）。
# 纯脚本树，免编译：整棵装 /usr/share/fluxion，/usr/bin/fluxion 符号链接。
# v6.32 无 X11 显示时自动回退 tmux 模式（headless 路由器即 tmux），无需 wrapper。
# 运行时写自己目录（握手 .cap、iptables 备份、preferences.conf）——
# OpenWrt overlayfs copy-up 落到 rootfs_data，直接可用；sysupgrade 会清。
#
include $(TOPDIR)/rules.mk

PKG_NAME:=fluxion
PKG_VERSION:=6.32
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/FluxionNetwork/fluxion.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_VERSION:=18d6c9e555dd87cd1eec53ebdbbf47a934a23a8c
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/fluxion
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+bash
  TITLE:=Wireless security auditing and evil twin attack suite
  URL:=https://github.com/FluxionNetwork/fluxion
endef

define Package/fluxion/description
  Fluxion v6.32: evil twin attack suite (captive portal phishing).
  Dependencies (aircrack-ng/cowpatty/kea/lighttpd/php8-cgi/mdk4 等) 由本固件
  其余包提供；7zr/dsniff/rfkill 为固件内 stub（攻击流程不调用）。
endef

define Build/Compile
endef

define Package/fluxion/install
	$(INSTALL_DIR) $(1)/usr/share/fluxion $(1)/usr/bin
	# .pkgdir 在 PKG_BUILD_DIR 里，cp . 会"拷进自己"（cp: cannot copy a directory
	# into itself），改 tar 管道并排除构建戳
	(cd $(PKG_BUILD_DIR) && tar --exclude=./.pkgdir --exclude='.prepared*' --exclude='.configured*' --exclude='.built*' -cf - .) | (cd $(1)/usr/share/fluxion && tar -xf -)
	$(LN) /usr/share/fluxion/fluxion.sh $(1)/usr/bin/fluxion
endef

$(eval $(call BuildPackage,fluxion))
