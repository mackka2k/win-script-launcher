Get-PnpDevice | Where-Object {$_.Status -eq 'Unknown' -or $_.ConfigManagerErrorCode -eq 45} | ForEach-Object { & pnputil /remove-device $_.InstanceId }
