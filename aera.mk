#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# AERA Recovery board configuration for Infinix X6886.
#
# Included from BoardConfig.mk only when the synced recovery core is AERA
# (bootable/recovery/aera_config.mk exists). AERA translates these public
# AERA_* names into its TWRP/OrangeFox backend variables after BoardConfig is
# read. The TWRP manifest keeps using the common TW_* configuration unchanged.

# Build identity. This is an unvalidated bring-up port, not an official release.
AERA_BUILD_STATUS := Unofficial
AERA_BUILD_TYPE := Alpha
AERA_PRODUCT_PREFIX := AERA
AERA_DEVICE_VERSION := X6886_AERA

# Virtual A/B with recovery resources in the header-v4 vendor_boot PLATFORM
# ramdisk. Do not enable AERA_VENDOR_BOOT_RECOVERY: that experimental switch
# forces legacy vAB installer compensation and is not this device's layout.
AERA_AB_DEVICE := 1
AERA_VIRTUAL_AB_DEVICE := 1
AERA_VANILLA_BUILD := 1

# X6886's zstd PLATFORM ramdisk plus empty RECOVERY fragment is not something
# the bundled recovery.cpio repacker can rewrite. Keep repack/reflash and the
# recovery ZIP installer unavailable.
AERA_NO_REFLASH_CURRENT_RECOVERY := 1
AERA_INCLUDE_REPACKTOOLS := false
AERA_INCLUDE_RECOVERY_INJECTION := false
# aera_build.mk tests OF_SKIP_ORANGEFOX_PROCESS against 1, not "true".
AERA_SKIP_LEGACY_PATCH_PROCESS := 1

# Crypto: preserve the common mt6789 FBE/metadata configuration. AERA requires
# a default keymaster version whenever TW_FORCE_KEYMASTER_VER is inherited.
AERA_INCLUDE_CRYPTO := true
AERA_INCLUDE_CRYPTO_FBE := true
AERA_INCLUDE_FBE_METADATA_DECRYPT := true
AERA_USE_FSCRYPT_POLICY := 2
AERA_DEFAULT_KEYMASTER_VERSION := 4.1

# Recovery tools and services carried over from the TWRP baseline.
AERA_INCLUDE_FASTBOOTD := true
AERA_INCLUDE_LOGCAT := true
AERA_INCLUDE_NTFS_3G := true
AERA_INCLUDE_RESETPROP := true
AERA_INCLUDE_LIBRESETPROP := true
AERA_INCLUDE_LPTOOLS := true
AERA_USE_TOOLBOX := true
# aera_build.mk derives TW_USE_DMCTL only when OF_USE_DMCTL equals 1.
AERA_USE_DMCTL := 1
AERA_ENABLE_FS_COMPRESSION := false
AERA_EXCLUDE_APEX := true

# The common tree supplies the configfs init.recovery.usb.rc; AERA's generic
# android0 USB rc would conflict with it.
AERA_EXCLUDE_DEFAULT_USB_INIT := true

# Native AERA UI: 1080x2400 AMOLED. AERA_SCREEN_H uses the 1080-wide reference
# coordinate space and is scaled to the native framebuffer by adaptive mode.
AERA_UI_ADAPTIVE_RESOLUTION := true
AERA_SCREEN_H := 2400
AERA_STATUS_H := 124
AERA_STATUS_INDENT_LEFT := 54
AERA_STATUS_INDENT_RIGHT := 54
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2400
AERA_DEFAULT_BRIGHTNESS := 2047
AERA_MAX_BRIGHTNESS := 4095
AERA_FRAMERATE := 120
AERA_DEFAULT_LANGUAGE := en

# Haptics are sysfs LED class devices on X6886 (vibrator_single, vibrator
# duration/activate, or regulator-vibrator brightness). The AERA minuitwrp
# patch probes those first; do not force the evdev force-feedback-only path.
AERA_SUPPORT_INPUT_FF_HAPTICS := false

# Settings/log locations used by the AERA vendor packaging script.
AERA_SETTINGS_ROOT_DIRECTORY := /data/recovery
AERA_MISCELLANEOUS_ROOT_DIRECTORY := /sdcard
