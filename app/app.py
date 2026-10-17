# -*- coding: utf-8 -*-
"""
Plataforma de Subastas Privadas - Proyecto 3 DBI (UMG)
Frontend estilo Copart: catalogo en tarjetas, lotes con panel de puja.
Local:   streamlit run app.py
RunPod:  streamlit run app.py --server.address 0.0.0.0 --server.port 8501 --server.headless true
"""
import os
import io
import pyodbc
import streamlit as st
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
import streamlit.components.v1 as components

st.set_page_config(page_title="Subastas Privadas UMG", page_icon="🔨", layout="wide")

# Hora oficial del negocio: Guatemala (UTC-6 fijo, sin horario de verano).
# La BD guarda DATETIME2 naive en hora GT via fn_AhoraGT(); aqui todas las
# comparaciones y capturas de fecha/hora se hacen en la misma zona para que
# el comportamiento sea identico local y en RunPod (que corre en UTC).
TZ_GT = ZoneInfo("America/Guatemala")


def ahora_gt():
    """datetime aware en hora Guatemala."""
    return datetime.now(TZ_GT)


def gt_naive(dt_aware):
    """Convierte un datetime aware a naive hora GT (formato de la BD)."""
    if dt_aware is None:
        return None
    if dt_aware.tzinfo is None:
        return dt_aware
    return dt_aware.astimezone(TZ_GT).replace(tzinfo=None)

DB_SERVER = os.environ.get("DB_SERVER", r"localhost\SQLEXPRESS")
DB_NAME = os.environ.get("DB_NAME", "subastas_privadas")
DB_USER = os.environ.get("DB_USER", "")       # vacio = Windows Auth (local)
DB_PASS = os.environ.get("DB_PASS", "")
DB_TRUSTED = os.environ.get("DB_TRUSTED", "yes" if not DB_USER else "no")

PAGINAS = ["🏷️ Catálogo", "🔨 Sala de puja", "📋 Mis Pujas", "📦 Mis Artículos"]


@st.cache_resource
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
    return pyodbc.connect(conn_str)


def query(sql, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql, params)
    cols = [c[0] for c in cursor.description] if cursor.description else []
    return [dict(zip(cols, row)) for row in cursor.fetchall()]


