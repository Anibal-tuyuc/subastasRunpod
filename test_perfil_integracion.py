# -*- coding: utf-8 -*-
"""Prueba de integracion temporal: registro, login y perfil contra la BD real.
Ejecutar:  py -3.12 -I test_perfil_integracion.py
Usa una cuenta de prueba que se crea y se borra al final."""
import os
import re
import sys
import types

os.environ.setdefault("DB_SERVER", r"localhost\SQLEXPRESS")
os.environ.setdefault("DB_NAME", "subastas_privadas")

APP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app", "app.py")
src = open(APP, encoding="utf-8").read()

# Stub minimo de streamlit para importar solo la logica (sin UI)
st = types.ModuleType("streamlit")
st.cache_resource = lambda f: f
st.set_page_config = lambda *a, **k: None


def _noop(*a, **k):
    return None


st.__getattr__ = lambda name: _noop  # absorbe markdown, warning, etc.
comp = types.ModuleType("streamlit.components")
v1 = types.ModuleType("streamlit.components.v1")
st.components = comp
sys.modules["streamlit"] = st
sys.modules["streamlit.components"] = comp
sys.modules["streamlit.components.v1"] = v1

# Cortar el modulo antes de la seccion UI (HEADER DE MARCA)
corte = src.index("# HEADER DE MARCA")
corte = src.rindex("# ===", 0, corte)
ns = {"__name__": "apptest"}
exec(src[:corte], ns)

registrar = ns["registrar_usuario"]
login = ns["login"]
actualizar = ns["actualizar_perfil"]
query = ns["query"]

EMAIL = "prueba.perfil.umg@gmail.com"
EMAIL_NUEVO = "nuevo.correo.umg@gmail.com"

conn = ns["get_connection"]()
cur = conn.cursor()
for e in (EMAIL, EMAIL_NUEVO):
    cur.execute("DELETE FROM Usuario_Roles WHERE id_usuario IN "
                "(SELECT id_usuario FROM Usuarios WHERE email = ?)", e)
    cur.execute("DELETE FROM Usuarios WHERE email = ?", e)
conn.commit()

# 1. Registro con correo en mayusculas y espacios -> normalizado
ok, msg = registrar("  Prueba  ", "Perfil", "  Prueba.Perfil.UMG@Gmail.COM ", "secreto1")
assert ok, msg
fila = query("SELECT nombre, email FROM Usuarios WHERE email = ?", (EMAIL,))[0]
assert fila["email"] == EMAIL and fila["nombre"] == "Prueba", fila
print("1. Registro normaliza correo y nombre: OK")

# 2. Registro duplicado (misma cuenta, otra capitalizacion)
ok, msg = registrar("Otro", "User", "PRUEBA.PERFIL.UMG@gmail.com", "secreto1")
assert not ok and "ya esta registrado" in msg, msg
print("2. Duplicado rechazado: OK ->", msg)

# 3. Registro con correo mal formado
ok, msg = registrar("X", "Y", "no-es-correo", "secreto1")
assert not ok and "formato" in msg, msg
print("3. Correo invalido rechazado: OK ->", msg)

# 4. Login con mayusculas/espacios funciona (normaliza)
u = login(" Prueba.Perfil.UMG@GMAIL.com ", "secreto1")
assert u and u["id_usuario"], u
uid = u["id_usuario"]
print("4. Login normalizado: OK (id", uid, ")")

# 5. Login con correo invalido no consulta BD (rechazo temprano)
assert login("basura", "secreto1") is None
print("5. Login con correo invalido rechazado: OK")

# 6. Actualizar perfil: nombre, apellido, telefono y correo
ok, msg = actualizar(uid, "NombreNuevo", "ApellidoNuevo", EMAIL_NUEVO, "5555-0001")
assert ok, msg
fila = query("SELECT nombre, apellido, email, telefono FROM Usuarios "
             "WHERE id_usuario = ?", (uid,))[0]
assert fila["nombre"] == "NombreNuevo" and fila["apellido"] == "ApellidoNuevo"
assert fila["email"] == EMAIL_NUEVO and fila["telefono"] == "5555-0001", fila
print("6. Actualizacion de perfil: OK")

# 7. Telefono vacio -> NULL
ok, msg = actualizar(uid, "NombreNuevo", "ApellidoNuevo", EMAIL_NUEVO, "")
assert ok, msg
assert query("SELECT telefono FROM Usuarios WHERE id_usuario = ?",
             (uid,))[0]["telefono"] is None
print("7. Telefono vacio -> NULL: OK")

# 8. Cambiar al correo de OTRA cuenta -> rechazado sin tocar nada
otro = query("SELECT TOP 1 email FROM Usuarios WHERE id_usuario != ?", (uid,))
assert otro, "Se necesita otra cuenta en la BD para esta prueba"
ok, msg = actualizar(uid, "NombreNuevo", "ApellidoNuevo", otro[0]["email"], None)
assert not ok and "otra cuenta" in msg, msg
fila = query("SELECT email FROM Usuarios WHERE id_usuario = ?", (uid,))[0]
assert fila["email"] == EMAIL_NUEVO
print("8. Correo de otra cuenta rechazado sin cambios: OK ->", msg)

# 9. Login con el correo NUEVO funciona; con el VIEJO ya no
assert login(EMAIL_NUEVO, "secreto1") is not None
assert login(EMAIL, "secreto1") is None
print("9. Login con correo nuevo / viejo: OK")

# 10. Campos protegidos no cambian: verificacion, activo, hash y fechas
antes = query("SELECT password_hash, id_estado_verificacion, fecha_registro, "
              "activo FROM Usuarios WHERE id_usuario = ?", (uid,))[0]
ok, msg = actualizar(uid, "OtroNombre", "OtroApellido", EMAIL_NUEVO, "123")
despues = query("SELECT password_hash, id_estado_verificacion, fecha_registro, "
                "activo FROM Usuarios WHERE id_usuario = ?", (uid,))[0]
assert antes == despues, (antes, despues)
print("10. Campos protegidos intactos tras actualizar perfil: OK")

# Limpieza
cur.execute("DELETE FROM Usuario_Roles WHERE id_usuario = ?", uid)
cur.execute("DELETE FROM Usuarios WHERE id_usuario = ?", uid)
conn.commit()
print()
print("TODAS LAS PRUEBAS DE INTEGRACION PASARON")
