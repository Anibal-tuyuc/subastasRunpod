# Subida de imágenes — Cloudinary

La app sube imágenes desde el equipo del usuario al **CDN de Cloudinary**, y la BD
guarda la URL pública (`https://res.cloudinary.com/...`). El pod de RunPod no almacena
nada y las imágenes cargan en cualquier navegador (sin problemas de hotlinking).

## Configuración (ya hecha para este proyecto)

- **Cloud name:** `xbylnxck`
- **Upload preset (unsigned):** `subastas_preset`

Ambos valores ya vienen por defecto en `app.py`. Para sobreescribirlos usa las
variables de entorno `CLOUDINARY_CLOUD` y `CLOUDINARY_PRESET`.

> **Nota:** se evaluó Google Drive primero, pero las cuentas de servicio tienen
> cuota de almacenamiento = 0 desde 2023 (no pueden subir a carpetas personales),
> y el hotlinking de Drive (`uc?id=`) suele dar 403 en navegadores sin sesión.
> Cloudinary resuelve ambos problemas: subida unsigned sin llaves secretas y
> URLs de CDN que siempre cargan.

## En RunPod

No requiere nada extra: la subida es HTTP puro (`urllib`), sin librerías nuevas.
`requirements.txt` se mantiene en `streamlit` + `pyodbc`.

