# Windows Client Health Check
# Autor: Jennifer Rösner
# Beschreibung:
# Dieses Skript prüft zentrale Systemzustände eines Windows-Arbeitsplatzes
# und erstellt einen HTML-Bericht für den Einsatz im Klinikumfeld.

$reportFolder = ".\reports"

if (-not (Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = Join-Path $reportFolder "system_report_$timestamp.html"

# Konfiguration für das Zielsystem
$internalTarget = "192.168.56.1"
$sharePath = "C:\"

# Grundlegende Systeminformationen
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

# Erreichbarkeit prüfen
$internetPing = Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
$internalPing = Test-Connection $internalTarget -Count 1 -Quiet -ErrorAction SilentlyContinue

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

# Speicherstatus bewerten
if ($freeDiskGB -lt 20) {
    $diskStatus = "Wenig Speicher"
    $diskClass = "error"
} else {
    $diskStatus = "OK"
    $diskClass = "ok"
}

# CPU-Auslastung bewerten
$cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$cpuLoad = [math]::Round($cpuLoad, 2)

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

# Freigabe / Pfad prüfen
if (Test-Path $sharePath) {
    $shareStatus = "Erreichbar"
    $shareClass = "ok"
} else {
    $shareStatus = "Nicht erreichbar"
    $shareClass = "error"
}

# Relevante Dienste prüfen
$servicesToCheck = @("Spooler", "wuauserv", "WinDefend", "LanmanWorkstation")
$serviceObjects = @()

foreach ($serviceName in $servicesToCheck) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        $serviceObjects += [PSCustomObject]@{
            Dienst    = $serviceName
            Status    = "Nicht gefunden"
            Bewertung = "Warnung"
        }
    }
    elseif ($service.Status -eq "Running") {
        $serviceObjects += [PSCustomObject]@{
            Dienst    = $serviceName
            Status    = "Running"
            Bewertung = "OK"
        }
    }
    else {
        $serviceObjects += [PSCustomObject]@{
            Dienst    = $serviceName
            Status    = $service.Status
            Bewertung = "Fehler"
        }
    }
}

$serviceRows = ""
foreach ($svc in $serviceObjects) {
    if ($svc.Bewertung -eq "OK") {
        $svcClass = "ok"
    }
    elseif ($svc.Bewertung -eq "Warnung") {
        $svcClass = "warning"
    }
    else {
        $svcClass = "error"
    }

    $serviceRows += "<tr><td>$($svc.Dienst)</td><td>$($svc.Status)</td><td class='$svcClass'>$($svc.Bewertung)</td></tr>"
}

$html = @"
<html>
<head>
<meta charset="UTF-8">
<title>Windows Client Health Check</title>
<style>
body {
    font-family: Arial;
    background-color: #f4f6f8;
    padding: 30px;
}
h1 {
    color: #003366;
}
h2 {
    color: #003366;
    margin-top: 30px;
}
.box {
    background: white;
    padding: 24px;
    border-radius: 8px;
    width: 760px;
    box-shadow: 0px 2px 8px rgba(0,0,0,0.1);
}
.ok {
    color: green;
    font-weight: bold;
}
.warning {
    color: darkorange;
    font-weight: bold;
}
.error {
    color: red;
    font-weight: bold;
}
table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
}
th, td {
    border: 1px solid #d0d7de;
    padding: 10px;
    text-align: left;
}
th {
    background-color: #e9eef5;
}
</style>
</head>
<body>
<div class="box">
<h1>Windows Client Health Check</h1>
<p><b>Erstellt am:</b> $(Get-Date)</p>

<h2>Systemübersicht</h2>
<p><b>Computer:</b> $computerName</p>
<p><b>Benutzer:</b> $userName</p>
<p><b>Betriebssystem:</b> $($os.Caption)</p>
<p><b>RAM:</b> $totalRAMGB GB</p>
<p><b>Datenträger gesamt:</b> $totalDiskGB GB</p>
<p><b>Datenträger frei:</b> $freeDiskGB GB</p>
<p><b>Speicherstatus:</b> <span class="$diskClass">$diskStatus</span></p>
<p><b>Letzter Start:</b> $lastBoot</p>
<p><b>IP-Adresse:</b> $ipv4</p>

<h2>Erreichbarkeit</h2>
<p><b>Internetverbindung:</b> <span class="$networkClass">$networkStatus</span></p>
<p><b>Interner Zielhost ($internalTarget):</b> <span class="$internalTargetClass">$internalTargetStatus</span></p>
<p><b>Netzwerkpfad ($sharePath):</b> <span class="$shareClass">$shareStatus</span></p>

<h2>Systembewertung</h2>
<p><b>CPU-Auslastung:</b> $cpuLoad %</p>
<p><b>CPU-Status:</b> <span class="$cpuClass">$cpuStatus</span></p>

<h2>Geprüfte Dienste</h2>
<table>
    <tr>
        <th>Dienst</th>
        <th>Status</th>
        <th>Bewertung</th>
    </tr>
    $serviceRows
</table>
</div>
</body>
</html>
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($reportPath, $html, $utf8NoBom)
try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($reportPath, $html, $utf8NoBom)
    Write-Host "Report erstellt: $reportPath"
}
catch {
    Write-Error "Fehler beim Schreiben des Reports: $($_.Exception.Message)"
}