#
# Ettercap 0.8.4.1（airgeddon et_sniffing 模式必需 ettercap + etterlog）。
# 上游无 OpenWrt 配方；0.8.x 走 cmake。要点：
#   - PCRE2 可选（找不到自动跳过），24.10 的 libpcre2 可直连
#   - FindLIBNET 在 staging 的 /usr/include/libnet.h 直接命中（libnet 1.3 布局）
#   - 上游 CMakeLists 要求 cmake>=3.25，ubuntu-22.04 runner 只有 3.22，
#     用补丁降到 3.16（项目未用 3.25 专属特性）
#   - 关 curses/GTK：airgeddon 只用文本模式 (-Tq)，可免掉 ncurses/panel/menu 依赖
#   - BUNDLED_LIBS=OFF：禁止回退到 bundled_deps，缺依赖时直接报错暴露问题
#   - 源内构建下 utils/etterfilter、utils/etterlog 输出路径与同名源码子目录
#     撞车（ld: Is a directory），把可执行文件统一输出到 $(PKG_BUILD_DIR)/bin；
#     install(TARGETS) 的 DESTINATION 不受影响，安装布局不变
#   - 运行必需两个库：libettercap.so 和 libettercap-ui.so（文本界面，目标名
#     ec_interfaces），install 段用 libettercap*.so* 一起带上，缺一个 ettercap
#     二进制就起不来
#
include $(TOPDIR)/rules.mk

PKG_NAME:=ettercap
PKG_VERSION:=0.8.4.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Ettercap/ettercap.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_VERSION:=0dc8409779f3a09cbfff4434b9a4d7b33480d88d
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ettercap
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+libpcap +libnet-1.2.x +libopenssl +zlib +libpthread +libpcre2
  TITLE:=Multipurpose sniffer/interceptor/logger for LAN
  URL:=https://www.ettercap-project.org
endef

define Package/ettercap/description
  Ettercap: MITM sniffer for LAN man-in-the-middle attacks.
  Airgeddon et_sniffing mode requires the ettercap and etterlog binaries.
endef

CMAKE_OPTIONS += \
	-DENABLE_CURSES=OFF \
	-DENABLE_GTK=OFF \
	-DENABLE_PLUGINS=OFF \
	-DENABLE_GEOIP=OFF \
	-DENABLE_LUA=OFF \
	-DENABLE_TESTS=OFF \
	-DENABLE_IPV6=OFF \
	-DINSTALL_DESKTOP=OFF \
	-DLIBRARY_BUILD=OFF \
	-DSYSTEM_LIBS=ON \
	-DBUNDLED_LIBS=OFF \
	-DINSTALL_SYSCONFDIR=/etc \
	-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$(PKG_BUILD_DIR)/bin \
	-DCMAKE_C_FLAGS="$(TARGET_CFLAGS) -Wno-int-conversion -Wno-return-mismatch -Wno-incompatible-pointer-types -Wno-implicit-function-declaration"

define Package/ettercap/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/lib $(1)/etc/ettercap $(1)/usr/share/ettercap
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ettercap $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/etterlog $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/etterfilter $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libettercap*.so* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/etc/ettercap/. $(1)/etc/ettercap/
	$(CP) $(PKG_INSTALL_DIR)/usr/share/ettercap/. $(1)/usr/share/ettercap/
endef

$(eval $(call BuildPackage,ettercap))
