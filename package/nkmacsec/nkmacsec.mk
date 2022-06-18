NKMACSEC_VERSION = 6b529d405c627edc853da31520344daf13dd8011
NKMACSEC_SITE = $(call github,resiliencetheatre,nk-macsec,$(NKMACSEC_VERSION))
NKMACSEC_DEPENDENCIES = libnitrokey
NKMACSEC_PREFIX = $(TARGET_DIR)/usr

define NKMACSEC_BUILD_CMDS
     $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define NKMACSEC_INSTALL_TARGET_CMDS
        (cd $(@D); cp nk-macsec $(NKMACSEC_PREFIX)/bin)
endef

define NKMACSEC_CLEAN_CMDS
        $(MAKE) $(NKMACSEC_MAKE_OPTS) -C $(@D) clean
endef

$(eval $(generic-package))
