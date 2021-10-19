#! /bin/bash

echo 'dtoverlay=dwc2' >> /boot/config.txt
echo -n ' modules-load=dwc2' >> /boot/cmdline.txt
echo 'libcomposite' >> /etc/modules
echo 'denyinterfaces usb0' >> /etc/dhcpd.conf