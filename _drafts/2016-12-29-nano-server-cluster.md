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


The Nano Server image generator needs a CAB file, which is inside the MSU. Extract the MSU with `expand <file.msu> -f:* <destination directory>`

```
expand windows10.0-kb3206632-x64_b2e20b7e1aa65288007de21e88cd21c3ffb05110.msu  -f:* .
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
```


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



Set up remote management client
```
net start winrm
PS C:\WINDOWS\system32> Set-Item WSMan:\localhost\Client\TrustedHosts -Force -Value "192.168.1.114,192.168.1.115,192.168
.1.116"
PS C:\WINDOWS\system32> $credential = get-credential

cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
Credential
PS C:\WINDOWS\system32> Enter-PSSession -Credential $credential 192.168.1.116
[192.168.1.116]: PS C:\Users\Administrator\Documents>
```

Check the version with `(Get-ComputerInfo).WindowsBuildLabEx`:

```
WindowsBuildLabEx                                       : 14393.576.amd64fre.rs1_release_inmarket.161208-2252
```

Now, you may install Docker using Windows PowerShell remoting with the steps described in [Container host deployment - Nano Server](https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/deploy-containers-on-nano). However, there are a few workarounds needed.

> **Temporary step - update to Docker v1.13-rc4**
> As of December 2016, the Docker OneGet provider installs a beta version 1.12.2-cs2-ws-beta. Docker Swarm mode requires v1.13, so we need to update to the latest release candidate build. Once v1.13 ships, Docker and Microsoft will be updating the OneGet provider to use it.
>```powershell
Import-Module "C:\Program Files\WindowsPowerShell\Modules\DockerMsftProvider\1.0.0.1\SaveHTTPItemUsingBITS.psm1"
Stop-Service Docker
dockerd.exe --unregister-service
Save-HTTPItemUsingBitsTransfer -Uri "https://test.docker.com/builds/Windows/x86_64/docker-1.13.0-rc4.zip" -Destination "$env:TEMP\docker-1.13.0-rc4.zip" 
Expand-Archive -Path "$env:TEMP\docker-1.13.0-rc4.zip" -DestinationPath $env:ProgramFiles -Force
dockerd.exe --register-service
Start-Service Docker
```
>
>Double check that it worked: 
>```
docker version
```


**TL;DR version**
I captured all of this into a [Install-Docker.ps1]({{site.url}}/scripts/2016-12-29-nano-server-cluster/Install-Docker.ps1)script that's easy to run against the remote servers.

```powershell
# Capture the administrator password
$credential = get-credential

# Get a list of server IPs and create a session for each one
$serverIPs = "192.168.1.114", "192.168.1.115", "192.168.1.116"
$sessions =  $serverIPs | ForEach-Object { New-PSSession -ComputerName $_ -Credential $credential }

# Run against the remote servers one at a time so you can watch Progress
Invoke-Command -Session $sessions[0] -FilePath .\install-Docker.ps1
Invoke-Command -Session $sessions[1] -FilePath .\install-Docker.ps1
Invoke-Command -Session $sessions[2] -FilePath .\install-Docker.ps1
```


You will see some progress from each OneGet installation followed by a final `docker version` output after the upgrade is done.

```none
PSComputerName       : 192.168.1.115
RunspaceId           : 63e5a197-20a2-42fb-a51e-e2071dca6b43
FastPackageReference : https://oneget.org/nugetv2-coreclr-2.8.5.205.package.swidtag
ProviderName         : Bootstrap
Source               : https://oneget.org/nugetv2-coreclr-2.8.5.205.package.swidtag
Status               : Installed
SearchKey            : https://oneget.org/nugetv2-coreclr-2.8.5.205.package.swidtag
FullPath             :
PackageFilename      : Microsoft.PackageManagement.NuGetProvider.dll
FromTrustedSource    : False
Summary              : NuGet provider for the OneGet meta-package manager
...


WARNING: KB3176936 or later is required for docker to work. Please ensure this is installed.
WARNING: A restart is required to start docker service. Please restart your machine.
WARNING: After the restart please start the docker service.
PSComputerName       : 192.168.1.115
RunspaceId           : 63e5a197-20a2-42fb-a51e-e2071dca6b43
FastPackageReference : DockerDefault|#|Docker|#|1.12.2-cs2-ws-beta|#|Contains the CS Docker Engine for use with Windows Server 2016 and Nano
                       Server.|#|10/10/2016 16:28:18|#|https://dockermsft.blob.core.windows.net/dockercontainer/docker-1-12-2-cs2-ws-beta.zip|#|1
                       4183015|#|FEFEB0CD5566550E9ECAFB87CF26C78AFC8643B2450F2AC0203F6B88BE15B68D
ProviderName         : DockerMsftProvider
Source               : DockerDefault
Status               : Installed
SearchKey            :
FullPath             :
PackageFilename      :
FromTrustedSource    : False
Summary              : Contains the CS Docker Engine for use with Windows Server 2016 and Nano Server.
...


Client:
 Version:      1.13.0-rc4
 API version:  1.25
 Go version:   go1.7.3
 Git commit:   88862e7
 Built:        Sat Dec 17 01:34:17 2016
 OS/Arch:      windows/amd64

Server:
 Version:      1.13.0-rc4
 API version:  1.25 (minimum version 1.24)
 Go version:   go1.7.3
 Git commit:   88862e7
 Built:        Sat Dec 17 01:34:17 2016
 OS/Arch:      windows/amd64
 Experimental: false
 ```
