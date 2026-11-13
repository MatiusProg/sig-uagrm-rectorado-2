## ¿Qué cambia?
<!-- Una o dos líneas. -->

## Tipo
- [ ] Base de datos (migración en `supabase/migrations/`)
- [ ] Web (`web/`)
- [ ] Datos geográficos (`datos/`, `arcgis/`)
- [ ] Documentación

## Checklist
- [ ] El CI está en verde.
- [ ] Si toca la BD: es una migración **nueva** (no edité una ya fusionada) y la probé en `dev`.
- [ ] Las geometrías nuevas están en **WGS84 (EPSG:4326)**.
- [ ] No subí claves, `.env.local` ni archivos `.lock` de ArcGIS.
