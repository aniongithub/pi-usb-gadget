#!/bin/bash
GADGET_PATH=/sys/kernel/config/usb_gadget/pi4

mkdir -p $GADGET_PATH

echo 0x1d50 > $GADGET_PATH/idVendor
echo 0x60c7 > $GADGET_PATH/idProduct
echo 0x0100 > $GADGET_PATH/bcdDevice
echo 0x0200 > $GADGET_PATH/bcdUSB

echo 0xEF > $GADGET_PATH/bDeviceClass
echo 0x02 > $GADGET_PATH/bDeviceSubClass
echo 0x01 > $GADGET_PATH/bDeviceProtocol

mkdir -p $GADGET_PATH/strings/0x409
echo "$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2)" > $GADGET_PATH/strings/0x409/serialnumber
echo "Raspberry Pi Foundation" > $GADGET_PATH/strings/0x409/manufacturer
echo "Raspberry Pi 4" > $GADGET_PATH/strings/0x409/product

mkdir -p $GADGET_PATH/os_desc
echo "1" > $GADGET_PATH/os_desc/use
echo 0xcd > $GADGET_PATH/os_desc/b_vendor_code # Microsoft
echo "MSFT100" > $GADGET_PATH/os_desc/qw_sign

mkdir -p $GADGET_PATH/configs/c.2
echo 0x80 > $GADGET_PATH/configs/c.2/bmAttributes # Bus powered
echo 500 > $GADGET_PATH/configs/c.2/MaxPower


mkdir -p $GADGET_PATH/configs/c.2/strings/0x409
echo "UVC" > $GADGET_PATH/configs/c.2/strings/0x409/configuration

mkdir -p $GADGET_PATH/functions/uvc.usb0
mkdir -p $GADGET_PATH/functions/rndis.usb0

mac="01:23:45:67:89:ab"
dev_mac="02$(echo ${mac} | cut -b 3-)"
host_mac="12$(echo ${mac} | cut -b 3-)"
echo "$dev_mac" > $GADGET_PATH/functions/rndis.usb0/dev_addr
echo "$host_mac" > $GADGET_PATH/functions/rndis.usb0/host_addr

mkdir -p $GADGET_PATH/functions/rndis.usb0/os_desc/interface.rndis
echo "RNDIS" > $GADGET_PATH/functions/rndis.usb0/os_desc/interface.rndis/compatible_id # matches Windows RNDIS Drivers
echo "5162001" > $GADGET_PATH/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id # matches Windows RNDIS 6.0 Driver

mkdir -p ${gadget}/functions/acm.usb0

mkdir -p $GADGET_PATH/functions/uvc.usb0/control/header/h
ln -s $GADGET_PATH/functions/uvc.usb0/control/header/h $GADGET_PATH/functions/uvc.usb0/control/class/fs/h

config_frame () {
    FORMAT=$1
    NAME=$2
        WIDTH=$3
        HEIGHT=$4

    framedir=$GADGET_PATH/functions/uvc.usb0/streaming/$FORMAT/$NAME/${HEIGHT}p

    mkdir -p $framedir

    echo $WIDTH > $framedir/wWidth
    echo $HEIGHT > $framedir/wHeight
    echo 333333 > $framedir/dwDefaultFrameInterval
    echo $(($WIDTH * $HEIGHT * 80)) > $framedir/dwMinBitRate
    echo $(($WIDTH * $HEIGHT * 160)) > $framedir/dwMaxBitRate
    echo $(($WIDTH * $HEIGHT * 2)) > $framedir/dwMaxVideoFrameBufferSize
    cat <<EOF > $framedir/dwFrameInterval
333333
400000
666666
EOF

}

config_frame mjpeg m 640 360
config_frame mjpeg m 640 480
config_frame mjpeg m 800 600
config_frame mjpeg m 1024 768
config_frame mjpeg m 1280 720
config_frame mjpeg m 1280 960
config_frame mjpeg m 1440 1080
config_frame mjpeg m 1536 864
config_frame mjpeg m 1600 900
config_frame mjpeg m 1600 1200
config_frame mjpeg m 1920 1080


mkdir -p $GADGET_PATH/functions/uvc.usb0/streaming/header/h
cd $GADGET_PATH/functions/uvc.usb0/streaming/header/h
ln -s ../../mjpeg/m
cd ../../class/fs
ln -s ../../header/h
cd ../../class/hs
ln -s ../../header/h
cd ../../../../..

ln -s $GADGET_PATH/configs/c.2 $GADGET_PATH/os_desc
ln -s $GADGET_PATH/functions/uvc.usb0 $GADGET_PATH/configs/c.2/uvc.usb0
ln -s $GADGET_PATH/functions/rndis.usb0 $GADGET_PATH/configs/c.2/rndis.usb0
ln -s $GADGET_PATH/functions/acm.usb0 $GADGET_PATH/configs/c.2/acm.usb0

udevadm settle -t 5 || :
ls /sys/class/udc > $GADGET_PATH/UDC

ifup usb0
service dnsmasq restart


