#
# 基于 syb999/openwrt-24.10.0 的成熟配方（已适配 24.10 官方源）：
#   - 去掉 +libpcre（pcre1 已被 24.10 淘汰；mdk4 的 pcre 支持是可选的，
#     不传 pcre=true 即关闭，只影响 ESSID 正则过滤）
#   - 去掉 +airmon-ng（OpenWrt 用 iw 管 monitor，无需 aircrack 的脚本）
#
include $(TOPDIR)/rules.mk

PKG_NAME:=mdk4
PKG_VERSION:=4.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/aircrack-ng/mdk4.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE).tar.gz
PKG_SOURCE_VERSION:=e94422ce8e4b8dcd132d658345814df7e63bfa41
PKG_HASH=311a4b9f011240a80181815b6a6ca8e9c12ae5b5ed43a508e58d4e6a7fbcdee3
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/mdk4
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+libpthread +libpcap +libnl +libnl-genl
  TITLE:=Tool to exploit wireless vulnerabilities
  URL:=https://github.com/aircrack-ng/mdk4
endef

define Package/mdk4/description
  Tool to exploit wireless vulnerabilities (deauth, beacon flooding, etc).
endef

IGNORE_WARNINGS:= \
	-Wno-implicit-function-declaration \
	-Wno-unused-function \
	-Wno-unused-variable \
	-Wno-unused-parameter \
	-Wno-pointer-sign

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/libnl3 \
	-DCONFIG_LIBNL30 \
	-D_FILE_OFFSET_BITS=64 \
	-D_REVISION=mdk4-v1 \
	-W -Wall -O3

TARGET_LDFLAGS:= \
	-Wl,--gc-sections -lnl

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/ \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		CC="$(TARGET_CC)"
endef

define Package/mdk4/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/mdk4 $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,mdk4))
