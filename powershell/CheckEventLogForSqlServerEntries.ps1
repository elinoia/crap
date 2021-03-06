<#
 .SYNOPSIS
    Check event log of a (remote) machine for SQL Server messages.
 .DESCRIPTION
    Queries all Event Log entries of a (remote) machine and filters the list for SQL Server related entires since a defined start date.
    Additional filter can be easily added with the WHERE operator or in the SELECT statement.
    
    Remark: Depending on the language settings of the machine the event log returns national desc for type.
            In this sample it's filtered by English (Error, Warning) and German types (Fehler, Warnung).
    
    Works with MS SQL Server 2000 and higher version services.
    Requires permission to connect to and fetch WMI data from the machine(s).
 .NOTES
    Author  : Olaf Helper
    Requires: PowerShell Version 1.0
 .LINK
    TechNet Get-WmiObject
        http://technet.microsoft.com/en-us/library/dd315295.aspx
#>

[string] $server = "LOCALHOST";
[DateTime] $startDate = (Get-Date).AddDays(-7);  # All events of the last x days.

$evt = Get-WmiObject `
       -computername $server `
       -query "SELECT * 
               FROM Win32_NTLogEvent 
               WHERE (   Type = 'Fehler' 
                      OR Type = 'Error' 
                      OR Type = 'Warnung'
                      OR Type = 'Warning'
                      ) 
                     AND
                     (   SourceName LIKE '%SQL%' 
                      OR SourceName LIKE '%MSOLAP%'
                      OR SourceName LIKE '%ReportServer%'
                      OR SourceName LIKE '%MSDtsServer%')" `
       | WHERE {$_.TimeWritten -ge $startDate.ToString("yyyyMMddhhmmss")};

# Defining output format for each column.
$fmtEvtCode =@{Label="EvtCode"     ;Alignment="right" ;Width=8  ;Expression={$_.EventCode};};
$fmtMsg     =@{Label="Message"     ;Alignment="left"  ;Width=80 ;Expression={$_.Message.Replace("`t", "").Replace("`n", "").Replace("`r", "").Replace("  ", " ")};};
$fmtFile    =@{Label="File"        ;Alignment="left"  ;Width=4  ;Expression={$_.LogFile.SubString(0, 3)};};
$fmtType    =@{Label="Type"        ;Alignment="left"  ;Width=4  ;Expression={$_.Type.SubString(0, 3)};};
$fmtSrcName =@{Label="Source Name" ;Alignment="left"  ;Width=20 ;Expression={$_.SourceName};};
$fmtWritten =@{Label="Time Stamp"  ;Alignment="left"  ;Width=20 ; `
               Expression={$_.TimeWritten.SubString(0, 4) + "-" + $_.TimeWritten.SubString( 4, 2) + "-" + $_.TimeWritten.SubString( 6, 2) + " " + 
                           $_.TimeWritten.SubString(8, 2) + ":" + $_.TimeWritten.SubString(10, 2) + ":" + $_.TimeWritten.SubString(12, 2)};};

Write-Output $evt | Format-Table $fmtEvtCode, $fmtFile, $fmtType, $fmtWritten, $fmtSrcName, $fmtMsg;