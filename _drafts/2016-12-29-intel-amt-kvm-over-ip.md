---
layout: post
title: "Setting up machines using Intel AMT for KVM over IP and storage redirection"
date: 2016-12-29
---



## What's needed
- A machine with [Intel Active Management Technology](https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/default.htm?turl=WordDocuments%2Fkvmandintelamt.htm) support, version 6.0 or later. I'm using the [Lenovo Thinkcentre M900 tiny](http://shop.lenovo.com/us/en/desktops/thinkcentre/m-series-tiny/m900/?cid=us:sem|se|msn|kw_1|Lenovo__Desktop_M900|NX_Lenovo_SMB_Desktops)
- [MeshCommander](http://www.meshcommander.com/meshcommander) installed on another Windows, Linux, or Mac machine on the same local network.


## Enabling Intel AMT and KVM
When you get a new machine, this is probably disabled by default for security reasons. You will need to enable it, and set a password for the default admin account before you can connect to it remotely.

The steps will vary somewhat by machine. I'm showing the Lenovo Thinkcentre M900, but most business machines should have similar options available in their BIOS/UEFI settings.

1. Enable Intel Manageability Control & MEBx hotkey:

![Enable AMT]({{site.url}}/images/2016-12-29-intel-amt/enable-manageability.PNG)


2. Save settings, and enter MEBx
There should be another prompt to get to the Intel Management Engine (MEBx) settings. On this machine, I needed to press <Ctrl-P> immediately when I turned it on.

Here I needed to:
- Log into MEBx. The default username is `admin`, and the password is also `admin`
- Set these settings
    - Intel ME General settings
        - Change ME password
    - Intel AMT Configuration
        - SOL/Storage Redirection/KVM
            - Set `Username and Password` = Enabled
            - Set `SOL` = Enabled
            - Set `Storage Redirection` = Enabled
            - Set `KVM Feature Selection` = Enabled
        - User Consent
            - Set `User Opt-in` = None
        - Network Setup
            - TCP/IP settings
                - Wired LAN IPV4 Configuration
                    - `DHCP Mode` = Enabled

## Using MeshCommander to connect
