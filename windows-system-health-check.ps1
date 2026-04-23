```powershell
# Windows System Health Check
# Autor: Jennifer Rösner
# Beschreibung:
# Dieses Script prüft Systeminformationen und erstellt einen HTML Report.

$reportFolder = ".\reports"

if (!(Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = Join-Path $reportFolder "system_report_$timestamp.html"

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
    Where-Object { $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -First 1).IPAddress

$ping = Test-Connection 8.8.8.8 -Count 1 -Quiet

if ($ping) {
    $networkStatus = "OK"
    $networkClass = "ok"
} else {
    $networkStatus = "Fehler"
    $networkClass = "error"
}

$html = @"
<html>
<head>
<title>System Health Check</title>
<style>
body {
    font-family: Arial;
    background-color: #f4f6f8;
    padding: 30px;
}

h1 {
    color: #003366;
}

.box {
    background: white;
    padding: 20px;
    border-radius: 8px;
    width: 400px;
    box-shadow: 0px 2px 8px rgba(0,0,0,0.1);
}

.ok {
    color: green;
    font-weight: bold;
}

.error {
    color: red;
    font-weight: bold;
}
</style>
</head>

<body>
<div class="box">
<h1>System Health Check</h1>

<p><b>Computer:</b> $computerName</p>
<p><b>Benutzer:</b> $userName</p>
<p><b>OS:</b> $($os.Caption)</p>
<p><b>RAM:</b> $totalRAMGB GB</p>
<p><b>Disk gesamt:</b> $totalDiskGB GB</p>
<p><b>Disk frei:</b> $freeDiskGB GB</p>
<p><b>Letzter Start:</b> $lastBoot</p>
<p><b>IP:</b> $ipv4</p>
<p><b>Netzwerk:</b> <span class="$networkClass">$networkStatus</span></p>

</div>
</body>
</html>
"@

$html | Out-File $reportPath -Encoding UTF8

Write-Host "Report erstellt: $reportPath"