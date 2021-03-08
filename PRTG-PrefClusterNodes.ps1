<#       
    .SYNOPSIS
    Checks if Windows Cluster Roles are on preferred Node(s)

    .DESCRIPTION
    Using WMI to check if all Cluster Roles from one Cluster are on preferred Nodes
    Exceptions can be made within this script by changing the variable $IgnoreScript. This way, the change applies to all PRTG sensors 
    based on this script. If exceptions have to be made on a per sensor level, the script parameter $IgnorePattern can be used.
    Copy this script to the PRTG probe EXE scripts folder (${env:ProgramFiles(x86)}\PRTG Network Monitor\Custom Sensors\EXE)
    and create a "EXE/Script" sensor. Choose this script from the dropdown and set at least:
    + Parameters: Cluster
    + Upper Error Limit 0,5

    .PARAMETER Cluster
    The Hostname of the Windows Cluster

    .PARAMETER IgnorePattern
    Regular expression to describe the ClusterGroup Name for Example "Fileserver-1" to exclude this role from checking.
    Example: ^(Clustergroup|Clustergruppe)$
    Example2: ^(Test123.*|TestPrinter555)$ excluded Test12345
    #https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions?view=powershell-7.1
    
    .EXAMPLE
    Sample call from PRTG EXE/Script
    EXE/Script= PRTG-PrefClusterNodes.ps1
    Parameters= -Cluster "Fileserver-Test"

    Author:  Jannos-443
    https://github.com/Jannos-443/PRTG-PrefClusterNodes
#>
param(
    [Parameter(Mandatory)] [string]$Cluster = $null,
    [string]$IgnorePattern = ""
)

#catch all unhadled errors
trap{
    Write-Host "1:$($_.ToString()) $($_.ScriptStackTrace)"
    Exit 1
}

#
if($Cluster -eq $null)
    {
    Write-Host "1:No Cluster specified"
    exit 1
    }

#Currently not in user because of PRTG 32-Bit Probe
#Start Load Powershell Module
#$module = Get-Module -Name "FailoverClusters" -ListAvailable -ErrorAction SilentlyContinue
#
#
#if($module -eq $null)
#    {
#    Write-Host "1:Failed to load FailoverClusters Module, RSAT Installed?"
#    exit 1
#    }
#
#Import-Module -Name "FailoverClusters" -ErrorAction Stop > $null
 


#Get all ClusterGroups
Try{
    #$ClusterGroups = Get-ClusterGroup -Cluster $Cluster -ErrorAction Stop | where {$_.Name -notin $Exclude}
    $ClusterGroups = Get-CimInstance -Namespace "root\MSCluster" -ClassName "MSCluster_ResourceGroup" -ComputerName $Cluster -ErrorAction Stop
    }

catch{
    Write-Host "1:Cluster $($Cluster) not found or access denied"
    exit 1
    }


#hardcoded list that applies to all hosts
$IgnoreScript = '^(Verfügbarer Speicher|Clustergruppe)$' 


#Remove Ignored ClusterGroups
if ($IgnorePattern -ne "") {
    $ClusterGroups = $ClusterGroups | where {$_.Name -notmatch $IgnorePattern}  
}

if ($IgnoreScript -ne "") {
    $ClusterGroups = $ClusterGroups | where {$_.Name -notmatch $IgnoreScript}  
}


#Clustergroup(s) found?

if(($ClusterGroups -eq 0) -or ($ClusterGroups -eq $null))
    {
    Write-Host "1:No ClusterGroups found"
    exit 1
    }

#get preferred node for each ClusterGroup
$ErrorText = ""
$AllNodes = ""

foreach($ClusterGroup in $ClusterGroups)
    {
    #get preferred node(s)
    #$PrefClusterNode = ((Get-ClusterOwnerNode -Cluster $Cluster -Group $ClusterGroup.Name).OwnerNodes).Name
    $PrefClusterNode = (Invoke-CimMethod -InputObject $ClusterGroup -MethodName GetPreferredOwners -ErrorAction Stop).NodeNames
    $PrefNodesTXT= ""
    $AllNodes += "$($ClusterGroup.Name) ;"
        
    #if pref Node exists
    if($PrefClusterNode.Count -ge 1)
        {

        #List Prefered Cluster Nodes as Text
        foreach($Node in $PrefClusterNode)
            {
            $PrefNodesTXT += "$($Node); "
            }

        #check if Group is on pref Node(s)
        if($ClusterGroup.OwnerNode -notin $PrefClusterNode)
            {
            $ErrorText += "$($ClusterGroup.name) is not on preferred Node $($PrefNodesTXT)"
            }
        }
    }


if(($ErrorText -eq $null) -or($ErrorText -eq ""))
    {
    Write-Host "0:All ClusterGroups are on preferred Nodes ClusterGroups=$($AllNodes)"
    exit 0
    }

else
    {
    Write-Host "1:$($ErrorText)"
    exit 1
    }
