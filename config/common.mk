SPICEOSspiceosSpiceOS# Allow vendor/extra to override any property by setting it first
$(call inherit-product-if-exists, vendor/extra/product.mk)

PRODUCT_BRAND ?= SpiceOS

PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

ifeq ($(TARGET_BUILD_VARIANT),eng)
# Disable ADB authentication
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.adb.secure=0
else
# Enable ADB authentication
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.adb.secure=1

# Disable extra StrictMode features on all non-engineering builds
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.strictmode.disable=true
endif

# Backup Tool
PRODUCT_COPY_FILES += \
    vendor/spiceos/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/spiceos/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions \
    vendor/spiceos/prebuilt/common/bin/50-lineage.sh:$(TARGET_COPY_OUT_SYSTEM)/addon.d/50-lineage.sh

ifneq ($(strip $(AB_OTA_PARTITIONS) $(AB_OTA_POSTINSTALL_CONFIG)),)
PRODUCT_COPY_FILES += \
    vendor/spiceos/prebuilt/common/bin/backuptool_ab.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/backuptool_ab.sh \
    vendor/spiceos/prebuilt/common/bin/backuptool_ab.functions:$(TARGET_COPY_OUT_SYSTEM)/bin/backuptool_ab.functions \
    vendor/spiceos/prebuilt/common/bin/backuptool_postinstall.sh:$(TARGET_COPY_OUT_SYSTEM)/bin/backuptool_postinstall.sh
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.ota.allow_downgrade=true
endif
endif

# Backup Services whitelist
PRODUCT_COPY_FILES += \
    vendor/spiceos/config/permissions/backup.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/sysconfig/backup.xml

# Copy all Lineage-specific init rc files
$(foreach f,$(wildcard vendor/spiceos/prebuilt/common/etc/init/*.rc),\
	$(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_SYSTEM)/etc/init/$(notdir $f)))

# Enable Android Beam on all targets
PRODUCT_COPY_FILES += \
    vendor/spiceos/config/permissions/android.software.nfc.beam.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.software.nfc.beam.xml

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.software.sip.voip.xml

# Enable wireless Xbox 360 controller support
PRODUCT_COPY_FILES += \
    frameworks/base/data/keyboards/Vendor_045e_Product_028e.kl:$(TARGET_COPY_OUT_SYSTEM)/usr/keylayout/Vendor_045e_Product_0719.kl

# Enforce privapp-permissions whitelist
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.control_privapp_permissions=enforce

# Include AOSP audio files
include vendor/spiceos/config/aosp_audio.mk

# TWRP
ifeq ($(WITH_TWRP),true)
include vendor/spiceos/config/twrp.mk
endif

# Do not include art debug targets
PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false

# Strip the local variable table and the local variable type table to reduce
# the size of the system image. This has no bearing on stack traces, but will
# leave less information available via JDWP.
PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true

# Disable vendor restrictions
PRODUCT_RESTRICT_VENDOR_FILES := false

# Bootanimation
TARGET_SCREEN_WIDTH ?= 1080
TARGET_SCREEN_HEIGHT ?= 1920
PRODUCT_PACKAGES += \
    bootanimation.zip

# AOSP packages
PRODUCT_PACKAGES += \
    Terminal

# SpiceOS packages
PRODUCT_PACKAGES += \
    SpiceOSParts \
    SpiceOSSettingsProvider \
    SpiceOSSetupWizard \
    Updater

# Themes
PRODUCT_PACKAGES += \
    SpiceOSThemesStub \
    ThemePicker

# Config
PRODUCT_PACKAGES += \
    SimpleDeviceConfig

# Extra tools in SpiceOS
PRODUCT_PACKAGES += \
    7z \
    bash \
    curl \
    getcap \
    htop \
    lib7z \
    libsepol \
    nano \
    pigz \
    setcap \
    unrar \
    vim \
    wget \
    zip

# Filesystems tools
PRODUCT_PACKAGES += \
    fsck.ntfs \
    mke2fs \
    mkfs.ntfs \
    mount.ntfs

# Openssh
PRODUCT_PACKAGES += \
    scp \
    sftp \
    ssh \
    sshd \
    sshd_config \
    ssh-keygen \
    start-ssh

# rsync
PRODUCT_PACKAGES += \
    rsync

# Storage manager
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.storage_manager.enabled=true

# These packages are excluded from user builds
PRODUCT_PACKAGES_DEBUG += \
    procmem

# Root
PRODUCT_PACKAGES += \
    adb_root
ifneq ($(TARGET_BUILD_VARIANT),user)
ifeq ($(WITH_SU),true)
PRODUCT_PACKAGES += \
    su
endif
endif

# Dex preopt
PRODUCT_DEXPREOPT_SPEED_APPS += \
    SystemUI

PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += vendor/spiceos/overlay
PRODUCT_PACKAGE_OVERLAYS += vendor/spiceos/overlay/common

PRODUCT_VERSION_MAJOR = 4
PRODUCT_VERSION_MINOR = 0
SPICEOS_EDITION := ALPHA

# Set SPICEOS_BUILDTYPE from the env RELEASE_TYPE, for jenkins compat

ifndef SPICEOS_BUILDTYPE
    ifdef RELEASE_TYPE
        # Starting with "SPICEOS_" is optional
        RELEASE_TYPE := $(shell echo $(RELEASE_TYPE) | sed -e 's|^SPICEOS_||g')
        SPICEOS_BUILDTYPE := $(RELEASE_TYPE)
    endif
endif

# Filter out random types, so it'll reset to UNOFFICIAL
ifeq ($(filter RELEASE NIGHTLY SNAPSHOT EXPERIMENTAL,$(SPICEOS_BUILDTYPE)),)
    SPICEOS_BUILDTYPE :=
endif

ifndef SPICEOS_BUILDTYPE
# If SPICEOS_BUILDTYPE is not defined, set to UNOFFICIAL
    SPICEOS_BUILDTYPE := UNOFFICIAL
endif

ifeq ($(SPICEOS_BUILDTYPE), UNOFFICIAL , OFFICIAL)
    # Enforce time of day appending on CI builds
    SPICEOS_VERSION_APPEND_TIME_OF_DAY := true
endif

ifeq ($(SPICEOS_VERSION_APPEND_TIME_OF_DAY),true)
    SPICEOS_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(SPICEOS_EDITION)-$(SPICEOS_BUILDTYPE)-$(SPICEOS_BUILD)-$(shell date -u +%Y%m%d_%H%M%S)
endif

PRODUCT_EXTRA_RECOVERY_KEYS += \
    vendor/spiceos/build/target/product/security/lineage

-include vendor/lineage-priv/keys/keys.mk

SPICEOS_DISPLAY_VERSION := $(SPICEOS_VERSION)

-include $(WORKSPACE)/build_env/image-auto-bits.mk
-include vendor/spiceos/config/partner_gms.mk
