# -*- coding: utf-8 -*-
"""
Script de pruebas de conexion a la VM de la universidad (SQL Server).
Ejecutar: python -I test_conexion_vm.py

Prueba 3 cosas:
  1. El puerto 1433 responde (firewall/NSG abierto)
  2. Autenticacion SQL funciona (login valido)
  3. La base de datos subastas_privadas existe y tiene las tablas esperadas
"""
import socket
import sys

# ============ CONFIGURA AQUI LOS DATOS DE TU VM ============
VM_HOST = "IP_DE_LA_VM"      # Ej: "20.x.x.x" o "subastas.universidad.edu"
VM_PORT = 1433
DB_USER = "USUARIO_SQL"      # Ej: "sa" o "app_subastas"
DB_PASS = "PASSWORD_SQL"
DB_NAME = "subastas_privadas"
# ===========================================================


def prueba_1_puerto_tcp():
    """Prueba si el puerto 1433 esta abierto desde esta maquina."""
    print("=" * 60)
    print(f"PRUEBA 1: Conexion TCP a {VM_HOST}:{VM_PORT}")
    print("=" * 60)
    try:
        sock = socket.create_connection((VM_HOST, VM_PORT), timeout=10)
        sock.close()
        print("[OK] Puerto 1433 ABIERTO. El firewall permite conexiones.")
        return True
    except socket.timeout:
        print("[FALLO] TIMEOUT - El puerto no responde.")
        print("  Posibles causas:")
        print("  - NSG de Azure bloquea el puerto 1433")
        print("  - Firewall de Windows en la VM lo bloquea")
        print("  - SQL Server no escucha en TCP/IP")
        print("  - La IP es incorrecta")
        return False
    except ConnectionRefusedError:
        print("[FALLO] CONEXION RECHAZADA - Algo escucha pero rechaza.")
        print("  SQL Server puede estar detenido o el firewall rechaza activamente.")
        return False
    except socket.gaierror:
        print("[FALLO] No se pudo resolver el nombre/IP. Verifica VM_HOST.")
        return False


def prueba_2_login_sql():
    """Prueba autenticacion contra SQL Server."""
    print()
    print("=" * 60)
    print("PRUEBA 2: Autenticacion SQL Server (pyodbc)")
    print("=" * 60)
    try:
        import pyodbc
    except ImportError:
        print("[SKIP] pyodbc no instalado. Instala con: pip install pyodbc")
        return None

    drivers = [d for d in pyodbc.drivers() if "SQL Server" in d]
    print(f"  Drivers ODBC disponibles: {drivers}")
    if not drivers:
        print("[FALLO] No hay driver ODBC de SQL Server instalado.")
        print("  Descarga: 'ODBC Driver 18 for SQL Server' de Microsoft")
        return False

    driver = "ODBC Driver 18 for SQL Server" if "ODBC Driver 18 for SQL Server" in drivers else drivers[-1]

    conn_str = (
        f"DRIVER={{{driver}}};"
        f"SERVER={VM_HOST},{VM_PORT};"
        f"DATABASE={DB_NAME};"
        f"UID={DB_USER};"
        f"PWD={DB_PASS};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=yes;"
        f"Connection Timeout=10;"
    )
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        print(f"[OK] LOGIN EXITOSO")
        print(f"  Version: {version.split(chr(10))[0]}")
        conn.close()
        return True
    except Exception as e:
        print(f"[FALLO] Error de autenticacion/conexion:")
        print(f"  {e}")
        msg = str(e)
        if "18456" in msg:
            print("  -> Login fallido: usuario/password incorrectos o autenticacion SQL deshabilitada")
        elif "10060" in msg or "10061" in msg:
            print("  -> Red: timeout o rechazo (revisa prueba 1)")
        return False


def prueba_3_estructura_bd():
    """Verifica que existan las tablas esperadas del proyecto."""
    print()
    print("=" * 60)
    print("PRUEBA 3: Estructura de la base de datos")
    print("=" * 60)
    try:
        import pyodbc
        conn_str = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};"
            f"SERVER={VM_HOST},{VM_PORT};"
            f"DATABASE={DB_NAME};"
            f"UID={DB_USER};PWD={DB_PASS};"
            f"Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=10;"
        )
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute("""
            SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME
        """)
        tablas = [r[0] for r in cursor.fetchall()]
        print(f"  Tablas encontradas ({len(tablas)}):")
        for t in tablas:
            print(f"    - {t}")

        esperadas = {"Usuarios", "Articulos", "Subastas", "Pujas", "Categorias",
                     "Monedas", "Ubicaciones_Almacenaje"}
        faltantes = esperadas - set(tablas)
        if faltantes:
            print(f"\n  [!] Faltan tablas: {faltantes}")
            print("  -> Ejecuta los scripts DDL y mejoras_subastas.sql en la VM")
        else:
            print("\n[OK] Todas las tablas base del proyecto existen.")

        # Verificar SPs clave
        cursor.execute("""
            SELECT name FROM sys.procedures ORDER BY name
        """)
        sps = [r[0] for r in cursor.fetchall()]
        print(f"\n  Stored Procedures ({len(sps)}):")
        for s in sps:
            print(f"    - {s}")
        if not sps:
            print("  [!] No hay SPs. El backend SQL aun no se implementa.")

        conn.close()
        return True
    except Exception as e:
        print(f"[FALLO] {e}")
        return False


if __name__ == "__main__":
    if VM_HOST == "IP_DE_LA_VM":
        print(">> Edita este script y configura VM_HOST, DB_USER y DB_PASS primero <<")
        sys.exit(1)

    r1 = prueba_1_puerto_tcp()
    if r1:
        r2 = prueba_2_login_sql()
        if r2:
            prueba_3_estructura_bd()
    else:
        print("\n>> Corrige la prueba 1 antes de continuar. <<")
        print("   Sin acceso al puerto 1433, RunPod tampoco podra conectarse.")

    print()
    print("=" * 60)
    print("RESUMEN PARA ARQUITECTURA RUNPOD -> VM")
    print("=" * 60)
    print("""
Si las 3 pruebas pasan desde tu PC, pasaran desde RunPod
(RunPod tiene salida a internet sin restricciones de origen).

Si la prueba 1 FALLA: la universidad tiene el puerto cerrado a nivel
de NSG/red. Sin acceso admin a la VM, tus opciones son:
  A) Pedir al admin de la universidad que abra 1433 (o un puerto alterno)
  B) Usar un tunel inverso desde la VM (requiere ejecutar algo EN la VM)
  C) Levantar SQL Server en RunPod con un disco persistente (volumen)
     y migrar la BD ahi. Funciona, pero la BD vivira en RunPod.
""")
