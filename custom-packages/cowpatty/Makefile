#
# joswr1ght/cowpatty（原作者 Josh Wright 的仓库）。
# 上游 Makefile 硬编码 clang 且用 += 追加 CFLAGS/LDLIBS，
# 所以命令行整串覆盖 CC/CFLAGS/LDLIBS。
# OpenSSL 3 下 MD5/HMAC 系 API 报 deprecated 警告但不影响编译，压掉即可。
#
include $(TOPDIR)/rules.mk

PKG_NAME:=cowpatty
PKG_VERSION:=4.6
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/joswr1ght/cowpatty.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_VERSION:=0a274975040960d85cd68550facf801fc3a9d7df
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/cowpatty
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+libpcap +libopenssl
  TITLE:=WPA-PSK dictionary attack and handshake verifier
  URL:=https://github.com/joswr1ght/cowpatty
endef

define Package/cowpatty/description
  CoWPAtty: WPA-PSK handshake audit tool (fluxion handshake verify mode).
  Includes genpmk for precomputed hash tables.
endef

MAKE_FLAGS += \
	CC="$(TARGET_CC)" \
	CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -DOPENSSL -Wno-deprecated-declarations -Wno-int-conversion -Wno-return-mismatch -Wno-incompatible-pointer-types -Wno-implicit-function-declaration" \
	LDLIBS="-lpcap -lcrypto"

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) all
endef

define Package/cowpatty/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/cowpatty $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/genpmk $(1)/usr/bin/
endef

$(eval $(call BuildPackage,cowpatty))
