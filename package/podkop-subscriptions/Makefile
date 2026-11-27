include $(TOPDIR)/rules.mk

PKG_NAME:=podkop-subscriptions
PKG_VERSION:=0.1.0
PKG_RELEASE:=3
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/podkop-subscriptions
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Subscription updater for Podkop URLTest
  DEPENDS:=+podkop +sing-box +curl +jq +ca-bundle +flock +coreutils-base64
endef

define Package/podkop-subscriptions/description
Safely updates Podkop's main URLTest links from HTTPS subscriptions.
endef

define Build/Compile
endef

define Package/podkop-subscriptions/conffiles
/etc/config/podkop-subscriptions
endef

define Package/podkop-subscriptions/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/sbin $(1)/usr/libexec/podkop-subscriptions
	$(INSTALL_CONF) ./files/etc/config/podkop-subscriptions $(1)/etc/config/podkop-subscriptions
	$(INSTALL_BIN) ./files/etc/init.d/podkop-subscriptions $(1)/etc/init.d/podkop-subscriptions
	$(INSTALL_BIN) ./files/usr/sbin/podkop-subscriptions $(1)/usr/sbin/podkop-subscriptions
	$(INSTALL_BIN) ./files/usr/libexec/podkop-subscriptions/update $(1)/usr/libexec/podkop-subscriptions/update
endef

define Package/podkop-subscriptions/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || chmod 600 /etc/config/podkop-subscriptions
endef

$(eval $(call BuildPackage,podkop-subscriptions))

