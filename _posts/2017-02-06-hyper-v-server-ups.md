---
layout: post
title: "Using a UPS to gracefully shut down a headless Hyper-V Server"
date: 2017-02-06
---

I run most of my servers with [Microsoft Hyper-V Server](https://technet.microsoft.com/en-us/hyper-v-server-docs/hyper-v-server-2016), which is a free version of the Microsoft Hyper-V hypervisor and just enough of an OS to support using Windows drivers and remote management with PowerShell or Remote Desktop. If you have used VMWare ESXi Server, you could compare it to this.

I wanted to protect my several terabytes of data stored on Storage Spaces and the boot SSD from corruption in case of a power outage. The Windows kernel that Hyper-V Server uses still has full power management support, which means I can have it monitor my UPS and automatically shut down the system before it runs out of battery power.

This was easy to do with PowerShell remoting!

## See if Windows detects the UPS

Make sure the UPS is detected as a battery with `Get-WmiObject -Namespace root\cimv2 Win32_Battery`

```
__GENUS                     : 2
__CLASS                     : Win32_Battery
__SUPERCLASS                : CIM_Battery
__DYNASTY                   : CIM_ManagedSystemElement
__RELPATH                   : Win32_Battery.DeviceID="JB0536025269  APCBack-UPS ES 500 FW:824.B1.D USB FW:B1"
__PROPERTY_COUNT            : 33
__DERIVATION                : {CIM_Battery, CIM_LogicalDevice, CIM_LogicalElement, CIM_ManagedSystemElement}
__SERVER                    : HYPERV1
__NAMESPACE                 : root\cimv2
__PATH                      : \\HYPERV1\root\cimv2:Win32_Battery.DeviceID="JB0536025269  APCBack-UPS ES 500
                              FW:824.B1.D USB FW:B1"
Availability                : 2
BatteryRechargeTime         :
BatteryStatus               : 2
Caption                     : Internal Battery
Chemistry                   : 3
ConfigManagerErrorCode      :
ConfigManagerUserConfig     :
CreationClassName           : Win32_Battery
Description                 : Internal Battery
DesignCapacity              :
DesignVoltage               : 13100
DeviceID                    : JB0536025269  APCBack-UPS ES 500 FW:824.B1.D USB FW:B1
ErrorCleared                :
ErrorDescription            :
EstimatedChargeRemaining    : 84
EstimatedRunTime            : 19
ExpectedBatteryLife         :
ExpectedLife                :
FullChargeCapacity          :
InstallDate                 :
LastErrorCode               :
MaxRechargeTime             :
Name                        : Back-UPS ES 500 FW:824.B1.D USB FW:B1
PNPDeviceID                 :
PowerManagementCapabilities : {1}
PowerManagementSupported    : False
SmartBatteryVersion         :
Status                      : OK
StatusInfo                  :
SystemCreationClassName     : Win32_ComputerSystem
SystemName                  : HYPERV1
TimeOnBattery               :
TimeToFullCharge            :
PSComputerName              : HYPERV1
```

I'm using an older UPS that was automatically detected by Windows. This is common with many older models that use serial ports, or use the same protocol with a USB to serial converter. If you see results, the you don't need to install any extra software in Windows to get basic monitoring and system shutdown functionality.

If you don't see anything here, then you will need to install drivers or software provided by the UPS manufacturer. 



## Viewing and Changing Power Settings

### Checking the initial settings

First, get the initial power settings with: `powercfg -list`

```
Existing Power Schemes (* Active)
-----------------------------------
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced) *
Power Scheme GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  (High performance)
Power Scheme GUID: a1841308-3541-4fab-bc81-f71556f20b4a  (Power saver)
```

I wanted to keep using the balanced settings for now, so run `powercfg -query` to see them:

```
[hyperv1]: PS C:\Users\Patrick\Documents> powercfg -query
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)
  GUID Alias: SCHEME_BALANCED
  Subgroup GUID: fea3413e-7e05-4911-9a71-700331f1c294  (Settings belonging to no subgroup)
    GUID Alias: SUB_NONE
    Power Setting GUID: 0e796bdb-100d-47d6-a2d5-f7d2daa51f51  (Require a password on wakeup)
      GUID Alias: CONSOLELOCK
      Possible Setting Index: 000
      Possible Setting Friendly Name: No
      Possible Setting Index: 001
      Possible Setting Friendly Name: Yes
    Current AC Power Setting Index: 0x00000001
    Current DC Power Setting Index: 0x00000001

...


    Power Setting GUID: 7648efa3-dd9c-4e3e-b566-50f929386280  (Power button action)
      GUID Alias: PBUTTONACTION
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000003
    Current DC Power Setting Index: 0x00000003

...

   Subgroup GUID: e73a048d-bf27-4f12-9731-8b2076e8891f  (Battery)
    GUID Alias: SUB_BATTERY
    Power Setting GUID: 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546  (Critical battery action)
      GUID Alias: BATACTIONCRIT
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000000
    Current DC Power Setting Index: 0x00000003

    Power Setting GUID: 8183ba9a-e910-48da-8769-14ae6dc1170a  (Low battery level)
      GUID Alias: BATLEVELLOW
      Minimum Possible Setting: 0x00000000
      Maximum Possible Setting: 0x00000064
      Possible Settings increment: 0x00000001
      Possible Settings units: %
    Current AC Power Setting Index: 0x0000000a
    Current DC Power Setting Index: 0x0000000a

    Power Setting GUID: 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469  (Critical battery level)
      GUID Alias: BATLEVELCRIT
      Minimum Possible Setting: 0x00000000
      Maximum Possible Setting: 0x00000064
      Possible Settings increment: 0x00000001
      Possible Settings units: %
    Current AC Power Setting Index: 0x00000005
    Current DC Power Setting Index: 0x00000005

    Power Setting GUID: bcded951-187b-4d05-bccc-f7e51960c258  (Low battery notification)
      GUID Alias: BATFLAGSLOW
      Possible Setting Index: 000
      Possible Setting Friendly Name: Off
      Possible Setting Index: 001
      Possible Setting Friendly Name: On
    Current AC Power Setting Index: 0x00000001
    Current DC Power Setting Index: 0x00000001

    Power Setting GUID: d8742dcb-3e6a-4b3c-b3fe-374623cdcf06  (Low battery action)
      GUID Alias: BATACTIONLOW
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000000
    Current DC Power Setting Index: 0x00000000
```


### Making changes

There were two things I wanted to do:

1. Make the power button gracefully shut down the system. This will make Hyper-V follow the VM's shutdown options then shut down the host gracefully.
2. Shut down the system automatically after a few minutes on battery. My goal isn't to get max uptime, just make sure it can shut down without losing data.

The first one was already done - the Power button action was set to 0x3, which is "Shut down":

```
    Power Setting GUID: 7648efa3-dd9c-4e3e-b566-50f929386280  (Power button action)
      GUID Alias: PBUTTONACTION
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000003
    Current DC Power Setting Index: 0x00000003
```

The second one required some changes. I decided to set 50% as the low battery level, 20% as critical, and shut down at the critical battery level.

This can be done with:
`powercfg -setdcvalueindex <Power Scheme Guid> <Subgroup Guid> <Setting Guid> <value>`

I pulled the GUIDs from my config above, and ran these three commands to make it so:


```powershell
powercfg -setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 50
powercfg -setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 20
powercfg -setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 3
```


Afterwards, I ran `powercfg -query` to double check that the settings were right:

```
Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)
  GUID Alias: SCHEME_BALANCED
  Subgroup GUID: fea3413e-7e05-4911-9a71-700331f1c294  (Settings belonging to no subgroup)
    GUID Alias: SUB_NONE
    Power Setting GUID: 0e796bdb-100d-47d6-a2d5-f7d2daa51f51  (Require a password on wakeup)
      GUID Alias: CONSOLELOCK
      Possible Setting Index: 000
      Possible Setting Friendly Name: No
      Possible Setting Index: 001
      Possible Setting Friendly Name: Yes
    Current AC Power Setting Index: 0x00000001
    Current DC Power Setting Index: 0x00000001

...


  Subgroup GUID: e73a048d-bf27-4f12-9731-8b2076e8891f  (Battery)
    GUID Alias: SUB_BATTERY
    Power Setting GUID: 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546  (Critical battery action)
      GUID Alias: BATACTIONCRIT
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000000
    Current DC Power Setting Index: 0x00000003

    Power Setting GUID: 8183ba9a-e910-48da-8769-14ae6dc1170a  (Low battery level)
      GUID Alias: BATLEVELLOW
      Minimum Possible Setting: 0x00000000
      Maximum Possible Setting: 0x00000064
      Possible Settings increment: 0x00000001
      Possible Settings units: %
    Current AC Power Setting Index: 0x0000000a
    Current DC Power Setting Index: 0x00000032

    Power Setting GUID: 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469  (Critical battery level)
      GUID Alias: BATLEVELCRIT
      Minimum Possible Setting: 0x00000000
      Maximum Possible Setting: 0x00000064
      Possible Settings increment: 0x00000001
      Possible Settings units: %
    Current AC Power Setting Index: 0x00000005
    Current DC Power Setting Index: 0x00000014

    Power Setting GUID: bcded951-187b-4d05-bccc-f7e51960c258  (Low battery notification)
      GUID Alias: BATFLAGSLOW
      Possible Setting Index: 000
      Possible Setting Friendly Name: Off
      Possible Setting Index: 001
      Possible Setting Friendly Name: On
    Current AC Power Setting Index: 0x00000001
    Current DC Power Setting Index: 0x00000001

    Power Setting GUID: d8742dcb-3e6a-4b3c-b3fe-374623cdcf06  (Low battery action)
      GUID Alias: BATACTIONLOW
      Possible Setting Index: 000
      Possible Setting Friendly Name: Do nothing
      Possible Setting Index: 001
      Possible Setting Friendly Name: Sleep
      Possible Setting Index: 002
      Possible Setting Friendly Name: Hibernate
      Possible Setting Index: 003
      Possible Setting Friendly Name: Shut down
    Current AC Power Setting Index: 0x00000000
    Current DC Power Setting Index: 0x00000000
```

The next time the power goes out, I'll check the event logs to see if it shut down gracefully or unexpectedly.