# AERA Recovery port for Infinix X6886

Status: **Alpha / source-level port**. This tree has been adapted to build
against AERA Recovery `aera-16.0`, but the port has **not** been validated by a
full AOSP/AERA sync, a completed `vendorbootimage` build, or hardware testing in
this workspace. Do not treat it as flash-ready.

The hardware-confirmed baseline remains the TWRP-Test `twrp-16.0` build
described in `README.md` and `AGENTS.md`.

## What changed

- `aera.mk` holds AERA-only board configuration. `BoardConfig.mk` includes it
  only when `bootable/recovery/aera_config.mk` exists, so the TWRP manifest is
  unchanged.
- `twrp_X6886.mk` inherits `vendor/twrp/config/common.mk` only for AERA.
- `vendorsetup.sh` detects the synced recovery core and applies either the
  TWRP patch set or the AERA patch set. It still fetches/verifies
  `device/transsion/mt6789-common` on `twrp-16.0-tos16` and applies the common
  zstd ramdisk patch to `build/make` for both cores.
- `patches/aera/` contains AERA-specific ports of the X6886 fixes:

| Patch | Target | Purpose |
|---|---|---|
| `0001-minuitwrp-Probe-X6886-sysfs-haptics.patch` | `bootable/recovery` | Probe `vibrator_single`, `vibrator` duration/activate, `timed_output`, then regulator-vibrator `brightness`; report availability to the native UI. |
| `0002-Signal-storage-readiness-before-TEE-consumers.patch` | `bootable/recovery` | Emit `twrp.storage.ready=1` after startup mount cleanup and before partition post-processing/FBE key recovery; also emit it in cold fastbootd after logical unmap. |
| `0003-Reconcile-X6886-USB-OTG-hotplug-from-uevents.patch` | `bootable/recovery` | Service disk/partition uevents from the native UI loop, resync removable parents/children from sysfs with bounded retries, unique OTG child mount points, presence-aware storage/wipe lists. |
| `0004-Respect-disabled-recovery-repacking.patch` | `bootable/recovery` | Stop forced repack-tools module inclusion and reject runtime recovery repack/reflash when current-recovery flashing is disabled. |

The common TWRP patches `0002-Respect-disabled-repacking.patch` and
`0003-Refresh-removable-partitions-after-uevent.patch` are **not** applied to
AERA; they target TWRP files/structure that AERA does not have.

## Boot layout preserved

X6886 still uses header-v4 `vendor_boot` with:

1. a zstd **PLATFORM** ramdisk containing the recovery files, and
2. an empty **RECOVERY** fragment named `emptyrecovery`.

Do not enable `AERA_VENDOR_BOOT_RECOVERY`. That experimental AERA switch forces
legacy virtual-A/B installer compensation and is not this device's layout.
`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT=true` from the common tree is the
correct packaging path. Recovery ZIP creation and repacking are disabled.

## Build

Sync AERA and place this tree at `device/infinix/Infinix-X6886`:

```bash
repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0
repo sync -c --no-tags --optimized-fetch

mkdir -p device/infinix
# Use the checkout/branch that contains this AERA port.
git clone <this-device-repository-url> device/infinix/Infinix-X6886

source build/envsetup.sh
lunch twrp_X6886-bp2a-eng
mka vendorbootimage
```

`vendorsetup.sh` runs during `source build/envsetup.sh`, clones the common tree
if absent, exports the AERA packaging environment, and applies the AERA patch
set. If the common tree already exists it must be on `twrp-16.0-tos16`; the
script does not switch or update an existing checkout.

Expected outputs:

- `out/target/product/Infinix-X6886/vendor_boot.img`
- `out/target/product/Infinix-X6886/AERA-R1.0-Alpha-Unofficial-X6886.img`
  (a copy of the final vendor_boot image produced by the AERA vendor hook)

Use `mka vendorbootimage`, not `mka recoveryimage`, for this layout. The
vendor_boot recipe runs AERA's `Fox_Before_Recovery_Image` /
`Fox_After_Recovery_Image` hooks and preserves the PLATFORM ramdisk plus empty
RECOVERY fragment.

On ServerHive, follow the existing login-shell/tmux workflow in `AGENTS.md` and
keep scratch files in workspace-local `tmp/`.

## Runtime contracts introduced by the port

- **TEE readiness:** common `init.recovery.mt6789.rc` / `init.tee.rc` gate
  Trustonic/mobicore on `twrp.storage.ready=1`. AERA now publishes that property
  before `Partition_Post_Processing()` and `Decrypt_Data()`, matching the TWRP
  startup order. Cold fastbootd publishes it after `Unmap_Super_Devices()`.
