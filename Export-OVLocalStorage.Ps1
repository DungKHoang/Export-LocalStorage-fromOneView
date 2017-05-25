## -------------------------------------------------------------------------------------------------------------
##
##
##      Description: Collect local storage of servers in OneView
##
## DISCLAIMER
## The sample scripts are not supported under any HPE standard support program or service.
## The sample scripts are provided AS IS without warranty of any kind. 
## HP further disclaims all implied warranties including, without limitation, any implied 
## warranties of merchantability or of fitness for a particular purpose. 
##
##    
## Scenario
##     	Export local storage
##	
## Description
##      The script exports server local storga to CSV files    
##		
##
## Input parameters:
##         OVApplianceIP                      = IP address of the OV appliance
##		   OVAdminName                        = Administrator name of the appliance
##         OVAdminPassword                    = Administrator's password
##         OVAuthDomain                       = "local" or AD domain name
##
## Pre-requisites
##       - HPE RESTCmdlets :                 https://www.powershellgallery.com/packages/HPRESTCmdlets/1.1.0.1
##       - HPE OneView PowerShell library :  https://github.com/HewlettPackard/POSH-HPOneView/releases
##
## -------------------------------------------------------------------------------------------------------------

Param ( [string]$OVApplianceIP    = "", 
        [string]$OVAdminName      = "Administrator", 
        [string]$OVAdminPassword  = "",
        [string]$OVAuthDomain     = "local"
    )


$RESTRoot      = "/rest/v1"
$RESTAccount   = "/rest/v1/AccountService"
$RESTChassis   = "/rest/v1/Chassis"
$RESTEvent     = "/rest/v1/EventService"
$RESTManagers  = "/rest/v1/Managers"
$RESTSession   = "/rest/v1/SessionService"
$RESTSystems   = "/rest/v1/Systems"

$PDFile        = "PhysicalDisk.CSV"
$LDFile        = "LogicalDisk.CSV"

$LDHeader      = "Server,Controller Model,Controller FW,Controller S/N,RAID Type,Logical Drive Size"
$PDHeader      = "Server,Controller Model,Controller FW,Controller S/N,Disk Number,Disk Size,Disk S/N, Disk Type, Disk Model"


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerDiskInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerDiskInfo
{
    Param($iLOSession, $Servername)

    $Systems = Get-HPRESTDataRaw -session $iLOSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $ControllerRef            = "$sys/Smartstorage/ArrayControllers"
        $ArrayControllers         =  Get-HPRESTDataRaw -session $iLOSession -href $ControllerRef
        foreach ($C in $ArrayControllers.links.member.href)
        { 
            $ThisController = Get-HPRESTDataRaw -session $iLOSession -href $C

            $FwVersion      = $ThisController.FirmwareVersion.Current.VersionString
            $Model          = $ThisController.Model
            $SN             = $Thiscontroller.SerialNumber
            
            $MemCache = "0"
            if ($Script:EnclosureName -eq $BL)
            {
                $MemCache       = $Thiscontroller.CacheMemorySizeMiB
            }

            # Get Logical Drives info
            $LDrivesref     = $Thiscontroller.Links.LogicalDrives.href

            $LDInventory = Get-HPRESTDataRaw -session $iLOSession -href $LDrivesref
            foreach ($LDref in $LDInventory.links.member.href)
            {
                $LD         = Get-HPRESTDataRaw -session $iLOSession -href $LDref
                $LDCapacity = [int]($LD.CapacityMiB /1KB)
                $LDSize     = $LD.StripeSizeBytes
                $LDRaidType = $LD.Raid

                            # $HeaderPrefix,Controller Model,Controller FW,Controller S/N,RAID Type,Logical Drive Size"
                $sLDArray += "$ServerName,$Model,$FWVersion,$SN,$LDRaidType,$LDCapacity`n"  

                
            }
            

            # Get Physical Drives info
            $PDCount         = 0
            $PDrivesRef      = $Thiscontroller.Links.PhysicalDrives.href

            $PDInventory = Get-HPRESTDataRaw -session $iLOSession -href $PDrivesref
            foreach ($PDRef in $PDinventory.Links.member.href)
            {
                $PD          = Get-HPRESTDataRaw -session $iLOSession -href $PDref
                $PDCount++
                $PDModel     = $PD.Model
                $PDSN        = $PD.SerialNumber
                $PDMediaType = $PD.MediaType
                $PDCapacity  = [int]($PD.CapacityMiB /1KB)
                

            #         $HeaderPrefix,Controller Model,Controller FW,Controller S/N,Disk Number,Disk Size,Disk S/N, Disk Type, Disk Model"
                $sPDArray += "$ServerName,$Model,$FWVersion,$SN,$PDCount,$PDCapacity,$PDSN,$PDMediatype,$PDModel`n"  
                
            }


        }

    }
    return $sLDArray,$sPDArray
   }


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Export-OVLocalStorage
##
## -------------------------------------------------------------------------------------------------------------

Function Export-OVLocalStorage($OVConnection)
{

$ListofGen89Servers = Get-hpovserver -ApplianceConnection $OVconnection | where Model -like "*GEN*"
$ListofOldServers   = Get-hpovserver -ApplianceConnection $OVconnection  | where Model -like "*G?"

set-content -path $LDFile -value $LDHeader -force
set-content -path $PDFile -value $PDHeader -force

if ($ListofGen89Servers)
{
    foreach ($ThisServer in $ListofGen89Servers)
    {
        
        $ThisRemoteConsole     = "$($ThisServer.Uri)/remoteConsoleUrl"
        $resp                  = Send-HPOVRequest $ThisRemoteConsole
        $URL,$session          = $resp.remoteConsoleUrl.Split("&")
        $http, $iLOIP          = $URL.split("=")
        $sName,$sessionkey     = $session.split("=")
        
        $rootURI   = "https://$iLOIP/rest/v1"

        $iloSession = new-object PSObject -Property @{"RootUri" = $rootURI ; "X-Auth-Token" = $sessionkey}    
        
        # Collect Storage info
        $Servername = '"' + $ThisServer.Name + '"'
        
        write-host -foreground Cyan "Collecting local storage information for server $ServerName ...." 
        $sLDArray, $sPDArray = Collect-ServerDiskInfo -ServerName $ServerName -iloSession $iLOSession
        add-content -path $LDFile   -Value $sLDArray    # Logical Disk
        add-content -path $PDFile   -Value $sPDArray    # Physical DiskCollect-ServerDiskInfo -iLOsession $iLOsession

    }
}


}


Disable-HPRESTCertificateAuthentication

$ThisConnection = Connect-HPOVMgmt -Hostname $OVApplianceIP -UserName $OVAdminName -Password $OVAdminPassword -AuthLoginDomain $OVAuthDomain

Export-OVLocalStorage -OVConnection $ThisConnection

$LD = dir $LDFile
$PD = dir $PDFile
write-host -foreground Cyan " Logical disk information for all Gen8/Gen9 servers is stored in $($LD.FullName)"
write-host -foreground Cyan " Physical disk information for all Gen8/Gen9 servers is stored in $($PD.FullName)"

Disconnect-HPOVMgmt