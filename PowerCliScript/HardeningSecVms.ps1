#Requires -Version 5.1
#Requires -RunAsAdministrator   

<#
.Synopsis
   Hardening VM
.DESCRIPTION
   Hardening and Sec VM Vcenter 6.5
.EXAMPLE
   Insert after create main function
.URL
  https://blogs.vmware.com/vsphere/2017/06/secure-default-vm-disable-unexposed-features.html
  https://blogs.vmware.com/vsphere/2017/04/vsphere-6-5-security-configuration-guide-now-available.html
  https://www.vmware.com/security/hardening-guides.html
  https://blogs.vmware.com/vsphere/2018/03/announcing-vsphere-6-5-update-1-security-configuration-guide.html
.EXAMPLE
   Inserir posteriormente
.CREATEDBY
    Juliano Alves de Brito Ribeiro (julianoalvesbr@live.com)
.VERSION INFO
    0.5.2
.TO THINK
    Seria possível que a vida evoluísse aleatoriamente a partir de matéria inorgânica? Não de acordo com os matemáticos.

    Nos últimos 30 anos, um número de cientistas proeminentes têm tentado calcular as probabilidades de que um organismo de vida livre e unicelular, como uma bactéria, pode resultar da combinação aleatória de blocos de construção pré-existentes. 
    Harold Morowitz calculou a probabilidade como sendo uma chance em 10^100.000.000.000
    Sir Fred Hoyle calculou a probabilidade de apenas as proteínas de amebas surgindo por acaso como uma chance em 10^40.000.

    ... As probabilidades calculadas por Morowitz e Hoyle são estarrecedoras. 
    Essas probabilidades levaram Fred Hoyle a afirmar que a probabilidade de geração espontânea 'é a mesma que a de que um tornado varrendo um pátio de sucata poderia montar um Boeing 747 com o conteúdo encontrado'. 
    Os matemáticos dizem que qualquer evento com uma improbabilidade maior do que uma chance em 10^50 faz parte do reino da metafísica - ou seja, um milagre.1

    1. Mark Eastman, MD, Creation by Design, T.W.F.T. Publishers, 1996, 21-22.

.IMPROVEMENTS
    0.5.2
    Blocks to choose enabled and disable:
        Copy Paste;
        VMDK BACKUP;
        Completely Disable Time Sync with ESXi
    
#>

Clear-Host

#VALIDATE MODULE
    $moduleExists = Get-Module -Name Vmware.VimAutomation.Core

    if ($moduleExists){
    
        Write-Output "The Module Vmware.VimAutomation.Core is already loaded"
    
    }#if validate module
    else{
    
        Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
    }#else validate module


function Script:Pause-PSScript
{

   Read-Host 'Pressione [ENTER] para continuar' | Out-Null

}

Write-Host "ATTENTION: RUN THE SCRIPT REMOTELY. IT IS NOT NECESSARY TO COPY TO THE VM (s)" -ForegroundColor White -BackgroundColor Red

Write-Output "`n"

Write-Host "ATTENTION: RUN THE SCRIPT WITH THE VM(s) POWERED ON. AFTER RUNNING, JUST RESTART THEM TO APPLY THE SETTINGS" -ForegroundColor White -BackgroundColor Red

Pause-PSScript 


$Script_Parent = Split-Path -Parent $MyInvocation.MyCommand.Definition  

$reportPathExists = Test-Path -Path "$Script_Parent\ReportHardSec"

$inputPathExists = Test-Path -Path "$Script_Parent\VMsInputList"

if (!($reportPathExists)){

    Write-Host "Folder Named: ReportHardSec does not exists. I will create it" -ForegroundColor Yellow -BackgroundColor Black

    New-Item -Path $Script_Parent -ItemType Directory -Name "ReportHardSec" -Confirm:$true -Verbose -Force

}else{

    Write-Host "Folder Named: ReportHardSec exists" -ForegroundColor White -BackgroundColor Blue
    
    Write-Output "`n"
 
}


#FUNCTION TO SET VM HARDENING - DOES NOT CHANGE ANYTHING !!!!!
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-VMHardeningSec
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Object[]]
        $vmList,
        [Parameter(Mandatory = $true, Position = 1)]
        [System.Boolean]
        $disableCopyPaste=$true,
        [Parameter(Mandatory = $true, Position = 2)]
        [System.Boolean]
        $ConfigBackupParam=$false,
        [Parameter(Mandatory = $false, Position = 3)]
        [System.Boolean]
        $DisableTimeSyncFull=$false
    
    )

