#!/bin/bash
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2024-2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	You should have received a copy of the GNU General Public License
#	along with OrangeFox.  If not, see <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

fetch_mt6789_common_repo() {
	local URL=https://github.com/ramabondanp/twrp-device_transsion_mt6789-common.git
	local common="$1/device/transsion/mt6789-common"
	if [ ! -d "$common" ]; then
		echo "Cloning $URL ... to $common"
		git clone "$URL" -b twrp-16.0-tos16 "$common" || return 1
	else
		echo "Device common repository: \"$common\" found ..."
	fi
	if [ ! -e "$common/.git" ]; then
		echo "ERROR: $common is not a Git checkout." >&2
		return 1
	fi
	local branch
	branch=$(git -C "$common" branch --show-current) || return 1
	if [ "$branch" != twrp-16.0-tos16 ]; then
		echo "ERROR: Common tree must be on twrp-16.0-tos16 (found: ${branch:-detached HEAD})." >&2
		return 1
	fi
}

apply_X6886_patch() {
	local tree="$1"
	local patch="$2"
	if git -C "$tree" apply --reverse --check "$patch" >/dev/null 2>&1; then
		echo "Already applied: $(basename "$patch")"
	elif git -C "$tree" apply --check "$patch"; then
		git -C "$tree" apply "$patch" || return 1
		echo "Applied: $(basename "$patch")"
	else
		echo "ERROR: Cannot apply $patch to $tree; resolve the conflict first." >&2
		return 1
	fi
}

detect_X6886_recovery() {
	local root="$1"
	if [ ! -d "$root/bootable/recovery" ]; then
		echo "ERROR: bootable/recovery is missing; sync a TWRP-Test or AERA manifest first." >&2
		return 1
	fi
	if [ -f "$root/bootable/recovery/aera_config.mk" ] && [ -f "$root/bootable/recovery/aera_build.mk" ]; then
		echo aera
	elif [ -f "$root/bootable/recovery/twrpminui/events.cpp" ] || [ -f "$root/bootable/recovery/Android.bp" ]; then
		echo twrp
	else
		echo "ERROR: Unsupported bootable/recovery core; expected TWRP-Test twrp-16.0 or AERA aera-16.0." >&2
		return 1
	fi
}

export_X6886_aera_env() {
	# These shell exports are captured by AERA's printconfig into
	# /tmp/X6886/fox_env.sh and consumed by vendor/recovery/AERA_A16.sh.
	# The matching make-side configuration lives in aera.mk.
	export LC_ALL="C"
	export AERA_AB_DEVICE=1
	export AERA_VIRTUAL_AB_DEVICE=1
	export AERA_VANILLA_BUILD=1
	export AERA_PRODUCT_PREFIX=AERA
	export AERA_BUILD_STATUS=Unofficial
	export AERA_BUILD_TYPE=Alpha
	export AERA_NO_REFLASH_CURRENT_RECOVERY=1
	export AERA_INCLUDE_REPACKTOOLS=false
	export AERA_DISABLE_UPDATEZIP=1
	export AERA_USE_UPDATED_MAGISKBOOT=0
	export AERA_USE_TAR_BINARY=1
	export AERA_USE_SED_BINARY=1
	export AERA_USE_GREP_BINARY=1
	export AERA_USE_LZ4_BINARY=1
	export AERA_USE_ZSTD_BINARY=1
	export AERA_USE_DATE_BINARY=1
	export AERA_USE_XZ_UTILS=1
	export AERA_SETTINGS_ROOT_DIRECTORY=/data/recovery
	export AERA_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard
	export TARGET_DEVICE_ALT="Infinix-X6886"
	export AERA_TARGET_DEVICES="$TARGET_DEVICE_ALT"
	unset AERA_MAINTAINER_PATCH_VERSION
}

setup_X6886() {
	local root
	root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) || return 1

	# Clone to fix build on minimal manifest
	if [ ! -d "$root/external/gflags" ]; then
		git clone https://android.googlesource.com/platform/external/gflags/ -b android-12.1.0_r4 "$root/external/gflags" || return 1
	else
		echo "Dependency: \"external/gflags\" found ..."
	fi

	# mt6789-common
	fetch_mt6789_common_repo "$root" || return 1

	local flavor
	flavor=$(detect_X6886_recovery "$root") || return 1
	echo "X6886 recovery core: $flavor"

	local device="$root/device/infinix/Infinix-X6886"
	local common="$root/device/transsion/mt6789-common"
	if [ "$flavor" = aera ]; then
		export_X6886_aera_env
		# AERA-specific ports of the device haptics and common storage/repack
		# patches. The TWRP patches do not apply to AERA's minuitwrp/native UI.
		apply_X6886_patch "$root/bootable/recovery" \
			"$device/patches/aera/0001-minuitwrp-Probe-X6886-sysfs-haptics.patch" || return 1
		apply_X6886_patch "$root/bootable/recovery" \
			"$device/patches/aera/0002-Signal-storage-readiness-before-TEE-consumers.patch" || return 1
		apply_X6886_patch "$root/bootable/recovery" \
			"$device/patches/aera/0003-Reconcile-X6886-USB-OTG-hotplug-from-uevents.patch" || return 1
		apply_X6886_patch "$root/bootable/recovery" \
			"$device/patches/aera/0004-Respect-disabled-recovery-repacking.patch" || return 1
		apply_X6886_patch "$root/build/make" \
			"$common/patches/0001-Add-zstd-ramdisk-compression.patch" || return 1
	else
		# TWRP-Test baseline.
		apply_X6886_patch "$root/bootable/recovery" \
			"$device/patches/0001-Change-haptics-activation-file-path.patch" || return 1
		apply_X6886_patch "$root/bootable/recovery" \
			"$common/patches/0003-Refresh-removable-partitions-after-uevent.patch" || return 1
		apply_X6886_patch "$root/bootable/recovery" \
			"$common/patches/0002-Respect-disabled-repacking.patch" || return 1
		apply_X6886_patch "$root/build/make" \
			"$common/patches/0001-Add-zstd-ramdisk-compression.patch" || return 1
	fi
	echo "OK: All patched ($flavor)"
}

setup_X6886
