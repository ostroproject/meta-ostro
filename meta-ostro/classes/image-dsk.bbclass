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


# Ostro custom conversion types
CONVERSIONTYPES_append = " vdi ova"
CONVERSION_CMD_vdi = "qemu-img convert -O vdi ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type} ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type}.vdi"
CONVERSION_DEPENDS_vdi = "qemu-native"
CONVERSION_DEPENDS_ova = "vboxmanage-native"

# Needed to use native python libraries
inherit pythonnative

# Image files of machines using image-dsk.bbclass do not use the redundant ".rootfs"
# suffix. Probably should be moved to ostro-os.conf eventually.
IMAGE_NAME_SUFFIX = ""

create_ova() {

  if [ "x${MACHINE}x" != "xintel-corei7-64x" ]; then
    return
  fi

  # 64 bit linux with sata bus (1 port)
  OS_TYPE="Linux_64"
  STORAGE_NAME="SATA"
  STORAGE_BUS_TYPE="sata"
  STORAGE_BUS_PORT_COUNT="1"

  VM_NAME="${IMAGE_NAME}"
  # 512 should be large enough value to run Ostro (Galileo has 256MB RAM for example)
  # but small enough value that even a modest host machine can afford it
  RAM="512"
  # min allowed - as we do not run graphical environment, it should be enough
  VRAM="12"
  # As above with RAM, 2 cores should be enough for Ostro without crippling the host machine
  CPU_CORE_COUNT=2
  # required for successful boot
  FIRMWARE="efi"
  IOAPIC="on"

  # default settings for hard drive
  STORAGE_PORT="0"
  STORAGE_DEVICE="0"
  STORAGE_DEVICE_TYPE="hdd"

  RAW_IMAGE="${IMGDEPLOYDIR}/${IMAGE_NAME}.dsk"
  VIRTUALBOX_IMAGE="${IMGDEPLOYDIR}/${IMAGE_NAME}.vmdk"
  VIRTUALBOX_EXECUTABLE="${STAGING_BINDIR_NATIVE}/VBoxManage"

  APPLIANCE_NAME="${VM_NAME}.dsk.ova"

  FOLDER_NAME="virtualbox-vm"
  WORK_FOLDER="${IMGDEPLOYDIR}/${FOLDER_NAME}"

  mkdir -p ${WORK_FOLDER}

  # Ensure we have unique directory for IPC under /tmp
  export VBOX_IPC_SOCKETID="ostro-appliance-creation-$$"

  # create vm
  ${VIRTUALBOX_EXECUTABLE} createvm --name ${VM_NAME} --ostype ${OS_TYPE} --basefolder ${WORK_FOLDER} --register

  #set core count, memory, firmware and ioapic
  ${VIRTUALBOX_EXECUTABLE} modifyvm ${VM_NAME} --memory ${RAM} --vram ${VRAM} --cpus ${CPU_CORE_COUNT} --firmware ${FIRMWARE} --ioapic ${IOAPIC}

  #set boot order (only trying to boot from Hard Disk)
  ${VIRTUALBOX_EXECUTABLE} modifyvm ${VM_NAME} --boot1 disk --boot2 none --boot3 none --boot4 none

  # add bus for hard drives
  ${VIRTUALBOX_EXECUTABLE} storagectl ${VM_NAME} --name ${STORAGE_NAME} --add ${STORAGE_BUS_TYPE} --portcount ${STORAGE_BUS_PORT_COUNT}

  # create virtual hard drive from the raw .dsk image
  ${VIRTUALBOX_EXECUTABLE} internalcommands createrawvmdk -filename ${VIRTUALBOX_IMAGE} -rawdisk ${RAW_IMAGE}

  # attach the .vmdk image as hard drive
  ${VIRTUALBOX_EXECUTABLE} storageattach ${VM_NAME} --storagectl ${STORAGE_NAME} --medium ${VIRTUALBOX_IMAGE} --port ${STORAGE_PORT} --device ${STORAGE_DEVICE} --type ${STORAGE_DEVICE_TYPE}

  # export the image
  ${VIRTUALBOX_EXECUTABLE} export ${VM_NAME} --output ${IMGDEPLOYDIR}/${APPLIANCE_NAME} --ovf20

  # unregister the VM from virtualbox -
  ${VIRTUALBOX_EXECUTABLE} unregistervm  ${VM_NAME}

  # chmod the outputs so that they can be accessed by non-owners as well
  chmod +r ${APPLIANCE_NAME}
  chmod +r ${VIRTUALBOX_IMAGE}

  # erase temp files created during appliance generation
  rm -rf "/tmp/.vbox-${VBOX_IPC_SOCKETID}-ipc"
  rm -rf ${WORK_FOLDER}
}

CONVERSION_CMD_ova = "create_ova"

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
                       python-native:do_populate_sysroot \
                       bmap-tools-native:do_populate_sysroot \
                     "

