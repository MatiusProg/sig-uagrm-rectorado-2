# Arquitectura

```
 Campo (GPS, SW Maps)          Escritorio                     Nube
 ───────────────────          ──────────                     ────
 puntos/tracks + fotos  ──▶  ArcMap 10.8                   Supabase (PostgreSQL 17 + PostGIS)
  (WGS84, Shapefile/KML)      digitalizar, editar,    ──▶    ├─ tablas del SIG (WGS84)
                              calcular áreas,  scripts/etl   ├─ funciones SQL: consultas espaciales (RPC)
                              plano con leyenda              ├─ RLS: lectura pública / edición con login
                                                             └─ Storage: fotos de oficinas
                                                                    ▲
                                                                    │ supabase-js (API REST)
                                                             Web / PWA (React + Vite + TS)
                                                             Cloudflare Pages · celular y PC
```

## Decisiones

| Tema | Decisión | Motivo |
|------|----------|--------|
| SIG de escritorio | ArcGIS Desktop 10.8 (ArcMap) | Es lo que se usa en la materia y lo que tenemos instalado |
| Sistema de referencia | WGS84 (EPSG:4326) | Lo exige el ingeniero y es el estándar de los mapas web. Las áreas se calculan con `geography` o proyectando a UTM 20S (EPSG:32720) |
| Base de datos | Supabase (PostgreSQL + PostGIS) | API lista, autenticación y Storage. Es gratis y sirve para web y móvil |
| Frontend | React + Vite + TypeScript, como PWA | Una sola app para PC y celular, con acceso a GPS y brújula (punto 21) |
| Mapa web | Por definir: Leaflet o MapLibre | Se decide junto con el diseño de capas |
| Hosting web | Cloudflare Pages | El equipo ya lo conoce. Gratis, con vistas previas por rama |
| Migraciones | Supabase CLI (`supabase/migrations/`) | Esquema versionado, reproducible y revisado en PR |
| CI/CD | GitHub Actions | `ci.yml` (lint, build, migraciones), `deploy.yml` (dev/prod), `keepalive.yml` |

## Ambientes

| Ambiente | Rama | Supabase | Web |
|----------|------|----------|-----|
| dev | `develop` | proyecto `sig-uagrm-dev` | `develop.<proyecto>.pages.dev` |
| prod | `main` | proyecto `sig-uagrm-prod` | `<proyecto>.pages.dev` |

## Configuración en GitHub (Settings → Environments)

**Secrets del repositorio** (comunes a todos los ambientes):
- `SUPABASE_ACCESS_TOKEN`: Supabase → Account → Access Tokens.
- `CLOUDFLARE_API_TOKEN`: Cloudflare → My Profile → API Tokens, con la plantilla *Edit Cloudflare Workers* o un permiso *Pages: Edit*.
- `CLOUDFLARE_ACCOUNT_ID`.

**Variable del repositorio:** `CF_PAGES_PROJECT`, el nombre del proyecto de Cloudflare Pages.

**Por ambiente (`dev` y `prod`):**
- Secret `SUPABASE_DB_PASSWORD`.
- Variables `SUPABASE_PROJECT_REF`, `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.

Mientras falten, los workflows de despliegue y keep-alive **no fallan**: muestran un aviso y no hacen nada.

## Estructura del repositorio

```
├── .github/          # CI/CD, plantilla de PR, CODEOWNERS
├── arcgis/           # .mxd, layouts, exportaciones del plano
├── datos/gps/        # levantamientos crudos (SW Maps)
├── datos/shp/        # capas procesadas en ArcMap
├── docs/             # enunciado, notas, arquitectura, diseño de BD
├── scripts/etl/      # carga de shapefiles a Supabase
├── supabase/         # config.toml, migrations/, tests/, seed.sql
└── web/              # app React + Vite + TS
```
