# Infraestructura del Proyecto — Plataforma de Subastas Privadas UMG

**Documento de arquitectura y operación** · Proyecto 3 — Base de Datos I
*Última actualización: 2026-10-17*

---

## 1. Vista general

Plataforma web de subastas privadas en línea, accesible públicamente por HTTPS, que soporta múltiples usuarios concurrentes registrándose, publicando artículos y pujando en tiempo real.

```
Usuarios (navegador)
        │  HTTPS
        ▼
https://<POD-ID>-8501.proxy.runpod.net      ← Proxy reverso de RunPod (TLS incluido)
        │
        ▼
┌─────────────────────────────────────────────┐
│  Pod RunPod (Ubuntu 22.04, contenedor)      │
│                                             │
│   Streamlit (Python 3) ──ODBC/TCP 1433──► SQL Server 2022 Developer
│   puerto 8501            localhost          BD: subastas_privadas
│                                             │
│   tmux session "app"      tmux session "sql"│
└─────────────────────────────────────────────┘
        │
        ▼
   Cloudinary (CDN externo de imágenes — API HTTPS)
```

**Decisión clave de arquitectura:** todo corre dentro de **un solo pod** (app + base de datos). No hay red externa entre componentes: la app habla con SQL Server por `localhost`, lo que elimina problemas de firewall, latencia y exposición del puerto 1433 a internet.

---

## 2. Componentes

| Capa | Tecnología | Detalle |
|---|---|---|
| Hosting | **RunPod** (nube, pods on-demand) | Contenedor Ubuntu 22.04, imagen `runpod/base:1.0.3-ubuntu2204` |
| Frontend/Backend | **Streamlit 1.66** (Python) | App monolítica `app.py` — UI y lógica de presentación |
| Base de datos | **SQL Server 2022 Developer** | ~38 tablas, stored procedures, funciones, triggers |
| Imágenes | **Cloudinary** | CDN externo; el pod no almacena archivos de usuarios |
| Proxy/TLS | **RunPod Proxy** | HTTPS terminado en `*.proxy.runpod.net`, puerto HTTP 8501 expuesto |
| Persistencia | **Network Volume 20 GB** en `/workspace` | Sobrevive reinicios y recreación del pod |

### ¿Por qué Streamlit?
Permite construir la interfaz web completa (catálogo, sala de puja en vivo, paneles de admin) directamente en Python, compartiendo el mismo lenguaje y la misma conexión a la BD, sin necesidad de un framework frontend separado (React, etc.). Ideal para un proyecto de BD donde el peso está en el modelo de datos y los SPs.

### ¿Por qué SQL Server en un contenedor Linux?
El curso trabaja con SQL Server (T-SQL, SPs, triggers, funciones con `AT TIME ZONE`). Microsoft publica imágenes/paquetes oficiales para Ubuntu, así que la misma BD del proyecto corre en el pod. La lógica de negocio pesada (motor de pujas, anti-sniping, cierre y adjudicación de subastas) vive en **stored procedures**, no en Python — la app solo los invoca.

---

## 3. Persistencia: Network Volume vs Container Disk

El pod tiene dos almacenamientos con comportamientos distintos:

| | Container Disk (15–20 GB) | Network Volume (20 GB, `/workspace`) |
|---|---|---|
| Contenido | Sistema operativo, SQL Server, Python | Datos del proyecto: código, backups, scripts |
| Al hacer **Stop/Start** | Se conserva | Se conserva |
| Al hacer **Terminate** | Se pierde | **Sobrevive** (se adjunta al siguiente pod) |

**Consecuencia operativa:** el software (SQL Server, paquetes) se reinstala automáticamente con `restart_completo.sh` cada vez que se recrea el pod; los datos valiosos (backup de la BD `backup_maestro.bak`, código, scripts SQL) viven en `/workspace` y nunca se pierden.

Archivos críticos en `/workspace`:
- `backup_maestro.bak` — backup completo de la BD (~7 MB)
- `restart_completo.sh` — reinstala todo el software y arranca servicios (idempotente)
- `run_streamlit.sh` — arranca la app con las flags anti-proxy
- `app/`, `sql/` — código fuente y scripts de base de datos

---

## 4. Seguridad implementada

