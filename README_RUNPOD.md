# Despliegue en RunPod (CPU Pod) -> SQL Server en VM universidad

## Arquitectura

```
30 usuarios -> https://<pod-id>-8501.proxy.runpod.net
                    |
            RunPod CPU Pod (Streamlit, ~$0.02-0.05/hr)
                    |  TCP 1433 (ODBC)
                    v
            VM Universidad (SQL Server 2022)
```

## Paso 1: Diagnostico de la VM (via RDP, SIN ser admin de Azure)

1. Entra a la VM por Escritorio Remoto.
2. Copia `sql/diagnostico_vm.ps1` a la VM y ejecutalo como Administrador
   (click derecho -> Ejecutar con PowerShell).
3. El script reporta: IP publica, si SQL Server escucha en 1433, firewall
   de Windows, autenticacion mixta, y si existe la BD.
4. Desde tu PC corre:

   ```powershell
   Test-NetConnection -ComputerName <IP_PUBLICA> -Port 1433
   ```

   - `TcpTestSucceeded: True`  -> arquitectura viable, sigue al Paso 2.
   - `False` -> el NSG de la universidad bloquea 1433. Opciones:
     a) Pedir que abran 1433 (o el puerto que sea).
     b) Cambiar SQL Server a un puerto ya abierto (80/443/8080).
     c) Tunel inverso (cloudflared) - ver Paso 4.

## Paso 2: Crear el CPU Pod en RunPod

1. RunPod Console -> Pods -> Deploy.
2. Template: **RunPod Pytorch 2.x** (cualquier imagen con Python 3.10+).
3. Tipo: **CPU Pod** (ej. 2 vCPU / 8 GB RAM es de sobra para 30 usuarios).
4. En "Expose HTTP Ports": agrega `8501`.
5. Variables de entorno del pod:
   - `DB_SERVER=<IP_PUBLICA_VM>,1433`
   - `DB_NAME=subastas_privadas`
   - `DB_USER=app_subastas`
   - `DB_PASS=<password>`
6. Deploy. RunPod te da una URL tipo:
   `https://<pod-id>-8501.proxy.runpod.net`

## Paso 3: Instalar y correr la app en el pod

Conectate por SSH o Web Terminal del pod:

```bash
apt-get update && apt-get install -y curl gnupg unixodbc
# Driver ODBC 18 para SQL Server (Debian/Ubuntu)
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
    > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql18

pip install streamlit pyodbc

# Subir app.py (git clone, scp, o pegar en el editor web)
cd /workspace
streamlit run app.py --server.address 0.0.0.0 --server.port 8501 \
    --server.headless true
```

Para que sobreviva reinicios de terminal: usa `tmux` o `nohup`.

## Paso 4 (Plan B): Si el NSG bloquea TODO trafico entrante a la VM

Tunel inverso con cloudflared — la conexion sale DESDE la VM, asi que el
NSG no lo bloquea (solo bloquea entrantes):

1. En la VM (RDP): descarga cloudflared.exe y corre:

   ```
   cloudflared access tcp --hostname sql.tudominio.com --url localhost:1433
   ```
   o un tunel rapido sin dominio:
   ```
   cloudflared tunnel --url tcp://localhost:1433
   ```

2. Cloudflare te da un hostname publico. En el pod, DB_SERVER apunta a ese.
3. Costo: $0 (Cloudflare Tunnel es gratis).

Alternativa sin cloudflared: `ssh -R` desde la VM hacia el pod de RunPod
(el pod tiene IP publica y SSH abierto):

```
ssh -R 1433:localhost:1433 root@<ip-pod-runpod> -p <puerto-ssh-pod>
```

Y en el pod DB_SERVER=localhost,1433. Simple y funciona.

## Costos estimados RunPod

| Recurso | Costo aprox |
|---|---|
| CPU Pod 2vCPU/8GB | $0.03-0.05/hora |
| Clase de 3 horas x 4 sabados | ~$0.60 total |
| 30 usuarios concurrentes | Sin costo extra |

Apaga el pod cuando no lo uses para no gastar saldo.
