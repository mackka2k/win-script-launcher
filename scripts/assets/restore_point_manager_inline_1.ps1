Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, @{Label='Date';Expression={$_.CreationTime}}, RestorePointType | Format-Table -AutoSize
