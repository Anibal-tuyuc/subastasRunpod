#!/bin/bash
# ============================================================
# INICIAR TODO - Reinstala (si hace falta) y arranca el stack
# completo despues de un reinicio/recreacion del pod RunPod.
# Idempotente: se puede correr N veces sin romper nada.
# Uso:  bash /workspace/iniciar_todo.sh
# ============================================================
SA_PASS="${SA_PASSWORD:?Define SA_PASSWORD antes de correr: export SA_PASSWORD='tu-clave'}"
# -I : QUOTED_IDENTIFIER ON (obligatorio para crear los SPs del motor:
# Ordenes_Pago tiene columnas calculadas y sin esto falla con error 1934).
SQLCMD="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SA_PASS -C -I"

# Zona horaria del negocio: Guatemala (UTC-6). El pod corre en UTC; sin
# esto los logs y cualquier fecha del sistema salen 6 horas adelantadas.
export TZ="America/Guatemala"
ln -sf /usr/share/zoneinfo/America/Guatemala /etc/localtime 2>/dev/null || true

echo "=============================="
echo " INICIO: $(date)"
echo "=============================="

# ---- 1) SQL Server instalado? ----
if [ ! -f /opt/mssql/bin/sqlservr ]; then
    echo "[1/6] Instalando SQL Server 2022 (tarda varios min)..."
    apt-get update
    apt-get install -y curl gnupg software-properties-common unixodbc tmux
    curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    curl -s https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list \
        > /etc/apt/sources.list.d/mssql-server-2022.list
    curl -s https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
        > /etc/apt/sources.list.d/mssql-release.list
    apt-get update
    apt-get install -y mssql-server
    echo "    Configurando instancia (el error de systemd al final es ESPERADO, se ignora)..."
    MSSQL_SA_PASSWORD="$SA_PASS" ACCEPT_EULA=Y MSSQL_PID=Developer \
        /opt/mssql/bin/mssql-conf -n setup accept-eula || true
else
    echo "[1/6] SQL Server ya instalado."
fi

# ---- 2) Herramientas sqlcmd + ODBC 18 ----
if [ ! -f /opt/mssql-tools18/bin/sqlcmd ]; then
    echo "[2/6] Instalando sqlcmd + ODBC 18..."
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 msodbcsql18
    ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
else
    echo "[2/6] sqlcmd ya instalado."
fi

# ---- 3) Dependencias Python ----
echo "[3/6] Verificando dependencias Python..."
pip install -q streamlit==1.66.0 pyodbc==5.1.0 bcrypt==4.2.0

# ---- 4) Arrancar SQL Server en tmux ----
if ! tmux has-session -t sql 2>/dev/null; then
    echo "[4/6] Arrancando SQL Server en tmux (sesion 'sql')..."
    mkdir -p /var/opt/mssql/log
    chown -R mssql:mssql /var/opt/mssql
    tmux new-session -d -s sql "su mssql -s /bin/bash -c '/opt/mssql/bin/sqlservr'"
else
    echo "[4/6] SQL Server ya corriendo en tmux."
fi

echo "    Esperando a que SQL Server responda..."
SQL_OK=0
for i in $(seq 1 36); do
    if $SQLCMD -l 2 -Q "SELECT 1" >/dev/null 2>&1; then
        echo "    SQL Server ARRIBA (~$((i*5))s)"
        SQL_OK=1
        break
    fi
    sleep 5
done
if [ $SQL_OK -eq 0 ]; then
    echo "ERROR: SQL Server no respondio en 3 min. Revisa: tmux attach -t sql"
    exit 1
fi

# ---- 5) Base de datos ----
echo "[5/6] Verificando base de datos..."
$SQLCMD -l 5 -Q "IF DB_ID('subastas_privadas') IS NULL CREATE DATABASE subastas_privadas;"

TABLAS=$($SQLCMD -d subastas_privadas -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables" 2>/dev/null | tr -d ' \r')
if [ "${TABLAS:-0}" -lt 30 ]; then
    echo "    BD vacia o incompleta ($TABLAS tablas). Cargando scripts..."
    bash /workspace/cargar_bd.sh
else
    echo "    BD ya tiene datos ($TABLAS tablas). OK."
fi

# ---- 6) Arrancar la app ----
if ! tmux has-session -t app 2>/dev/null; then
    echo "[6/6] Arrancando Streamlit (sesion 'app')..."
    tmux new-session -d -s app \
        "export DB_SERVER=localhost,1433 DB_NAME=subastas_privadas DB_USER=sa DB_PASS='$SA_PASS' TZ=America/Guatemala; \
         streamlit run /workspace/app/app.py --server.address 0.0.0.0 --server.port 8501 --server.headless true \
         --server.enableCORS false --server.enableXsrfProtection false --server.enableWebsocketCompression false"
else
    echo "[6/6] App ya corriendo en tmux."
fi

echo ""
echo "=============================="
echo " VERIFICACION"
echo "=============================="
# Los SPs deben tener QUOTED_IDENTIFIER congelado en ON, si no el cierre
# de subastas falla con error 1934 (columnas calculadas en Ordenes_Pago).
QI=$($SQLCMD -d subastas_privadas -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.sql_modules sm JOIN sys.objects o ON sm.object_id=o.object_id WHERE o.name IN ('sp_RegistrarPuja','sp_CerrarSubasta','sp_CerrarSubastasVencidas') AND sm.uses_quoted_identifier=1" 2>/dev/null | tr -d ' \r\n')
if [ "${QI:-0}" -eq 3 ]; then
    echo " OK: 3/3 SPs con QUOTED_IDENTIFIER ON"
else
    echo " ⚠️  Solo ${QI:-0}/3 SPs correctos — re-aplicando motor de pujas..."
    $SQLCMD -d subastas_privadas -i /workspace/sql/sp_motor_pujas.sql -l 30 || true
fi
echo " Hora GT: $($SQLCMD -h -1 -W -Q "SET NOCOUNT ON; SELECT CONVERT(VARCHAR, dbo.fn_AhoraGT(), 120)" -d subastas_privadas 2>/dev/null | tr -d '\r')"
echo "=============================="
echo " TODO LISTO"
echo " URL: https://<POD-ID>-8501.proxy.runpod.net"
echo "=============================="
tmux ls
