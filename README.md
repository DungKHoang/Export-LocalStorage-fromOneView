# Collect Local Storage of Servers in OneView

Export-OVLocalStorage.ps1 is a PowerShell script that collects information about logical and physical disks of servers being managed under OneView.
The script queries servers only of Gen8/Gen9 generations and they can be either DL or BL.

## Prerequisites
The script leverages the follwoing PowerShell libraries:
* OneView PowerShell library : https://github.com/HewlettPackard/POSH-HPOneView/releases
* HPE REST cmdlets           : https://www.powershellgallery.com/packages/HPRESTCmdlets/1.1.0.0



## Syntax


```
    .\Export-OVLocalStorage.ps1 -OVApplianceIP <OV-IP-Address> -OVAdminName <Admin-name> -OVAdminPassword <password> 

```

## Output

    Check the samples.zip for output of the script.
