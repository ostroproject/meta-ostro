# This class implements image creation for the ostro target.
# The image is GPT based.
# To boot, it uses a combo file, containing kernel, initramfs and
# command line, presented to the BIOS as UEFI application, by prepending
# it with the efi stub obtained from systemd-boot.
# The layout of the image is described in a separate, customizable json file.

# A layout files is built accordingly to the following example:
#   {
#       "gpt_initial_offset_mb": 3,          <-  Space allocated for the 1st GPT
#       "gpt_tail_padding_mb": 3,            <-  Space allocated for the 2nd GPT
#       "primary_uefi_boot_partition": {     <-- Name of the entry in the dictionary
#           "name": "primary_uefi",          <-- Name of the partition in the GPT (MAX 16 ch)
#           "uuid": 0,                       <-- UUID of the partition, 0 means random
#           "size_mb": 30,                   <-- Size of the partition in MB
#           "source": "${S}/hdd/boot",       <-- Directory containing the root for the partition
#           "filesystem": "vfat",            <-- Filesystem for the partition
#           "type": "ef00"                   <-- Type of the partition, to be used in the GPT
#       },
#       [...]                                Iterate partitions as needed
#   }
#
#   The main rootfs partition is a special case and must be named "rootfs".
#   This is required to identify it and pass its Partition UUID to the kernel, for booting.


COMPRESSIONTYPES_append = " vdi"
COMPRESS_CMD_vdi = "qemu-img convert -O vdi ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type} ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type}.vdi"
COMPRESS_DEPENDS_vdi = "qemu-native"

IMAGE_DSK_ACTIVE = "${@ bool([x for x in d.getVar('IMAGE_FSTYPES', True).split() if x == 'dsk' or x.startswith('dsk.')])}"
python () {
    if d.getVar('IMAGE_DSK_ACTIVE', True) == 'True':
        d.setVar('IMAGE_NAME_SUFFIX', '')
}

do_uefiapp[depends] += " \
                         systemd:do_deploy \
                         virtual/kernel:do_deploy \
                         initramfs-framework:do_populate_sysroot \
                         intel-microcode:do_deploy \
                         ${INITRD_IMAGE}:do_image_complete \
                       "

IMAGE_DEPENDS_dsk += " \
                       gptfdisk-native:do_populate_sysroot \
                       parted-native:do_populate_sysroot \
                       mtools-native:do_populate_sysroot \
                       dosfstools-native:do_populate_sysroot \
                       dosfstools-native:do_populate_sysroot \
                     "
INITRD_append = "${@ ('${DEPLOY_DIR_IMAGE}/' + d.getVar('INITRD_IMAGE', expand=True) + '-${MACHINE}.cpio.gz') if d.getVar('INITRD_IMAGE', True) and ${IMAGE_DSK_ACTIVE} else ''}"

PACKAGES = " "
EXCLUDE_FROM_WORLD = "1"

ROOTFS_PARTUUID_VALUE ?= "deadbeef-dead-beef-dead-beefdeadbeef"

# Partition types used for building the image - DO NOT MODIFY
PARTITION_TYPE_EFI = "EF00"
PARTITION_TYPE_EFI_BACKUP = "2700"

DSK_IMAGE_LAYOUT ??= ' \
{ \
    "gpt_initial_offset_mb": 3, \
    "gpt_tail_padding_mb": 3, \
    "partition_01_primary_uefi_boot": { \
        "name": "primary_uefi", \
        "uuid": 0, \
        "size_mb": 15, \
        "source": "${IMAGE_ROOTFS}/boot/", \
        "filesystem": "vfat", \
        "type": "${PARTITION_TYPE_EFI}" \
    }, \
    "partition_02_secondary_uefi_boot": { \
        "name": "secondary_uefi", \
        "uuid": 0, \
        "size_mb": 15, \
        "source": "${IMAGE_ROOTFS}/boot/", \
        "filesystem": "vfat", \
        "type": "${PARTITION_TYPE_EFI_BACKUP}" \
    }, \
    "partition_03_rootfs": { \
        "name": "rootfs", \
        "uuid": "${ROOTFS_PARTUUID_VALUE}", \
        "size_mb": 3800, \
        "source": "${IMAGE_ROOTFS}", \
        "filesystem": "ext4", \
        "type": "8300" \
    } \
}'

inherit deploy

