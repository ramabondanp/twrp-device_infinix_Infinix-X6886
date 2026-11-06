#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# AERA Recovery vendor product defaults (AERA manifest only). The TWRP-Test
# manifest builds this product without inheriting vendor/twrp/config/common.mk.
ifneq ($(wildcard bootable/recovery/aera_config.mk),)
$(call inherit-product, vendor/twrp/config/common.mk)
endif

# Inherit from Infinix-X6886 device
$(call inherit-product, device/infinix/Infinix-X6886/device.mk)

# Product Specifics
PRODUCT_NAME := twrp_X6886
PRODUCT_DEVICE := Infinix-X6886
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6886
PRODUCT_MANUFACTURER := INFINIX
