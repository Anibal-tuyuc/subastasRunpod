# Despliegue en RunPod — paso a paso

## 1) Crear el pod

- RunPod → **Pods** → Deploy. Cualquier GPU disponible sirve (la app no usa GPU;
  la ADA4000 funcionó bien). Plantilla base de Ubuntu 22.04.
- **Importante:** expón el puerto **8501** (HTTP). En la config del pod,
  "Expose HTTP Ports" → `8501`.
- SIN Network Volume = si haces **Terminate** se pierde TODO. **Stop** conserva.
  Haz backup antes de terminar (ver paso 6).

## 2) Subir los archivos al pod

Abre el **Web Terminal** del pod (o `runpodctl` / SSH). Sube a `/workspace`:

```
/workspace/
├── setup_runpod.sh
├── cargar_bd.sh
├── app/
│   ├── app.py
│   └── requirements.txt
└── sql/
    ├── script_utf8.sql
    ├── mejoras_subastas.sql
    ├── seed_catalogos.sql
    ├── seed_catalogos_apoyo.sql
    ├── seed_roles.sql
    ├── datos_prueba_subastas.sql
    ├── sp_motor_pujas.sql
    └── seed_subastas_prueba.sql
```

Forma fácil de subir todo de golpe desde tu PC (Git Bash, con SSH del pod configurado):

```bash
cd /c/Users/Admin/subastas-app
scp -P <puerto_ssh> setup_runpod.sh cargar_bd.sh root@<ip-pod>:/workspace/
scp -P <puerto_ssh> -r app sql root@<ip-pod>:/workspace/
```

O pega cada archivo en el Web Terminal / editor del pod.

## 3) Setup del pod (una sola vez, ~10-15 min)

```bash
cd /workspace
bash setup_runpod.sh
```

Esto instala SQL Server 2022 Developer, lo arranca en tmux, crea la BD
`subastas_privadas` e instala Python + dependencias.

> ⚠️ **La clave del SA NO está en el repo.** Define la variable antes de correr
> cualquier script (usa tu propia clave, sin espacios raros):
> ```bash
> export SA_PASSWORD='TuClaveFuerte!'
> bash setup_runpod.sh
> ```
> (Opcional) password del admin web, por defecto `Admin2025!`:
> `export ADMIN_WEB_PASS='OtraClave!'`

## 4) Cargar la base de datos

```bash
bash /workspace/cargar_bd.sh
```

Carga DDL + mejoras + catálogos + roles + datos de prueba + SPs + subastas demo.
Al final imprime la verificación (debe decir ~38 tablas, 3 SPs, 5 Resultados_Intento).

## 5) Arrancar la app

```bash
bash /workspace/start_app.sh
```

URL pública (la compartes con los compañeros):
```
https://<POD-ID>-8501.proxy.runpod.net
```
El POD-ID está en la consola de RunPod (ej. `abc123xyz`).

### Credenciales iniciales
- **Admin:** `juniortuyuc5@gmail.com` / (el valor de `ADMIN_WEB_PASS`, default `Admin2025!`)
- Postores demo: `juan@test.com` / `hashejemplo`, `ana@test.com` / `hashejemplo`
- Los compañeros se **registran solos** (bcrypt) y quedan como postores.

## 6) Backup (antes de Terminate, o cada día del torneo)

```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -I -Q \
  "BACKUP DATABASE subastas_privadas TO DISK='/workspace/subastas_backup.bak'"
```
Descarga `subastas_backup.bak` a tu PC (scp o el gestor de archivos del pod).

### Restaurar (si levantas un pod nuevo)
```bash
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -I -Q \
  "RESTORE DATABASE subastas_privadas FROM DISK='/workspace/subastas_backup.bak' WITH REPLACE"
```

## 7) Operación diaria

| Tarea | Comando |
|---|---|
| Ver logs de la app | `tmux attach -t app` (Ctrl+B, D para salir) |
| Ver SQL Server | `tmux attach -t sql` |
| Reiniciar app | `tmux kill-session -t app; bash /workspace/start_app.sh` |
| Cerrar subastas vencidas | Desde 🛠️ Admin → 🔒 Cerrar subastas (o `EXEC sp_CerrarSubastasVencidas`) |

## Notas

- **Imágenes:** van a Cloudinary (ya configurado en el código), no al pod. Nada que instalar.
- **Anti-sniping y motor de pujas:** todo corre en SQL Server (SPs), la app solo llama.
- Si el pod se reinicia: `bash /workspace/start_app.sh` levanta SQL Server + app de nuevo.