1. **Contraseñas con bcrypt.** Los hashes se guardan en `Usuarios.password_hash`. Existe migración silenciosa: si un usuario antiguo tenía contraseña en texto plano, se convierte a bcrypt en su primer login exitoso.
2. **Sesiones con token aleatorio de 256 bits.** Al hacer login se genera un token (`secrets.token_urlsafe(32)`) que se guarda en `Usuarios.token_sesion` y viaja en la URL (`?st=...`) para sobrevivir recargas del navegador. **No** se expone el `id_usuario` numérico (eso permitía un ataque IDOR: cambiar `?uid=2` en la URL para entrar como otro usuario). El token se invalida en la BD al cerrar sesión.
3. **Roles.** Tabla `Usuario_Roles`: el rol admin habilita el panel 🛠️ (cierre manual de subastas, gestión). Los usuarios que se registran solos quedan como postores.
4. **La BD no está expuesta a internet.** SQL Server solo escucha en `localhost` del pod; el único puerto público es el 8501 (HTTP de Streamlit) a través del proxy de RunPod.
5. **Secretos fuera del código.** La contraseña del SA se pasa por variable de entorno (`SA_PASSWORD`), no está en el repo.
6. **SQL injection:** todas las consultas usan parámetros (`?` de pyodbc), no concatenación de strings.

---

## 5. Reglas de negocio clave (para las preguntas del ingeniero)

- **Monto de apertura:** toda subasta arranca en el **80% del precio base/reserva** del artículo (`Subastas.monto_apertura`), nunca en cero. La primera puja mínima es `monto_apertura + incremento`.
- **Adjudicación:** al cerrar, solo hay ganador si la puja máxima **≥ monto de apertura** (regla del 20% bajo la reserva). Si nadie alcanza, la subasta cierra **sin ganador ni orden de pago**.
- **Cierre:** automático por `sp_CerrarSubastasVencidas` (o manual desde el panel Admin). Al adjudicar se genera la `Ordenes_Pago` con columnas calculadas (`total_a_pagar`, `neto_vendedor` — comisión de la plataforma).
- **Anti-sniping / motor de pujas:** implementado en stored procedures T-SQL (`sp_motor_pujas.sql`), no en Python. La app es una "cáscara" que llama SPs.

### Zona horaria (detalle importante)
El negocio opera en **hora Guatemala (UTC-6)**, pero el pod corre en UTC. Solución en dos niveles:
- **SQL Server:** toda la lógica usa la función `dbo.fn_AhoraGT()` (`AT TIME ZONE 'Central America Standard Time'`). Nunca `GETDATE()` pelado.
- **Python:** `ZoneInfo("America/Guatemala")`; la BD guarda `DATETIME2` naive en hora GT, así que las comparaciones se hacen con `ahora_gt().replace(tzinfo=None)`.
- Además los scripts de despliegue fijan `TZ=America/Guatemala` en el sistema operativo del pod.

---

## 6. Operación: cómo se levanta el servicio

### Escenario A — el pod está apagado (Stop) o recién creado

```bash
# 1. Reinstalar software y arrancar servicios (10-15 min si es pod nuevo)
export SA_PASSWORD='<clave-sa>'
bash /workspace/restart_completo.sh

# 2. Restaurar la BD con todos los datos desde el Network Volume
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -I -Q \
  "RESTORE DATABASE subastas_privadas FROM DISK='/workspace/backup_maestro.bak' WITH REPLACE"

# 3. Arrancar la app (si el script no lo hizo ya)
bash /workspace/run_streamlit.sh
```

`restart_completo.sh` es idempotente y hace, en orden: instala SQL Server 2022 + sqlcmd + ODBC 18 → fija la zona horaria → arranca SQL Server en **tmux** (sesión `sql`) → crea la BD si no existe → carga DDL/catálogos/datos si está vacía → crea el usuario admin si no existe → arranca Streamlit en tmux (sesión `app`). Al final **verifica que los 3 SPs tengan `QUOTED_IDENTIFIER ON`** (trampa conocida: sin eso, las columnas calculadas de `Ordenes_Pago` fallan con error 1934).

### Escenario B — solo se detuvo la app

```bash
bash /workspace/iniciar_todo.sh    # o: tmux kill-session -t app; bash /workspace/run_streamlit.sh
```

### Operación diaria

| Tarea | Comando |
|---|---|
| Ver logs de la app | `tmux attach -t app` (salir: Ctrl+B, luego D) |
| Ver SQL Server | `tmux attach -t sql` |
| Reiniciar solo la app | `tmux kill-session -t app; bash /workspace/run_streamlit.sh` |
| Backup antes de apagar | `sqlcmd ... -Q "BACKUP DATABASE subastas_privadas TO DISK='/workspace/backup_maestro.bak' WITH FORMAT"` |

