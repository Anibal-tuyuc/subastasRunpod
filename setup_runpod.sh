#!/bin/bash
# ============================================================
# SETUP COMPLETO: SQL Server 2022 + Streamlit en RunPod (CPU o GPU pod)
# OJO: los pods son contenedores SIN systemd. SQL Server se arranca
# directamente con sqlservr en segundo plano (tmux).
#
# Uso:  bash setup_runpod.sh
# ============================================================
set -e

SA_PASS="${SA_PASSWORD:?Define SA_PASSWORD antes de correr: export SA_PASSWORD='tu-clave'}"

# Zona horaria del negocio: Guatemala (UTC-6). El pod corre en UTC; sin
# esto los logs y cualquier fecha del sistema salen 6 horas adelantadas.
export TZ="America/Guatemala"
ln -sf /usr/share/zoneinfo/America/Guatemala /etc/localtime 2>/dev/null || true

echo "=== [1/6] Repositorios Microsoft + paquetes base ==="
apt-get update
apt-get install -y curl gnupg software-properties-common unixodbc tmux

curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list \
    > /etc/apt/sources.list.d/mssql-server-2022.list
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
    > /etc/apt/sources.list.d/mssql-release.list
apt-get update

echo "=== [2/6] Instalando SQL Server 2022 (Developer - gratis) ==="
apt-get install -y mssql-server

echo "=== Configurando instancia (edicion Developer) ==="
MSSQL_SA_PASSWORD="$SA_PASS" ACCEPT_EULA=Y MSSQL_PID=Developer \
    /opt/mssql/bin/mssql-conf -n setup accept-eula

echo "=== [3/6] Herramientas sqlcmd + driver ODBC 18 ==="
ACCEPT_EULA=Y apt-get install -y mssql-tools18 msodbcsql18
ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd || true

echo "=== [4/6] Arrancando SQL Server en tmux (sesion 'sql') ==="
# SIN systemd: sqlservr corre como proceso en primer plano dentro de tmux.
# El usuario del proceso debe ser mssql:
mkdir -p /var/opt/mssql/log
chown -R mssql:mssql /var/opt/mssql
tmux new-session -d -s sql "su mssql -s /bin/bash -c '/opt/mssql/bin/sqlservr'"

echo "Esperando a que SQL Server responda..."
for i in $(seq 1 30); do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASS" -C -l 2 -Q "SELECT 1" >/dev/null 2>&1; then
        echo "SQL Server ARRIBA despues de ${i}0s aprox."
        break
    fi
    sleep 10
done

echo "=== [5/6] Creando la base de datos ==="
sqlcmd -S localhost -U sa -P "$SA_PASS" -C -Q \
    "IF DB_ID('subastas_privadas') IS NULL CREATE DATABASE subastas_privadas;"

echo "=== [6/6] Python + dependencias + variables de entorno ==="
pip install streamlit==1.66.0 pyodbc==5.1.0 bcrypt==4.2.0

cat >> /etc/environment <<EOF
DB_SERVER=localhost,1433
DB_NAME=subastas_privadas
DB_USER=sa
DB_PASS=$SA_PASS
TZ=America/Guatemala
EOF

cat > /workspace/start_app.sh <<'EOF'
#!/bin/bash
# Arranque diario: SQL Server (si no esta) + Streamlit
export $(grep -v '^#' /etc/environment | xargs)
if ! tmux has-session -t sql 2>/dev/null; then
    tmux new-session -d -s sql "su mssql -s /bin/bash -c '/opt/mssql/bin/sqlservr'"
    sleep 30
fi
if ! tmux has-session -t app 2>/dev/null; then
    tmux new-session -d -s app \
        "streamlit run /workspace/app/app.py --server.address 0.0.0.0 --server.port 8501 --server.headless true \
         --server.enableCORS false --server.enableXsrfProtection false --server.enableWebsocketCompression false"
fi
echo "App en marcha. URL: https://<POD-ID>-8501.proxy.runpod.net"
EOF
chmod +x /workspace/start_app.sh

echo ""
echo "============================================================"
echo " SETUP COMPLETO"
echo "============================================================"
echo "Siguiente paso - carga la BD con UN solo comando (sube los .sql a /workspace):"
echo "  bash /workspace/cargar_bd.sh"
echo ""
echo "(cargar_bd.sh ya usa sqlcmd con -I = QUOTED_IDENTIFIER ON, obligatorio"
echo " para que sp_motor_pujas.sql se cree bien; sin eso el cierre de subastas"
echo " falla con error 1934 por las columnas calculadas de Ordenes_Pago)."
echo ""
echo "Luego arranca la app con:  bash /workspace/start_app.sh"
echo "URL publica: https://<POD-ID>-8501.proxy.runpod.net"
echo ""
echo "Sesiones tmux: 'sql' (motor BD) y 'app' (web)."
echo "Verlas:  tmux attach -t sql   /   tmux attach -t app   (Ctrl+B,D para salir)"
