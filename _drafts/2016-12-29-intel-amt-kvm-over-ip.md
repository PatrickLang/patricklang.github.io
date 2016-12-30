---
layout: post
title: "Setting up machines using Intel AMT for KVM over IP and storage redirection"
date: 2016-12-29
---



## What's needed
- A machine with [Intel Active Management Technology](https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/default.htm?turl=WordDocuments%2Fkvmandintelamt.htm) support, version 6.0 or later. I'm using the [Lenovo Thinkcentre M900 tiny](http://shop.lenovo.com/us/en/desktops/thinkcentre/m-series-tiny/m900/?cid=us:sem|se|msn|kw_1|Lenovo__Desktop_M900|NX_Lenovo_SMB_Desktops)
- [MeshCommander](http://www.meshcommander.com/meshcommander) installed on another Windows, Linux, or Mac machine on the same local network.


## Enabling Intel AMT and KVM
The steps will vary somewhat by machine. I'm showing the Lenovo Thinkcentre M900, but most business machines should have similar options available in their BIOS/UEFI settings.

