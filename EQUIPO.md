# 👥 División de trabajo — Equipo de 3

El proyecto se desarrolló entre 3 integrantes, cada uno dueño de un módulo con
responsabilidades claras. Esta es la guía de "quién toca qué": si vas a modificar
una zona, habla primero con su dueño.

---

## 🗄️ Integrante A — Base de datos y motor de negocio

**Carpeta:** `sql/`

| Archivo | Qué contiene |
|---|---|
| `sql/script_utf8.sql` | DDL base: 34+ tablas (Usuarios, Articulos, Subastas, Pujas, Ordenes_Pago, catalogos) |
| `sql/sp_motor_pujas.sql` | **Motor transaccional**: `sp_RegistrarPuja` (validaciones, anti-sniping, concurrencia), `sp_CerrarSubasta` (liquidación, comisiones), `sp_CerrarSubastasVencidas`, `fn_AhoraGT` (hora Guatemala) |
| `sql/mejoras_subastas.sql` | Tablas extra: Ubicaciones_Almacenaje, Historial_Pedigree, Catalogo_Busquedas_Caché |
| `sql/seed_*.sql`, `datos_prueba_subastas.sql` | Catálogos y datos de prueba |

**Decisiones técnicas de este módulo:**
- Concurrencia con `UPDLOCK, HOLDLOCK` + `version` (optimista) en Subastas
- Regla de apertura: `monto_apertura` = 80% de `precio_base_reserva`
- Hora Guatemala centralizada en `fn_AhoraGT()` (AT TIME ZONE)
- Auditoría de todo intento en `Auditoria_Pujas`
- Columnas calculadas en `Ordenes_Pago` → los SPs exigen QUOTED_IDENTIFIER ON

**Pruebas:** cargar scripts en SQL Express local y ejecutar el motor con sqlcmd.

---

## 🎨 Integrante B — Frontend y experiencia de usuario

**Archivo:** `app/app.py` — secciones de **vistas de usuario** y **estilos**

| Sección (marcador en el código) | Líneas aprox. | Qué contiene |
|---|---|---|
| `ESTILOS` | 129–232 | Tema oscuro tipo casa de subastas (CSS en `st.markdown`) |
| `icono_categoria / tiempo_restante / badge_estado / countdown_html` | 344–420 | Componentes visuales: countdown en vivo (JS), badges de estado |
| Vista `🏷️ Catálogo` | 503–578 | Tarjetas de lotes, filtros por categoría/estado |
| Vista `🔨 Sala de puja` | 582–710 | Detalle del lote, galería de imágenes, historial, panel de puja |
| Vista `📋 Mis Pujas` | 714–733 | Historial del usuario logueado |
| Vista `📦 Mis Artículos` (UI) | 738–1062 | Lista de artículos propios, formulario de registro con subida de imágenes |

**Decisiones técnicas de este módulo:**
- Countdown en vivo con `streamlit.components.v1.html` (único que ejecuta JS)
- Panel de puja muestra "Apertura" (no Q0.00) cuando nadie ha pujado
- Imágenes desde Cloudinary (CDN), portada primero
- Layout `wide`, 3 columnas en catálogo

**Pruebas:** `streamlit run app/app.py` y navegar las 4 vistas.

---

## ⚙️ Integrante C — Backend, autenticación e infraestructura

**Archivos:** conexión/auth de `app/app.py` + todos los scripts de despliegue

| Archivo / sección | Qué contiene |
|---|---|
| `app.py`: `get_connection / query / ejecutar_sp` | Capa de acceso a datos (pyodbc, ODBC 18, vars de entorno) |
| `app.py`: `subir_imagen_drive` (Cloudinary) | Subida unsigned de imágenes al CDN |
| `app.py`: `_verificar_password / _hashear / login / registrar_usuario / es_admin` | **Autenticación bcrypt** con migración automática de hashes viejos en texto plano |
| `app.py`: vista `🛠️ Admin` | Panel admin: KPIs, crear subasta (con apertura 80%), cerrar subastas, ubicaciones, auditoría, gestión de usuarios/roles |
| `restart_completo.sh` | RunPod: reinstala SQL Server + app, **verifica** SPs (QUOTED_IDENTIFIER) y hora GT |
| `iniciar_todo.sh`, `setup_runpod.sh` | RunPod: arranque rápido / setup inicial del pod |
| `cargar_bd.sh` | RunPod: carga los `.sql` en orden con `sqlcmd -I` |
| `DESPLIEGUE_RUNPOD.md` | Guía de despliegue |

**Decisiones técnicas de este módulo:**
- Credenciales por variables de entorno, nunca en el código
- Scripts idempotentes (se pueden correr N veces)
- sqlcmd con `-I` (QUOTED_IDENTIFIER) y `-C` (TrustServerCertificate)
- Zona horaria del pod forzada a `America/Guatemala`
- Flags anti-proxy de Streamlit para el proxy de RunPod

**Pruebas:** levantar el stack completo en un pod y en local.

---

## 🔀 Flujo de trabajo con git

Para cambios nuevos (a partir de ahora):

```bash
# cada integrante trabaja en su rama
git checkout -b feature/A-nombre-del-cambio     # o B-... / C-...
# ...hacer cambios en SU módulo...
git add . && git commit -m "A: descripcion del cambio"
git push -u origin feature/A-nombre-del-cambio
# abrir Pull Request en GitHub -> otro integrante revisa -> merge a main
```

**Regla de oro:** cada quien hace PR solo de su módulo. Si un cambio toca dos
módulos (ej. una columna nueva en SQL + su vista), se coordinan A y B en el
mismo PR y ambos lo revisan.

El prefijo en el mensaje de commit (`A:` / `B:` / `C:`) deja claro en el
historial qué integrante hizo cada cambio.
