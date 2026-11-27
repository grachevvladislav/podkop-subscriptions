include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-podkop-subscriptions
PKG_VERSION:=0.1.0
PKG_RELEASE:=3
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-podkop-subscriptions
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI UI for Podkop subscriptions
  DEPENDS:=+podkop-subscriptions +luci-base
endef

define Build/Compile
endef

define Package/luci-app-podkop-subscriptions/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/podkop-subscriptions $(1)/usr/share/luci/menu.d $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/podkop-subscriptions/overview.js $(1)/www/luci-static/resources/view/podkop-subscriptions/overview.js
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-podkop-subscriptions.json $(1)/usr/share/luci/menu.d/luci-app-podkop-subscriptions.json
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-podkop-subscriptions.json $(1)/usr/share/rpcd/acl.d/luci-app-podkop-subscriptions.json
endef

$(eval $(call BuildPackage,luci-app-podkop-subscriptions))

