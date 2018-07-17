<#
.Synopsis
   Script to gather hardware information
.DESCRIPTION
   This script gathers hardware information for the specified computer provided in the computername parameter.
.EXAMPLE
   get-compinfo -computername 'SERVER01'
.EXAMPLE
   get-compinfo -file C:\servers.txt
#>
function get-compinfo
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Provides the computer name or IP address of the device from which to retrieve hardware information
        [string(Position=0)]
        $computername,

        # Provides a text file containing one computer name or IP address per line to retrieve information from multiple devices
        [string]
        $file
    )

    Begin
    {
        if ($computername)
                {if ($(Test-connection -ComputerName $computername -Count 1 -Quiet) -eq $true) 
                {Write-Verbose "$computername is online, proceeding to retrieve hardware info"} 
                else {write-warning "$computername is offline"; break}} 

        else {$list = @(); foreach ($comp in ($(get-content -Path $file)))
                {if ($(Test-connection -ComputerName $comp -Count 1 -Quiet) -eq $true)
                {$list += "$comp";Write-Verbose "$comp is online, adding to retrieval list"}
                else {write-warning "$comp is offline"}}}
        

    }
    Process
    {
        # Check if computername parameter has been used.  If found to be true create PSCustomObjects for CPU memory & disk and populate with data from WMI

        if ($computername){
        $Server = @{CPU = @();Memory = @();Disk = @()}
        $cpu = gwmi -ComputerName $computername -Class win32_processor -Property DeviceID,Caption,Manufacturer,Name,NumberOfCores,NumberOfLogicalProcessors,SocketDesignation
           foreach ($obj in $cpu){$Server.CPU += [PSCustomObject]@{
                CPUID = $obj.DeviceID
                Caption = $obj.Caption
                Manufacturer = $obj.Manufacturer
                Name = $obj.Name
                NumberOfCores = $obj.NumberOfCores
                NumberOfLogicalProcessors = $obj.NumberOfLogicalProcessors
                SocketDesignation = $obj.SocketDesignation

            }
        }
        
        $Server.CPU | ft
        
        $mem = gwmi -ComputerName $computername -Class win32_physicalmemory -Property Description,Capacity,Speed,Manufacturer,DeviceLocator
        foreach ($obj in $mem){$Server.Memory += [PSCustomObject]@{
            Description = $obj.Description
            'Capacity(GB)' = [math]::round($obj.Capacity/1GB)
            Speed = $obj.Speed
            Manufacturer = $obj.Manufacturer
            Location = $obj.DeviceLocator

            }
        }

        $Server.Memory | ft 

        $LD = gwmi -ComputerName $computername -Class win32_LogicalDisk -Property Name,VolumeName,Size,FreeSpace
        foreach ($obj in $LD){$Server.Disk += [PSCustomObject]@{
            Drive = $obj.Name
            Label = $obj.VolumeName
            'Capacity(GB)' = [math]::round($obj.Size/1GB)
            'Free Space(GB)' = [math]::round($obj.FreeSpace/1GB)
            'Used Space(GB)' = [math]::round(($obj.Size/1GB)-($obj.FreeSpace/1GB))
            }
        }
        
        $Server.Disk | ft
        
        }

        # If the user has opted to query based on a list of devices within a text file, create PSCustomObject that includes the server name and iterate through all devices found to be online, populating with data from WMI.

        else {
            foreach ($comp in $list) {
                $server = @{Name = "$comp";CPU = @();Memory = @();Disk = @()}
                $cpu = gwmi -ComputerName $comp -Class win32_processor -Property DeviceID,Caption,Manufacturer,Name,NumberOfCores,NumberOfLogicalProcessors,SocketDesignation
                foreach ($obj in $cpu){$Server.CPU += [PSCustomObject]@{
                     CPUID = $obj.DeviceID
                     Caption = $obj.Caption
                     Manufacturer = $obj.Manufacturer
                     Name = $obj.Name
                     NumberOfCores = $obj.NumberOfCores
                     NumberOfLogicalProcessors = $obj.NumberOfLogicalProcessors
                     SocketDesignation = $obj.SocketDesignation
     
                 }
             }
             $size = (Measure-Object -InputObject $Server.name -Character).characters
             write-host '###' -NoNewline
             do {write-host '#' -NoNewline; $size -= 1 } until ($size -ile 0) ; write-host '###'
             
             write-host "#  $($Server.name.toupper())  #"
             
             $size = (Measure-Object -InputObject $Server.name -Character).characters
             write-host '###' -NoNewline
             do {write-host '#' -NoNewline; $size -= 1 } until ($size -ile 0) ; write-host '###'
             
             $Server.CPU | ft
             
             $mem = gwmi -ComputerName $comp -Class win32_physicalmemory -Property Description,Capacity,Speed,Manufacturer,DeviceLocator
             foreach ($obj in $mem){$Server.Memory += [PSCustomObject]@{
                 Description = $obj.Description
                 'Capacity(GB)' = [math]::round($obj.Capacity/1GB)
                 Speed = $obj.Speed
                 Manufacturer = $obj.Manufacturer
                 Location = $obj.DeviceLocator
     
                 }
             }
             
             $Server.Memory | ft 

             $LD = gwmi -ComputerName $comp -Class win32_LogicalDisk -Property Name,VolumeName,Size,FreeSpace
             foreach ($obj in $LD){$Server.Disk += [PSCustomObject]@{
                 Drive = $obj.Name
                 Label = $obj.VolumeName
                 'Capacity(GB)' = [math]::round($obj.Size/1GB)
                 'Free Space(GB)' = [math]::round($obj.FreeSpace/1GB)
                 'Used Space(GB)' = [math]::round(($obj.Size/1GB)-($obj.FreeSpace/1GB))
                 }
             }

             $Server.Disk | ft

            }
        }
    }
    
    End
    {

    }
}
