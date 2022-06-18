# routerboard

External tree for [buildroot](https://buildroot.org) to build Raspberry Pi Compute Module 4 based  macsec router firmware image. This firmware boots on [seeed studio Mini Router](https://www.seeedstudio.com/Dual-GbE-Carrier-Board-with-4GB-RAM-32GB-eMMC-RPi-CM4-Case-p-5029.html) and acts as router between your macsec segment and normal ipv4 LAN segment.

## Building

To build macsec router firmware, you need to install Buildroot environment and clone this repository as 'external tree' to buildroot. Make sure you check buildroot manual for required packages for your host, before building.

```
mkdir ~/build-directory
cd ~/build-directory
git clone https://git.buildroot.net/buildroot
git clone https://github.com/resiliencetheatre/routerboard
```

Define _external tree_ location to **BR2_EXTERNAL** variable:

```
export  MACSECROUTER=~/build-directory/routerboard
export BR2_EXTERNAL=${MACSECROUTER}
```

Make macsec router configuration (defconfig) and start building:

```
cd ~/build-directory/buildroot
make routerboard_defconfig
make
```

After build is completed, you find image file for eMMC at:

```
~/build-directory/buildroot/output/images/sdcard.img
```

Use 'dd' to copy this image to your eMMC after you have closed 'boot' jumper and initialized mass storage mode with rpiboot program. See [Mini Router wiki](https://wiki.seeedstudio.com/Dual-Gigabit-Ethernet-Carrier-Board-for-Raspberry-Pi-CM4/) for details.

```
sudo rpiboot
export TARGET_PARTITION=/dev/[TARGET DEVICE]
sudo dd if=output/images/sdcard.img of=$TARGET_PARTITION status=progress
sync
```

## Keying sequence

Solution uses [Nitrokey Pro2](https://shop.nitrokey.com/shop/product/nkpr2-nitrokey-pro-2-3) (or Storage) HSM element to (re)key macsec enabled hosts 'out of band'. This means that you need to insert Nitrokey first to macsec router and it will generate random keys & mac addresses into HSM and after this, when you insert same Nitrokey to Linux host(s) they will be re-keyed to macsec segment. This activity happens automatically via udev located rule and script located /opt/nk-macsec.

## RPi configuration

To complete configuration after build, you need **console access** to your RPi since image contains no SSH daemon. 

### Defining mac addresses

You need to edit **mac-adddress-list.txt** file and define all mac addresses of computers in your macsec segment. It's important to have macsec router mac address as first entry on list. 

After logging in with console (user: root, no password) you can check your ethernet interface (eth0) mac address with 'ip a' command:

```
# ip a
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether e4:5f:01:98:f6:5d brd ff:ff:ff:ff:ff:ff
    inet 192.168.5.55/24 metric 1024 brd 192.168.5.255 scope global dynamic eth0
       valid_lft 86340sec preferred_lft 86340sec
    inet6 fe80::e65f:1ff:fe98:f65d/64 scope link 
       valid_lft forever preferred_lft forever
```

Edit **/opt/nk-macsec/mac-adddress-list.txt** and adjust all required addresses.

```
# nano /opt/nk-macsec/mac-adddress-list.txt

e4:5f:01:98:f6:5d
20:c6:eb:69:7f:f3
34:02:86:c1:5b:bf
00:26:c6:d6:b1:3e
00:1b:d3:dd:be:6e
f0:2f:74:d0:2c:1f
00:0b:97:51:84:d3
00:1d:e0:62:dd:91
08:11:96:fb:52:e4
00:00:00:00:00:03
00:00:00:00:00:04
00:00:00:00:00:05
00:00:00:00:00:06 
00:00:00:00:00:07
00:00:00:00:00:08 
00:00:00:00:00:09
```

### Configuring Nitrokey PIN code

It is **important** to change Nitrokey user PIN to match in **/opt/nk-macsec/rekey.sh** script. This script is run automatically when you insert you Nitrokey to your RPi. 

Edit file and change entries on line 41 and 50:

```
nano /opt/nk-macsec/rekey.sh script

/bin/nk-macsec -p [PIN_CODE] -s -i eth0 -f /opt/nk-macsec/mac-adddress-list.txt
...
/bin/nk-macsec -p [PIN_CODE] -g -i eth0 > /opt/nk-macsec/macsec.sh
```

### Dry run and activation

After these changes, you can insert your Nitrokey to RPi and see does it create file **/opt/nk-macsec/macsec.sh**. This script is automatically created by **nk-macsec** binary based on mac addresses on **/opt/nk-macsec/mac-adddress-list.txt** and macsec keys stored in Nitrokey.

If **/opt/nk-macsec/macsec.sh** gets created containing meaningful values for mac addresses and encryption keys, you can enable script execution in **/opt/nk-macsec/rekey.sh** script by uncommenting line 67:

```
#
# Execute macsec.sh
#
/opt/nk-macsec/macsec.sh
```

With this change, script will rekey macsec segment keys into your Nitrokey and activate macsec interface via macsec.sh script automatically on Nitrokey insert. 

## udev rules

Automation is handled by udev ruleset located at: **/etc/udev/rules.d/90-nk-macsec.rules** Depending your Nitrokey model (storage or Pro2), you need to adjust udev rule with idProduct as follows:

Nitrokey Pro2:

```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="4108", RUN+="/opt/nk-macsec/rekey.sh"
```

Nitrokey Storage:

```
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="4109", RUN+="/opt/nk-macsec/rekey.sh"
```

