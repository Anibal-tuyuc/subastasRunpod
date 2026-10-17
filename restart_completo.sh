#!/bin/bash
# ============================================================
# RESTART COMPLETO - Soluciona todos los problemas conocidos
# despues de reiniciar/recrear el pod RunPod.
# Uso: bash /workspace/restart_completo.sh
# ============================================================
set -u  # No usar set -e para no detenerse en errores esperados
# La clave del SA NO va en el repo: se pasa por variable de entorno.
#   export SA_PASSWORD='tu-clave'  &&  bash restart_completo.sh
SA_PASS="${SA_PASSWORD:?Define SA_PASSWORD antes de correr: export SA_PASSWORD='tu-clave'}"
# -I : QUOTED_IDENTIFIER ON (obligatorio para crear los SPs del motor:
# Ordenes_Pago tiene columnas calculadas y sin esto falla con error 1934).
SQLCMD="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SA_PASS -C -I"

# Zona horaria del negocio: Guatemala (UTC-6). El pod corre en UTC; sin
# esto los logs y cualquier fecha del sistema salen 6 horas adelantadas.
export TZ="America/Guatemala"
ln -sf /usr/share/zoneinfo/America/Guatemala /etc/localtime 2>/dev/null || true

echo "=========================================="
echo " RESTART COMPLETO - $(date)"
echo "=========================================="

# ---- 1) SQL Server instalado? ----
if [ ! -f /opt/mssql/bin/sqlservr ]; then
    echo "[1/8] Instalando SQL Server (esto tarda)..."
    apt-get update -qq
    apt-get install -y -qq curl gnupg software-properties-common unixodbc tmux
    curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null
    curl -s https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list > /etc/apt/sources.list.d/mssql-server-2022.list
    curl -s https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
    apt-get update -qq
    apt-get install -y -qq mssql-server
    echo "    Configurando instancia (el error de systemd es ESPERADO, continuando)..."
    MSSQL_SA_PASSWORD="$SA_PASS" ACCEPT_EULA=Y MSSQL_PID=Developer /opt/mssql/bin/mssql-conf -n setup accept-eula 2>/dev/null || true
else
    echo "[1/8] SQL Server ya instalado"
fi

# ---- 2) Herramientas sqlcmd ----
if [ ! -f /opt/mssql-tools18/bin/sqlcmd ]; then
    echo "[2/8] Instalando sqlcmd..."
    ACCEPT_EULA=Y apt-get install -y -qq mssql-tools18 msodbcsql18
    ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
else
    echo "[2/8] sqlcmd listo"
fi

# ---- 3) Python ----
echo "[3/8] Instalando dependencias Python..."
pip install -q streamlit==1.66.0 pyodbc==5.1.0 bcrypt==4.2.0 2>/dev/null

# ---- 4) Arrancar SQL Server ----
if ! tmux has-session -t sql 2>/dev/null; then
    echo "[4/8] Arrancando SQL Server..."
    mkdir -p /var/opt/mssql/log
    chown -R mssql:mssql /var/opt/mssql 2>/dev/null || true
    tmux new-session -d -s sql "su mssql -s /bin/bash -c '/opt/mssql/bin/sqlservr'"
    sleep 10
else
    echo "[4/8] SQL Server ya corriendo"
fi

# Esperar a que responda
echo "    Esperando SQL Server..."
for i in $(seq 1 30); do
    if $SQLCMD -l 2 -Q "SELECT 1" >/dev/null 2>&1; then
        echo "    SQL Server ARRIBA"
        break
    fi
    [ $i -eq 30 ] && echo "    ERROR: SQL Server no responde"
    sleep 5
done

# ---- 5) Crear BD si no existe ----
echo "[5/8] Verificando base de datos..."
$SQLCMD -l 5 -Q "IF DB_ID('subastas_privadas') IS NULL CREATE DATABASE subastas_privadas;" 2>/dev/null

