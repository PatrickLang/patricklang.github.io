---
layout: post
title: "Finding the switch port for an IP or MAC on Mikrotik RouterOS"
date: 2017-02-06
---

Want to know what port a machine is connected to on a Mikrotik RouterOS device? Do you need to disable it and enable it to force DHCP renewal? Read on.

## Finding the MAC address

There are two ways to do this. 

1. If you are using a DHCP server on this router, then you can use `/ip dhcp-server lease print`
2. If it's just a switch, then you can try using the ARP table instead: `/ip arp print`

Once you have the MAC address, go see what port it's connected to. There may be multiple MACs per port if there's a downstream switch, or in my case a Hyper-V host with a virtual switch.

## Finding the switch port by MAC address

`/interface ethernet switch host print` will show all of the devices on the network by MAC address, along with the port they're connected to. This is very similar to the `show mac address-table` command on Cisco Catalyst switches.

```
[admin@MikroTik] /interface ethernet> /interface ethernet switch host print
Flags: D - dynamic, I - invalid
 #   SWITCH                          MAC-ADDRESS       PORTS                         TIMEOUT DROP MIRROR VLAN-ID
 0 D switch1                         B8:27:EB:28:6B:24 ether4                        2m22s                     1
 1 D switch1                         00:0E:8F:84:3E:3A ether2-master                 2m25s                     1
 2 D switch1                         E8:40:F2:06:25:A8 ether4                        2m29s                     1
22 D switch1                         00:15:5D:01:62:00 ether5                        2m29s                     1
23 D switch1                         00:1B:21:6A:92:AE ether5                        2m25s                     1

```


## Toggling the switch port

If `00:1B:21:6A:92:AE` is what you were looking for, then you can cycle that port by disabling it, then enabling it:

 - `set ether5 disabled=yes`
 - `set ether5 disabled=no`