- **Haptics:** AERA's `minuitwrp/events.cpp` probes the X6886 LED sysfs paths
  before optional force-feedback/HAL paths. The brightness fallback pulses off
  the UI thread and lets the newest request own the final off transition.
- **OTG hotplug:** AERA has no TWRP operation executor/list-snapshot lock, so
  `Service_Uevents()` runs on the native UI thread only when no backend job,
  decryption, NAS, or plugin operation is active. It drains uevents
  non-blockingly, handles disk and partition events, and performs bounded
  250 ms resync retries after coldboot/overflow. Hotplug reconciliation is
  deferred during active operations; this is an Alpha limitation to retest.
- **Repacking:** `TW_NO_FLASH_CURRENT_TWRP` / `AERA_NO_REFLASH_CURRENT_RECOVERY`
  disable the forced repack-tools module and reject runtime recovery
  repack/reflash entry points. `AERA_DISABLE_UPDATEZIP=1` skips the recovery
  ZIP installer. Note: AERA's vendor packaging script still stages its prebuilt
  `magiskboot` as a boot-image tool during `Fox_Before_Recovery_Image`; verify
  the final ramdisk/image size against the 64 MiB `vendor_boot` limit.

## Validation checklist before calling the port ready

1. Complete a full AERA sync and `mka vendorbootimage` without missing
   dependencies. Inspect make/product parsing for `twrp_X6886`.
2. Inspect the packaged ramdisk, not only source: required HAL binaries,
   Trustonic libraries/registry, rc files, VINTF manifests, fonts, modules,
   and firmware must be present.
3. Verify the two-entry vendor_boot ramdisk layout (zstd PLATFORM + empty
   RECOVERY fragment), AVB footer, and image size against the 64 MiB
   `vendor_boot` partition.
4. Hardware-test, with user authorization for any flashing/slot changes:
   - recovery boot and normal Android boot with the same image;
   - display/touch on the 1080x2400 panel;
   - haptics on all three sysfs variants if available;
   - FBE decryption with default password and PIN/password-protected data;
   - USB OTG insert/remove/reinsert, multi-partition drives, and hotplug after
     an active backup/restore finishes;
   - ADB, sideload, MTP, battery/charging, fastbootd, and A/B slot switching.
5. Capture recovery logs/logcat for failures. Do not dismiss service failures
   just because SELinux is permissive.

## Host-side checks run in this workspace

The port was checked without a full Android sync, a C++ compile of the recovery
sources, or a connected phone:

- All four `patches/aera/` patches apply cleanly to
  `AERA-Recovery/android_bootable_recovery@aera-16.0` (`3a5ffe0`), both
  individually and sequentially. Each patch passes `git apply --reverse --check`
  after the full series is applied. The common zstd patch applies to AERA
  `build/make@aera-16.0` (`ee2c190`). Scratch trees were reset afterwards.
- `bash -n vendorsetup.sh`; shell smoke tests for AERA/TWRP/unknown core
  detection, AERA environment exports, and idempotent patch application.
- GNU make parsing of `BoardConfig.mk` and `twrp_X6886.mk` with and without
  `bootable/recovery/aera_config.mk`: AERA flags/vendor inheritance appear only
  for the AERA core; the TWRP product path is unchanged.
- `aera.mk` → `aera_config.mk` mapping assertions: `TW_NO_FLASH_CURRENT_TWRP=true`,
  `TW_INCLUDE_REPACKTOOLS=false`, `TW_INCLUDE_INJECTTWRP=false`,
  `OF_SKIP_ORANGEFOX_PROCESS=1`, `OF_USE_DMCTL=1`,
  `OF_DEFAULT_KEYMASTER_VERSION=4.1`, `TW_EXCLUDE_DEFAULT_USB_INIT=true`,
  settings/misc roots, 1080x2400, framerate 120, brightness 2047/4095.
- Extracted AERA make-guard smoke tests: repack disabled/enabled module
  selection, dmctl derivation and dmctl/dmsetup conflict, forced-keymaster
  missing/default error, and settings-directory conflict.
- Source contracts: `twrp.storage.ready=1` before `Partition_Post_Processing()` /
  `Decrypt_Data()` and after cold-fastbootd logical unmap; hotplug service wired
  through the native UI loop with idle gating; sysfs haptics probe/availability;
  repack/reflash guards; presence-filtered storage/wipe lists; no stale
  `Check_UsbOtg_Status` references.

These checks are **not** a substitute for a full build or hardware validation.
