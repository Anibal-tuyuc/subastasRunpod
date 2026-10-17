#!/bin/bash
# ============================================================
# CARGA COMPLETA DE LA BD en el pod RunPod (corre DESPUES de setup_runpod.sh)
# Uso:  bash /workspace/cargar_bd.sh
# ============================================================
set -e
SA_PASS="${SA_PASSWORD:?Define SA_PASSWORD antes de correr: export SA_PASSWORD='tu-clave'}"
# -I : habilita QUOTED_IDENTIFIER en la sesion de sqlcmd. OBLIGATORIO para
# sp_motor_pujas.sql (Ordenes_Pago tiene columnas calculadas; si el SP se
# crea con QUOTED_IDENTIFIER OFF falla con error 1934 al insertar).
SQLCMD="/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $SA_PASS -C -I -d subastas_privadas"
cd /workspace

echo "Cargando scripts SQL en orden..."
for f in \
    sql/script_utf8.sql \
    sql/mejoras_subastas.sql \
    sql/seed_catalogos.sql \
    sql/seed_catalogos_apoyo.sql \
    sql/seed_roles.sql \
    sql/datos_prueba_subastas.sql \
    sql/sp_motor_pujas.sql \
    sql/seed_subastas_prueba.sql
do
    echo "  -> $f"
    $SQLCMD -i "$f" -l 30
done

echo ""
echo "=== Verificacion ==="
$SQLCMD -W -Q "
SELECT 'tablas' AS obj, COUNT(*) AS n FROM sys.tables
UNION ALL SELECT 'SPs motor', COUNT(*) FROM sys.procedures WHERE name LIKE 'sp_%'
UNION ALL SELECT 'usuarios', COUNT(*) FROM Usuarios
UNION ALL SELECT 'subastas activas', COUNT(*) FROM Subastas s
    JOIN Estados_Subasta e ON s.id_estado_subasta=e.id_estado_subasta WHERE e.nombre='Activa'
UNION ALL SELECT 'Resultados_Intento (debe ser 5)', COUNT(*) FROM Resultados_Intento;"

echo ""
echo "BD lista. Arranca la app con:  bash /workspace/start_app.sh"
