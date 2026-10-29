#
# Airgeddon v12.02 官方 release（v1s1t0r1sh3r3/airgeddon tag v12.02）。
# 纯脚本树，免编译：整棵装 /usr/share/airgeddon。
# /usr/bin/airgeddon 是 wrapper：路由器无 xterm，强制 tmux 窗口模式
# （AIRGEDDON_WINDOWS_HANDLING=tmux，tmux 已在固件内）。
#
include $(TOPDIR)/rules.mk

PKG_NAME:=airgeddon
PKG_VERSION:=12.02
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/v1s1t0r1sh3r3/airgeddon.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_VERSION:=700ad7d63df04e565bcd14d2aec6f935fcec5185
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/airgeddon
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+bash +gawk +tmux +evil-twin-mon
  TITLE:=Multi-use bash script for Linux wireless audits
  URL:=https://github.com/v1s1t0r1sh3r3/airgeddon
endef

define Package/airgeddon/description
  Airgeddon v12.02: wireless security auditing (evil twin, PMKID, WPS).
  依赖全部由固件提供；缺 crunch/hashcat/john/tshark（离线破解/分析，路由器
  CPU 无意义）、bully/bettercap/beef/hostapd-wpe/asleap（有意不打包）。
endef

define Build/Compile
endef

define Package/airgeddon/install
	$(INSTALL_DIR) $(1)/usr/share/airgeddon $(1)/usr/bin
	# .pkgdir 在 PKG_BUILD_DIR 里，cp . 会"拷进自己"（cp: cannot copy a directory
	# into itself），改 tar 管道并排除构建戳
	(cd $(PKG_BUILD_DIR) && tar --exclude=./.pkgdir --exclude='.prepared*' --exclude='.configured*' --exclude='.built*' -cf - .) | (cd $(1)/usr/share/airgeddon && tar -xf -)
	$(INSTALL_BIN) ./files/airgeddon $(1)/usr/bin/
endef

$(eval $(call BuildPackage,airgeddon))
