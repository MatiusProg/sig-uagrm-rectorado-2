# Mapa de Infraestructura UAGRM — Oficinas Administrativas del Rectorado (2)

Proyecto de la materia **Sistemas de Información Geográfica (INF442-SA)** — Semestre 2026-2
Universidad Autónoma Gabriel René Moreno (UAGRM), Santa Cruz de la Sierra, Bolivia.

## Equipo

| # | Integrante |
|---|------------|
| 1 | Luis Mateo Hurtado Castro |
| 2 | Karen Paola Ortega Mancilla |
| 3 | Cristian Mamani Arcayne |
| 4 | Douglas Padilla Severiche |
| 5 | Yeison Choque Leon |

## Tema asignado

**Punto 2: OFICINAS ADMINISTRATIVAS DEL RECTORADO (2)**

> Este punto lo comparten tres grupos: Rectorado (1), (2) y (3). Hay que coordinar con los otros dos grupos para repartir oficinas y no duplicar levantamientos.

### Problema
Docentes, estudiantes y visitantes necesitan localizar ambientes y servicios de la UAGRM.

### Solución
Elaborar un plano geográfico y desarrollar una aplicación web que muestre la información geográfica de las oficinas asignadas.

## Requisitos del enunciado

- **Datos vectoriales**
  - Puntos: entradas, extintores y servicios.
  - Líneas: senderos y vías internas.
  - Polígonos: edificios, canchas y jardines.
- **Operaciones:** digitalización, edición de atributos, cálculo de superficies y clasificación de ambientes.
- **Producto final:** plano digital universitario con leyenda y tabla de infraestructura.
- **App web:**
  - Mostrar la información alfanumérica de los puntos al apuntar con el celular.
  - Mostrar el camino que debe recorrer el visitante desde un punto de inicio hasta un punto final (con extintores, centros médicos, etc.).

Enunciado completo: [`docs/enunciado-proyecto-sig-2026.pdf`](docs/enunciado-proyecto-sig-2026.pdf)

### Indicaciones del ingeniero
1. Levantar con **GPS** la información geográfica de lo que nos tocó en el sorteo.
2. Sobreponerla a la base. Si la referencia geográfica está correcta, no debería haber problemas.

## Herramientas

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| ArcGIS Desktop (ArcMap) | 10.8 | Digitalización, edición, cálculo de superficies, plano final |
| Supabase (PostgreSQL + PostGIS) | — | Base de datos espacial en la nube y API para la app web/móvil |
| PostgreSQL | 18 | Base local para pruebas (opcional) |
| Visual Studio Code | — | Desarrollo de la app web |

**Flujo de datos:** GPS → ArcMap 10.8 (digitalizar, editar, calcular áreas) → exportar shapefile → cargar a Supabase/PostGIS (`ogr2ogr` o `shp2pgsql`) → app web lee desde la API de Supabase.

**Sistema de referencia (lo exige el ingeniero): WGS 84 (EPSG:4326).** Para calcular superficies en m² en ArcMap se puede proyectar temporalmente a UTM 20S (EPSG:32720), pero la entrega va en WGS 84.

> En clase el ingeniero usa **ActualMap** (Windows) y **AspMap** (web), de VDS Technologies, con Visual Studio y VB.NET. Ver [`docs/notas-clases-y-sorteo.md`](docs/notas-clases-y-sorteo.md).

## Estructura del repositorio

```
├── arcgis/      # Documentos de mapa (.mxd), layouts y exportaciones
├── bd/          # Scripts SQL (esquema, carga, consultas)
├── datos/
│   ├── gps/     # Levantamientos GPS crudos (GPX, CSV, KML)
│   └── shp/     # Capas procesadas (shapefiles / geodatabase)
├── docs/        # Enunciado, informes, notas de clase
└── web/         # Aplicación web
```

## Cómo colaborar

1. Clonar: `git clone <url-del-repo>`
2. Antes de trabajar: `git pull`
3. Commits pequeños y descriptivos: `git add . && git commit -m "Agrega puntos GPS de planta baja" && git push`
4. **No** subir archivos `.lock` de ArcGIS ni videos o audios pesados. El `.gitignore` ya los excluye.