# Always ensure that the INITRD_IMAGE gets added to the initramfs .cpio.
# This needs to be done even when the actual .dsk image format is inactive,
# because the .cpio file gets copied into the rootfs, and that rootfs
# must be consistent regardless of the image format. This became relevant
# when adding swupd bundle support, because there virtual images
# without active .dsk are used to generate the rootfs for other
# images with .dsk format.
INITRD_LIVE_append = "${@ ('${DEPLOY_DIR_IMAGE}/' + d.getVar('INITRD_IMAGE', expand=True) + '-${MACHINE}.cpio.gz') if d.getVar('INITRD_IMAGE', True) else ''}"

PACKAGES = " "
EXCLUDE_FROM_WORLD = "1"

REMOVABLE_MEDIA_ROOTFS_PARTUUID_VALUE ?= "deadbeef-dead-beef-dead-beefdeadbeef"

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
        "uuid": "${REMOVABLE_MEDIA_ROOTFS_PARTUUID_VALUE}", \
        "size_mb": 3700, \
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
    import shutil
    from subprocess import check_call

    # This data is imported by OS installer and used for partitioning internal storage
    PART_DATA_TPL = """
export PART_%(pnum)d_NAME=%(name)s
export PART_%(pnum)d_SIZE=%(size_mb)d
export PART_%(pnum)d_UUID=%(uuid)s
export PART_%(pnum)d_TYPE=%(type)s
export PART_%(pnum)d_FS=%(filesystem)s
"""
    partition_data = ""

    layout = d.getVar('DSK_IMAGE_LAYOUT', True)
    bb.note("Parsing disk image JSON %s" % layout)
    partition_table = json.loads(layout)

    full_image_size_mb = partition_table["gpt_initial_offset_mb"] + \
                         partition_table["gpt_tail_padding_mb"]

    rootfs_type = None
    pnum = 0
    for key in sorted(partition_table.keys()):
        if not isinstance(partition_table[key], dict):
            continue
        full_image_size_mb += partition_table[key]["size_mb"]
        # Generate randomized uuids only if required uuid == 0
        # Otherwise leave whatever was set in the configuration file.
        if str(partition_table[key]['uuid']) == '0':
            partition_table[key]['uuid'] = str(uuid.uuid4())
        # Store these for the creation of the UEFI binary
        if partition_table[key]['name'] == 'rootfs':
            rootfs_type = partition_table[key]['filesystem']
            int_part_uuid = d.getVar('INT_STORAGE_ROOTFS_PARTUUID_VALUE', True)
        else:
            int_part_uuid = partition_table[key]["uuid"]
        partition_data += PART_DATA_TPL % {
            "pnum": pnum,
            "size_mb": partition_table[key]["size_mb"],
            "uuid": int_part_uuid,
            "type": partition_table[key]["type"],
            "name": partition_table[key]["name"],
            "filesystem": partition_table[key]["filesystem"],
        }
        pnum = pnum + 1

    assert rootfs_type is not None
    partition_data += "export PART_COUNT=%d\n" % pnum

    if os.path.exists(d.expand('${B}/initrd')):
        os.remove(d.expand('${B}/initrd'))
    # initrd is a concatenation of compressed cpio archives
    # (initramfs, microcode, etc.)
    with open(d.expand('${B}/initrd'), 'wb') as dst:
        for cpio in d.getVar('INITRD_LIVE', True).split():
            with open(cpio, 'rb') as src:
                dst.write(src.read())
    with open(d.expand('${B}/machine.txt'), 'w') as f:
        f.write(d.expand('${MACHINE}'))
    if '64' in d.getVar('MACHINE', True):
        executable = 'bootx64.efi'
    else:
        executable = 'bootia32.efi'

    def generate_app(partuuid, cmdline, suffix):
        with open(d.expand('${B}/cmdline' + suffix + '.txt'), 'w') as f:
            f.write(d.expand('${APPEND} root=PARTUUID=%s rootfstype=%s %s' % \
                             (partuuid, rootfs_type, cmdline)))
        check_call(d.expand('objcopy ' +
                          '--add-section .osrel=${B}/machine.txt ' +
                              '--change-section-vma  .osrel=0x20000 ' +
                          '--add-section .cmdline=${B}/cmdline' + suffix + '.txt ' +
                              '--change-section-vma .cmdline=0x30000 ' +
                          '--add-section .linux=${DEPLOY_DIR_IMAGE}/bzImage ' +
                              '--change-section-vma .linux=0x40000 ' +
                          '--add-section .initrd=${B}/initrd ' +
                              '--change-section-vma .initrd=0x3000000 ' +
                          glob.glob(d.expand('${DEPLOY_DIR_IMAGE}/linux*.efi.stub'))[0] +
                          ' ${B}/' + executable + '_tmp' + suffix
                          ).split())
        with open(d.expand('${B}/signature.txt'), 'w') as f:
            f.write('Signature Placeholder.')
        with open(d.expand('${B}/' + executable + '_tmp' + suffix), 'rb') as combo:
            with open(d.expand('${B}/signature.txt'), 'rb') as signature:
                with open(d.expand('${B}/' + executable + suffix), 'wb') as signed_combo:
                    signed_combo.write(combo.read())
                    signed_combo.write(signature.read())
        if not os.path.exists(d.expand('${DEPLOYDIR}/EFI' + suffix + '/BOOT')):
            os.makedirs(d.expand('${DEPLOYDIR}/EFI' + suffix + '/BOOT'))
        shutil.copyfile(d.expand('${B}/' + executable + suffix), d.expand('${DEPLOYDIR}/EFI' + suffix + '/BOOT/' + executable))

    generate_app(d.getVar('REMOVABLE_MEDIA_ROOTFS_PARTUUID_VALUE', True), "installer", "")
    generate_app(d.getVar('INT_STORAGE_ROOTFS_PARTUUID_VALUE', True), "", "_internal_storage")

    with open(d.expand('${B}/emmc-partitions-data'), 'w') as emmc_part_data:
        emmc_part_data.write(partition_data)
    shutil.copyfile(d.expand('${B}/emmc-partitions-data'), d.expand('${DEPLOYDIR}/emmc-partitions-data'))
}

