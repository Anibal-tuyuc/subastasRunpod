# ============================================================
# DIAGNOSTICO DE LA VM - Correr DENTRO de la VM via RDP
# Click derecho -> "Ejecutar con PowerShell" (como Administrador)
# Copia TODO el output y pegalo en el chat
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 1. IP PUBLICA DE LA VM" -ForegroundColor Cyan
Write-Host "============================================================"
try {
    $ipPublica = (Invoke-RestMethod -Uri "https://ifconfig.me/ip" -TimeoutSec 10).Trim()
    Write-Host "[OK] IP publica: $ipPublica" -ForegroundColor Green
} catch {
    Write-Host "[FALLO] No se pudo obtener IP publica (sin salida a internet?)" -ForegroundColor Red
}
Write-Host ""
Write-Host "IPs locales:"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
    ForEach-Object { Write-Host "  $($_.InterfaceAlias): $($_.IPAddress)" }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 2. SERVICIO SQL SERVER" -ForegroundColor Cyan
Write-Host "============================================================"
Get-Service | Where-Object { $_.Name -like "MSSQL*" -or $_.DisplayName -like "*SQL Server*" } |
    Format-Table Name, Status, StartType -AutoSize

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 3. PUERTOS DONDE ESCUCHA SQL SERVER" -ForegroundColor Cyan
Write-Host "============================================================"
$conexiones = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.OwningProcess -in (Get-Process sqlservr -ErrorAction SilentlyContinue).Id }
if ($conexiones) {
    $conexiones | Format-Table LocalAddress, LocalPort -AutoSize
    Write-Host "[OK] SQL Server esta escuchando en los puertos de arriba" -ForegroundColor Green
} else {
    Write-Host "[FALLO] SQL Server no escucha en TCP/IP (o esta detenido)" -ForegroundColor Red
    Write-Host "  -> Abrir 'SQL Server Configuration Manager' -> Protocols -> TCP/IP -> Enable"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 4. FIREWALL DE WINDOWS - REGLAS PUERTO 1433" -ForegroundColor Cyan
Write-Host "============================================================"
$reglas = Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*SQL*" -or $_.DisplayName -like "*1433*" }
if ($reglas) {
    $reglas | Format-Table DisplayName, Action, Profile -AutoSize
} else {
    Write-Host "[!] No hay regla de firewall para 1433. Creando una..." -ForegroundColor Yellow
    try {
        New-NetFirewallRule -DisplayName "SQL Server 1433 Inbound" -Direction Inbound `
            -Protocol TCP -LocalPort 1433 -Action Allow -Profile Any -ErrorAction Stop
        Write-Host "[OK] Regla creada: SQL Server 1433 Inbound" -ForegroundColor Green
    } catch {
        Write-Host "[FALLO] No se pudo crear la regla (ejecuta como Administrador)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 5. AUTENTICACION MIXTA Y BASE DE DATOS (sqlcmd local)" -ForegroundColor Cyan
Write-Host "============================================================"
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if ($sqlcmd) {
    Write-Host "Probando conexion local con Windows Auth..."
    $query = @"
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS [Solo_Windows_Auth_1_si_0_no];
SELECT name FROM sys.databases WHERE name = 'subastas_privadas';
"@
    $resultado = sqlcmd -S localhost -E -Q $query -W 2>&1
    Write-Host $resultado
    Write-Host ""
    Write-Host "NOTA: Si 'Solo_Windows_Auth' = 1, hay que habilitar autenticacion mixta:" -ForegroundColor Yellow
    Write-Host "  SSMS -> click derecho servidor -> Properties -> Security -> SQL Server and Windows Auth"
} else {
    Write-Host "[!] sqlcmd no esta en el PATH. Usa SSMS manualmente para:" -ForegroundColor Yellow
    Write-Host "  - Verificar autenticacion mixta"
    Write-Host "  - Verificar que existe la BD subastas_privadas"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 6. RESUMEN - QUE FALTA VERIFICAR" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host @"

Copia este output completo.

El punto que NO podemos ver desde dentro de la VM es el NSG de Azure
(el firewall externo de la red de la universidad). Eso se prueba
DESDE FUERA: desde tu PC, corre despues:

    Test-NetConnection -ComputerName <IP_PUBLICA> -Port 1433

Si eso da TcpTestSucceeded: True  -> RunPod podra conectarse. LISTO.
Si eso da False                 -> el NSG bloquea 1433. Opciones:
    A) Pedir a la universidad abrir 1433 en el NSG
    B) Cambiar SQL Server a escuchar en un puerto ya abierto (80/443/8080)
    C) Tunel inverso: cloudflared o SSH -R desde la VM hacia RunPod
       (la conexion es SALIENTE desde la VM, el NSG no lo bloquea)
"@
