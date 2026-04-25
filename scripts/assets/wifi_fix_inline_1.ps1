Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Wi-Fi|WiFi|Wireless|WLAN|802\.11' } | Select-Object -ExpandProperty FriendlyName