# To be populated when creating the uefiapp.
DEPLOYDIR = "${WORKDIR}/uefiapp-${PN}"
# Permanent location of the uefiapp, also available when restoring from sstate.
# Shared between all image variants of the same base image. Only the
# base image executes do_uefiapp, all other image variants take the
# result from there.
UEFIAPPDIR = "${DEPLOY_DIR_IMAGE}/${@ d.getVar('PN_BASE', True) if d.getVar('PN_BASE', True) else '${PN}'}-uefiapp"
do_uefiapp[vardeps] += " APPEND"
do_uefiapp[sstate-inputdirs] = "${DEPLOYDIR}"
do_uefiapp[sstate-outputdirs] = "${UEFIAPPDIR}"
# uefiapp_deploy will copy the entire directory, therefore we
# have to ensure that there is no cruft left over from
# previous builds (sstate support will add to the target directory
# and overwrite old files, but not remove extra ones).
do_uefiapp[cleandirs] = "${UEFIAPPDIR}"
do_uefiapp_setscene[cleandirs] = "${UEFIAPPDIR}"
# This has to be set unconditionally because it must be set
# when the anonymous python code in sstate.bbclass runs. There
# is no guaranteed ordering of anonymous python code and in practice
# the code below really ran too late.
SSTATETASKS += 'do_uefiapp'

python do_uefiapp_setscene () {
    sstate_setscene(d)
}

uefiapp_deploy() {
  #Let's make sure that only what is needed stays in the /boot dir
  rm -rf ${IMAGE_ROOTFS}/boot/*
  cp  --preserve=timestamps -r ${UEFIAPPDIR}/* ${IMAGE_ROOTFS}/boot/
  chown -R root:root ${IMAGE_ROOTFS}/boot
}

do_uefiapp[dirs] = "${DEPLOYDIR} ${B}"

python () {
    # PN_BASE is set by meta-swupd when creating variants of the base
    # image. As an additional sanity check we also check PN, but that
    # shouldn't be necessary because the base image does not have PN_BASE
    # set.
    pn_base = d.getVar('PN_BASE', True)
    pn = d.getVar('PN', True)
    if pn_base and pn_base != pn:
        # variant, use uefiapp from base
        d.appendVarFlag('do_rootfs', 'depends', ' %s:do_uefiapp' % pn_base)
    else:
        # base image, do the work
        bb.build.addtask('do_uefiapp', 'do_rootfs', None, d)
        bb.build.addtask('do_uefiapp_setscene', None, None, d)
}

ROOTFS_POSTPROCESS_COMMAND += " uefiapp_deploy; "

# All variables explicitly passed to image-dsk.py.
IMAGE_DSK_VARIABLES = " \
    APPEND \
    IMGDEPLOYDIR \
    DSK_IMAGE_LAYOUT \
    IMAGE_LINK_NAME \
    IMAGE_NAME \
    IMAGE_ROOTFS \
    ROOTFS_TYPE \
    REMOVABLE_MEDIA_ROOTFS_PARTUUID_VALUE \
    PARTITION_TYPE_EFI \
    PARTITION_TYPE_EFI_BACKUP \
    S \
"

IMAGE_CMD_dsk = "${PYTHON} ${IMAGE_DSK_BASE}/lib/image-dsk.py ${@' '.join(["'%s=%s'" % (x, d.getVar(x, True) or '') for x in d.getVar('IMAGE_DSK_VARIABLES', True).split()])}"
IMAGE_CMD_dsk[vardeps] = "${IMAGE_DSK_VARIABLES}"
