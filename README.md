# galaxyxr-base-partitions

The Galaxy XR's own partitions, and the firmware in them, for Ubuntu on
[Galaxy XR kernels](https://github.com/rustedsword/samsung_kernel_galaxy_xr/tree/I610UES3AZJ2_fixed).
Everything is mounted read-only, flat under `/run/platform`.

- `galaxyxr-base-partitions` mounts the UFS partitions apnhlos, dsp, efs,
  persist and sec_efs on `/run/platform/NAME`, and links `/efs` to sec_efs,
  where the Samsung kernel reads its factory calibration.
- `galaxyxr-base-partitions-vendor` maps vendor out of Android's super
  partition with `map_super` from galaxyxr-mini-tools and mounts it on
  `/run/platform/vendor`.
- `galaxyxr-firmware` links every firmware file of apnhlos (`image/`) and
  vendor (`firmware/`) into `/usr/lib/firmware`, where the kernel and
  userspace such as pd-mapper look for it. `galaxyxr-firmware.service` makes
  `wlan_mac.bin`, wlan's MAC address, from efs into `/run/galaxyxr-firmware`,
  where its link points.

## Before any module loads

A module asks for its firmware when it loads, and the kernel doesn't wait for
a link to resolve. So `galaxyxr-base-partitions.service` and
`galaxyxr-base-partitions-vendor.service` mount their partitions before udev,
`systemd-modules-load` and `galaxyxr-modules` (the 5.10 kernel's second
stage) start. They find the partitions in sysfs, because `/dev/disk` doesn't
exist yet. The `run-platform-*.mount` units describe the same mounts to
systemd. Other units can depend on them with `RequiresMountsFor=`.

`galaxyxr-firmware.service` makes `wlan_mac.bin` after efs is mounted and
before those start too.

A driver built into the kernel, or loaded by an initramfs, still needs its
firmware in the kernel or in the initramfs. None of this happens in an
initramfs: whoever wants Wi-Fi there needs `wlan_mac.bin` there, embedded when
the image is built or made by the initramfs itself. To embed a file, copy its
link's target: in an initramfs `/run` is a fresh tmpfs, so a copied link
dangles.

## The firmware links

`debian/galaxyxr-firmware.links` is generated from mounted partitions:

    sudo tools/firmware-links > debian/galaxyxr-firmware.links

Without arguments it reads `/run/platform/apnhlos` and `/run/platform/vendor`;
two arguments name other mount points of the same partitions. apnhlos wins
a name both partitions have, as in Android. Links of vendor's that lead out
of it, into `/data` or persist, are left out. `wlan_mac.bin` always links
into `/run/galaxyxr-firmware`.

The links share `/usr/lib/firmware` with linux-firmware. No name is in both,
and dpkg would refuse one that is.
