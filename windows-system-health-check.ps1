# Windows Client Health Check
# Autor: Jennifer Rösner

$reportFolder = ".\reports"
if (-not (Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$htmlPath = Join-Path $reportFolder "system_report_$timestamp.html"
$csvPath  = Join-Path $reportFolder "system_report_$timestamp.csv"

$internalTarget = "192.168.56.1"
$sharePath = "C:\"

$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$totalRAMGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$totalDiskGB = [math]::Round($disk.Size / 1GB, 2)
$freeDiskGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$lastBoot = $os.LastBootUpTime

$ipv4 = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object -First 1).IPAddress

$internetPing = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
$internalPing = Test-Connection $internalTarget -Count 1 -Quiet -ErrorAction SilentlyContinue

$cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$cpuLoad = [math]::Round($cpuLoad, 2)

$servicesToCheck = @("Spooler", "wuauserv", "WinDefend", "LanmanWorkstation")
$serviceObjects = foreach ($serviceName in $servicesToCheck) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        [PSCustomObject]@{
            Kategorie = "Dienst"
            Name      = $serviceName
            Wert      = "Nicht gefunden"
            Status    = "Warnung"
            Farbe     = "warning"
        }
    }
    elseif ($service.Status -eq "Running") {
        [PSCustomObject]@{
            Kategorie = "Dienst"
            Name      = $serviceName
            Wert      = "Running"
            Status    = "OK"
            Farbe     = "ok"
        }
    }
    else {
        [PSCustomObject]@{
            Kategorie = "Dienst"
            Name      = $serviceName
            Wert      = $service.Status
            Status    = "Fehler"
            Farbe     = "error"
        }
    }
}

$summaryItems = @()

if ($freeDiskGB -lt 20) {
    $diskStatus = "Wenig Speicher"
    $diskClass = "error"
} else {
    $diskStatus = "OK"
    $diskClass = "ok"
}

if ($cpuLoad -ge 80) {
    $cpuStatus = "Hoch"
    $cpuClass = "error"
} elseif ($cpuLoad -ge 50) {
    $cpuStatus = "Erhöht"
    $cpuClass = "warning"
} else {
    $cpuStatus = "OK"
    $cpuClass = "ok"
}

if ($internetPing) {
    $networkStatus = "OK"
    $networkClass = "ok"
} else {
    $networkStatus = "Fehler"
    $networkClass = "error"
}

if ($internalPing) {
    $internalTargetStatus = "Erreichbar"
    $internalTargetClass = "ok"
} else {
    $internalTargetStatus = "Nicht erreichbar"
    $internalTargetClass = "error"
}

if (Test-Path $sharePath) {
    $shareStatus = "Erreichbar"
    $shareClass = "ok"
} else {
    $shareStatus = "Nicht erreichbar"
    $shareClass = "error"
}

$summaryItems += [PSCustomObject]@{ Kategorie = "Netzwerk"; Name = "Internetverbindung"; Wert = "Ping zu 8.8.8.8"; Status = $networkStatus; Farbe = $networkClass }
$summaryItems += [PSCustomObject]@{ Kategorie = "Netzwerk"; Name = "Interner Zielhost"; Wert = $internalTarget; Status = $internalTargetStatus; Farbe = $internalTargetClass }
$summaryItems += [PSCustomObject]@{ Kategorie = "Pfad"; Name = "Lokaler Pfad"; Wert = $sharePath; Status = $shareStatus; Farbe = $shareClass }
$summaryItems += [PSCustomObject]@{ Kategorie = "Speicher"; Name = "Freier Speicher (GB)"; Wert = $freeDiskGB; Status = $diskStatus; Farbe = $diskClass }
$summaryItems += [PSCustomObject]@{ Kategorie = "CPU"; Name = "Auslastung (%)"; Wert = $cpuLoad; Status = $cpuStatus; Farbe = $cpuClass }
$summaryItems += [PSCustomObject]@{ Kategorie = "System"; Name = "Computer"; Wert = $computerName; Status = "Info"; Farbe = "warning" }
$summaryItems += [PSCustomObject]@{ Kategorie = "System"; Name = "Benutzer"; Wert = $userName; Status = "Info"; Farbe = "warning" }
$summaryItems += [PSCustomObject]@{ Kategorie = "System"; Name = "Betriebssystem"; Wert = $os.Caption; Status = "Info"; Farbe = "warning" }

$allRows = $summaryItems + $serviceObjects

$csvData = $allRows | Select-Object Kategorie, Name, Wert, Status
$csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$htmlRows = ($allRows | ForEach-Object {
    "<tr><td>$($_.Kategorie)</td><td>$($_.Name)</td><td>$($_.Wert)</td><td class='$($_.Farbe)'>$($_.Status)</td></tr>"
}) -join "`n"

$html = @"
<html>
<head>
<meta charset="UTF-8">
<title>Windows Client Health Check</title>
<style>
body { font-family: Arial; background-color: #f4f6f8; padding: 30px; }
h1, h2 { color: #003366; }
.box { background: white; padding: 24px; border-radius: 8px; width: 900px; box-shadow: 0px 2px 8px rgba(0,0,0,0.1); }
.ok { color: green; font-weight: bold; }
.warning { color: darkorange; font-weight: bold; }
.error { color: red; font-weight: bold; }
table { width: 100%; border-collapse: collapse; margin-top: 10px; }
th, td { border: 1px solid #d0d7de; padding: 10px; text-align: left; }
th { background-color: #e9eef5; }
</style>
</head>
<body>
<div class="box">
<h1>Windows Client Health Check</h1>
<p><b>Erstellt am:</b> $(Get-Date)</p>
<h2>Statusübersicht</h2>
<table>
<tr><th>Kategorie</th><th>Name</th><th>Wert</th><th>Status</th></tr>
$htmlRows
</table>
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($true))

Write-Host "HTML erstellt: $htmlPath"
Write-Host "CSV erstellt: $csvPath"