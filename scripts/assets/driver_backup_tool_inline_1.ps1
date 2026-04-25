Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate | Out-File -FilePath "$env:backup_dir\driver_list.txt" -Encoding UTF8
