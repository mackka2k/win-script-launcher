Get-WinEvent -FilterHashtable @{LogName='System'; Id=41} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message | Format-List
