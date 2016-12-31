---
layout: post
title: "Setting up a 3-node cluster on Nano Server"
date: 2016-12-29
---


This is a work in progress for building a 3-node cluster lab with Docker Swarm and Windows Failover Clustering


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

> Note - the default image size for the Nano Server image generator is 8GB. The Nano Server installer formats the first disk in the system, copies the VHDX to it, and configures the system to boot from VHDX. As a result - most of your free disk space will be on D:, not C:. This will be important to know later.

## Create the USB key


## Create the ISO



## Boot it and watch it run


http://www.meshcommander.com/meshcommander




## Watch for reboot


> Gotcha - if it boots to the old OS and you have more than one drive, you will need to clear it out or use `bcdedit /delete` to remove the old boot entry



## Set up a workstation for PowerShell remote management
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

Since I'm setting up multiple machines, I'll save time by opening PowerShell sessions to each. Now I can forget about username, passwords, and IPs.

```powershell
# Capture the administrator password
$credential = get-credential

# Get a list of server IPs and create a session for each one
$serverIPs = "192.168.1.114", "192.168.1.115", "192.168.1.116"
$sessions =  $serverIPs | ForEach-Object { New-PSSession -ComputerName $_ -Credential $credential }
```

## Install Docker

Now, you may install Docker using Windows PowerShell remoting with the steps described in [Container host deployment - Nano Server](https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/deploy-containers-on-nano). However, there are a few workarounds needed.


**TL;DR Version**
I captured all of the steps I used into [Install-Docker.ps1]({{site.url}}/scripts/2016-12-29-nano-server-cluster/Install-Docker.ps1) that's easy to run against the remote servers. You can modify and reuse it for your needs, or read on to learn more of the details.

```powershell
# Run against the remote servers one at a time so you can watch Progress
Invoke-Command -Session $sessions[0] -FilePath .\install-Docker.ps1
Invoke-Command -Session $sessions[1] -FilePath .\install-Docker.ps1
Invoke-Command -Session $sessions[2] -FilePath .\install-Docker.ps1
```


You will see some progress from each OneGet installation followed by a final `docker version` output after the upgrade is done.

```
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

**Redirecting Docker image storage**

If you don't have at least 20GB of space on C:, now is a good time to choose another place to store container images. If you used the default VHDX size in the Nano Server Image Generator, then it will look something like this:

```
[192.168.1.115]: PS C:\Users\Administrator\Documents> get-volume

DriveLetter FileSystemLabel FileSystem DriveType HealthStatus OperationalStatus SizeRemaining    Size
----------- --------------- ---------- --------- ------------ ----------------- -------------    ----
C                           NTFS       Fixed     Healthy      OK                      6.33 GB 7.65 GB
D           MAIN            NTFS       Fixed     Healthy      OK                     69.02 GB   80 GB
```


The [Docker Engine on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon) page has many examples, but here are some steps to create a `c:\ProgramData\docker\config\daemon.json` that will move container storage to `d:\docker`

```powershell

$daemonjson=@"
{ 
    "graph": "d:\\docker"
}
"@

Invoke-Command -Session $sessions[1] -ScriptBlock { 
    Stop-Service docker
    $Using:daemonjson | Out-File -Encoding ascii c:\ProgramData\docker\config\daemon.json
    Start-Service docker
}
```


Now that each server is set up with the Docker engine, it's time to form a swarm!

## Setting up Docker Swarm

Setting up a Docker Swarm is just a few easy steps:
- Run `docker swarm init` on the first node
- Run `docker swarm join` on each remaining node


TL;DR 

```powershell
# Open the ports on each host
Invoke-Command -Session $sessions[0] -ScriptBlock { netsh advfirewall firewall add rule name="Docker swarm" dir=in action=allow protocol=TCP localport=2377 }
Invoke-Command -Session $sessions[1] -ScriptBlock { netsh advfirewall firewall add rule name="Docker swarm" dir=in action=allow protocol=TCP localport=2377 }
Invoke-Command -Session $sessions[2] -ScriptBlock { netsh advfirewall firewall add rule name="Docker swarm" dir=in action=allow protocol=TCP localport=2377 }


# Create the swarm
Invoke-Command -Session $sessions[0] -ScriptBlock { docker.exe swarm init --advertise-addr $Using:sessions[0].ComputerName }

# Get the manager token
$managerToken = Invoke-Command -Session $sessions[0] -ScriptBlock { docker.exe swarm join-token manager -q }

# Join the other nodes as managers
Invoke-Command -Session $sessions[1] -ScriptBlock { docker.exe swarm join --token $Using:managerToken "$($Using:sessions[0].ComputerName):2377" }
Invoke-Command -Session $sessions[2] -ScriptBlock { docker.exe swarm join --token $Using:managerToken "$($Using:sessions[0].ComputerName):2377" }
# Each should return "This node joined a swarm as a manager."
```

## Enable TLS
PowerShell remoting is great for getting things set up, but Docker also has its own client (docker.exe) that can handle remote connections. You can enable an unencrypted, unauthenticated connection but it's better to secure your connection with TLS. Stefan Scherer has a great post [How to protect a Windows Docker engine with TLS](https://stefanscherer.github.io/protecting-a-windows-2016-docker-engine-with-tls/) on how to achieve this. 

We'll use the same steps, but put the same certificate onto each of the 3 hosts.

Create the certificates and config.json
```powershell
# Make a list of all IPs
$serverIPsJoined = $serverIPs -Join ","

# Create the directories to store the certs and then generate them using the stefanscherer/dockertls-windows container
Invoke-Command -Session $sessions[0] -ScriptBlock {
    mkdir server  
    mkdir client\.docker 
    docker run --rm `
        --isolation=hyperv `
        -e SERVER_NAME=$(hostname) `
        -e IP_ADDRESSES=$Using:serverIPsJoined `
        -v "$(pwd)\server:C:\ProgramData\docker" `
        -v "$(pwd)\client\.docker:C:\Users\ContainerAdministrator\.docker" `
        stefanscherer/dockertls-windows
}
```
> A few notes...
> - The `docker pull` progress look odd since Invoke-Command's output redirection isn't a full console redirection. To work arond this, you can use Enter-PSSession instead.
> - This may take several minutes to download and extract if you haven't used a container based on `microsoft/windowsservercore` before. 

> TODO: Copy CA cert out

> TODO: generate certs for nth servers & update config.json

Now, open the ports on each host:

```powershell
Invoke-Command -Session $sessions[0] -ScriptBlock { netsh advfirewall firewall add rule name="Docker Engine (TLS)" dir=in action=allow protocol=TCP localport=2376 }
Invoke-Command -Session $sessions[1] -ScriptBlock { netsh advfirewall firewall add rule name="Docker Engine (TLS)" dir=in action=allow protocol=TCP localport=2376 }
Invoke-Command -Session $sessions[2] -ScriptBlock { netsh advfirewall firewall add rule name="Docker Engine (TLS)" dir=in action=allow protocol=TCP localport=2376 }
```
