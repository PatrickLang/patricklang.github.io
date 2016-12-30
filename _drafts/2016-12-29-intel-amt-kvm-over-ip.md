---
layout: post
title: "Setting up machines using Intel AMT for KVM over IP and storage redirection"
date: 2016-12-29
---



## What's needed
- A machine with [Intel Active Management Technology](https://software.intel.com/sites/manageability/AMT_Implementation_and_Reference_Guide/default.htm?turl=WordDocuments%2Fkvmandintelamt.htm) support, version 6.0 or later. I'm using the [Lenovo Thinkcentre M900 tiny](http://shop.lenovo.com/us/en/desktops/thinkcentre/m-series-tiny/m900/)
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
            - `Activate Network Access`

![Activate]({{site.url}}/images/2016-12-29-intel-amt/activate.png)

After the last step, exit MEBx.

You can unplug the keyboard and mouse, and put it in a closet. It's time to move onto using the KVM to install the OS!

## Using MeshCommander to connect

Now, launch MeshCommander on another machine.

Click `Scan`, and enter the DHCP IP range for your local network.

![MeshCommander Scan]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-scan.PNG)

After a few seconds, it will list all the machines found with Intel AMT enabled.

![MeshCommander Scan Results]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-results.PNG)

Check the box next to all of them, and click `Ok`

Looks easy, right? Well, not quite. MeshCommander never asked for the username & password.

Right click each one in the list, and go to `Edit`. The username (admin) and password go there.

![MeshCommander Edit Computer]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-edit.PNG)

Now, you're ready to connect. You can click `Connect` next to any of the computers, or you can hold shift and click it to open it in a new window.

![MeshCommander Connected]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-connected.PNG)

If you click `Remote Desktop` in the left pane, you can normally connect using KVM over IP. However, the first time you need to click the warning at the top, and enable both `Redirection Port` and `Remote Desktop`

![MeshCommander Connected]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-redirection.PNG)

Then, you can connect.

### Installing with an ISO
Intel AMT & MeshCommander also have _Storage Redirection_, which is convenient for installing an OS from an ISO file. This is convenient, but not as fast as using a USB drive attached directly to the computer or a PXE-based installation.

Click IDE-R, then `Choose file` next to ISO. If you want to use it right away, choose `Start` = Immediately.

![MeshCommander ISO]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-iso.PNG)

To force booting from the ISO, click `Power Actions`, then `Reset to IDE-R CDROM`. That will reset the machine, which will drop the KVM connection. Hit `Connect` again right away so you can watch the boot progress.

If you're booting Windows and there is already an OS installed, be ready to press the _any_ key right away :)

![MeshCommander Booting from ISO]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-boot-iso.png)

I created a Nano Server ISO with the [Nano Server Image Builder](https://blogs.technet.microsoft.com/nanoserver/2016/10/15/introducing-the-nano-server-image-builder/) for this example, so now it's time to just sit back and wait.
![MeshCommander Installing Nano Server from ISO]({{site.url}}/images/2016-12-29-intel-amt/meshcommander-installing-nano.PNG)

Once it's done, it will automatically reboot and I can disconnect.