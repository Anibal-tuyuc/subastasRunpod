# 🔨 Plataforma de Subastas Privadas — Proyecto 3, Base de Datos I (UMG)

Sistema de subastas privadas en línea: catálogo de artículos exclusivos, sala de
pujas en tiempo real con anti-sniping, liquidación automática con comisiones y
panel de administración.

**Stack:** SQL Server 2022 · Streamlit (Python) · pyodbc (ODBC 18) · Cloudinary (imágenes)

---

## 🚀 Levantar en local (Windows)

Requisitos: SQL Server Express, Python **3.12** (NO 3.14 — pyodbc no compila ahí), ODBC Driver 18.

```powershell
# 1. Crear la BD y cargar esquema + datos (en SSMS o sqlcmd, en este orden):
#    sql/script_utf8.sql          -> DDL base (34+ tablas)
#    sql/mejoras_subastas.sql     -> tablas extra (ubicaciones, pedigree, cache)
#    sql/seed_catalogos.sql       -> catalogos (estados, roles, categorias)
#    sql/seed_catalogos_apoyo.sql
#    sql/seed_roles.sql
#    sql/datos_prueba_subastas.sql
#    sql/sp_motor_pujas.sql       -> motor (con sqlcmd usar flag -I, ver abajo)
#    sql/seed_subastas_prueba.sql

# 2. Instalar dependencias y arrancar
py -3.12 -m pip install streamlit pyodbc bcrypt
py -3.12 -m streamlit run app/app.py
# -> http://localhost:8501
```

> ⚠️ **sqlcmd necesita `-I`** al ejecutar `sp_motor_pujas.sql` (QUOTED_IDENTIFIER ON).
> `Ordenes_Pago` tiene columnas calculadas; sin eso los SPs se crean mal y el
> cierre de subastas falla con **error 1934**.
>
> Windows local: `SQLCMD.EXE -S localhost\SQLEXPRESS -E -C -I -d subastas_privadas -i sql\sp_motor_pujas.sql`

## ☁️ Despliegue en RunPod

Ver **[DESPLIEGUE_RUNPOD.md](DESPLIEGUE_RUNPOD.md)**. Resumen:

```bash
bash /workspace/restart_completo.sh   # instala todo + verifica SPs y hora GT
# restaurar backup si aplica, luego:
bash /workspace/run_streamlit.sh
```

URL: `https://<POD-ID>-8501.proxy.runpod.net`

---

## 📐 Reglas de negocio clave

| Regla | Detalle |
|---|---|
| **Monto de apertura** | `Subastas.monto_apertura` = **80%** de `Articulos.precio_base_reserva`. La subasta nunca arranca en 0: la primera puja mínima es `apertura + incremento`. |
| **Adjudicación** | Al cerrar, solo se adjudica si la puja ganadora **≥ monto_apertura**. Si no, cierra sin ganador ni orden de pago. |
| **Incrementos** | `Reglas_Incremento`: incremento mínimo por rango de montos, por subasta. |
| **Anti-sniping** | Puja en los últimos `extension_anti_sniping_seg` segundos → extiende el cierre. |
| **Hora Guatemala** | Toda la lógica usa `dbo.fn_AhoraGT()` (UTC-6). El servidor puede correr en UTC (RunPod) sin desfasar nada. |
| **Concurrencia** | `UPDLOCK, HOLDLOCK` + columna `version` (optimista) en `Subastas`. |
| **Auditoría** | Todo intento de puja (éxito o rechazo) queda en `Auditoria_Pujas` con resultado, IP y user-agent. |

## 👥 Equipo y responsabilidades

Ver **[EQUIPO.md](EQUIPO.md)** — división del código entre los 3 integrantes.

## 📁 Estructura

```
subastas-app/
├── app/
│   ├── app.py               # App Streamlit (ver secciones por duenio en EQUIPO.md)
│   └── requirements.txt
├── sql/
│   ├── script_utf8.sql      # DDL base
│   ├── sp_motor_pujas.sql   # Motor: sp_RegistrarPuja / sp_CerrarSubasta / sp_CerrarSubastasVencidas + fn_AhoraGT
│   ├── mejoras_subastas.sql # Tablas extra
│   ├── seed_*.sql           # Catalogos y datos de prueba
│   └── datos_prueba_subastas.sql
├── restart_completo.sh      # RunPod: reinstala todo + verifica (idempotente)
├── iniciar_todo.sh          # RunPod: arranque rapido
├── setup_runpod.sh          # RunPod: setup inicial del pod
├── cargar_bd.sh             # RunPod: carga todos los .sql en orden (sqlcmd -I)
├── DESPLIEGUE_RUNPOD.md
└── EQUIPO.md
```

## 🔒 Nota sobre credenciales

- Las contraseñas de la BD se toman de **variables de entorno** (`DB_SERVER`,
  `DB_NAME`, `DB_USER`, `DB_PASS`) — nunca hardcodeadas en `app.py`.
- **La clave del SA NO está en el repo.** Los scripts `.sh` la exigen como
  variable: `export SA_PASSWORD='tu-clave'` antes de correrlos. Si falta,
  fallan con un mensaje claro.
- Password del admin web: `ADMIN_WEB_PASS` (default `Admin2025!`, solo para dev).
- `service_account.json` (Google, en desuso) está en `.gitignore` y **nunca** se sube.