# ---- 6) Cargar scripts SQL si la BD esta vacia ----
TABLAS=$($SQLCMD -d subastas_privadas -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.tables" 2>/dev/null | tr -d ' \r\n')
if [ "${TABLAS:-0}" -lt 30 ]; then
    echo "[6/8] Cargando DDL y catalogos..."
    bash /workspace/cargar_bd.sh

    # Corregir IDs de articulos si es necesario (problema conocido)
    echo "    Verificando IDs de articulos para seed_subastas..."
    IDS=$($SQLCMD -d subastas_privadas -h -1 -W -Q "SET NOCOUNT ON; SELECT STRING_AGG(CAST(id_articulo AS VARCHAR), ',') FROM (SELECT TOP 2 id_articulo FROM Articulos ORDER BY id_articulo) t" 2>/dev/null | tr -d ' \r\n')
    if [ -n "$IDS" ] && [ "$IDS" != "2,3" ]; then
        ID1=$(echo $IDS | cut -d',' -f1)
        ID2=$(echo $IDS | cut -d',' -f2)
        echo "    Ajustando seed_subastas_prueba.sql: articulos $ID1 y $ID2"
        sed -i "s/id_articulo = 2/id_articulo = $ID1/g; s/id_articulo = 3/id_articulo = $ID2/g; s/VALUES (2,/VALUES ($ID1,/g; s/VALUES (3,/VALUES ($ID2,/g" /workspace/sql/seed_subastas_prueba.sql
        $SQLCMD -d subastas_privadas -i /workspace/sql/seed_subastas_prueba.sql 2>/dev/null || true
    fi
else
    echo "[6/8] BD ya tiene datos ($TABLAS tablas)"
fi

# ---- 7) Crear usuario admin si no existe ----
echo "[7/8] Verificando usuario admin..."
ADMIN_EXISTS=$($SQLCMD -d subastas_privadas -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM Usuarios WHERE email = 'juniortuyuc5@gmail.com'" 2>/dev/null | tr -d ' \r\n')
if [ "${ADMIN_EXISTS:-0}" -eq 0 ]; then
    echo "    Creando usuario admin (hash bcrypt)..."
    # Password del admin web: variable ADMIN_WEB_PASS (default solo para dev).
    ADMIN_WEB_PASS="${ADMIN_WEB_PASS:-Admin2025!}"
    HASH=$(python3 -c "import bcrypt,os; print(bcrypt.hashpw(os.environ['AWP'].encode(), bcrypt.gensalt()).decode())" AWP="$ADMIN_WEB_PASS" 2>/dev/null || echo '')
    if [ -z "$HASH" ]; then
        HASH=$(AWP="$ADMIN_WEB_PASS" python3 -c "import bcrypt,os; print(bcrypt.hashpw(os.environ['AWP'].encode(), bcrypt.gensalt()).decode())")
    fi
    $SQLCMD -d subastas_privadas -Q "
        INSERT INTO Usuarios (nombre, apellido, email, password_hash, id_estado_verificacion, fecha_registro, activo)
        VALUES ('Junior', 'Tuyuc', 'juniortuyuc5@gmail.com', '$HASH', 1, dbo.fn_AhoraGT(), 1);
        INSERT INTO Usuario_Roles (id_usuario, id_rol, fecha_asignacion)
        SELECT id_usuario, 1, dbo.fn_AhoraGT() FROM Usuarios WHERE email = 'juniortuyuc5@gmail.com';" 2>/dev/null || true
    echo "    Usuario admin creado: juniortuyuc5@gmail.com (password: valor de ADMIN_WEB_PASS)"
else
    echo "    Usuario admin ya existe"
fi

# ---- 8) Arrancar Streamlit con flags anti-proxy ----
if ! tmux has-session -t app 2>/dev/null; then
    echo "[8/8] Arrancando Streamlit..."
    cat > /workspace/run_streamlit.sh << RUNEOF
#!/bin/bash
export DB_SERVER=localhost,1433
export DB_NAME=subastas_privadas
export DB_USER=sa
export DB_PASS='$SA_PASS'
export TZ=America/Guatemala
streamlit run /workspace/app/app.py \
  --server.address 0.0.0.0 \
  --server.port 8501 \
  --server.headless true \
  --server.enableCORS false \
  --server.enableXsrfProtection false \
  --server.enableWebsocketCompression false
RUNEOF
    chmod +x /workspace/run_streamlit.sh
    tmux new-session -d -s app "bash /workspace/run_streamlit.sh"
else
    echo "[8/8] App ya corriendo"
fi

echo ""
echo "=========================================="
echo " VERIFICACION"
echo "=========================================="
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
echo "=========================================="
echo " TODO LISTO"
echo " URL: https://$(hostname)-8501.proxy.runpod.net"
echo " Admin: juniortuyuc5@gmail.com (password: tu ADMIN_WEB_PASS)"
echo "=========================================="
tmux ls
