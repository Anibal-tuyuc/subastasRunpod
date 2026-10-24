# -*- coding: utf-8 -*-
"""
consultar_usuarios.py — Lista los usuarios registrados en la BD de subastas.

Uso:
    py -3.12 consultar_usuarios.py                # todos los usuarios
    py -3.12 consultar_usuarios.py --email juan   # filtrar por email/nombre
    py -3.12 consultar_usuarios.py --csv out.csv  # exportar a CSV

Variables de entorno (mismas que app.py):
    DB_SERVER, DB_NAME, DB_USER, DB_PASS, DB_TRUSTED
    Por defecto: localhost\\SQLEXPRESS, subastas_privadas, Windows Auth.
    Para el pod: DB_SERVER=localhost DB_USER=sa DB_PASS=... DB_TRUSTED=no
"""

import argparse
import csv
import os
import sys

import pyodbc

DB_SERVER = os.environ.get("DB_SERVER", r"localhost\SQLEXPRESS")
DB_NAME = os.environ.get("DB_NAME", "subastas_privadas")
DB_USER = os.environ.get("DB_USER", "")
DB_PASS = os.environ.get("DB_PASS", "")
DB_TRUSTED = os.environ.get("DB_TRUSTED", "yes" if not DB_USER else "no")

SQL_USUARIOS = """
DECLARE @filtro varchar(150) = ?;
DECLARE @like    varchar(160) = ?;

SELECT
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.email,
    u.telefono,
    ev.nombre          AS estado_verificacion,
    u.fecha_registro,
    u.fecha_ultimo_acceso,
    u.activo,
    STUFF((
        SELECT ', ' + r.nombre
        FROM dbo.Usuario_Roles ur
        JOIN dbo.Roles r ON r.id_rol = ur.id_rol
        WHERE ur.id_usuario = u.id_usuario
        FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 2, '') AS roles
FROM dbo.Usuarios u
JOIN dbo.Estados_Verificacion ev
    ON ev.id_estado_verificacion = u.id_estado_verificacion
WHERE (@filtro IS NULL
       OR u.email   LIKE @like
       OR u.nombre  LIKE @like
       OR u.apellido LIKE @like)
ORDER BY u.id_usuario;
"""


def get_connection():
    if DB_TRUSTED == "yes":
        auth = "Trusted_Connection=yes;"
    else:
        auth = f"UID={DB_USER};PWD={DB_PASS};"
    conn_str = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};{auth}"
        "Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=15;"
    )
    return pyodbc.connect(conn_str, autocommit=True)


def main():
    ap = argparse.ArgumentParser(description="Consulta usuarios registrados")
    ap.add_argument("--filtro", "--email", dest="filtro", default=None,
                    help="Texto a buscar en email, nombre o apellido")
    ap.add_argument("--csv", dest="csv_path", default=None,
                    help="Ruta para exportar el resultado a CSV")
    args = ap.parse_args()

    filtro = args.filtro
    like = f"%{filtro}%" if filtro else None

    try:
        conn = get_connection()
    except Exception as e:
        print(f"ERROR conectando a {DB_SERVER}/{DB_NAME}: {e}", file=sys.stderr)
        sys.exit(1)

    cur = conn.cursor()
    cur.execute(SQL_USUARIOS, (filtro, like))
    cols = [c[0] for c in cur.description]
    rows = cur.fetchall()
    cur.close()
    conn.close()

    if not rows:
        print("No se encontraron usuarios" + (f" para el filtro '{filtro}'." if filtro else "."))
        return

    # Tabla por consola
    anchos = {c: len(c) for c in cols}
    data = []
    for r in rows:
        fila = {}
        for c, v in zip(cols, r):
            if c == "activo":
                txt = "SI" if v else "NO"
            elif v is None:
                txt = "-"
            else:
                txt = str(v)
            fila[c] = txt
            anchos[c] = max(anchos[c], len(txt))
        data.append(fila)

    mostrar = ["id_usuario", "nombre", "apellido", "email", "telefono",
               "estado_verificacion", "roles", "activo",
               "fecha_registro", "fecha_ultimo_acceso"]

    enc = " | ".join(c.ljust(anchos[c]) for c in mostrar)
    print(enc)
    print("-+-".join("-" * anchos[c] for c in mostrar))
    for f in data:
        print(" | ".join(f[c].ljust(anchos[c]) for c in mostrar))
    print(f"\nTotal: {len(rows)} usuario(s).")

    if args.csv_path:
        with open(args.csv_path, "w", newline="", encoding="utf-8-sig") as fh:
            w = csv.DictWriter(fh, fieldnames=mostrar)
            w.writeheader()
            w.writerows(data)
        print(f"Exportado a {args.csv_path}")


if __name__ == "__main__":
    main()