# The image does without traditional bootloader.
# In its place, instead, it uses a single UEFI executable binary, which is
# composed by:
#   - an UEFI stub
#     The linux kernel can generate a UEFI stub, however the one from systemd-boot can fetch
#     the command line from a separate section of the EFI application, avoiding the need to
#     rebuild the kernel.
#   - the kernel
#   - the initramfs
#   There is a catch: all of these binary components must have the same word size as the BIOS:
#   either 32 or 64 bit.
python do_uefiapp() {
    import random, string, json, uuid, shutil, glob, re
    from subprocess import check_call

    def copy(src, dst):
        with open(dst, 'w') as destination:
            with open(src) as source:
                destination.write(source.read())

    layout = d.getVar('DSK_IMAGE_LAYOUT', True)
    bb.note("Parsing disk image JSON %s" % layout)
    partition_table = json.loads(layout)

    full_image_size_mb = partition_table["gpt_initial_offset_mb"] + \
                         partition_table["gpt_tail_padding_mb"]

    for key in sorted(partition_table.iterkeys()):
        if not isinstance(partition_table[key], dict):
            continue
        full_image_size_mb += partition_table[key]["size_mb"]
        # Generate randomized uuids only if required uuid == 0
        # Otherwise leave whatever was set in the configuration file.
        if str(partition_table[key]['uuid']) == '0':
            partition_table[key]['uuid'] = str(uuid.uuid4())
        # Store these for the creation of the UEFI binary
        if partition_table[key]['name'] == 'rootfs':
            d.setVar("ROOTFS_TYPE", partition_table[key]['filesystem'])
            d.setVar("ROOTFS_SOURCE", partition_table[key]["source"])
            d.setVar("ROOTFS_PARTUUID", partition_table[key]["uuid"])

    if os.path.exists(d.expand('${B}/initrd')):
        os.remove(d.expand('${B}/initrd'))
    # initrd is a concatenation of compressed cpio archives
    # (initramfs, microcode, etc.)
    with open(d.expand('${B}/initrd'), 'w') as dst:
        for cpio in d.getVar('INITRD', True).split():
            with open(cpio, 'rb') as src:
                dst.write(src.read())
    with open(d.expand('${B}/machine.txt'), 'w') as f:
        f.write(d.expand('${MACHINE}'))
    with open(d.expand('${B}/cmdline.txt'), 'w') as f:
        f.write(d.expand('${APPEND} root=PARTUUID=${ROOTFS_PARTUUID} rootfstype=${ROOTFS_TYPE}'))
    if '64' in d.getVar('MACHINE', True):
        executable = 'bootx64.efi'
    else:
        executable = 'bootia32.efi'
    check_call(d.expand('objcopy ' +
                      '--add-section .osrel=${B}/machine.txt ' +
                          '--change-section-vma  .osrel=0x20000 ' +
                      '--add-section .cmdline=${B}/cmdline.txt ' +
                          '--change-section-vma .cmdline=0x30000 ' +
                      '--add-section .linux=${DEPLOY_DIR_IMAGE}/bzImage ' +
                          '--change-section-vma .linux=0x40000 ' +
                      '--add-section .initrd=${B}/initrd ' +
                          '--change-section-vma .initrd=0x3000000 ' +
                      glob.glob(d.expand('${DEPLOY_DIR_IMAGE}/linux*.efi.stub'))[0] +
                      ' ${B}/' + executable + '_tmp'
                     ).split())
    with open(d.expand('${B}/signature.txt'), 'w') as f:
        f.write('Signature Placeholder.')
    with open(d.expand('${B}/' + executable + '_tmp'), 'rb') as combo:
        with open(d.expand('${B}/signature.txt'), 'rb') as signature:
            with open(d.expand('${B}/' + executable), 'w') as signed_combo:
                signed_combo.write(combo.read())
                signed_combo.write(signature.read())
    if not os.path.exists(d.expand('${DEPLOYDIR}/EFI/BOOT')):
        os.makedirs(d.expand('${DEPLOYDIR}/EFI/BOOT'))
    copy(d.expand('${B}/' + executable), d.expand('${DEPLOYDIR}/EFI/BOOT/' + executable))
}

DEPLOYDIR = "${WORKDIR}/uefiapp-${PN}"
SSTATETASKS += "do_uefiapp"
do_uefiapp[sstate-inputdirs] = "${DEPLOYDIR}"
do_uefiapp[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"

python do_uefiapp_setscene () {
    sstate_setscene(d)
}

uefiapp_deploy() {
  #Let's make sure that only what is needed stays in the /boot dir
  rm -rf ${IMAGE_ROOTFS}/boot/*
  cp  --preserve=timestamps -r ${DEPLOYDIR}/* ${IMAGE_ROOTFS}/boot/
  chown -R root:root ${IMAGE_ROOTFS}/boot
}

do_uefiapp[dirs] = "${DEPLOYDIR} ${B}"

addtask do_uefiapp_setscene
addtask do_uefiapp

addtask do_uefiapp before do_rootfs

ROOTFS_POSTPROCESS_COMMAND += " uefiapp_deploy; "

# Workaround for spurious execution of unrequested task
# related to wic.
# See: https://bugzilla.yoctoproject.org/show_bug.cgi?id=9095
deltask do_rootfs_wicenv

# All variables explicitly passed to image-iot.py.
IMAGE_DSK_VARIABLES = " \
    APPEND \
    BPN \
    DEPLOY_DIR_IMAGE \
    DSK_IMAGE_LAYOUT \
    IMAGE_NAME \
    IMAGE_ROOTFS \
    INITRD \
    MACHINE \
    ROOTFS_TYPE \
    ROOTFS_PARTUUID_VALUE \
    PARTITION_TYPE_EFI \
    PARTITION_TYPE_EFI_BACKUP \
    S \
"

IMAGE_CMD_dsk = "${PYTHON} ${IMAGE_DSK_BASE}/lib/image-dsk.py ${@' '.join(["'%s=%s'" % (x, d.getVar(x, True) or '') for x in d.getVar('IMAGE_DSK_VARIABLES', True).split()])}"
IMAGE_CMD_dsk[vardeps] = "${IMAGE_DSK_VARIABLES}"
