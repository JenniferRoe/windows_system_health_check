# Windows System Health Check

## Projektbeschreibung

Dieses Projekt ist ein PowerShell-Skript zur automatisierten Analyse des Systemzustands eines Windows-Clients.

Das Skript wurde entwickelt, um typische Aufgaben aus dem IT-Support und der Systemadministration praktisch umzusetzen. Es sammelt relevante Systemdaten, bewertet diese und stellt die Ergebnisse strukturiert in einem Report dar.

Ziel ist es, schnell einen Überblick über den Zustand eines Systems zu erhalten.

---

## Funktionen

- Ermittlung von Systeminformationen
  - Computername
  - Benutzername
  - Betriebssystem

- Analyse von Systemressourcen
  - RAM
  - Festplattenspeicher (gesamt und frei)
  - CPU-Auslastung

- Netzwerkprüfung
  - Internetverbindung (Ping-Test)
  - Erreichbarkeit eines internen Zielsystems

- Überprüfung wichtiger Windows-Dienste

- Bewertung der Ergebnisse in:
  - OK
  - Warnung
  - Fehler

- Export der Ergebnisse als:
  - HTML-Report (visuelle Übersicht)
  - CSV-Datei (Weiterverarbeitung möglich)

---

## Technologien

- PowerShell
- WMI / CIM (Systemabfragen)
- HTML / CSS (Reporting)
- Windows Systemdienste

---

## Anwendung

```powershell
.\windows-system-health-check.ps1

##Projektstruktur

windows-system-health-check/
│
├── windows-system-health-check.ps1
├── reports/
│   ├── system_report_*.html
│   └── system_report_*.csv
└── README.md

Beispielausgabe

Das Skript erstellt einen HTML-Report mit einer strukturierten Übersicht aller geprüften Bereiche:

Systeminformationen
Netzwerkstatus
Speicher und CPU
Dienststatus

Zusätzlich wird eine CSV-Datei erzeugt, die für weitere Auswertungen genutzt werden kann.

Hinweis

Dieses Projekt dient Demonstrationszwecken und ist nicht für den produktiven Einsatz in sensiblen Umgebungen vorgesehen.