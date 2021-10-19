#!/bin/bash

# Adapted from: https://github.com/hardillb/rpi-gadget-image-creator/blob/master/usr/local/sbin/usb-gadget.sh-alternate
GADGET_PATH=/sys/kernel/config/usb_gadget/pi4

usb_version="0x0200" # USB 2.0
device_class="0xEF"
device_subclass="0x02"
bcd_device="0x0100" # v1.0.0
device_protocol="0x01"
vendor_id="0x1d50"
product_id="0x60c7"
vendor_id="0x1d6b" # Linux Foundation
product_id="0x0104" # Multifunction composite gadget
manufacturer="Raspberry Pi Foundation"
product="Raspberry Pi 4"
serial="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2)"
attr="0x80" # Bus powered
power="250"
config1="RNDIS"
config2="CDC"
ms_vendor_code="0xcd" # Microsoft
ms_qw_sign="MSFT100" # also Microsoft (if you couldn't tell)
ms_compat_id="RNDIS" # matches Windows RNDIS Drivers
ms_subcompat_id="5162001" # matches Windows RNDIS 6.0 Driver

mac="01:23:45:67:89:ab"
dev_mac="02$(echo ${mac} | cut -b 3-)"
host_mac="12$(echo ${mac} | cut -b 3-)"

mkdir -p ${GADGET_PATH}
echo "${usb_version}" > ${GADGET_PATH}/bcdUSB
echo "${device_class}" > ${GADGET_PATH}/bDeviceClass
echo "${device_subclass}" > ${GADGET_PATH}/bDeviceSubClass
echo "${vendor_id}" > ${GADGET_PATH}/idVendor
echo "${product_id}" > ${GADGET_PATH}/idProduct
echo "${bcd_device}" > ${GADGET_PATH}/bcdDevice
echo "${device_protocol}" > ${GADGET_PATH}/bDeviceProtocol

mkdir -p ${GADGET_PATH}/strings/0x409
echo "${manufacturer}" > ${GADGET_PATH}/strings/0x409/manufacturer
echo "${product}" > ${GADGET_PATH}/strings/0x409/product
echo "${serial}" > ${GADGET_PATH}/strings/0x409/serialnumber

mkdir ${GADGET_PATH}/configs/c.1
echo "${attr}" > ${GADGET_PATH}/configs/c.1/bmAttributes
echo "${power}" > ${GADGET_PATH}/configs/c.1/MaxPower

mkdir -p ${GADGET_PATH}/configs/c.1/strings/0x409
echo "${config1}" > ${GADGET_PATH}/configs/c.1/strings/0x409/configuration
mkdir -p ${GADGET_PATH}/os_desc
echo "1" > ${GADGET_PATH}/os_desc/use
echo "${ms_vendor_code}" > ${GADGET_PATH}/os_desc/b_vendor_code
echo "${ms_qw_sign}" > ${GADGET_PATH}/os_desc/qw_sign

mkdir -p ${GADGET_PATH}/functions/rndis.usb0
echo "${dev_mac}" > ${GADGET_PATH}/functions/rndis.usb0/dev_addr
echo "${host_mac}" > ${GADGET_PATH}/functions/rndis.usb0/host_addr
echo "${ms_compat_id}" > ${GADGET_PATH}/functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "${ms_subcompat_id}" > ${GADGET_PATH}/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

mkdir -p ${GADGET_PATH}/functions/acm.usb0

ln -s ${GADGET_PATH}/configs/c.1 ${GADGET_PATH}/os_desc
ln -s ${GADGET_PATH}/functions/rndis.usb0 ${GADGET_PATH}/configs/c.1
ln -s ${GADGET_PATH}/functions/acm.usb0 ${GADGET_PATH}/configs/c.1/

ls /sys/class/udc > ${GADGET_PATH}/UDC
udevadm settle -t 5 || :
ifup usb0
service dnsmasq restart