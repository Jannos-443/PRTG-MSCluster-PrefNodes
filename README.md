# PRTG-PrefClusterNodes
# About

## Project Owner:

Jannos-443

## Project Details

Checks if Windows Cluster Roles are on preferred Node(s)

## HOW TO

1. Place "PRTG-PrefClusterNodes.ps1" under "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXE"

2. Change "Value" Channel >> "Lookups and Limits" to "Enable alerting based on limits"
   - Upper Error Limit 0,5
![PRTG-PrefClusterNodes](media/Sensor-Limit-Channel.png)
![PRTG-PrefClusterNodes](media/Sensor-Limit.png)

3. Set the "$IgnorePattern" or "$IgnoreScript" parameter to Exclude ClusterGroups


## Examples
![PRTG-PrefClusterNodes](media/Limits-OK.png)
![PRTG-PrefClusterNodes](media/Limits-Error.png)

ClusterGroup exceptions
------------------
You can either use the **parameter $IgnorePattern** to exclude a ClusterGroup on sensor basis, or set the **variable $IgnoreScript** within the script. Both variables take a regular expression as input to provide maximum flexibility. These regexes are then evaluated againt the **VM Name**

By default, the $IgnoreScript varialbe looks like this:

```powershell
$IgnoreScript = '^(Verfügbarer Speicher|Clustergruppe)$'
```

For more information about regular expressions in PowerShell, visit [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions).

".+" is one or more charakters
".*" is zero or more charakters
