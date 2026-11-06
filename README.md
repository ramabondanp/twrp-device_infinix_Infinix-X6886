# TWRP for Infinix HOT 60 Pro+ (X6886)

Unofficial TWRP 16.0 recovery for the Infinix HOT 60 Pro+.

> [!WARNING]
> **Requires Android 16 firmware and a compatible 6.12 kernel.**
> Android 15 and older firmware are not supported.

## Device information

| Item | Details |
|---|---|
| Device | Infinix HOT 60 Pro+ |
| Codename | `Infinix-X6886` |
| SoC | MediaTek Helio G200 (MT6789) |
| Display | AMOLED, 1080x2400, 480 dpi |
| Partition layout | Virtual A/B with dynamic partitions |
| Recovery image | `vendor_boot.img` |
| Development branch | `twrp-16.0-tos16` |

## Working features (TWRP baseline, hardware-confirmed)

- Recovery boot
- Touchscreen
- Vibration
- USB OTG, including multi-partition drives and hotplug
- FBE decryption, including PIN/password-protected data
- Battery and charging status
- ADB and ADB sideload
- Fastbootd and A/B slot switching
- Normal Android boot alongside TWRP

## Reporting issues

Please include your firmware and kernel versions, the recovery build you
used, and steps to reproduce the problem.

Use **Advanced → Export logs** to save recovery logs. Review them for
personal information before sharing.

## AERA Recovery (Alpha)

This tree also contains an **unvalidated source-level port** to
[AERA Recovery](https://github.com/AERA-Recovery) (`aera-16.0`). It preserves the
X6886 `vendor_boot` layout and adapts haptics, TEE readiness, USB OTG hotplug,
and repack guards to AERA's native UI/core. See [docs/AERA.md](docs/AERA.md) for
build instructions and the hardware validation checklist. Do not flash the AERA
port until it has been built and tested on the device.

## Development

The TWRP baseline uses the [TWRP-Test manifest](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)
(`twrp-16.0` branch), not the official TeamWin minimal manifest. The AERA port
uses the AERA `aera-16.0` manifest instead; `vendorsetup.sh` detects the synced
recovery core and applies the matching patch set.

Build instructions and development notes are in [AGENTS.md](AGENTS.md),
which is written primarily for AI coding agents.

Shared device support is maintained in the MT6789 common tree
(`device/transsion/mt6789-common`, branch `twrp-16.0-tos16`).

## Credits

- [Team Win Recovery Project](https://twrp.me)
- [OrangeFox Recovery Project](https://orangefox.download)
- MediaTek and Transsion for stock firmware components
- Maintainer: [rama982 / ramabondanp](https://github.com/ramabondanp)
