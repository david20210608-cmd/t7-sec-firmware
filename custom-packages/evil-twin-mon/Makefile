#
# evil-twin-mon: monitor-interface lifecycle for fluxion/airgeddon on mt76.
# One mon<N> (monitor type) per phy<N>, provisioned by ieee80211 hotplug and
# re-ensured by the airgeddon/fluxion wrappers after their exit cleanup resets
# interfaces to managed. Also ships the tput shim (nothing else provides it).
#
include $(TOPDIR)/rules.mk

PKG_NAME:=evil-twin-mon
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/evil-twin-mon
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Wireless
  DEPENDS:=+iw
  TITLE:=Keep monitor-mode mon interfaces alive for fluxion/airgeddon
endef

define Package/evil-twin-mon/description
  Provisions mon0/mon1 (monitor type) on every wifi phy via hotplug, so
  fluxion/airgeddon always have a usable monitor interface regardless of the
  AP/master state netifd keeps on the radios. Also provides a minimal tput
  shim (fluxion needs it; no OpenWrt package ships the binary).
endef

define Build/Compile
endef

define Package/evil-twin-mon/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/hotplug.d/ieee80211
	$(INSTALL_BIN) ./files/usr/bin/evil-twin-mon $(1)/usr/bin/
	$(INSTALL_BIN) ./files/usr/bin/tput $(1)/usr/bin/
	$(INSTALL_DATA) ./files/etc/hotplug.d/ieee80211/30-evil-twin-mon $(1)/etc/hotplug.d/ieee80211/
endef

$(eval $(call BuildPackage,evil-twin-mon))
