@echo off
setlocal EnableDelayedExpansion
title Subastas UMG - Inicio Automatico

echo ============================================================
echo   SUBASTAS UMG - Inicio automatico
echo   Proyecto: C:\Users\Admin\subastas-app
echo ============================================================
echo.

set "APP_PATH=C:\Users\Admin\subastas-app\app\app.py"
set "SQLCMD=C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\180\Tools\Binn\SQLCMD.EXE"
set "DB_NAME=subastas_privadas"
set "BACKUP_PATH=C:\Users\Admin\subastas-app\backup_subastas_v3.bak"
set "PYTHON=py -3.12"

REM ============================================================
REM 1. Verificar que SQL Server (SQLEXPRESS) este corriendo
REM ============================================================
echo [1/4] Verificando SQL Server SQLEXPRESS...
sc query "MSSQL$SQLEXPRESS" | find "RUNNING" >nul 2>&1
if %errorlevel% neq 0 (
    echo       No esta corriendo. Intentando iniciar servicio...
    net start "MSSQL$SQLEXPRESS" >nul 2>&1
    if !errorlevel! neq 0 (
        echo.
        echo [ERROR] No se pudo iniciar SQL Server.
        echo         Ejecuta este .bat como ADMINISTRADOR o inicia el servicio manualmente.
        echo.
        pause
        exit /b 1
    )
    echo       Servicio iniciado. Esperando a que acepte conexiones...
) else (
    echo       OK - Servicio en ejecucion.
)

REM Esperar a que SQL Server responda (hasta 30 segundos)
set /a INTENTOS=0
:esperar_sql
"%SQLCMD%" -S "localhost\SQLEXPRESS" -E -C -l 2 -Q "SELECT 1" >nul 2>&1
if %errorlevel% neq 0 (
    set /a INTENTOS+=1
    if !INTENTOS! geq 15 (
        echo.
        echo [ERROR] SQL Server no respondio en 30 segundos.
        pause
        exit /b 1
    )
    timeout /t 2 /nobreak >nul
    goto :esperar_sql
)
echo       SQL Server responde correctamente.
echo.

REM ============================================================
REM 2. Verificar que exista la base de datos
REM ============================================================
echo [2/4] Verificando base de datos '%DB_NAME%'...
"%SQLCMD%" -S "localhost\SQLEXPRESS" -E -C -Q "SELECT name FROM sys.databases WHERE name='%DB_NAME%'" -h -1 | find "%DB_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo       La base de datos NO existe.
    echo       Restaurando desde backup: %BACKUP_PATH%
    "%SQLCMD%" -S "localhost\SQLEXPRESS" -E -C -I -Q "RESTORE DATABASE [%DB_NAME%] FROM DISK='%BACKUP_PATH%' WITH REPLACE"
    if !errorlevel! neq 0 (
        echo.
        echo [ERROR] No se pudo restaurar el backup.
        echo         Verifica que exista: %BACKUP_PATH%
        pause
        exit /b 1
    )
    echo       Backup restaurado correctamente.
) else (
    echo       OK - Base de datos existe.
)
echo.

REM ============================================================
REM 3. Verificar Python 3.12 y Streamlit
REM ============================================================
echo [3/4] Verificando Python 3.12 y Streamlit...
%PYTHON% -c "import streamlit" >nul 2>&1
if %errorlevel% neq 0 (
    echo       Streamlit no detectado en Python 3.12. Instalando...
    %PYTHON% -m pip install -r "C:\Users\Admin\subastas-app\app\requirements.txt"
    if !errorlevel! neq 0 (
        echo.
        echo [ERROR] No se pudieron instalar las dependencias.
        echo         Verifica que Python 3.12 este instalado: py -3.12 --version
        pause
        exit /b 1
    )
)
echo       OK - Python 3.12 + Streamlit listos.
echo.

REM ============================================================
REM 4. Arrancar la aplicacion
REM ============================================================
echo [4/4] Iniciando aplicacion Streamlit...
echo.
echo ============================================================
echo   La app se abrira en: http://localhost:8501
echo   Usuario: juniortuyuc5@gmail.com
echo   Clave:   Admin2025!
echo ============================================================
echo   Para detener: cierra esta ventana o presiona Ctrl+C
echo ============================================================
echo.

timeout /t 3 /nobreak >nul
start "" "http://localhost:8501"

%PYTHON% -m streamlit run "%APP_PATH%" ^
    --server.port 8501 ^
    --server.address localhost ^
    --server.enableCORS false ^
    --server.enableXsrfProtection false

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] La aplicacion se cerro con error.
    pause
)

endlocal