def ejecutar_sp(nombre_sp, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(f"EXEC {nombre_sp} " + ", ".join("?" * len(params)), params)
    conn.commit()


# ============================================================
# [INTEGRANTE C - Backend/Infra] Capa de acceso a datos e imagenes.
# ============================================================
# CLOUDINARY - subida de imagenes con "unsigned upload preset".
# Las imagenes caen en el CDN de Cloudinary (rapidas y estables,
# sin problemas de hotlinking) y la BD guarda la URL publica.
# Sin llaves secretas: el preset unsigned esta pensado para esto.
# ============================================================
CLOUDINARY_CLOUD = os.environ.get("CLOUDINARY_CLOUD", "xbylnxck")
CLOUDINARY_PRESET = os.environ.get("CLOUDINARY_PRESET", "subastas_preset")


def drive_disponible():
    """Nombre historico: indica si el hosting de imagenes esta configurado."""
    return bool(CLOUDINARY_CLOUD and CLOUDINARY_PRESET)


def subir_imagen_drive(bytes_img, nombre, mime):
    """Sube la imagen a Cloudinary (preset unsigned) y devuelve la URL
    segura del CDN. El parametro 'nombre' se usa como public_id legible."""
    import re
    import urllib.request
    import urllib.parse
    import json as _json
    import uuid
    import mimetypes

    boundary = uuid.uuid4().hex
    url = f"https://api.cloudinary.com/v1_1/{CLOUDINARY_CLOUD}/image/upload"
    public_id = re.sub(r"[^A-Za-z0-9_-]+", "_", os.path.splitext(nombre)[0])[:80]

    campos = {"upload_preset": CLOUDINARY_PRESET, "public_id": public_id}
    partes = []
    for k, v in campos.items():
        partes.append(
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n"
            .encode("utf-8"))
    mime_real = mime or mimetypes.guess_type(nombre)[0] or "image/jpeg"
    partes.append(
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; "
        f"filename=\"{nombre}\"\r\nContent-Type: {mime_real}\r\n\r\n".encode("utf-8"))
    partes.append(bytes_img)
    partes.append(f"\r\n--{boundary}--\r\n".encode("utf-8"))
    cuerpo = b"".join(partes)

    req = urllib.request.Request(
        url, data=cuerpo,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        datos = _json.loads(resp.read().decode("utf-8"))
    return datos["secure_url"]


# ============================================================
# [INTEGRANTE B - Frontend] Tema visual de toda la app.
# ============================================================
# ESTILOS - tema oscuro tipo casa de subastas (Copart-like)
# ============================================================
st.markdown("""
<style>
    :root {
        --brand: #d6202f;          /* rojo marca */
        --bg-dark: #14181d;
        --bg-card: #1e242b;
        --bg-soft: #262d36;
        --line: #333c46;
        --txt: #e8ecf1;
        --txt-dim: #9aa5b1;
        --green: #2fa84f;
        --amber: #f0a500;
    }
    .stApp { background: var(--bg-dark); color: var(--txt); }
    [data-testid="stSidebar"] { background: #0e1216; }
    h1, h2, h3, h4 { color: var(--txt) !important; }
    p, label, .stMarkdown { color: var(--txt-dim); }

    /* Header de marca */
    .brand-bar {
        display: flex; align-items: center; gap: 14px;
        background: linear-gradient(90deg, #0b0e11 0%, #1a2027 100%);
        border-bottom: 3px solid var(--brand);
        padding: 14px 22px; margin: -1rem -1rem 1.2rem -1rem;
    }
    .brand-logo {
        font-size: 1.5rem; font-weight: 800; color: #fff; letter-spacing: .5px;
    }
    .brand-logo span { color: var(--brand); }
    .brand-tag { color: var(--txt-dim); font-size: .85rem; }

    /* Tarjetas del catalogo */
    .lot-card {
        background: var(--bg-card); border: 1px solid var(--line);
        border-radius: 10px; overflow: hidden; height: 100%;
        transition: border-color .15s;
    }
    .lot-card:hover { border-color: var(--brand); }
    .lot-img {
        height: 120px; display: flex; align-items: center; justify-content: center;
        background: var(--bg-soft); font-size: 3rem;
        border-bottom: 1px solid var(--line);
    }
    .lot-body { padding: 12px 14px 14px 14px; }
    .lot-title {
        color: var(--txt); font-weight: 700; font-size: .98rem;
        min-height: 2.6em; line-height: 1.3em;
    }
    .lot-cat { color: var(--txt-dim); font-size: .78rem; margin-bottom: 8px; }
    .lot-badges { display: flex; gap: 6px; margin-bottom: 10px; flex-wrap: wrap; }
    .badge {
        font-size: .68rem; font-weight: 700; padding: 2px 8px;
        border-radius: 20px; text-transform: uppercase; letter-spacing: .4px;
    }
    .badge-live  { background: rgba(47,168,79,.15); color: var(--green); border: 1px solid var(--green); }
    .badge-end   { background: rgba(214,32,47,.15); color: var(--brand); border: 1px solid var(--brand); }
    .badge-soon  { background: rgba(240,165,0,.12); color: var(--amber); border: 1px solid var(--amber); }
    .badge-plain { background: var(--bg-soft); color: var(--txt-dim); border: 1px solid var(--line); }
    .lot-price-row { display: flex; justify-content: space-between; align-items: baseline; }
    .lot-label { color: var(--txt-dim); font-size: .72rem; text-transform: uppercase; }
    .lot-price { color: #fff; font-weight: 800; font-size: 1.25rem; }
    .lot-meta { color: var(--txt-dim); font-size: .78rem; margin-top: 6px; }
    .countdown { color: var(--amber); font-weight: 600; font-size: .8rem; }

    /* Panel de puja (detalle de lote) */
    .bid-panel {
        background: var(--bg-card); border: 1px solid var(--line);
        border-radius: 12px; padding: 20px;
    }
    .bid-current-label { color: var(--txt-dim); font-size: .75rem; text-transform: uppercase; }
    .bid-current { color: #fff; font-size: 2.2rem; font-weight: 800; }
    .bid-min { color: var(--amber); font-weight: 600; margin: 4px 0 14px 0; }
    .bid-timer {
        background: var(--bg-soft); border-radius: 8px; padding: 10px 14px;
        color: var(--amber); font-weight: 700; text-align: center; margin-bottom: 14px;
        font-size: 1.05rem;
    }

    /* Botones */
    .stButton > button[kind="primary"], .stButton > button {
        background: var(--brand); color: #fff; border: none; border-radius: 6px;
        font-weight: 700;
    }
    .stButton > button:hover { background: #b31a27; color: #fff; }

    /* Tabs y inputs */
    .stTabs [data-baseweb="tab"] { color: var(--txt-dim); }
    .stTabs [aria-selected="true"] { color: #fff !important; }
    div[data-testid="stMetricValue"] { color: #fff; }

    /* Iframe del countdown sin borde visible */
    iframe[title="streamlit_components.v1.html"] { border: none; }
</style>
""", unsafe_allow_html=True)


# ---------------- [INTEGRANTE C] AUTENTICACION (bcrypt) ----------------
# Los hashes bcrypt ($2b$...) miden 60 chars: caben exacto en el char(60) del DDL.
# Migracion silenciosa: los usuarios creados en texto plano (seed de pruebas)
# entran con su contraseña actual y al primer login su hash se convierte a bcrypt.
_BCRYPT_PREFIX = ("$2a$", "$2b$", "$2y$")


def _es_hash_bcrypt(valor):
    return isinstance(valor, str) and valor.startswith(_BCRYPT_PREFIX)


def _verificar_password(password_plano, hash_guardado):
    """Devuelve (es_valido, necesita_migrar)."""
    hash_limpio = (hash_guardado or "").rstrip()
    if _es_hash_bcrypt(hash_limpio):
        import bcrypt
        try:
            ok = bcrypt.checkpw(password_plano.encode("utf-8"),
                                hash_limpio.encode("utf-8"))
            return ok, False
        except ValueError:
            return False, False
    # Texto plano (datos seed previos a bcrypt)
    return password_plano == hash_limpio, True


def _hashear(password_plano):
    import bcrypt
    return bcrypt.hashpw(password_plano.encode("utf-8"),
                         bcrypt.gensalt()).decode("utf-8")


def login(email, password):
    filas = query(
        "SELECT id_usuario, nombre, apellido, password_hash FROM Usuarios "
        "WHERE email = ? AND activo = 1",
        (email,),
    )
    if not filas:
        return None
    usr = filas[0]
    es_valido, migrar = _verificar_password(password, usr["password_hash"])
    if not es_valido:
        return None
    if migrar:
        # Convierte el hash de texto plano a bcrypt (migracion silenciosa)
        try:
            conn = get_connection()
            conn.cursor().execute(
                "UPDATE Usuarios SET password_hash = ? WHERE id_usuario = ?",
                (_hashear(password), usr["id_usuario"]))
            conn.commit()
        except pyodbc.Error:
            pass  # si falla la migracion, el login igual es valido
    usr.pop("password_hash", None)
    usr["es_admin"] = es_admin(usr["id_usuario"])
    return usr


def es_admin(id_usuario):
    filas = query(
        "SELECT 1 AS x FROM Usuario_Roles ur JOIN Roles r ON ur.id_rol = r.id_rol "
        "WHERE ur.id_usuario = ? AND r.nombre = 'Admin'",
        (id_usuario,),
    )
    return bool(filas)


def login_por_id(id_usuario):
    filas = query(
        "SELECT id_usuario, nombre, apellido FROM Usuarios "
        "WHERE id_usuario = ? AND activo = 1",
        (id_usuario,),
    )
    if not filas:
        return None
    usr = filas[0]
    usr["es_admin"] = es_admin(usr["id_usuario"])
    return usr


def registrar_usuario(nombre, apellido, email, password):
    if len(password) < 6:
        return False, "La contraseña debe tener al menos 6 caracteres."
    conn = get_connection()
    cursor = conn.cursor()
    id_verif = query(
        "SELECT TOP 1 id_estado_verificacion FROM Estados_Verificacion ORDER BY id_estado_verificacion"
    )
    if not id_verif:
        return False, "No hay estados de verificacion cargados en la BD."
    try:
        cursor.execute(
            "INSERT INTO Usuarios (nombre, apellido, email, password_hash, "
            "id_estado_verificacion, fecha_registro, activo) "
            "VALUES (?, ?, ?, ?, ?, dbo.fn_AhoraGT(), 1)",
            (nombre, apellido, email, _hashear(password),
             id_verif[0]["id_estado_verificacion"]),
        )
        # Todo usuario nuevo entra como postor
        cursor.execute(
            "INSERT INTO Usuario_Roles (id_usuario, id_rol, fecha_asignacion) "
            "SELECT id_usuario, 2, dbo.fn_AhoraGT() FROM Usuarios WHERE email = ? "
            "AND NOT EXISTS (SELECT 1 FROM Usuario_Roles ur "
            "                WHERE ur.id_usuario = Usuarios.id_usuario AND ur.id_rol = 2)",
            (email,))
        conn.commit()
        return True, "Registro exitoso. Ya puedes iniciar sesion."
    except pyodbc.IntegrityError:
        return False, "Ese email ya esta registrado."


# ---------------- HELPERS UI ----------------
ICONOS_CATEGORIA = {
    "instrumentos": "🎸", "joyer": "💎", "reloj": "⌚", "ropa": "🧥",
    "arte": "🖼️", "vehic": "🚗", "vino": "🍷", "coleccion": "🏺",
}

def icono_categoria(nombre_cat):
    n = (nombre_cat or "").lower()
    for clave, icono in ICONOS_CATEGORIA.items():
        if clave in n:
            return icono
    return "🏷️"


def tiempo_restante(fecha_fin):
    """Texto humano del tiempo restante; None si ya cerro.
    fecha_fin viene de la BD como naive hora Guatemala."""
    if not fecha_fin:
        return None
    fin = gt_naive(fecha_fin)
    ahora = ahora_gt().replace(tzinfo=None)
    delta = fin - ahora
    if delta.total_seconds() <= 0:
        return None
    d = delta.days
    h, rem = divmod(delta.seconds, 3600)
    m, s = divmod(rem, 60)
    if d > 0:
        return f"{d}d {h}h {m}m"
    if h > 0:
        return f"{h}h {m}m {s}s"
    return f"{m}m {s}s"


def badge_estado(estado, fecha_fin):
    if estado == "Activa":
        restante = tiempo_restante(fecha_fin)
        if restante is None:
            return '<span class="badge badge-end">Cerrando</span>'
        return '<span class="badge badge-live">● En vivo</span>'
    if estado in ("Finalizada", "Cancelada"):
        return '<span class="badge badge-end">Finalizada</span>'
    return f'<span class="badge badge-soon">{estado}</span>'


def countdown_html(fecha_fin, alto=30):
    """Countdown en vivo (JS, corre en el navegador dentro de un iframe).
    Requiere components.v1.html: es el unico componente que ejecuta JS;
    st.html/st.markdown solo inyectan contenido estatico."""
    if not fecha_fin:
        return
    # La BD guarda hora GT naive: el ISO sale con offset -06:00 explicito
    # para que el countdown del navegador calcule bien sin importar la zona
    # del visitante (compañeros en GT = mismo resultado).
    fin = gt_naive(fecha_fin)
    iso = fin.replace(tzinfo=TZ_GT).isoformat()
    components.html(f"""
<div style="margin:0;padding:0;background:transparent;">
  <span id="cd" style="color:#f0a500;font-weight:700;font-size:1rem;
       font-family:'Source Sans Pro',sans-serif;">⏱ ...</span>
</div>
<script>
(function() {{
    var fin = new Date("{iso}").getTime();
    var el = document.getElementById("cd");
    function tick() {{
        var ms = fin - Date.now();
        if (ms <= 0) {{ el.innerHTML = "⏱ Cerrada"; el.style.color = "#d6202f"; return; }}
        var s = Math.floor(ms / 1000);
        var d = Math.floor(s / 86400); s %= 86400;
        var h = Math.floor(s / 3600);  s %= 3600;
        var m = Math.floor(s / 60);
        var seg = s % 60;
        el.innerHTML = "⏱ " + (d > 0 ? d + "d " : "")
            + String(h).padStart(2, "0") + ":"
            + String(m).padStart(2, "0") + ":"
            + String(seg).padStart(2, "0");
        setTimeout(tick, 1000);
    }}
    tick();
}})();
</script>
""", height=alto)


# ============================================================
# HEADER DE MARCA
# ============================================================
st.markdown("""
<div class="brand-bar">
    <div>
        <div class="brand-logo">SUBASTAS<span>UMG</span></div>
        <div class="brand-tag">Plataforma de subastas privadas y bienes exclusivos</div>
    </div>
</div>
""", unsafe_allow_html=True)

# ============================================================
# SESION - persistida en query params (?uid=N) para sobrevivir
# recargas manuales del navegador y reruns.
# ============================================================
if "usuario" not in st.session_state:
    st.session_state.usuario = None

if st.session_state.usuario is None and "uid" in st.query_params:
    try:
        st.session_state.usuario = login_por_id(int(st.query_params["uid"]))
    except (ValueError, pyodbc.Error):
        st.session_state.usuario = None

if st.session_state.usuario is None:
    col_a, col_b, col_c = st.columns([1, 2, 1])
    with col_b:
        tab_login, tab_registro = st.tabs(["Iniciar Sesión", "Registrarse"])
        with tab_login:
            email = st.text_input("Email", key="login_email")
            pwd = st.text_input("Contraseña", type="password", key="login_pwd")
            if st.button("Entrar", width='stretch'):
                u_log = login(email, pwd)
                if u_log:
                    st.session_state.usuario = u_log
                    st.query_params["uid"] = str(u_log["id_usuario"])
                    st.rerun()
                else:
                    st.error("Credenciales inválidas o usuario inactivo.")
        with tab_registro:
            n = st.text_input("Nombre")
            a = st.text_input("Apellido")
            e = st.text_input("Email", key="reg_email")
            p = st.text_input("Contraseña (mín. 6 caracteres)", type="password", key="reg_pwd")
            p2 = st.text_input("Confirmar contraseña", type="password", key="reg_pwd2")
            if st.button("Crear cuenta", width='stretch'):
                if not (n and a and e and p):
                    st.warning("Completa todos los campos.")
                elif p != p2:
                    st.error("Las contraseñas no coinciden.")
                else:
                    ok, msg = registrar_usuario(n, a, e, p)
                    (st.success if ok else st.error)(msg)
    st.stop()

u = st.session_state.usuario
st.sidebar.markdown(f"### 👤 {u['nombre']} {u['apellido']}")
if st.sidebar.button("Cerrar sesión"):
    st.session_state.usuario = None
    st.query_params.clear()
    st.rerun()

# Navegacion: el radio del sidebar es la fuente, pero los botones
# internos (p.ej. "Entrar a pujar") pueden pedir un cambio de pagina
# marcando _pending_page; se aplica ANTES de dibujar el radio.
if "_pending_page" in st.session_state:
    st.session_state.nav = st.session_state.pop("_pending_page")
if "nav" not in st.session_state:
    st.session_state.nav = PAGINAS[0]

paginas_visibles = list(PAGINAS)
if u.get("es_admin"):
    paginas_visibles.append("🛠️ Admin")

pagina = st.sidebar.radio("Menú", paginas_visibles, key="nav")

# ============================================================
# [INTEGRANTE B - Frontend] VISTA: Catalogo - tarjetas de lotes
# (estilo Copart)
# ============================================================
if pagina == "🏷️ Catálogo":
    st.markdown("## Lotes en subasta")

    fc1, fc2, fc3 = st.columns([2, 2, 1])
    solo_activas = fc1.checkbox("Solo en vivo", value=True)
    categorias = query("SELECT DISTINCT nombre FROM Categorias ORDER BY nombre")
    filtro_cat = fc2.selectbox("Categoría", ["Todas"] + [c["nombre"] for c in categorias])
    if fc3.button("🔄 Actualizar", width='stretch'):
        st.rerun()

    sql = """
        SELECT s.id_subasta, a.titulo, c.nombre AS categoria, a.codigo_moneda,
               s.puja_actual_maxima, s.total_pujas, s.monto_apertura,
               s.fecha_hora_inicio, s.fecha_hora_fin, e.nombre AS estado,
               (SELECT TOP 1 i.url FROM Imagenes_Articulo i
                 WHERE i.id_articulo = a.id_articulo
                 ORDER BY i.es_portada DESC, i.orden ASC) AS portada
        FROM Subastas s
        JOIN Articulos a ON s.id_articulo = a.id_articulo
        JOIN Categorias c ON a.id_categoria = c.id_categoria
        JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
        WHERE 1=1
    """
    params = []
    if solo_activas:
        sql += " AND e.nombre = 'Activa'"
    if filtro_cat != "Todas":
        sql += " AND c.nombre = ?"
        params.append(filtro_cat)
    sql += " ORDER BY s.fecha_hora_fin ASC"

    try:
        items = query(sql, tuple(params))
    except pyodbc.Error as ex:
        st.error(f"Error consultando BD: {ex}")
        st.stop()

    st.caption(f"{len(items)} lote(s) encontrado(s)")
    if not items:
        st.info("No hay subastas para mostrar con esos filtros.")
    else:
        for fila_ini in range(0, len(items), 3):
            cols = st.columns(3)
            for col, it in zip(cols, items[fila_ini:fila_ini + 3]):
                with col:
                    img_html = (f'<img src="{it["portada"]}" '
                                f'style="width:100%;height:160px;object-fit:cover;" '
                                f'onerror="this.style.display=\'none\'">'
                                if it.get("portada") else "")
                    st.markdown(f"""
<div class="lot-card">
    <div class="lot-img">{img_html if img_html else icono_categoria(it['categoria'])}</div>
    <div class="lot-body">
        <div class="lot-title">{it['titulo']}</div>
        <div class="lot-cat">{it['categoria']} · Lote #{it['id_subasta']}</div>
        <div class="lot-badges">{badge_estado(it['estado'], it['fecha_hora_fin'])}
            <span class="badge badge-plain">{it['total_pujas']} pujas</span></div>
        <div class="lot-price-row">
            <div>
                <div class="lot-label">{'Puja actual' if it['puja_actual_maxima'] > 0 else 'Apertura'}</div>
                <div class="lot-price">{it['codigo_moneda']} {(it['puja_actual_maxima'] if it['puja_actual_maxima'] > 0 else it['monto_apertura']):,.2f}</div>
            </div>
        </div>
    </div>
</div>
""", unsafe_allow_html=True)
                    # Countdown en vivo (JS) justo bajo el precio
                    if it["estado"] == "Activa" and it["fecha_hora_fin"]:
                        countdown_html(it["fecha_hora_fin"])
                    if it["estado"] == "Activa":
                        if st.button("🔨 Entrar a pujar", key=f"bid_{it['id_subasta']}",
                                     width='stretch'):
                            st.session_state.lote_sel = it["id_subasta"]
                            st.session_state._pending_page = "🔨 Sala de puja"
                            st.rerun()

# ============================================================
# [INTEGRANTE B - Frontend] VISTA: Sala de puja - detalle de
# lote con panel estilo "Bid Now"
# ============================================================
elif pagina == "🔨 Sala de puja":
    lotes = query("""
        SELECT s.id_subasta, a.titulo FROM Subastas s
        JOIN Articulos a ON s.id_articulo = a.id_articulo
        ORDER BY s.id_subasta
    """)
    if not lotes:
        st.info("Aún no hay subastas creadas.")
        st.stop()

    opciones = {f"#{l['id_subasta']} — {l['titulo']}": l["id_subasta"] for l in lotes}
    idx_default = 0
    if "lote_sel" in st.session_state:
        for i, (txt, lid) in enumerate(opciones.items()):
            if lid == st.session_state.lote_sel:
                idx_default = i
                break
    sel = st.selectbox("Selecciona el lote", list(opciones.keys()), index=idx_default)
    id_subasta = opciones[sel]
    st.session_state.lote_sel = id_subasta

    info = query("""
        SELECT a.titulo, a.descripcion, a.codigo_moneda, a.precio_base_reserva,
               a.procedencia, a.anio_fabricacion,
               c.nombre AS categoria, s.puja_actual_maxima, s.total_pujas,
               s.monto_apertura,
               s.fecha_hora_inicio, s.fecha_hora_fin, e.nombre AS estado
        FROM Subastas s
        JOIN Articulos a ON s.id_articulo = a.id_articulo
        JOIN Categorias c ON a.id_categoria = c.id_categoria
        JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
        WHERE s.id_subasta = ?
    """, (id_subasta,))
    if not info:
        st.warning("Lote no encontrado.")
        st.stop()
    it = info[0]

    # Incremento minimo vigente (misma logica que el SP): si nadie ha pujado,
    # el rango se calcula sobre el monto de apertura y la primera puja debe
    # superar apertura + incremento (la subasta nunca arranca en 0).
    apertura = float(it["monto_apertura"] or 0)
    puja_actual = float(it["puja_actual_maxima"])
    base_rango = puja_actual if puja_actual > 0 else apertura
    regla = query("""
        SELECT TOP 1 incremento_minimo FROM Reglas_Incremento
        WHERE id_subasta = ? AND ? >= monto_desde
          AND (monto_hasta IS NULL OR ? < monto_hasta)
        ORDER BY monto_desde DESC
    """, (id_subasta, base_rango, base_rango))
    incremento = float(regla[0]["incremento_minimo"]) if regla else 1.0
    puja_minima = (puja_actual + incremento) if puja_actual > 0 else (apertura + incremento)

    col_det, col_bid = st.columns([3, 2])

    with col_det:
        st.markdown(f"## {icono_categoria(it['categoria'])} {it['titulo']}")
        st.markdown(badge_estado(it["estado"], it["fecha_hora_fin"]), unsafe_allow_html=True)

        # Galeria de imagenes del articulo (portada + resto en orden)
        imgs_lote = query("""
            SELECT url FROM Imagenes_Articulo
            WHERE id_articulo = (SELECT id_articulo FROM Subastas WHERE id_subasta = ?)
            ORDER BY es_portada DESC, orden ASC
        """, (id_subasta,))
        if imgs_lote:
            st.image([x["url"] for x in imgs_lote],
                     width=180 if len(imgs_lote) > 1 else 320)

        st.write(it["descripcion"] or "")
        d1, d2, d3 = st.columns(3)
        d1.metric("Reserva", f"{it['codigo_moneda']} {it['precio_base_reserva']:,.2f}")
        d2.metric("Total pujas", it["total_pujas"])
        d3.metric("Categoría", it["categoria"])
        if it["procedencia"]:
            st.caption(f"Procedencia: {it['procedencia']}"
                       + (f" · Año: {it['anio_fabricacion']}" if it["anio_fabricacion"] else ""))

        st.markdown("#### Historial de pujas")
        historial = query("""
            SELECT TOP 10 p.monto_oferta, p.fecha_hora_puja,
                   us.nombre + ' ' + LEFT(us.apellido, 1) + '.' AS postor
            FROM Pujas p JOIN Usuarios us ON p.id_usuario = us.id_usuario
            WHERE p.id_subasta = ? ORDER BY p.monto_oferta DESC
        """, (id_subasta,))
        if historial:
            st.dataframe(historial, width='stretch', hide_index=True)
        else:
            st.caption("Aún no hay pujas. ¡Sé el primero!")

    with col_bid:
        restante = tiempo_restante(it["fecha_hora_fin"])
        st.markdown('<div class="bid-panel">', unsafe_allow_html=True)
        if puja_actual > 0:
            st.markdown('<div class="bid-current-label">Puja actual</div>', unsafe_allow_html=True)
            st.markdown(f'<div class="bid-current">{it["codigo_moneda"]} {puja_actual:,.2f}</div>',
                        unsafe_allow_html=True)
        else:
            st.markdown('<div class="bid-current-label">Apertura (80% de reserva)</div>',
                        unsafe_allow_html=True)
            st.markdown(f'<div class="bid-current">{it["codigo_moneda"]} {apertura:,.2f}</div>',
                        unsafe_allow_html=True)
        st.markdown("</div>", unsafe_allow_html=True)

        # Countdown en vivo bajo el panel de precio
        if it["fecha_hora_fin"]:
            countdown_html(it["fecha_hora_fin"])

        if it["estado"] == "Activa" and restante:
            st.markdown(f'<div class="bid-min">Puja mínima: {it["codigo_moneda"]} '
                        f'{puja_minima:,.2f}</div>', unsafe_allow_html=True)
            monto = st.number_input("Tu oferta", min_value=0.0,
                                    value=float(puja_minima), step=float(incremento),
                                    format="%.2f")
            if st.button(f"🔨 PUJAR {it['codigo_moneda']} {monto:,.2f}",
                         width='stretch'):
                try:
                    ejecutar_sp("sp_RegistrarPuja", (id_subasta, u["id_usuario"], monto))
                    st.success("¡Puja registrada! Vas ganando. 🎉")
                    st.rerun()
                except pyodbc.Error as ex:
                    st.error(f"Puja rechazada: {ex.args[-1] if ex.args else ex}")
            st.caption("Si pujas en los últimos segundos, la subasta se extiende "
                       "automáticamente (anti-sniping).")
        elif it["estado"] != "Activa":
            st.warning(f"Esta subasta está **{it['estado']}**.")
        else:
            st.warning("El tiempo de esta subasta ya venció.")

# ============================================================
# [INTEGRANTE B - Frontend] VISTA: Mis Pujas
# ============================================================
elif pagina == "📋 Mis Pujas":
    st.markdown("## Historial de mis pujas")
    filas = query("""
        SELECT s.id_subasta AS lote, a.titulo, p.monto_oferta, p.fecha_hora_puja,
               e.nombre AS estado_subasta,
               CASE WHEN e.nombre = 'Finalizada' AND s.id_puja_lider = p.id_puja THEN '✅ Ganaste'
                    WHEN s.id_puja_lider = p.id_puja THEN '🏆 Vas ganando'
                    ELSE '—' END AS situacion
        FROM Pujas p
        JOIN Subastas s ON p.id_subasta = s.id_subasta
        JOIN Articulos a ON s.id_articulo = a.id_articulo
        JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
        WHERE p.id_usuario = ?
        ORDER BY p.fecha_hora_puja DESC
    """, (u["id_usuario"],))
    if filas:
        st.dataframe(filas, width='stretch', hide_index=True)
    else:
        st.info("Todavía no has pujado. Entra al catálogo y elige un lote.")

# ============================================================
# [INTEGRANTE B - Frontend] VISTA: Mis Articulos - alta y
# edicion de articulos con imagenes, ubicacion, certificado
# y pedigree (sinergia con el catalogo)
# ============================================================
elif pagina == "📦 Mis Artículos":
    st.markdown("## Mis artículos")

    # Catalogos compartidos (alta y edicion)
    cats = query("SELECT id_categoria, nombre FROM Categorias ORDER BY nombre")
    efis = query("SELECT id_estado_fisico, nombre FROM Estados_Fisicos ORDER BY id_estado_fisico")
    monedas = query("SELECT codigo_moneda FROM Monedas ORDER BY codigo_moneda")
    ubics = query("SELECT id_ubicacion, nombre_ubicacion FROM Ubicaciones_Almacenaje ORDER BY nombre_ubicacion")
    ents = query("SELECT id_entidad_emisora, nombre FROM Entidades_Certificadoras ORDER BY nombre")

    tab_lista, tab_nuevo = st.tabs(["📦 Inventario", "➕ Registrar artículo"])

    # ---------------- INVENTARIO + EDICION ----------------
    with tab_lista:
        # El admin ve tambien los articulos TEST_ para poder editarlos
        filtro_propietario = ("(a.id_vendedor = ? OR a.titulo LIKE 'TEST[_]%')"
                              if u.get("es_admin") else "a.id_vendedor = ?")
        arts = query(f"""
            SELECT a.id_articulo, a.titulo, c.nombre AS categoria, a.precio_base_reserva,
                   a.codigo_moneda, ea.nombre AS estado, ef.nombre AS estado_fisico,
                   ub.nombre_ubicacion AS ubicacion,
                   (SELECT COUNT(*) FROM Imagenes_Articulo i WHERE i.id_articulo = a.id_articulo) AS fotos,
                   (SELECT TOP 1 i.url FROM Imagenes_Articulo i
                     WHERE i.id_articulo = a.id_articulo AND i.es_portada = 1) AS portada,
                   CASE WHEN EXISTS (SELECT 1 FROM Subastas s WHERE s.id_articulo = a.id_articulo)
                        THEN 1 ELSE 0 END AS tiene_subasta
            FROM Articulos a
            JOIN Categorias c ON a.id_categoria = c.id_categoria
            JOIN Estados_Articulo ea ON a.id_estado_articulo = ea.id_estado_articulo
            LEFT JOIN Estados_Fisicos ef ON a.id_estado_fisico = ef.id_estado_fisico
            LEFT JOIN Ubicaciones_Almacenaje ub ON a.id_ubicacion_actual = ub.id_ubicacion
            WHERE {filtro_propietario}
            ORDER BY a.fecha_ingreso DESC
        """, (u["id_usuario"],))
        if not arts:
            st.info("Aún no registras artículos. Usa la pestaña «Registrar artículo».")

        for a in arts:
            with st.container(border=True):
                c_img, c_info, c_num = st.columns([1, 3, 2])
                with c_img:
                    if a["portada"]:
                        st.image(a["portada"], width=90)
                    else:
                        st.markdown("<div style='font-size:2.4rem;text-align:center'>🏷️</div>",
                                    unsafe_allow_html=True)
                c_info.markdown(f"**#{a['id_articulo']} — {a['titulo']}**")
                c_info.caption(f"{a['categoria']} · {a['estado']} · {a['estado_fisico'] or 's/d'}"
                               + (f" · 📍 {a['ubicacion']}" if a["ubicacion"] else ""))
                c_num.metric("Reserva", f"{a['codigo_moneda']} {a['precio_base_reserva']:,.2f}",
                             delta=f"{a['fotos']} foto(s)", delta_color="off")
                if a["tiene_subasta"]:
                    c_num.caption("🔨 ya en subasta")

                with st.expander(f"✏️ Editar #{a['id_articulo']}"):
                    det = query("SELECT * FROM Articulos WHERE id_articulo = ?",
                                (a["id_articulo"],))[0]
                    imgs_act = query(
                        "SELECT url, orden FROM Imagenes_Articulo WHERE id_articulo = ? "
                        "ORDER BY orden", (a["id_articulo"],))
                    urls_act = [x["url"] for x in imgs_act] + ["", "", ""]

                    with st.form(f"form_edit_{a['id_articulo']}"):
                        e_tit = st.text_input("Título", value=det["titulo"], max_chars=150)
                        e_desc = st.text_area("Descripción", value=det["descripcion"] or "")
                        ec1, ec2, ec3 = st.columns(3)
                        i_cat = next((i for i, c in enumerate(cats)
                                      if c["id_categoria"] == det["id_categoria"]), 0)
                        e_cat = ec1.selectbox("Categoría", [c["nombre"] for c in cats], index=i_cat)
                        i_ef = next((i for i, x in enumerate(efis)
                                     if x["id_estado_fisico"] == det["id_estado_fisico"]), 0)
                        e_ef = ec2.selectbox("Estado físico", [x["nombre"] for x in efis], index=i_ef)
                        i_mon = next((i for i, m in enumerate(monedas)
                                      if m["codigo_moneda"] == det["codigo_moneda"]), 0)
                        e_mon = ec3.selectbox("Moneda", [m["codigo_moneda"] for m in monedas],
                                              index=i_mon)
                        ec4, ec5, ec6 = st.columns(3)
                        e_res = ec4.number_input("Reserva", min_value=0.0,
                                                 value=float(det["precio_base_reserva"]),
                                                 step=100.0, format="%.2f")
                        e_anio = ec5.number_input("Año", min_value=0, max_value=2100,
                                                  value=int(det["anio_fabricacion"] or 0), step=1)
                        ub_names = ["— sin asignar —"] + [x["nombre_ubicacion"] for x in ubics]
                        i_ub = next((i for i, x in enumerate(ubics)
                                     if x["id_ubicacion"] == det["id_ubicacion_actual"]), -1) + 1
                        e_ub = ec6.selectbox("Ubicación", ub_names, index=i_ub)
                        e_proc = st.text_input("Procedencia", value=det["procedencia"] or "",
                                               max_chars=255)

                        e_url1 = st.text_input("Imagen 1 (portada)", value=urls_act[0])
                        ce2, ce3 = st.columns(2)
                        e_url2 = ce2.text_input("Imagen 2", value=urls_act[1])
                        e_url3 = ce3.text_input("Imagen 3", value=urls_act[2])

                        guardar = st.form_submit_button("💾 Guardar cambios", width='stretch')

                    if guardar:
                        if not e_tit.strip():
                            st.error("El título es obligatorio.")
                        elif not e_url1.strip().startswith(("http://", "https://")):
                            st.error("La imagen 1 (portada) debe ser una URL http(s).")
                        else:
                            id_cat_e = next(c["id_categoria"] for c in cats if c["nombre"] == e_cat)
                            id_ef_e = next(x["id_estado_fisico"] for x in efis
                                           if x["nombre"] == e_ef)
                            id_ub_e = (next((x["id_ubicacion"] for x in ubics
                                             if x["nombre_ubicacion"] == e_ub), None)
                                       if e_ub != "— sin asignar —" else None)
                            conn = get_connection()
                            cur = conn.cursor()
                            try:
                                cur.execute(
                                    "UPDATE Articulos SET id_categoria=?, id_estado_fisico=?, "
                                    "codigo_moneda=?, titulo=?, descripcion=?, anio_fabricacion=?, "
                                    "procedencia=?, precio_base_reserva=?, id_ubicacion_actual=? "
                                    "WHERE id_articulo=?",
                                    (id_cat_e, id_ef_e, e_mon, e_tit.strip(),
                                     e_desc.strip() or None, (e_anio or None),
                                     e_proc.strip() or None, e_res, id_ub_e, a["id_articulo"]))
                                # Reemplazo simple de imagenes: borrar y reinsertar en orden
                                cur.execute("DELETE FROM Imagenes_Articulo WHERE id_articulo = ?",
                                            (a["id_articulo"],))
                                imgs_e = [x.strip() for x in (e_url1, e_url2, e_url3) if x and x.strip()]
                                for i, url_img in enumerate(imgs_e, start=1):
                                    cur.execute(
                                        "INSERT INTO Imagenes_Articulo (id_articulo, url, orden, "
                                        "es_portada) VALUES (?, ?, ?, ?)",
                                        (a["id_articulo"], url_img, i, 1 if i == 1 else 0))
                                conn.commit()
                                st.success(f"Artículo #{a['id_articulo']} actualizado. ✅")
                                st.rerun()
                            except pyodbc.Error as ex:
                                conn.rollback()
                                st.error(f"Error actualizando: {ex.args[-1] if ex.args else ex}")

    # ---------------- REGISTRAR NUEVO ----------------
    with tab_nuevo:
        st.markdown("### Registrar nuevo artículo")

        # Alta rapida de categoria y ubicacion (inline, sin salir del form)
        with st.expander("➕ ¿No existe la categoría o ubicación? Agrégala aquí"):
            nc1, nc2 = st.columns(2)
            with nc1:
                st.markdown("**Nueva categoría**")
                nom_cat = st.text_input("Nombre categoría", max_chars=100, key="nc_nom")
                desc_cat = st.text_input("Descripción", max_chars=255, key="nc_desc")
                if st.button("Agregar categoría", key="btn_nc"):
                    if not nom_cat.strip():
                        st.error("Nombre obligatorio.")
                    elif any(c["nombre"].lower() == nom_cat.strip().lower() for c in cats):
                        st.warning("Esa categoría ya existe.")
                    else:
                        try:
                            conn = get_connection()
                            conn.cursor().execute(
                                "INSERT INTO Categorias (nombre, descripcion) VALUES (?, ?)",
                                (nom_cat.strip(), desc_cat.strip() or None))
                            conn.commit()
                            st.success("Categoría agregada. Ya aparece en el formulario.")
                            st.rerun()
                        except pyodbc.Error as ex:
                            st.error(f"Error: {ex.args[-1] if ex.args else ex}")
            with nc2:
                st.markdown("**Nueva ubicación**")
                nom_ub = st.text_input("Nombre ubicación", max_chars=150, key="nu_nom")
                tipo_ub = st.selectbox("Tipo", ["Bóveda Bancaria", "Caja de Seguridad",
                                                "Almacén Privado", "Bóveda Internacional",
                                                "Custodia Propia"], key="nu_tipo")
                inst_ub = st.text_input("Institución", max_chars=100, key="nu_inst")
                if st.button("Agregar ubicación", key="btn_nu"):
                    if not nom_ub.strip():
                        st.error("Nombre obligatorio.")
                    else:
                        try:
                            conn = get_connection()
                            conn.cursor().execute(
                                "INSERT INTO Ubicaciones_Almacenaje (nombre_ubicacion, "
                                "tipo_ubicacion, institucion) VALUES (?, ?, ?)",
                                (nom_ub.strip(), tipo_ub, inst_ub.strip() or None))
                            conn.commit()
                            st.success("Ubicación agregada. Ya aparece en el formulario.")
                            st.rerun()
                        except pyodbc.Error as ex:
                            st.error(f"Error: {ex.args[-1] if ex.args else ex}")

        if not ubics:
            st.warning("No hay ubicaciones registradas; agrégala arriba o en 🛠️ Admin → Ubicaciones.")

        with st.form("form_nuevo_articulo", clear_on_submit=True):
            titulo = st.text_input("Título *", max_chars=150,
                                   placeholder="Ej. Reloj Rolex Daytona 2018 con papeles")
            desc = st.text_area("Descripción", placeholder="Detalles, historia, condición...")
            r1, r2, r3 = st.columns(3)
            cat = r1.selectbox("Categoría *", [c["nombre"] for c in cats])
            estado_f = r2.selectbox("Estado físico", [x["nombre"] for x in efis])
            moneda = r3.selectbox("Moneda", [m["codigo_moneda"] for m in monedas])
            r4, r5, r6 = st.columns(3)
            reserva = r4.number_input("Precio base / reserva *", min_value=0.0,
                                      step=100.0, format="%.2f")
            anio = r5.number_input("Año de fabricación", min_value=0, max_value=2100,
                                   value=0, step=1)
            ubic = r6.selectbox("Ubicación", ["— sin asignar —"] + [x["nombre_ubicacion"] for x in ubics])
            proced = st.text_input("Procedencia", max_chars=255,
                                   placeholder="Ej. Colección privada, herencia familiar...")

            st.markdown("#### 📷 Imágenes")
            if drive_disponible():
                st.caption("Sube desde tu equipo (va al CDN de Cloudinary) o pega URLs. "
                           "Mínimo 1 entre ambas; el orden de portada es: primero las subidas, "
                           "luego las URLs.")
                archivos = st.file_uploader(
                    "Desde tu equipo → Cloudinary",
                    type=["jpg", "jpeg", "png", "webp"],
                    accept_multiple_files=True)
                if archivos:
                    prev = st.columns(min(len(archivos), 4))
                    for col_p, f in zip(prev, archivos[:4]):
                        col_p.image(f, width=110)
            else:
                st.caption("Pega URLs públicas (imgur, cloudinary, Drive público...). "
                           "Para subir desde tu equipo falta configurar Cloudinary: "
                           "CLOUDINARY_CLOUD + CLOUDINARY_PRESET.")
                archivos = []
            url1 = st.text_input("URL imagen", placeholder="https://... (opcional si subes archivos)")
            c_u2, c_u3 = st.columns(2)
            url2 = c_u2.text_input("URL imagen 2", placeholder="https://... (opcional)")
            url3 = c_u3.text_input("URL imagen 3", placeholder="https://... (opcional)")

            with st.expander("📜 Certificado de autenticidad (opcional)"):
                ent = st.selectbox("Entidad emisora", [x["nombre"] for x in ents])
                cc1, cc2 = st.columns(2)
                num_reg = cc1.text_input("Número de registro", max_chars=100)
                fecha_em = cc2.date_input("Fecha de emisión", value=None)
                url_doc = st.text_input("URL del documento", max_chars=255, placeholder="https://...")

            with st.expander("🏺 Pedigrí / historia (opcional)"):
                famoso = st.text_input("Propietario famoso anterior", max_chars=150)
                evento = st.text_input("Evento destacado", max_chars=200)
                hist = st.text_area("Descripción histórica")

            enviado = st.form_submit_button("💾 Registrar artículo", width='stretch')

        if enviado:
            urls_manual = [x.strip() for x in (url1, url2, url3)
                           if x and x.strip().startswith(("http://", "https://"))]
            if not titulo.strip():
                st.error("El título es obligatorio.")
            elif reserva <= 0:
                st.error("La reserva debe ser mayor a cero.")
            elif not archivos and not urls_manual:
                st.error("Necesitas al menos 1 imagen: súbela desde tu equipo o pega una URL.")
            else:
                id_cat = next(c["id_categoria"] for c in cats if c["nombre"] == cat)
                id_ef = next(x["id_estado_fisico"] for x in efis if x["nombre"] == estado_f)
                id_ub = (next((x["id_ubicacion"] for x in ubics
                               if x["nombre_ubicacion"] == ubic), None)
                         if ubic != "— sin asignar —" else None)

                # 1) Subir archivos a Cloudinary (si los hay) y recolectar sus URLs
                urls_finales = []
                if archivos:
                    progreso = st.progress(0, text="Subiendo imágenes...")
                    try:
                        for i, f in enumerate(archivos):
                            progreso.progress((i + 1) / len(archivos),
                                              text=f"Subiendo {f.name} ({i+1}/{len(archivos)})...")
                            url_drive = subir_imagen_drive(f.getvalue(), f.name,
                                                           f.type or "image/jpeg")
                            urls_finales.append(url_drive)
                    except Exception as ex:
                        progreso.empty()
                        st.error(f"Error subiendo la imagen: {ex}")
                        st.stop()
                    progreso.empty()
                urls_finales += urls_manual

                # 2) Insertar articulo + imagenes + certificado + pedigree
                conn = get_connection()
                cur = conn.cursor()
                try:
                    # OUTPUT INSERTED: devuelve el id en el mismo batch
                    # (SCOPE_IDENTITY() en un execute aparte devuelve NULL)
                    cur.execute(
                        "INSERT INTO Articulos (id_vendedor, id_categoria, id_estado_fisico, "
                        "id_estado_articulo, codigo_moneda, titulo, descripcion, "
                        "anio_fabricacion, procedencia, precio_base_reserva, fecha_ingreso, "
                        "id_ubicacion_actual) "
                        "OUTPUT INSERTED.id_articulo "
                        "VALUES (?, ?, ?, 1, ?, ?, ?, ?, ?, ?, dbo.fn_AhoraGT(), ?)",
                        (u["id_usuario"], id_cat, id_ef, moneda, titulo.strip(),
                         desc.strip() or None, (anio or None), proced.strip() or None,
                         reserva, id_ub))
                    id_art = int(cur.fetchone()[0])

                    for i, url_img in enumerate(urls_finales, start=1):
                        cur.execute(
                            "INSERT INTO Imagenes_Articulo (id_articulo, url, orden, es_portada) "
                            "VALUES (?, ?, ?, ?)",
                            (id_art, url_img, i, 1 if i == 1 else 0))

                    if num_reg.strip():
                        id_ent = next(x["id_entidad_emisora"] for x in ents if x["nombre"] == ent)
                        cur.execute(
                            "INSERT INTO Certificados_Autenticidad (id_articulo, id_entidad_emisora, "
                            "numero_registro, fecha_emision, url_documento, "
                            "verificado_por_plataforma) VALUES (?, ?, ?, ?, ?, 0)",
                            (id_art, id_ent, num_reg.strip(),
                             fecha_em if fecha_em else None, url_doc.strip() or None))

                    if famoso.strip() or evento.strip() or hist.strip():
                        cur.execute(
                            "INSERT INTO Historial_Pedigree_Articulos (id_articulo, "
                            "propietario_anterior_famoso, evento_destacado, descripcion_historica) "
                            "VALUES (?, ?, ?, ?)",
                            (id_art, famoso.strip() or None, evento.strip() or None,
                             hist.strip() or ""))

                    conn.commit()
                    msg_drive = (f"{len(archivos)} subida(s) a Cloudinary + " if archivos else "")
                    st.success(f"Artículo #{id_art} registrado ({msg_drive}"
                               f"{len(urls_finales)} imagen(es) en total). 🎉 "
                               "Un Admin ya puede crearle una subasta desde 🛠️ Admin.")
                except pyodbc.Error as ex:
                    conn.rollback()
                    st.error(f"Error registrando: {ex.args[-1] if ex.args else ex}")

# ============================================================
# [INTEGRANTE C - Backend] VISTA: Panel Admin - crear/cerrar
# subastas y reportes (solo rol Admin)
# ============================================================
elif pagina == "🛠️ Admin":
    if not u.get("es_admin"):
        st.error("Acceso restringido al rol Admin.")
        st.stop()

    st.markdown("## Panel de administración")

    # --- Resumen rapido ---
    kpi = query("""
        SELECT
            (SELECT COUNT(*) FROM Subastas s JOIN Estados_Subasta e
                ON s.id_estado_subasta = e.id_estado_subasta
             WHERE e.nombre = 'Activa') AS activas,
            (SELECT COUNT(*) FROM Subastas s JOIN Estados_Subasta e
                ON s.id_estado_subasta = e.id_estado_subasta
             WHERE e.nombre = 'Activa' AND s.fecha_hora_fin < dbo.fn_AhoraGT()) AS vencidas,
            (SELECT COUNT(*) FROM Usuarios WHERE activo = 1) AS usuarios,
            (SELECT COUNT(*) FROM Pujas) AS pujas
    """)[0]
    k1, k2, k3, k4 = st.columns(4)
    k1.metric("Subastas activas", kpi["activas"])
    k2.metric("Vencidas sin cerrar", kpi["vencidas"],
              delta="⚠️ pendientes" if kpi["vencidas"] else None,
              delta_color="inverse" if kpi["vencidas"] else "off")
    k3.metric("Usuarios activos", kpi["usuarios"])
    k4.metric("Pujas totales", kpi["pujas"])

    tab_crear, tab_cerrar, tab_ubics, tab_aud, tab_users = st.tabs(
        ["➕ Crear subasta", "🔒 Cerrar subastas", "📍 Ubicaciones", "📜 Auditoría", "👥 Usuarios"])

    # ---------------- CREAR SUBASTA ----------------
    with tab_crear:
        st.markdown("### Nueva subasta")
        articulos = query("""
            SELECT a.id_articulo, a.titulo, a.precio_base_reserva, a.codigo_moneda
            FROM Articulos a
            WHERE NOT EXISTS (
                SELECT 1 FROM Subastas s JOIN Estados_Subasta e
                    ON s.id_estado_subasta = e.id_estado_subasta
                WHERE s.id_articulo = a.id_articulo
                  AND e.nombre IN ('Activa', 'Programada'))
            ORDER BY a.id_articulo
        """)
        politicas = query("SELECT id_politica, nombre FROM Politicas_Comision ORDER BY id_politica")

        if not articulos:
            st.info("No hay artículos libres (todos ya tienen subasta activa o programada).")
        else:
            opts_art = {f"#{x['id_articulo']} — {x['titulo']} "
                        f"(reserva {x['codigo_moneda']} {x['precio_base_reserva']:,.2f})":
                        x for x in articulos}
            opts_pol = {p["nombre"]: p["id_politica"] for p in politicas}
            ahora_local = ahora_gt()

            with st.form("form_crear_subasta", clear_on_submit=True):
                art_sel = st.selectbox("Artículo", list(opts_art.keys()))
                art_obj = opts_art[art_sel]
                # Regla del negocio: la subasta abre en el 80% de la reserva
                # (20% menos). Ese es el minimo para adjudicar y la base
                # de la primera puja — nunca se arranca en 0.
                apertura = round(float(art_obj["precio_base_reserva"]) * 0.80, 2)
                st.info(f"💰 Reserva: **{art_obj['codigo_moneda']} "
                        f"{art_obj['precio_base_reserva']:,.2f}** → "
                        f"Monto de apertura (80%): **{art_obj['codigo_moneda']} "
                        f"{apertura:,.2f}**. La puja ganadora debe alcanzarlo para adjudicar.",
                        icon="ℹ️")
                c1, c2 = st.columns(2)
                f_ini = c1.date_input("Inicio (hora GT)", value=ahora_local.date())
                h_ini = c1.time_input("Hora inicio", value=ahora_local.time())
                f_fin = c2.date_input("Cierre (hora GT)", value=ahora_local.date())
                h_fin = c2.time_input("Hora cierre")
                c3, c4 = st.columns(2)
                pol_sel = c3.selectbox("Política de comisión", list(opts_pol.keys()))
                antisnip = c4.number_input("Anti-sniping (segundos)", min_value=0,
                                           max_value=3600, value=120, step=30)
                st.caption("Reglas de incremento (por rango de puja actual)")
                r1, r2, r3 = st.columns(3)
                inc1 = r1.number_input("0–999", min_value=1.0, value=50.0, step=10.0)
                inc2 = r2.number_input("1,000–9,999", min_value=1.0, value=100.0, step=10.0)
                inc3 = r3.number_input("10,000 en adelante", min_value=1.0, value=500.0, step=50.0)
                enviado = st.form_submit_button("🚀 Crear subasta", width='stretch')

            if enviado:
                # Los datetime se guardan naive en hora Guatemala
                inicio = datetime.combine(f_ini, h_ini)
                fin = datetime.combine(f_fin, h_fin)
                if fin <= inicio:
                    st.error("La fecha de cierre debe ser posterior a la de inicio.")
                else:
                    conn = get_connection()
                    cur = conn.cursor()
                    try:
                        id_estado = query(
                            "SELECT id_estado_subasta FROM Estados_Subasta WHERE nombre = 'Activa'"
                        )[0]["id_estado_subasta"]
                        cur.execute(
                            "INSERT INTO Subastas (id_articulo, id_estado_subasta, id_politica, "
                            "id_usuario_creador, fecha_hora_inicio, fecha_hora_fin, "
                            "extension_anti_sniping_seg, puja_actual_maxima, total_pujas, "
                            "version, fecha_creacion, monto_apertura) "
                            "OUTPUT INSERTED.id_subasta "
                            "VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 1, dbo.fn_AhoraGT(), ?)",
                            (art_obj["id_articulo"], id_estado, opts_pol[pol_sel],
                             u["id_usuario"], inicio, fin, int(antisnip), apertura))
                        id_nueva = int(cur.fetchone()[0])
                        cur.executemany(
                            "INSERT INTO Reglas_Incremento (id_subasta, monto_desde, "
                            "monto_hasta, incremento_minimo) VALUES (?, ?, ?, ?)",
                            [(id_nueva, 0.0, 1000.0, inc1),
                             (id_nueva, 1000.0, 10000.0, inc2),
                             (id_nueva, 10000.0, None, inc3)])
                        conn.commit()
                        st.success(f"Subasta #{id_nueva} creada y activa. 🎉 "
                                   f"Abre en {art_obj['codigo_moneda']} {apertura:,.2f}.")
                        st.rerun()
                    except pyodbc.Error as ex:
                        conn.rollback()
                        st.error(f"Error creando la subasta: {ex.args[-1] if ex.args else ex}")

    # ---------------- CERRAR SUBASTAS ----------------
    with tab_cerrar:
        st.markdown("### Cierre de subastas")
        c_v1, c_v2 = st.columns([2, 1])
        with c_v2:
            st.markdown("&nbsp;", unsafe_allow_html=True)
            if st.button("⏱ Cerrar TODAS las vencidas", width='stretch'):
                try:
                    ejecutar_sp("sp_CerrarSubastasVencidas")
                    st.success("Subastas vencidas cerradas.")
                    st.rerun()
                except pyodbc.Error as ex:
                    st.error(f"Error: {ex.args[-1] if ex.args else ex}")

        abiertas = query("""
            SELECT s.id_subasta, a.titulo, s.puja_actual_maxima, s.total_pujas,
                   s.fecha_hora_fin, e.nombre AS estado,
                   CASE WHEN s.fecha_hora_fin < dbo.fn_AhoraGT() THEN 1 ELSE 0 END AS vencida
            FROM Subastas s
            JOIN Articulos a ON s.id_articulo = a.id_articulo
            JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
            WHERE e.nombre = 'Activa'
            ORDER BY s.fecha_hora_fin ASC
        """)
        if not abiertas:
            st.info("No hay subastas activas.")
        for it in abiertas:
            with st.container(border=True):
                cc1, cc2, cc3 = st.columns([3, 2, 1])
                cc1.markdown(f"**#{it['id_subasta']} — {it['titulo']}**")
                cc1.caption(f"Cierra: {it['fecha_hora_fin']:%Y-%m-%d %H:%M}"
                            + ("  ·  ⚠️ **vencida**" if it["vencida"] else ""))
                cc2.metric("Puja actual", f"{it['puja_actual_maxima']:,.2f}",
                           delta=f"{it['total_pujas']} pujas", delta_color="off")
                if cc3.button("🔒 Cerrar", key=f"cerrar_{it['id_subasta']}",
                              width='stretch'):
                    try:
                        ejecutar_sp("sp_CerrarSubasta", (it["id_subasta"],))
                        st.success(f"Subasta #{it['id_subasta']} cerrada.")
                        st.rerun()
                    except pyodbc.Error as ex:
                        st.error(f"Error: {ex.args[-1] if ex.args else ex}")

        st.markdown("#### Últimos cierres")
        cierres = query("""
            SELECT TOP 15 s.id_subasta, a.titulo,
                   COALESCE(ad.monto_adjudicado, s.puja_actual_maxima) AS monto_final,
                   COALESCE(ug.nombre + ' ' + ug.apellido, '— sin ganador —') AS ganador,
                   ad.fecha_adjudicacion,
                   op.id_orden AS orden_pago, op.total_a_pagar
            FROM Subastas s
            JOIN Articulos a ON s.id_articulo = a.id_articulo
            JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
            LEFT JOIN Adjudicaciones ad ON ad.id_subasta = s.id_subasta
            LEFT JOIN Usuarios ug ON ad.id_usuario_ganador = ug.id_usuario
            LEFT JOIN Ordenes_Pago op ON op.id_subasta = s.id_subasta
            WHERE e.nombre = 'Finalizada'
            ORDER BY ad.fecha_adjudicacion DESC
        """)
        if cierres:
            st.dataframe(cierres, width='stretch', hide_index=True)
        else:
            st.caption("Todavía no se ha cerrado ninguna subasta.")

    # ---------------- UBICACIONES ----------------
    with tab_ubics:
        st.markdown("### Ubicaciones de almacenaje")
        ub = query("""
            SELECT ub.id_ubicacion, ub.nombre_ubicacion, ub.tipo_ubicacion,
                   ub.institucion, ub.nivel_seguridad,
                   (SELECT COUNT(*) FROM Articulos a WHERE a.id_ubicacion_actual = ub.id_ubicacion) AS piezas
            FROM Ubicaciones_Almacenaje ub ORDER BY ub.nombre_ubicacion
        """)
        if ub:
            st.dataframe(ub, width='stretch', hide_index=True)

        st.markdown("#### Agregar ubicación")
        with st.form("form_nueva_ubicacion", clear_on_submit=True):
            u1, u2 = st.columns(2)
            nom_u = u1.text_input("Nombre *", max_chars=150, placeholder="Ej. Bóveda Zona 10")
            tipo_u = u2.selectbox("Tipo", ["Bóveda Bancaria", "Caja de Seguridad",
                                           "Almacén Privado", "Bóveda Internacional",
                                           "Custodia Propia"])
            u3, u4 = st.columns(2)
            inst_u = u3.text_input("Institución", max_chars=100)
            nseg_u = u4.selectbox("Nivel de seguridad", ["Media", "Media-Alta", "Alta",
                                                         "Máxima", "Extrema"])
            dir_u = st.text_input("Dirección", max_chars=255)
            cont_u = st.text_input("Contacto responsable", max_chars=100)
            if st.form_submit_button("➕ Agregar", width='stretch'):
                if not nom_u.strip():
                    st.error("El nombre es obligatorio.")
                else:
                    try:
                        conn = get_connection()
                        conn.cursor().execute(
                            "INSERT INTO Ubicaciones_Almacenaje (nombre_ubicacion, tipo_ubicacion, "
                            "institucion, direccion, nivel_seguridad, contacto_responsable) "
                            "VALUES (?, ?, ?, ?, ?, ?)",
                            (nom_u.strip(), tipo_u, inst_u.strip() or None,
                             dir_u.strip() or None, nseg_u, cont_u.strip() or None))
                        conn.commit()
                        st.success("Ubicación agregada.")
                        st.rerun()
                    except pyodbc.Error as ex:
                        st.error(f"Error: {ex.args[-1] if ex.args else ex}")

    # ---------------- AUDITORIA ----------------
    with tab_aud:
        st.markdown("### Bitácora de intentos de puja")
        f1, f2 = st.columns(2)
        resultados = query("SELECT id_resultado, codigo FROM Resultados_Intento ORDER BY id_resultado")
        filtro_res = f1.multiselect("Resultado", [r["codigo"] for r in resultados],
                                    default=[r["codigo"] for r in resultados])
        limite = f2.selectbox("Filas", [50, 100, 500], index=0)

        sql_aud = f"""
            SELECT TOP {int(limite)} a.fecha_hora_intento, a.id_subasta,
                   us.nombre + ' ' + us.apellido AS usuario,
                   r.codigo AS resultado, a.monto_intento, a.puja_maxima_al_momento
            FROM Auditoria_Pujas a
            JOIN Usuarios us ON a.id_usuario = us.id_usuario
            JOIN Resultados_Intento r ON a.id_resultado = r.id_resultado
            WHERE r.codigo IN ({",".join("?" * len(filtro_res)) or "NULL"})
            ORDER BY a.fecha_hora_intento DESC
        """
        aud = query(sql_aud, tuple(filtro_res)) if filtro_res else []
        if aud:
            st.dataframe(aud, width='stretch', hide_index=True)
        else:
            st.caption("Sin registros para ese filtro.")

    # ---------------- USUARIOS ----------------
    with tab_users:
        st.markdown("### Usuarios registrados")
        usuarios = query("""
            SELECT us.id_usuario, us.nombre + ' ' + us.apellido AS usuario, us.email,
                   ev.nombre AS verificacion, us.fecha_registro,
                   CASE WHEN us.activo = 1 THEN 'Sí' ELSE 'No' END AS activo,
                   (SELECT COUNT(*) FROM Pujas p WHERE p.id_usuario = us.id_usuario) AS pujas
            FROM Usuarios us
            JOIN Estados_Verificacion ev ON us.id_estado_verificacion = ev.id_estado_verificacion
            ORDER BY us.fecha_registro DESC
        """)
        st.dataframe(usuarios, width='stretch', hide_index=True)

        st.markdown("#### Asignar / quitar rol Admin")
        todos = query("""
            SELECT us.id_usuario, us.nombre + ' ' + us.apellido + ' (' + us.email + ')' AS etiqueta,
                   CASE WHEN EXISTS (
                       SELECT 1 FROM Usuario_Roles ur JOIN Roles r ON ur.id_rol = r.id_rol
                       WHERE ur.id_usuario = us.id_usuario AND r.nombre = 'Admin')
                   THEN 1 ELSE 0 END AS es_adm
            FROM Usuarios us WHERE us.activo = 1 ORDER BY us.nombre
        """)
        opts_usr = {t["etiqueta"]: (t["id_usuario"], t["es_adm"]) for t in todos}
        usr_sel = st.selectbox("Usuario", list(opts_usr.keys()))
        id_sel, ya_admin = opts_usr[usr_sel]
        if ya_admin:
            st.info("Este usuario ya es Admin.")
            if st.button("➖ Quitar rol Admin"):
                if id_sel == u["id_usuario"]:
                    st.warning("No puedes quitarte el rol a ti mismo.")
                else:
                    conn = get_connection()
                    conn.cursor().execute(
                        "DELETE FROM Usuario_Roles WHERE id_usuario = ? AND id_rol = 1", (id_sel,))
                    conn.commit()
                    st.success("Rol Admin removido.")
                    st.rerun()
        else:
            if st.button("➕ Hacer Admin"):
                conn = get_connection()
                conn.cursor().execute(
                    "INSERT INTO Usuario_Roles (id_usuario, id_rol, fecha_asignacion) "
                    "VALUES (?, 1, dbo.fn_AhoraGT())", (id_sel,))
                conn.commit()
                st.success("Rol Admin asignado.")
                st.rerun()

st.sidebar.caption(f"BD: {DB_SERVER} · GT {ahora_gt():%H:%M:%S}")
