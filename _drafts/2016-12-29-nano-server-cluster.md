---
layout: post
title: "Setting up a 3-node cluster on Nano Server"
date: 2016-12-29
---



## Mount the server disk image
mount-diskimage (Get-Item *.iso).fullName


## Download the latest Windows Server 2016 update
https://support.microsoft.com/en-us/help/4000825/windows-10-update-history

Under _How to get this update_ heading, click the the _Microsoft Update Catalog_ link. Example:
http://catalog.update.microsoft.com/v7/site/Search.aspx?q=KB3206632

PS E:\nanoserver> expand C:\Users\Patrick.coffee\Downloads\windows10.0-kb3206632-x64_b2e20b7e1aa65288007de21e88cd21c3ffb
05110.msu  -f:* .
Microsoft (R) File Expansion Utility
Copyright (c) Microsoft Corporation. All rights reserved.

Adding .\WSUSSCAN.cab to Extraction Queue
Adding .\Windows10.0-KB3206632-x64.cab to Extraction Queue
Adding .\Windows10.0-KB3206632-x64-pkgProperties.txt to Extraction Queue
Adding .\Windows10.0-KB3206632-x64.xml to Extraction Queue

Expanding Files ....
Progress: 1 out of 4 files
Expanding Files Complete ...
4 files total.


## Create the image using the generator

<!-- screenshots, etc -->

```
New-NanoServerImage -MediaPath 'G:\' -Edition 'Datacenter' -DeploymentType Host -TargetPath 'e:\nanoserver\m900-2.vhdx' -MaxSize 8589934592 -SetupUI ('NanoServer.Containers', 'NanoServer.FailoverCluster', 'NanoServer.Storage', 'NanoServer.Compute', 'NanoServer.OEM-Drivers') -ServicingPackagePath ('E:\nanoserver\Windows10.0-KB3206632-x64.cab') -ComputerName 'plang-m9-1' -SetupCompleteCommand ('tzutil.exe /s "Pacific Standard Time"') -LogPath 'e:\temp\NanoServerImageBuilder\Logs\2016-12-20 23-08'
```



## Create the USB key


## Create the ISO



## Boot it and watch it run


http://www.meshcommander.com/meshcommander




## Watch for reboot


> Gotcha - if it boots to the old OS and you have more than one drive, you will need to clear it out or use `bcdedit /delete` to remove the old boot entry



net start winrm
Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.1.186 -Force


Check the version with `(Get-ComputerInfo).WindowsBuildLabEx`:

```
WindowsBuildLabEx                                       : 14393.576.amd64fre.rs1_release_inmarket.161208-2252
```