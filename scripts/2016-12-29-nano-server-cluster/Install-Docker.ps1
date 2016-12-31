# Install the default Docker Engine using the OneGet provider
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force


# If D: exists and has more space, store containers there
$daemonjson=@"
{ 
    "graph": "d:\\docker"
}
"@

if (Test-Path d:\) {
    if ((Get-Volume c).SizeRemaining -le (Get-Volume d).SizeRemaining) {
        Stop-Service docker
        $daemonjson | Out-File -Encoding ascii c:\ProgramData\docker\config\daemon.json
        Start-Service docker
    }
}

# TEMP: Update to Docker v1.13-rc4
Import-Module "C:\Program Files\WindowsPowerShell\Modules\DockerMsftProvider\1.0.0.1\SaveHTTPItemUsingBITS.psm1"
Stop-Service Docker
dockerd.exe --unregister-service
Save-HTTPItemUsingBitsTransfer -Uri "https://test.docker.com/builds/Windows/x86_64/docker-1.13.0-rc4.zip" -Destination "$env:TEMP\docker-1.13.0-rc4.zip" 
Expand-Archive -Path "$env:TEMP\docker-1.13.0-rc4.zip" -DestinationPath $env:ProgramFiles -Force
dockerd.exe --register-service
Start-Service Docker
docker.exe version