forEach ($vmGuest in $vmList){

    
    #Save Current Settings
    Write-Output "Advanced Settings of VM: $vmGuest" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
            
    Get-AdvancedSetting -Entity $vmGuest | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
    
       
######Limit informational messages from the VM to the VMX file    
    $paramName = ""
    $paramName = "tools.setInfo.sizeLimit"
    
    $toolsSetInfoSizeLimitParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($toolsSetInfoSizeLimitParam){
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $toolsSetInfoSizeLimitValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($toolsSetInfoSizeLimitValue -eq "1048576"){
            
            Write-Output "The Value of $paramName is: $toolsSetInfoSizeLimitValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 1048576 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
         Get-VM -Name $vmGuest  | New-AdvancedSetting -Name $paramName -value 1048576 -Confirm:$False -Verbose
        
}#END of Main Else 
    
######Disable 3D features on Server and desktop virtual machines   
    $paramName = ""
    $paramName = "mks.enable3d"
    
    
    $mksenable3DParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($mksenable3DParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $mksenable3DValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($mksenable3DValue -eq 'False'){
            
            Write-Output "The Value of $paramName is: $mksenable3DValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "False" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value "False" -Confirm:$False -Verbose

}#END of Main Else

  
########Disable certain unexposed features
########VMCH-06-000021
    $paramName = ""
    $paramName = "isolation.tools.unity.push.update.disable"
       
      
    $isolationtoolsunitypushupdatedisableParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($isolationtoolsunitypushupdatedisableParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $isolationtoolsunitypushupdatedisableValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($isolationtoolsunitypushupdatedisableValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $isolationtoolsunitypushupdatedisableValue. Value OK"
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -Value "True" -Confirm:$False -Verbose

}#END of Main Else 


######Disable certain unexposed features - Launch Menu   
    $paramName = ""
    $paramName = "isolation.tools.ghi.launchmenu.change"
    
    
    $isolationtoolsghilaunchmenuchangeParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($isolationtoolsghilaunchmenuchangeParam){
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $isolationtoolsghilaunchmenuchangeValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($isolationtoolsghilaunchmenuchangeValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $isolationtoolsghilaunchmenuchangeValue . Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -Value "True" -Confirm:$False -Verbose

}#END of Main Else 


######Disable certain unexposed features 
######VMCH-06-000013
######http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-60E83710-8295-41A2-9C9D-83DEBB6872C2.html
    $paramName = ""
    $paramName = "isolation.tools.memSchedFakeSampleStats.disable"

    $VMdisableunexposedfeaturesmemsfssParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMdisableunexposedfeaturesmemsfssParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $VMdisableunexposedfeaturesmemsfssValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMdisableunexposedfeaturesmemsfssValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $VMdisableunexposedfeaturesmemsfssValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $true -Confirm:$False -Verbose

}#END of Main Else
    
######Disable certain unexposed features 
######VMCH-06-000009
######http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-60E83710-8295-41A2-9C9D-83DEBB6872C2.html
    $paramName = ""
    $paramName = "isolation.tools.ghi.autologon.disable"

    $VMdisableunexposedfeaturesautologonParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMdisableunexposedfeaturesautologonParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"

        $VMdisableunexposedfeaturesautologonValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMdisableunexposedfeaturesautologonValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $VMdisableunexposedfeaturesautologonValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $true -Confirm:$False -Verbose

}#END of Main Else 

   
#####DISABLE OR ENABLE COPY PASTE
if ($disableCopyPaste){


#Explicitly disable copy/paste operations
#VMCH-06-000004
#http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-367D02C1-B71F-4AC3-AA05-85033136A667.html
    $paramName = ""
    $paramName = "isolation.tools.paste.disable"


    $VMdisableconsolePasteParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMdisableconsolePasteParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $VMdisableconsolePasteValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMdisableconsolePasteValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $VMdisableconsolePasteValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $true -Confirm:$False -Verbose

}#END of Main Else

#Explicitly disable copy/paste operations
#VMCH-06-000001
#​http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-367D02C1-B71F-4AC3-AA05-85033136A667.html
    $paramName = ""
    $paramName = "isolation.tools.copy.disable"


    $VMdisableconsolecopyParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMdisableconsolecopyParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $VMdisableconsolecopyValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMdisableconsolecopyValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $VMdisableconsolecopyValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $true -Confirm:$False -Verbose

}#END of Main Else



}#DISABLE COPY PASTE
else{

#Explicitly Enable copy/paste operations
#VMCH-06-000004
#http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-367D02C1-B71F-4AC3-AA05-85033136A667.html
    $paramName = ""
    $paramName = "isolation.tools.paste.disable"
    
    $VMenableconsolePasteParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMenableconsolePasteParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $VMenableconsolePasteValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMenableconsolePasteValue -eq 'True'){
            
            Write-Output "Value Default. I will Change to Enable Copy Paste"

            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "False" -Confirm:$False -Verbose

            }#END of Internal IF
            else{
            
            Write-Output "The Value of $paramName is: $VMenableconsolePasteValue. Value OK"
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $false -Confirm:$False -Verbose

}#END of Main Else

#Explicitly Enable copy/paste operations
#VMCH-06-000001
#​http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-367D02C1-B71F-4AC3-AA05-85033136A667.html
    $paramName = ""
    $paramName = "isolation.tools.copy.disable"

    $VMenableconsolecopyParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($VMenableconsolecopyParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"

        $VMenableconsolecopyValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($VMenableconsolecopyValue -eq 'True'){
            
            Write-Output "Value Default. I will Change to Enable Copy Paste"
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "False" -Confirm:$False -Verbose
            
            
            }#END of Internal IF
            else{
            
            Write-Output "The Value of $paramName is: $VMenableconsolecopyValue. Value OK"
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
       Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $false -Confirm:$False -Verbose

    }#END of Main Else

}#ENABLE COPY PASTE


######Set Max Session Number of Console to 2  
    $paramName = ""
    $paramName = "RemoteDisplay.maxConnections"

    
    $RemoteDisplaymaxConnectionsParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($RemoteDisplaymaxConnectionsParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $RemoteDisplaymaxConnectionsValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($RemoteDisplaymaxConnectionsValue -eq '2'){
            
            Write-Output "The Value of $paramName is: $RemoteDisplaymaxConnectionsValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 2 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-vm -Name $vmGuest | New-AdvancedSetting -Name $paramName -Value 2 -Confirm:$False -Verbose

}#END of Main Else 
   

#####Disable virtual disk shrinking
#####http://pubs.vmware.com/vsphere-65/topic/com.vmware.vsphere.security.doc/GUID-9610FE65-3A78-4982-8C28-5B34FEB264B6.html
#####VMCH-06-000006
    $paramName = ""
    $paramName = "isolation.tools.diskWiper.disable"
    
    $isolationtoolsdiskWiperdisableParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($isolationtoolsdiskWiperdisableParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $isolationtoolsdiskWiperdisableValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($isolationtoolsdiskWiperdisableValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $isolationtoolsdiskWiperdisableValue. Value OK"
            
            }#END of Internal IF
            else{
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value $true -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value $true -Confirm:$false -Verbose

}#END of Main Else


#####Set Snapshot Max to 3 - Better Performance - https://kb.vmware.com/s/article/1025279
    $paramName = ""
    $paramName = "Snapshot.MaxSnapshots"

    $SnapshotMaxSnapshotsParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($SnapshotMaxSnapshotsParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $SnapshotMaxSnapshotsValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($SnapshotMaxSnapshotsValue -eq '3'){
            
            Write-Output "The Value of $paramName is: $SnapshotMaxSnapshotsValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 3 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 3 -Confirm:$false -Verbose

}#END of Main Else 


###########################################
#RUN CONFIG BACKUP PROJECT
###########################################

if ($ConfigBackupParam){

###### https://kb.vmware.com/s/article/1031873
###### Enable CBT snapshots backup
    $paramName = ""
    $paramName = "changeTrackingEnabled"
    
    
    $changeTrackingEnabledParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($changeTrackingEnabledParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $changeTrackingEnabledValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($changeTrackingEnabledValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $changeTrackingEnabledValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value "True" -Confirm:$False -Verbose

}#END of Main Else  
                  
##### https://kb.vmware.com/s/article/52815
##### https://sort.veritas.com/public/documents/sfha/6.2/vmwareesx/productguides/html/sfhas_virtualization/ch10s05s01.htm
##### https://blogs.vmware.com/kb/2013/03/setting-disk-enableuuidtrue-in-vmware-data-protection.html
    $paramName = ""
    $paramName = "disk.EnableUUID"
    
    
    $diskEnableUUIDParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($diskEnableUUIDParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $diskEnableUUIDValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($diskEnableUUIDValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $diskEnableUUIDValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value "True" -Confirm:$False -Verbose

}#END of Main Else

##### https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.monitoring.doc/GUID-F465D340-6556-49E8-B137-C0B4A060E83B.html
##### https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.monitoring.doc/GUID-2DD66869-52C7-42C5-8F5B-145EBD26BBA1.html
##### https://pubs.vmware.com/vsphere-51/index.jsp?topic=%2Fcom.vmware.vmtools.install.doc%2FGUID-685722FA-9009-439C-9142-18A9E7C592EA.html
    $paramName = ""
    $paramName = "log.keepOld"
    
    
    $logkeepOldParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($logkeepOldParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $logkeepOldValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($logkeepOldValue -eq '10'){
            
            Write-Output "The Value of $paramName is: $logkeepOldValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 10 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 10 -Confirm:$False -Verbose

}#END of Main Else

#####http://buildvirtual.net/using-powercli-to-set-log-rotation-options-for-a-group-of-virtual-machines/
#####https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.monitoring.doc/GUID-2DD66869-52C7-42C5-8F5B-145EBD26BBA1.html
#####https://www.altaro.com/vmware/introduction-esxi-vm-log-files/
#####https://kb.vmware.com/s/article/8182749

    $paramName = ""
    $paramName = "log.rotateSize"
    
    
    $logRotateSizeParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($logRotateSizeParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $logRotateSizeValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($logRotateSizeValue -eq '2097152'){
            
            Write-Output "The Value of $paramName is: $logRotateSizeValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 2097152 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 2097152 -Confirm:$False -Verbose

}#END of Main Else

                  
#### https://kb.vmware.com/s/article/2146270
#### https://vsebastian.net/vmware/quickfix-virtual-machine-consolidation-is-needed-esxi-5-5/
#### http://vmware1520.rssing.com/chan-18332165/all_p6752.html 
#### https://kb.vmware.com/s/article/2039754?lang=en_US
#### https://gist.github.com/mycloudrevolution/0de7b009458fdc255c572049ea3a0838
    $paramName = ""
    $paramName = "snapshot.maxConsolidateTime"
    
    
    $snapshotmaxConsolidateTimeParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($snapshotmaxConsolidateTimeParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $snapshotmaxConsolidateTimeValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($snapshotmaxConsolidateTimeValue -eq '60'){
            
            Write-Output "The Value of $paramName is: $snapshotmaxConsolidateTimeValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 60 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 60 -Confirm:$False -Verbose

}#END of Main Else
                  
###### https://allthatiknw.wordpress.com/2015/12/08/snapshot-consolidation-in-vmware-esxi-5-5-x-and-esxi-6-0-x-fails-with-the-error-maximum-consolidate-retries-was-exceeded-for-scsixx/
###### https://kb.vmware.com/s/article/2082886
###### https://communities.vmware.com/thread/493639
    $paramName = ""
    $paramName = "snapshot.asyncConsolidate.forceSync"
    
    
    $snapshotasyncConsolidateforceSyncParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($snapshotasyncConsolidateforceSyncParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $snapshotasyncConsolidateforceSyncValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($snapshotasyncConsolidateforceSyncValue -eq 'True'){
            
            Write-Output "The Value of $paramName is: $snapshotasyncConsolidateforceSyncValue. Value OK"
            
            }#END of Internal IF
            
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "True" -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
        else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value "True" -Confirm:$False -Verbose

}#END of Main Else                   


}#END OF IF BACKUP PARAM
else{

    Write-Host "You choose not configure backup param in VM: $vmGuest" -ForegroundColor White -BackgroundColor DarkGreen

}#END OF ELSE BACKUP PARAM


##############################################
#RUN CONFIG TO COMPLETELY TIME SYNC WITH ESXI
##############################################

if ($DisableTimeSyncFull){

    Write-Host "PLEASE ATTENTION. BEFORE INPUT NEXT CONFIG, I HAVE TO SHUTDOWN THE VM: $vmGuest" -ForegroundColor White -BackgroundColor DarkRed

    Write-Host "OPERATION WILL FAIL IF VMTOOLS IS NOT INSTALLED ON VM: $vmGuest" -ForegroundColor White -BackgroundColor DarkRed
    
    Pause-PSScript
    
    $tmpVM = Vmware.VimAutomation.Core\Get-VM -Name $vmGuest -ErrorAction Continue

    Shutdown-VMGuest -VM $tmpVM -Confirm:$True -Verbose -ErrorAction Continue

    Start-Sleep -Seconds 150

#####Disable Time Sync - https://kb.vmware.com/s/article/1189
#####https://dirteam.com/sander/2019/07/18/managing-active-directory-time-synchronization-on-vmware-vsphere/
    $paramName = ""
    $paramName = "tools.syncTime"

    $toolsSyncTimeParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($toolsSyncTimeParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $toolsSyncTimeValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($toolsSyncTimeValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $toolsSyncTimeValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.continue"

    $timeSynchronizeContinueParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeContinueParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeContinueValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeContinueValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeContinueValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 



    $paramName = ""
    $paramName = "time.synchronize.restore"

    $timeSynchronizeRestoreParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeRestoreParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeRestoreValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeRestoreValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeRestoreValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.resume.disk"

    $timeSynchronizeResumeDiskParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeResumeDiskParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeResumeDiskValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeResumeDiskValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeResumeDiskValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.shrink"

    $timeSynchronizeShrinkParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeShrinkParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeShrinkValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeShrinkValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeShrinkValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.tools.startup"

    $timeSynchronizeToolsStartupParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeToolsStartupParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeToolsStartupValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeToolsStartupValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeToolsStartupValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.tools.enable"

    $timeSynchronizeToolsEnableParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeToolsEnableParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeToolsEnableValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeToolsEnableValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeToolsEnableValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 


    $paramName = ""
    $paramName = "time.synchronize.resume.host"

    $timeSynchronizeResumeHostParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
    if ($timeSynchronizeResumeHostParam){
        
        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
        $timeSynchronizeResumeHostValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
        if ($timeSynchronizeResumeHostValue -eq '0'){
            
            Write-Output "The Value of $paramName is: $timeSynchronizeResumeHostValue . Value OK"
            
            }#END of Internal IF
            else{
            
            Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value 0 -Confirm:$False -Verbose
            
            }#END of Internal ELSE


        }#end of Main IF
    else{
        
        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value 0 -Confirm:$false -Verbose

}#END of Main Else 

######## TURN ON VM AGAIN ######################
Start-Sleep -Seconds 5

Import-Module -Name Vmware.VimAutomation.Core -Force

Vmware.VimAutomation.Core\Start-VM -VM $tmpVM -Confirm:$false -RunAsync -Verbose

}#END OF MAIN DISABLE TIME SYNC FULL
else{

    Write-Host "You choose not to change time sync in VM: $vmGuest" -BackgroundColor DarkGreen -ForegroundColor White

}#END OF ELSE DISABLE TIME SYNC FULL


##########################################################################

#Check for Floppy Devices attached to VMs
    $floppyState = Get-VM -Name $vmGuest | Get-FloppyDrive | Where-Object -FilterScript {$_.ConnectionState -like "Connected*"}

    $floppyStateConnected = $floppyState.ConnectionState.Connected
    $floppyStateStartConnected = $floppyState.ConnectionState.StartConnected

    if ($floppyStateConnected -eq 'True' -or $floppyStateStartConnected -eq 'True'){

        Write-Output "This VM has Floppy Connected. I will disconnected it"

        #Disconnect Floppy Drive
        Get-Vm -Name $vmGuest | Get-FloppyDrive | Set-FloppyDrive -Connected:$false -StartConnected:$False -Confirm:$true


#REMOVE FLOPPY DISK
do {

    Write-Output "Would you like to Remove Floopy Drive of this VM? I will need to shutdown it First (Default is No)" 
        
        $MainChoiceYN = Read-Host " ( y / n ) "
        
            Switch ($MainChoiceYN)
              {
                Y {
                   
                   #SHUTDOWN VM BEFORE REMOVE FLOPPY
                   $vmPowerState = Get-VM -Name $vmGuest | Select-Object -ExpandProperty PowerState

                    if ($vmPowerState -eq "PoweredOn"){
    
                        do {

                            Write-Output "Would you like to Shutdown the VM $vmGuest (Default is No)" 
                            
                            $ChoiceYN = Read-Host " ( y / n ) "
                            
                            Switch ($ChoiceYN)
                                {
                                    Y {
                    
                                        Get-VM -Name $vmGuest | Shutdown-VMGuest -Confirm:$false -Verbose
                    
                                        Start-Sleep -Seconds 50
       
                                        #Remove all Floppy drives attached to VMs
                                        Get-VM -Name $vmGuest | Get-FloppyDrive | Remove-FloppyDrive -Confirm:$false -Verbose

                                       }#end of Y
                                    N {
                                        
                                        Write-Output "Ok. I will not Shutdown the VmGuest, so I cannot remove the Floppy Drive"
       
                                       }#end of NO
                                    
                                    Default { 
                                        
                                        Write-Output "Ok. I will not Shutdown the VmGuest, so I cannot remove the Floppy Drive"          
       
                                }#end of Default
                    
                     }#end of Switch

                }while ($ChoiceYN -notmatch ('^(?:Y\b|N\b)'))

}#end IF
        else{
    
    #Remove all Floppy drives attached to VMs
    Get-VM -Name $vmGuest | Get-FloppyDrive | Remove-FloppyDrive -Confirm:$false -Verbose         

}#end of Else


                     
       
                    }#end of Y
                N {
                    
                    Write-Output "You choose don't remove floopy of the VM $vmGuest"  
       
                    }#end of NO
                Default { 
                    
                    Write-Output "You choose don't remove floopy of the VM $vmGuest"         
       
                 }#end of Default
    }#end of Switch

}while ($MainChoiceYN -notmatch ('^(?:Y\b|N\b)'))

}#END MAIN IF

#FOR LINUX MACHINE WITH SHELL ONLY
do {

        Write-Output "`n"

        Write-Host "IS THIS A LINUX MACHINE WITH ONLY SHELL INSTALLED. ARE YOU SURE THIS VM ONLY USES SHELL AND DONT HAVE GUI INSTALLED?" -ForegroundColor Red -BackgroundColor White
        
        Write-Output "`n"

        Write-Host "IF YOU ARE NOT SURE, ANSWER NO BECAUSE VIRTUAL MACHINE WILL CRASH !!!!!" -ForegroundColor Red -BackgroundColor White 
        
        $ChoiceSvgaLinux = Read-Host " ( y / n ) "
            
            Switch ($ChoiceSvgaLinux)
              {
                Y {
                    
                    ####Disable all but VGA mode on specific virtual machines
                    $paramName = ""
                    $paramName = "svga.vgaOnly"
    
                    $svgaOnlyParam = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName}
    
                    if ($svgaOnlyParam){
        
                        Write-Output "O parâmetro - $paramName - existe. Verificando valor"
        
                        $svgaOnlyValue = Get-AdvancedSetting -Entity $vmGuest | Where-Object -FilterScript {$PSItem.Name -eq $paramName} | Select-Object -ExpandProperty Value
        
                    if ($svgaOnlyValue -eq 'True'){
            
                        Write-Output "The Value of $paramName is: $svgaOnlyValue . Value OK"
            
                    }#END of Internal IF
                    else{
            
                        Get-AdvancedSetting -Entity $vmGuest -Name $paramName | Set-AdvancedSetting -Value "False" -Confirm:$False -Verbose
            
                    }#END of Internal ELSE
                
                    }#end of Main IF
                    else{
        
                        Get-VM -Name $vmGuest | New-AdvancedSetting -Name $paramName -value "False" -Confirm:$false -Verbose

                    }#END of Main Else 

                    
                    Start-Sleep -Milliseconds 300 -Verbose   
       
                    }#end of Y
                N {
                    
                    Write-Output "Nothing to do with VM $vmGuest"
       
                    }#end of NO
                Default
                { 
                
                    Write-Output "Nothing to do with VM $vmGuest"        
       
                 }#end of Default
    }#end of Switch
}while ($ChoiceSvgaLinux -notmatch ('^(?:Y\b|N\b)'))

###########################################################################################################################
#Export Advanced Config to File
###########################################################################################################################
Get-AdvancedSetting -Entity $vmGuest | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileAfter -Append -Verbose
###########################################################################################################################
          

}#end ForEach
 
}#end Function


 function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric

#MAIN SCRIPT


#CREATE VCENTER LIST
$vcServers = @();
$vcServers = ("vCenter1","vCenter2")#CHANGE WITH YOUR(S) VCENTER(S)

$workingLocationNum = ""
$tmpWorkingLocationNum = ""
$WorkingServer = ""
$i = 0

foreach ($vcServer in $vcServers){
	   
        $vcServerValue = $vcServer
	    
        Write-Output "            [$i].- $vcServerValue ";	
	    $i++	
        }#end foreach	
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingLocationNum)) ){
	        $tmpWorkingLocationNum = Read-Host "Type Vcenter Number that you want to connect"
        }#end of while

            $workingLocationNum = ($tmpWorkingLocationNum / 1)

        if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($i-1))  ){
	        $WorkingServer = $vcServers[$WorkingLocationNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else

#Define Port
$port = '443'

#Connect to Vcenter
Connect-VIServer -Server $WorkingServer -Port $port -WarningAction Continue -ErrorAction Continue


$dataAtual = (Get-date -Format dd-MM-yyyy_HHmm)

$Response = 'Y'

$vmList = @()

$bunchOfVMs = @()


#MENU ACTION HARDENIG SEC
Do {
    Write-Output "
---------- MENU HARDENING SEC VM ----------

You are connected to VCenter: $workingServer

1 = Get Advanced Settings of Single VM
2 = Get Advanced Settings of One or More VMs
3 = Get Advanced Settings of All VMs in a Cluster
4 = Get Advanced Settings of a Bunch of VMs (Read from File List)
5 = Set Advanced Settings of Single VM
6 = Set Advanced Settings of One or More VMs
7 = Set Advanced Settings of All VMs in a Cluster
8 = Set Advanced Settings in a Bunch of VMs (Read from File List)
9 = Exit

--------------------------------------------"

$choiceHS = Read-host -prompt "Select an Option & Press Enter"
} until ($choiceHS -eq "1" -or $choiceHS -eq "2" -or $choiceHS -eq "3" -or $choiceHS -eq "4" -or $choiceHS -eq "5" -or $choiceHS -eq "6" -or $choiceHS -eq "7" -or $choiceHS -eq "8" -or $choiceHS -eq "9")


#CONFIGURE BLOCKS TO ENABLE OR NOT
if (($choiceHS -eq 5) -or ($choiceHS -eq 6) -or ($choiceHS -eq 7) -or ($choiceHS -eq 8)){

    #CONFIGURE MAIN PARAMETERS OF VM-HARDENING
###################################################################################################################################################

#DISABLE OR ENABLE COPY PASTE
do
{
    $StringDisableCopyPasteValue = Read-Host "Digite (FALSE) para ATIVAR o Copy/Paste e (TRUE) para DESATIVAR"
    
    if ($StringDisableCopyPasteValue -eq 'False' -or $StringDisableCopyPasteValue -eq 'True'){
    
        $boolDisableCopyPasteValue = [System.Convert]::ToBoolean($StringDisableCopyPasteValue)
    
    }else{
    
        Write-Host "Você digitou um valor inválido, somente é aceito (FALSE) ou (TRUE)" -ForegroundColor White -BackgroundColor DarkRed    
    
    } 
         
}
while ($StringDisableCopyPasteValue -notmatch ('^(?:false\b|true\b)'))

#DISABLE OR ENABLE BACKUP PARAMETERS
do
{
    $StringConfigBackupParam = Read-Host "Digite (FALSE) para DESATIVAR parâmetros de Backup VMDK e (TRUE) para ATIVAR"
    
    if ($StringConfigBackupParam -eq 'False' -or $StringConfigBackupParam -eq 'True'){
    
        $boolConfigBackupParam = [System.Convert]::ToBoolean($StringConfigBackupParam)
    
    }else{
    
        Write-Host "Você digitou um valor inválido, somente é aceito (FALSE) ou (TRUE)" -ForegroundColor White -BackgroundColor DarkRed    
    
    } 
         
}
while ($StringConfigBackupParam -notmatch ('^(?:false\b|true\b)'))

#COMPLETELY DISABLE OR ENABLE TIME SYNC
do
{
    $StringDisableTimeSyncFull = Read-Host "Digite (FALSE) para NÃO ALTERAR e (TRUE) para DESATIVAR COMPLETAMENTE o timesync da(s) VM(s) com o ESXi"
    
    if ($StringDisableTimeSyncFull -eq 'False' -or $StringDisableTimeSyncFull -eq 'True'){
    
        $boolDisableTimeSyncFull = [System.Convert]::ToBoolean($StringDisableTimeSyncFull)
    
    }else{
    
        Write-Host "Você digitou um valor inválido, somente é aceito (FALSE) ou (TRUE)" -ForegroundColor White -BackgroundColor DarkRed    
    
    } 
         
}
while ($StringDisableTimeSyncFull -notmatch ('^(?:false\b|true\b)'))


###################################################################################################################################################



}#END OF IF CONFIGURE BLOCKS TO ENABLE OR NOT 
else{

    Write-Host "You Choose Just Get Info from VMs. So I have nothing to configure" -ForegroundColor DarkGreen -BackgroundColor White

}#END OF ELSE CONFIGURE BLOCKS TO ENABLE OR NOT


#SET FILE NAME BASED ON CHOICE
if (($choiceHS -eq 1) -or ($choiceHS -eq 5)){
    
    $vmName = ""

    $vmName = Read-Host -Prompt 'Digite o nome da VM'
    
    $Error.Clear()

    $tmpData = Get-VM -Name $vmName -ErrorAction Continue
    
    if ($Error[0])
    {
        Write-Output "The VM $vmName does not exist..."
        
        Write-Output "I will out of this script...bye =)"
        
        Start-Sleep -Seconds 3
        
        Exit
     }#end of IF
    

    $fileNameBefore = "Before-Hardening-$vmName-$dataAtual.txt"

    $fileNameAfter = "Hardening-After-$vmName-$dataAtual.txt"

    $outputfileBefore = ($SCRIPT_PARENT + "\ReportHardSec\$fileNameBefore")
        
    $outputfileAfter = ($SCRIPT_PARENT + "\ReportHardSec\$fileNameAfter")

}#end IF
else{

    $fileNameBefore = "Before-Hardening-VMs-$dataAtual.txt"

    $fileNameAfter = "Hardening-VMs-After-$dataAtual.txt"

    $outputfileBefore = ($SCRIPT_PARENT + "\ReportHardSec\$fileNameBefore")
        
    $outputfileAfter = ($SCRIPT_PARENT + "\ReportHardSec\$fileNameAfter")


}#end ELSE


switch ($choiceHS)
{
    "1" {
    #Get Advanced Settings of Single VM
    
     Write-Host "Advanced Settings of VM: $vmName" -ForegroundColor White -BackgroundColor Red
     
     Get-AdvancedSetting -Entity $vmName | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

         
    }#end of 1
    "2" {
    #Get Advanced Settings of One or More VMs
    Do 
    { 
            
            Do{
            
            $Error.Clear()

            $vmName = Read-Host -Prompt 'Enter the VM Name'
            
            $tmpData = Get-VM -Name $vmName -ErrorAction SilentlyContinue

                        
            }#end of Internal Do
            while($Error[0])#End of While

            $Response = Read-Host 'Would you like to add additional VMs to this list? (y/n)'            

            $vmList += $vmName
       
                       
      }#end of external DO
    Until ($Response -eq 'n')#end of Until

         foreach ($vmName in $vmList){
         
         Write-Host "Advanced Settings of VM: $vmName" -ForegroundColor White -BackgroundColor Red
         
         Write-Output "Advanced Settings of VM: $vmName" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
            
         Get-AdvancedSetting -Entity $vmName | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
         
         }#end of ForEach

    }#end of 2
    "3" {
        
        #CREATE CLUSTER LIST
        $VCClusterList = (get-cluster | Select-Object -ExpandProperty Name| Sort-Object)

        $tmpWorkingClusterNum = ""
        $WorkingCluster = ""
        $i = 0
        $vmClusterList = ""

        #CREATE CLUSTER MENU LIST
        foreach ($VCCluster in $VCClusterList){
	   
            $VCClusterValue = $VCCluster
	    
        Write-Output "            [$i].- $VCClusterValue ";	
	    $i++	
        }#end foreach	
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingClusterNum)) ){
	        $tmpWorkingClusterNum = Read-Host "Type the Vcenter Cluster Number that you want to Apply the Hardenig"
        }#end of while

            $workingClusterNum = ($tmpWorkingClusterNum / 1)

        if(($workingClusterNum -ge 0) -and ($workingClusterNum -le ($i-1))  ){
	        $WorkingCluster = $vcClusterList[$workingClusterNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else


        $vmClusterList = Get-VM -Location $WorkingCluster
        
        Write-Output "ADVANCED CONFIGURATION SETTINGS OF CLUSTER: $workingCluster" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

        Write-Output "`n" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

        #OUTPUT ALL INFO TO A FILE BEFORE ANY CHANGES. 
        $vmClusterList | foreach {

        $vmName = $_.Name

        Write-Output "Advanced Settings of VM: $vmName" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
            
        Get-AdvancedSetting -Entity $vmName | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

        Write-Output "=======================================================================================================================" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

        }#end ForEach ClusterList Get
    
    
    }#end of 3
    "4" {
    
        if (!($inputPathExists)){

            Write-Host "Folder Named: VMsInputList does not exists. I will create it" -ForegroundColor Yellow -BackgroundColor Black

            New-Item -Path $Script_Parent -ItemType Directory -Name "VMsInputList" -Confirm:$true -Verbose -Force

        }else{

            Write-Host "Folder Named: VMsInputList exists" -ForegroundColor White -BackgroundColor Blue
            
            Write-Output "`n"
 
        }#END OF ELSE


        #CREATE FILE WITH VM INPUT LIST IF NOT EXIST
        if (Test-Path -Path "$Script_Parent\VMsInputList\VmsInputList.txt"){
            
            Write-Host "File VmsInputList.txt already exists" -ForegroundColor White -BackgroundColor Red          
        }#end of IF
        else{
        
        New-Item -Path "$Script_Parent\VMsInputList" -ItemType File -Name VmsInputList.txt -Confirm:$true -Verbose
        
        Start-Process -FilePath "notepad" -Wait -WindowStyle Maximized -ArgumentList "$Script_Parent\VMsInputList\VmsInputList.txt"
        
        Start-Sleep -Seconds 5
        
        
        }#end of Else
               
          
        $bunchOfVMs = (Get-content -Path "$Script_Parent\VMsInputList\VmsInputList.txt")

        foreach ($vmName in $bunchOfVMs){
        
        Write-Output "Advanced Settings of VM: $vmName" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
            
        Get-AdvancedSetting -Entity $vmName | Format-Table -AutoSize | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose

        Write-Output "=======================================================================================================================" | Out-File -Width 2048 -FilePath $outputfileBefore -Append -Verbose
        
        }#end of ForEach

    
    }#end of 4
    "5" {
    
        Write-Output "Setting Advanced Setings om Vm: $vmName"
        
        Set-VMHardeningSec -vmList $vmName -disableCopyPaste $boolDisableCopyPasteValue -ConfigBackupParam $boolConfigBackupParam -DisableTimeSyncFull $boolDisableTimeSyncFull

    
    }#end of 5
    "6" {
    
    Do 
    { 
            
            Do{
            
            $Error.Clear()

            $vmName = Read-Host -Prompt 'Enter the VM Name'
            
            $tmpData = Get-VM -Name $vmName -ErrorAction SilentlyContinue

                        
            }#end of Internal Do
            while($Error[0])#End of While

            $Response = Read-Host 'Would you like to add additional VMs to this list? (y/n)'            

            $vmList += $vmName
       
                       
      }#end of external DO
    Until ($Response -eq 'n')#end of Until
            
                       
            Set-VMHardeningSec -vmList $vmList -disableCopyPaste $boolDisableCopyPasteValue -ConfigBackupParam $boolConfigBackupParam -DisableTimeSyncFull $boolDisableTimeSyncFull -ErrorAction Continue
    
    }#end of 6
    "7" {
    
    Write-Host "CUIDADO. AO RODAR ESSA OPÇÃO VOCÊ APLICARÁ A CONFIGURAÇÃO EM TODAS AS VMS do CLUSTER" -BackgroundColor Red -ForegroundColor White

    Pause-PSScript

    #CREATE CLUSTER LIST
        $VCClusterList = (get-cluster  | Select-Object -ExpandProperty Name| Sort-Object)

        $tmpWorkingClusterNum = ""
        $WorkingCluster = ""
        $i = 0
        $vmClusterList = ""

        #CREATE CLUSTER MENU LIST
        foreach ($VCCluster in $VCClusterList){
	   
            $VCClusterValue = $VCCluster
	    
        Write-Output "            [$i].- $VCClusterValue ";	
	    $i++	
        }#end foreach	
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingClusterNum)) ){
	        $tmpWorkingClusterNum = Read-Host "Type the Vcenter Cluster Number that you want to Apply the Hardenig"
        }#end of while

            $workingClusterNum = ($tmpWorkingClusterNum / 1)

        if(($workingClusterNum -ge 0) -and ($workingClusterNum -le ($i-1))  ){
	        $WorkingCluster = $vcClusterList[$workingClusterNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else

        $vmClusterList = Get-VM -Location $WorkingCluster
        
        #OUTPUT ALL INFO TO A FILE BEFORE ANY CHANGES. 
        $vmClusterList | foreach {

        $vmName = $_.Name

        Write-Output "Advanced Settings of VM: $vmName" | Out-File -Width 2048 -FilePath $outputfileAfter -Append -Verbose
            
        Set-VMHardeningSec -vmList $vmList -disableCopyPaste $boolDisableCopyPasteValue -ConfigBackupParam $boolConfigBackupParam -DisableTimeSyncFull $boolDisableTimeSyncFull -ErrorAction Continue

        Write-Output "=======================================================================================================================" | Out-File -Width 2048 -FilePath $outputfileAfter -Append -Verbose

        }#end ForEach Cluster List Set

    
    }#end of 7
    "8" {
    

    if (!($inputPathExists)){

            Write-Host "Folder Named: VMsInputList does not exists. I will create it" -ForegroundColor Yellow -BackgroundColor Black

            New-Item -Path $Script_Parent -ItemType Directory -Name "VMsInputList" -Confirm:$true -Verbose -Force

        }else{

            Write-Host "Folder Named: VMsInputList exists" -ForegroundColor White -BackgroundColor Blue
        
            Write-Output "`n"
 
        }#END OF ELSE


        #CREATE FILE WITH VM INPUT LIST IF NOT EXIST
        if (Test-Path -Path "$Script_Parent\VMsInputList\VmsInputList.txt"){
            
            Write-Host "File VmsInputList.txt already exists" -ForegroundColor White -BackgroundColor Red  
                    
        }#end of IF
        else{
        
            New-Item -Path "$Script_Parent\VMsInputList" -ItemType File -Name VmsInputList.txt -Confirm:$true -Verbose
        
            Start-Process -FilePath "notepad" -Wait -WindowStyle Maximized -ArgumentList "$Script_Parent\VMsInputList\VmsInputList.txt"
        
            Start-Sleep -Seconds 5
        
        
        }#end of Else
               
          
        $bunchOfVMs = (Get-content -Path "$Script_Parent\VMsInputList\VmsInputList.txt")

        foreach ($vmName in $bunchOfVMs){
        
        Write-Output "Advanced Settings of VM: $vmName" | Out-File -Width 2048 -FilePath $outputfileAfter -Append -Verbose
        
        Set-VMHardeningSec -vmList $vmList -disableCopyPaste $boolDisableCopyPasteValue -ConfigBackupParam $boolConfigBackupParam -DisableTimeSyncFull $boolDisableTimeSyncFull -ErrorAction Continue

        Write-Output "=======================================================================================================================" | Out-File -Width 2048 -FilePath $outputfileAfter -Append -Verbose
        
        }#end of ForEach
    
    
    
    }#end of 8
    "9" {
    
        Write-Output "You choose finish the Script"
    
        Start-Sleep -Seconds 1
    
        Exit
    
    
    }#end of 9
}
