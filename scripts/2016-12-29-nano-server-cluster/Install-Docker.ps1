Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

Import-Module "C:\Program Files\WindowsPowerShell\Modules\DockerMsftProvider\1.0.0.1\SaveHTTPItemUsingBITS.psm1"
Stop-Service Docker
dockerd.exe --unregister-service
Save-HTTPItemUsingBitsTransfer -Uri "https://test.docker.com/builds/Windows/x86_64/docker-1.13.0-rc4.zip" -Destination "$env:TEMP\docker-1.13.0-rc4.zip" 
Expand-Archive -Path "$env:TEMP\docker-1.13.0-rc4.zip" -DestinationPath $env:ProgramFiles -Force
dockerd.exe --register-service
Start-Service Docker
docker.exe version