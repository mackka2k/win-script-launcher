param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName
)

$result = Test-Connection -ComputerName $ComputerName -Count 3 -ErrorAction SilentlyContinue
if ($result) {
    $measurement = $result | Measure-Object -Property ResponseTime -Average
    [math]::Round($measurement.Average)
}
