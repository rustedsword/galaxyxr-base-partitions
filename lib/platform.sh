# The Galaxy XR's partitions on /run/platform, sourced by the mount services. They run before
# udev, so the partitions come from sysfs, not from /dev/disk.

# Tenths of a second the partitions may still take to be ready, all of them together
platform_wait=100

# Sets device to the node of the GPT partition named $1, once that opens: the kernel shows a new
# partition in sysfs before it makes the node, and makes the node before the partition opens
platform_part() {
    while :; do
        device=$(grep -l -x -F "PARTNAME=$1" /sys/class/block/*/uevent 2> /dev/null | head -n 1)
        if [ -n "$device" ]; then
            device=${device%/uevent}
            device=/dev/${device##*/}
            blockdev --getsz "$device" > /dev/null 2>&1 && return 0
        fi
        if [ "$platform_wait" -le 0 ]; then
            if [ -n "$device" ]; then
                echo "$1: $device doesn't open" >&2
            else
                echo "no partition $1" >&2
            fi
            return 1
        fi
        platform_wait=$((platform_wait - 1))
        sleep 0.1
    done
}

# Mounts $2 of type $3 with options $4 on /run/platform/$1, unless something is mounted there already. The device
# is made read-only first: even a read-only ext4 mount writes an error into a partition that isn't.
platform_mount() {
    mountpoint -q "/run/platform/$1" && return 0
    blockdev --setro "$2" && mkdir -p "/run/platform/$1" && mount -t "$3" -o "$4" "$2" "/run/platform/$1"
}