### ¿Por qué tmux y no systemd?
Los contenedores de RunPod **no tienen systemd**. Los procesos de larga duración (SQL Server, Streamlit) corren en sesiones tmux desacopladas del terminal, así sobreviven al cierre del Web Terminal / SSH.

---

## 7. Red y acceso público

- El pod expone **únicamente el puerto 8501 (HTTP)**, configurado en "Expose HTTP Ports" al crear el pod.
- RunPod provee un **proxy reverso con TLS**: `https://<POD-ID>-8501.proxy.runpod.net`. No necesitamos configurar certificados ni Nginx.
- **Flags anti-proxy en Streamlit** (ya en `run_streamlit.sh`): `--server.enableCORS false --server.enableXsrfProtection false --server.enableWebsocketCompression false`. Sin ellas, el proxy de RunPod deja la app cargando en un spinner infinito.
- El **puerto 1433 (SQL Server) nunca se expone**: solo localhost dentro del contenedor.

---

## 8. Entorno de desarrollo local (Windows)

Réplica del pod para desarrollar sin gastar saldo:

- **SQL Server Express** en `localhost\SQLEXPRESS`, BD `subastas_privadas`, autenticación de Windows.
- **Python 3.12** (NO 3.14: pyodbc no compila ahí) con streamlit 1.66, pyodbc 5.3, bcrypt 5.0.
- Arranque: `iniciar_subastas.bat` (doble clic) — verifica el servicio SQL, restaura el backup si la BD no existe, verifica dependencias y abre `http://localhost:8501`.
- La misma `app.py` corre en ambos lados: la conexión se configura por variables de entorno (`DB_SERVER`, `DB_USER`, `DB_PASS`); en local cae por defecto a `localhost\SQLEXPRESS` + Windows Auth.
- **Sincronización:** GitHub (`Anibal-tuyuc/subastasRunpod`) es el punto medio entre la PC y el pod.

---

## 9. Costos

| Recurso | Costo aproximado |
|---|---|
| Pod RunPod (CPU, no requiere GPU) | ~$0.03–0.05 / hora |
| Network Volume 20 GB | centavos / mes |
| Cloudinary | $0 (plan gratis) |
| **Práctica:** apagar el pod (Stop) cuando no se usa; con Terminate los datos sobreviven en el volumen. | |

---

## 10. Limitaciones conocidas y decisiones tomadas

1. **Sin systemd** → procesos en tmux; los scripts de arranque son idempotentes para recuperarse de reinicios.
2. **SQL Server corre como usuario `mssql`**, no root → los backups se generan en `/var/opt/mssql/backups` y se copian a `/workspace`.
3. **Sesión por token en URL:** decisión pragmática para que F5 no cierre la sesión en Streamlit. El token es aleatorio (no enumerable) y muere al cerrar sesión; riesgo residual: compartir la URL comparte la sesión (igual que cualquier token portador).
4. **Backups manuales:** el respaldo a `backup_maestro.bak` es por comando (se hace antes de apagar); no hay tarea programada dentro del contenedor.
5. **QUOTED_IDENTIFIER:** los SPs del motor deben crearse siempre con `SET QUOTED_IDENTIFIER ON` (sqlcmd con flag `-I`) por las columnas calculadas de `Ordenes_Pago`; los scripts ya lo garantizan y lo verifican al final.

---

## 11. Resumen en 30 segundos (para la defensa oral)

> "La plataforma corre en un contenedor de RunPod con Ubuntu 22.04. Dentro del mismo contenedor conviven la app web —Streamlit en Python— y SQL Server 2022, comunicados por localhost, así la base de datos nunca se expone a internet. El acceso público es por HTTPS a través del proxy de RunPod en el puerto 8501. La lógica de negocio pesada —motor de pujas, anti-sniping, cierre y adjudicación— está en stored procedures T-SQL; Python solo presenta e invoca. Los datos sobreviven en un Network Volume de 20 GB aunque el pod se destruya, y hay scripts idempotentes que reinstalan todo el software y restauran el backup en minutos. La seguridad incluye contraseñas con bcrypt, sesiones con tokens aleatorios de 256 bits en lugar de IDs enumerables, roles de administrador, y toda la lógica de fechas normalizada a hora de Guatemala tanto en SQL como en Python. Las imágenes se externalizan a Cloudinary."
