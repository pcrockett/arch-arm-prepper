#!/usr/bin/env bash
set -Eeuo pipefail

# This script tries to automate the instructions here:
#
# https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
#
# Notable dependencies:
#
# * fzf
# * wget
#

panic() {
    echo "${@}"
    exit 1
}

if [ "$(id --user)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

WORKING_DIR="tmp"
ARCHIVE_NAME="ArchLinuxARM-rpi-armv7-latest.tar.gz"
export GNUPGHOME="gpghome"

test ! -e "${WORKING_DIR}" || rmdir "${WORKING_DIR}"
mkdir "${WORKING_DIR}"
pushd "${WORKING_DIR}" &> /dev/null

on_exit() {
    if [ -d boot ]; then
        umount boot
        rmdir boot
    fi

    if [ -d root ]; then
        umount root
        rmdir root
    fi

    if [ -d "${GNUPGHOME}" ]; then
        rm -r "${GNUPGHOME}"
    fi

    rm -f "${ARCHIVE_NAME}"
    rm -f "${ARCHIVE_NAME}.sig"

    popd &> /dev/null
    rmdir "${WORKING_DIR}"
}
trap 'on_exit' EXIT

prompt_for_device() {
    # Display a rich fuzzy search / menu for the user to select their SD card device,
    # and output just the SD card device's PATH

    # Disable warning about using single-quotes
    # shellcheck disable=SC2016
    lsblk --list --nodeps --output PATH,SIZE \
        | fzf \
            --header-lines 1 \
            --layout reverse \
            --prompt "Select your SD card device: " \
            --preview 'fdisk --list "$(echo {} | cut --fields 1 --delimiter " ")"' \
            --preview-window down \
        | cut --fields 1 --delimiter " "
}

DEVICE_PATH="$(prompt_for_device)"

FORMAT_SCRIPT="
label: dos
size=200MiB, type=c
type=83
"

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!  REFORMATTING DEVICE  !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo
echo "${DEVICE_PATH}"
echo
echo "All the data on this device will now go bye-bye."
echo "Press enter to continue or Ctrl+C to cancel..."
read -r

echo "${FORMAT_SCRIPT}" | sfdisk "${DEVICE_PATH}"
sync

mkfs.vfat "${DEVICE_PATH}1"
sync

mkdir boot
mount "${DEVICE_PATH}1" boot

mkfs.ext4 "${DEVICE_PATH}2"
sync

mkdir root
mount "${DEVICE_PATH}2" root

wget "http://os.archlinuxarm.org/os/${ARCHIVE_NAME}"
wget "http://os.archlinuxarm.org/os/${ARCHIVE_NAME}.sig"

ARCH_ARM_SIGNING_KEY="
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
fx6y8+A0kBiaAmcY01U/upYXeHs=
=AIgD
-----END PGP PUBLIC KEY BLOCK-----
"

# Make a temporary gpg home dir and import the key
mkdir "${GNUPGHOME}"
echo "${ARCH_ARM_SIGNING_KEY}" | gpg --import

# Give the key "ultimate" trust by navigating the gpg menu programmatically
# Yes I know this sucks. But that's gpg, folks.
echo -e "5\ny\n" \
    | gpg --command-fd 0 --edit-key "68B3537F39A313B3E574D06777193F152BDBE6A6" trust \
    &> /dev/null

gpg --verify "${ARCHIVE_NAME}.sig"

tar --extract --preserve-permissions \
    --file "${ARCHIVE_NAME}" \
    --directory root
sync

mv root/boot/* boot
sync

echo "Done! You may boot your Raspberry Pi with the SD card now."
echo "Default user:password is \`alarm:alarm\`"
echo "Default root password is \`root\`"
echo
echo "IMPORTANT! SSH is enabled! First order of business: CHANGE YOUR PASSWORDS!"
echo
