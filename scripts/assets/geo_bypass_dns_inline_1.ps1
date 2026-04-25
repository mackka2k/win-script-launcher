Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ResetServerAddresses }
