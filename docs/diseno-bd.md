# Modelo de datos común — SIG UAGRM 2026-2

> **Propuesta del grupo Rectorado (2)** para los 22 grupos del proyecto de SIG (INF442-SA).
> **Versión 1.0 (19-11-2026).** Se cerró tabla por tabla. El SQL completo es [`supabase/migrations/20261119000000_modelo_datos.sql`](../supabase/migrations/20261119000000_modelo_datos.sql) y se probó en Supabase (PostgreSQL 17 + PostGIS 3.3 + pgRouting 3.4).

## Para qué sirve

El ingeniero pidió que los 22 grupos puedan integrarse y sugirió un esquema común. Esta propuesta **no pide compartir un repositorio ni una base**:

1. Cada grupo trabaja en **su propio repo y su propia base**. Nadie espera a nadie.
2. Todos usan **las mismas tablas, los mismos nombres y las mismas convenciones de código**. Para eso alcanza con copiar el SQL en su Supabase (o usarlo de guía en otra base PostgreSQL/PostGIS) y cargar sus shapefiles con los campos de la [plantilla](#plantilla-de-campos-para-arcmap).
3. Si algún día se juntan los datos (por ejemplo, si la DTIC publica la app), se cargan los 22 aportes en una sola base **sin choques**: cada fila tiene un `codigo` único y legible y un `grupo_id` que dice quién la levantó.

![Modelo de datos](diagramas/png/Modelo%20de%20Dominio%20-%20Base%20de%20datos%20SIG%20UAGRM.png)

*Diagrama generado en Enterprise Architect a partir de la base real con [`scripts/ea/ea-modelo-datos.ps1`](../scripts/ea/ea-modelo-datos.ps1). El modelo está en `docs/diagramas/SIG-UAGRM.eapx`.*

---

## Reglas comunes

| Regla | Detalle |
|---|---|
| Nombres | En español, `snake_case`, tablas en singular |
| Claves | `id` entero como clave primaria **más** un `codigo` de texto único y legible (`CAMPUS-ADM-DAEF`). El código es lo que se escribe en ArcMap y lo que permite juntar datos de varios grupos |
| Sistema de referencia | **WGS84 (EPSG:4326)** en todas las geometrías, en la columna `geom` |
| Polígonos | `MultiPolygon` (ArcMap a veces exporta polígonos de varias partes). Las líneas de `via` son `LineString` simple |
| Superficies y longitudes | `area_m2` y `longitud_m` **se calculan solas** con `geography` (metros reales). Nadie las escribe |
| Listas cortas y fijas | Texto con `check` (por ejemplo `uso`, `material`) |
| Listas que arman la leyenda | Un catálogo por capa (`tipo_ambiente`, `tipo_punto`, `tipo_area`, `tipo_via`) con **color e ícono** |
| Autoría | `grupo_id` en cada tabla de datos = número del punto del enunciado (1 a 22) |
| Auditoría | `creado_en` y `actualizado_en` en todas las tablas (`actualizado_en` se actualiza solo) |
| Verificación | `verificado_en` (fecha): vacío = todavía no se confirmó en campo |

### Convenciones de `codigo`

| Tabla | Convención | Ejemplos |
|---|---|---|
| `grupo` | Sigla del tema | `RECT2`, `DTIC`, `BIBLIO` |
| `sede` | Mayúsculas | `CAMPUS`, `CU`, `VALLECITO`, `MUSEO` |
| `edificio` | `M` + número si es un módulo numerado; si no, `<SEDE>-<SIGLA>` | `M236`, `CAMPUS-ADM` |
| `unidad` | Código del padre + `-` + sigla | `DAEF`, `DAEF-AF`, `FICCT-INF` |
| `ambiente` | `<EDIFICIO>-<SIGLA>`; al aire libre, `<SEDE>-<SIGLA>` | `CAMPUS-ADM-DAEF`, `M236-LAB3`, `CU-K01` |
| `punto_interes` | Edificio (o sede) + tipo abreviado + número | `CAMPUS-ADM-EXT01`, `CU-ENT03` |
| `area` | Sede + tipo abreviado + número | `CU-CANCHA01`, `CAMPUS-PARQ02` |
| `via` | Sede + `V` + número | `CU-V001` |

Solo mayúsculas, números y guiones. La base rechaza cualquier otro formato.

---

## Las tablas

### 0. `grupo`

Los 22 grupos del sorteo. **`id` es el número del punto del enunciado** (2 = Rectorado 2), así `grupo_id = 2` se entiende sin buscar. Ya viene cargada con los 22 temas. **No guarda integrantes**: la base es pública por la API; los integrantes van en el README de cada grupo.

| Columna | Tipo | Nota |
|---|---|---|
| `id` | smallint PK | 1 a 22 |
| `codigo` | text único | `RECT2` |
| `tema` | text | Tal cual el enunciado |
| `contacto` | text | Opcional: un canal del grupo, no datos personales |

### 1. `sede`

Campus, sedes de provincia e instalaciones sueltas en la ciudad. Responde "¿qué hay en el Vallecito?".

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `CAMPUS`, `CU`, `VALLECITO`, `MUSEO` |
| `nombre` | text | |
| `tipo` | text | `campus` / `sede_provincial` / `instalacion_externa` |
| `municipio` | text | Por defecto `Santa Cruz de la Sierra` |
| `direccion` | text | Opcional |
| `geom` | MultiPolygon | **Puede quedar vacía** hasta digitalizarla |
| `area_m2` | numeric | Se calcula sola |

**Datos iniciales:** `CAMPUS` (Campus Universitario), `CU` (Ciudad Universitaria; son dos sedes distintas aunque estén cerca), `VALLECITO` y `MUSEO` (Calle Junín #151). Cada grupo agrega las que le falten.

### 2. `edificio`

Módulos y bloques. Son los polígonos de edificios que pide el enunciado.

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `M236`, `CAMPUS-ADM` |
| `nombre` | text | `Edificio Administrativo` |
| `alias` | text[] | Otros nombres con los que se conoce: `{rectorado, "edificio central"}`. La búsqueda los usa |
| `sede_id` | → sede | Obligatorio |
| `uso` | text | `academico` / `administrativo` / `servicios` / `deportivo` / `mixto` |
| `pisos` | smallint ≥ 1 | Cantidad de plantas **contando la planta baja** (una sola planta = 1) |
| `ascensor` | boolean | Para calcular si se llega sin escaleras |
| `descripcion` | text | |
| `geom` | MultiPolygon | Puede quedar vacía al principio |
| `centro` | Point | Se calcula solo (punto **dentro** del polígono): etiqueta del mapa y destino del punto 21 |
| `area_m2` | numeric | Se calcula sola: el "cálculo de superficies" del enunciado |

### 3. `unidad`

El organigrama, **sin geometría** (una unidad puede tener oficinas en varios lugares; la ubicación la da `ambiente`). Responde "qué hace" y "quién es el responsable".

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `DAEF-AF` |
| `nombre`, `sigla` | text | |
| `alias` | text[] | `{"Recursos Humanos", RRHH}` |
| `tipo` | text | Ver la tabla de abajo |
| `padre_id` | → unidad | Vacío solo en las de primer nivel. Una unidad no puede ser su propio padre |
| `responsable`, `cargo_responsable` | text | El nombre del cargo público, como figura en la web oficial |
| `descripcion` | text | **Qué hace** |
| `servicios` | text[] | Lo que puede ir a hacer un visitante (`{"Pago de haberes"}`) |
| `correo`, `web` | text | Institucionales. Teléfono y horario van en `ambiente` |

| `tipo` | Ejemplos | Puntos del enunciado |
|---|---|---|
| `autoridad` | Rectorado, Vicerrectorado | 1–5 |
| `direccion` | DAEF, Planificación, DTIC | 1–5, 13 |
| `departamento` | Activo Fijo, Presupuesto | 1–5 |
| `organo_especial` | Corte Electoral, Defensoría, Guardería, Canal 11 | 6 |
| `gremio` | FUP, asociaciones de docentes | 7 |
| `postgrado` | Escuelas de postgrado | 8 |
| `facultad` | FICCT | 9 |
| `carrera` | Ingeniería Informática | 10 |
| `instituto` | Acreditación, extensión, investigación | 11, 12 |
| `centro` | Centros internos, CPD | 13, 16 |

Los laboratorios, bibliotecas, kioscos, canchas, etc. (puntos 14 a 20) **no son unidades**: son lugares y van en `ambiente`, `punto_interes` o `area`.

### 4. Catálogos de la leyenda: `tipo_ambiente`, `tipo_punto`, `tipo_area`, `tipo_via`

Los cuatro tienen la misma estructura: `codigo`, `nombre`, `categoria`, `color` (`#RRGGBB`), `icono`, `orden`, `descripcion`. **Cada categoría tiene un solo color**, así la leyenda queda corta. La vista `v_leyenda` los junta para la app.

| Capa | Categoría | Color | Tipos |
|---|---|---|---|
| ambiente | `administrativo` | `#1F6FEB` azul | `OFICINA`, `SECRETARIA`, `CAJA` |
| ambiente | `academico` | `#8250DF` violeta | `AULA`, `LABORATORIO`, `BIBLIOTECA`, `AUDITORIO` |
| ambiente | `investigacion_extension` | `#CF222E` rojo | `INVESTIGACION`, `EXTENSION`, `CENTRO_INTERNO` |
| ambiente | `tecnologia` | `#2DA44E` verde | `CPD`, `SALA_COMPUTO` |
| ambiente | `servicios` | `#BC4C00` naranja | `KIOSCO`, `FOTOCOPIADORA`, `COMEDOR`, `GUARDERIA` |
| ambiente | `salud_seguridad` | `#DB2777` magenta | `CONSULTORIO`, `ENFERMERIA` |
| punto_interes | `acceso` | `#24292F` negro | `ENTRADA`, `RAMPA`, `GRADAS` |
| punto_interes | `seguridad` | `#D1242F` rojo | `EXTINTOR`, `BOTIQUIN`, `SALIDA_EMERGENCIA`, `PUNTO_ENCUENTRO` |
| punto_interes | `servicios_basicos` | `#0969DA` azul | `SANITARIO`, `BEBEDERO` |
| area | `deportivo` | `#1A7F37` verde oscuro | `CANCHA_FUTBOL`, `CANCHA_MULTIPLE`, `PISTA_ATLETISMO`, `PISCINA` |
| area | `area_verde` | `#82C91E` verde claro | `JARDIN`, `AREA_VERDE`, `PLAZA` |
| area | `estacionamiento` | `#8C959F` gris | `PARQUEO` |
| via | `peatonal` | `#A0522D` marrón | `SENDERO`, `ACERA`, `PASILLO_TECHADO` |
| via | `vehicular` | `#444C56` gris oscuro | `VIA_INTERNA`, `CALLE` |

Los coliseos y gimnasios techados son **edificios**, no áreas.

### 5. `ambiente` — la tabla principal

Cada lugar concreto que alguien busca: una oficina, un laboratorio, una biblioteca, un kiosco. **La mayoría de los grupos carga casi todo aquí.**

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `CAMPUS-ADM-DAEF` |
| `nombre` | text | |
| `alias` | text[] | |
| `tipo_ambiente_id` | → tipo_ambiente | Obligatorio. Da color e ícono |
| `unidad_id` | → unidad | Opcional (vacío para un kiosco particular) |
| `edificio_id` | → edificio | Opcional (vacío si está al aire libre) |
| `sede_id` | → sede | **Se completa sola** con la del edificio |
| `piso` | smallint | **0 = planta baja**, 1 = primer piso, −1 = sótano |
| `referencia` | text | "Subiendo la escalera, segunda puerta a la izquierda". Varias oficinas caen casi en el mismo punto: esto es lo que ayuda a encontrarlas |
| `encargado` | text | Para laboratorios y CPD |
| `telefono`, `horario` | text | Texto libre: `"3-355-5555 int. 120"`, `"Lun–Vie 08:00–12:00 y 14:30–18:30"` |
| `servicios` | text[] | Lo propio de este lugar (para un kiosco, lo que ofrece) |
| `descripcion` | text | |
| `verificado_en` | date | Vacío = no se verificó en campo |
| `geom` | Point | **Obligatorio** |

### 6. `punto_interes`

Elementos de infraestructura: entradas, extintores, botiquines, sanitarios, bebederos. **Regla para elegir:** si es un lugar al que **vas a hacer algo** (tiene nombre, responsable u horario) va en `ambiente`; si es un **elemento de infraestructura**, va aquí. Por eso los sanitarios van aquí y los kioscos en `ambiente`.

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `CAMPUS-ADM-EXT01` |
| `tipo_punto_id` | → tipo_punto | Obligatorio |
| `nombre` | text | Opcional (las entradas sí lo llevan) |
| `edificio_id`, `sede_id`, `piso` | | Igual que en `ambiente` |
| `accesible` | boolean | **El elemento en sí** está adaptado (sanitario con barras, rampa, entrada sin escalones) |
| `nota` | text | |
| `extintor_agente` | text | Solo extintores, opcional: `PQS`, `CO2`, `AGUA`, `ESPUMA`, `K` |
| `extintor_kg` | numeric | Opcional |
| `extintor_vence` | date | Opcional. Permite consultar "extintores vencidos" |
| `verificado_en`, `geom` (Point, obligatorio) | | |

**Accesibilidad: dos preguntas distintas.** `accesible` dice si el elemento está adaptado. Si **se puede llegar** sin escaleras lo calculan las vistas `v_ambiente` y `v_punto_interes` (`llegada_sin_escaleras`): sí si está en planta baja o si el edificio tiene ascensor. Un sanitario adaptado en un 2do piso sin ascensor sale "adaptado, pero sin acceso sin escaleras".

### 7. `area`

Canchas, jardines, parqueos (polígonos).

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `CU-CANCHA01` |
| `tipo_area_id` | → tipo_area | Obligatorio |
| `nombre` | text | Opcional |
| `sede_id` | → sede | **Se completa sola** por ubicación |
| `unidad_id` | → unidad | Opcional: si pertenece a una facultad |
| `material` | text | Opcional: `cesped_natural`, `cesped_sintetico`, `cemento`, `tierra`, `pavimento`, `ripio` |
| `capacidad` | smallint | Opcional: espacios de un parqueo |
| `acceso` | text | `publico` (por defecto) / `restringido` |
| `nota` | text | `"Solo docentes"` |
| `geom` | MultiPolygon | Obligatorio y válido (que no se cruce consigo mismo) |
| `area_m2` | numeric | Se calcula sola |

### 8. `via` y `via_nodo`

Senderos y vías internas. Además de dibujarse, **forman la red de rutas** del punto 22.

| Columna | Tipo | Nota |
|---|---|---|
| `codigo` | text único | `CU-V001` |
| `tipo_via_id` | → tipo_via | Obligatorio |
| `nombre` | text | Opcional |
| `sede_id` | → sede | Se completa sola por ubicación |
| `superficie` | text | Opcional: `asfalto`, `cemento`, `adoquin`, `tierra`, `ripio` (el ejemplo de renderizado por categoría de la clase 2) |
| `techado` | boolean | Opcional |
| `accesible` | boolean | `false` si tiene gradas: se excluye de las rutas para silla de ruedas |
| `geom` | LineString | Un solo tramo por fila |
| `longitud_m` | numeric | Se calcula sola: es el "costo" de la ruta |
| `origen`, `destino` | → via_nodo | **Los arma la base**, no se cargan |

`via_nodo` guarda los nodos de la red. Se rehace sola cada vez que cambia una vía.

**Reglas de digitalización (sin esto no hay rutas):**
1. **Snapping activado**: las líneas que se juntan terminan **exactamente** en el mismo punto.
2. **Cortar la línea en cada cruce**: dos senderos que se cruzan son cuatro tramos.
3. **Cada `ENTRADA` toca un sendero.**

Cada grupo dibuja los senderos **de su zona** (desde la entrada de la sede hasta sus edificios). La ruta funciona donde haya red; si se juntan las capas de todos, la red se completa sola.

### 9. `foto`

Fotos de la puerta, la fachada o el interior, guardadas en el bucket público `fotos` de Supabase Storage.

| Columna | Tipo | Nota |
|---|---|---|
| `edificio_id` / `ambiente_id` / `punto_interes_id` / `area_id` | FK | **Se llena exactamente una** |
| `ruta` | text único | `<GRUPO>/<CODIGO del elemento>/<archivo>`: `RECT2/CAMPUS-ADM-DAEF/puerta.jpg` |
| `tipo` | text | `fachada` / `puerta` / `interior` / `referencia` |
| `principal` | boolean | La que se muestra primero. Como máximo una por elemento |
| `descripcion`, `tomada_en` | | Opcionales |

---

## Reglas automáticas de la base

| Regla | Qué hace |
|---|---|
| Sede automática | En `ambiente` y `punto_interes`, la sede sale del edificio; si no hay edificio, de la sede cuyo polígono contiene el punto. En `area` y `via`, por ubicación. Si se indica una sede que no coincide con la del edificio, se rechaza |
| Piso válido | No puede ser mayor que el último piso del edificio (`pisos − 1`) |
| Tolerancia GPS | Un punto hasta **10 m** fuera de su edificio se acepta (aparece en `v_ambiente_fuera_de_edificio`). A más de 10 m se **rechaza** con un mensaje que dice la distancia |
| Red de rutas | Al cargar o cambiar vías, `armar_red()` rehace los nodos sola |
| Geometrías válidas | Los polígonos de `sede`, `edificio` y `area` deben ser válidos |
| Fotos | Exactamente un dueño y como máximo una principal por elemento |

## Vistas y funciones (para la app)

| Nombre | Para qué |
|---|---|
| `v_leyenda` | La leyenda completa: capa, categoría, tipo, color, ícono |
| `v_ambiente`, `v_punto_interes` | Los datos listos para el mapa (tipo, color, unidad, edificio, sede y `llegada_sin_escaleras`) |
| `buscar(texto)` | "¿Dónde queda…?": busca en nombre, alias, sigla y servicios (sin importar tildes) y devuelve el texto **y** la coordenada para marcarla |
| `ruta(o_lon, o_lat, d_lon, d_lat, solo_accesible, radio_m)` | Punto 22: ruta más corta (Dijkstra, pgRouting) y los extintores, botiquines, etc. a menos de `radio_m` metros |
| `v_ambiente_fuera_de_edificio` | Control: puntos aceptados pero fuera del polígono |
| `v_via_desconectada` | Control: tramos sueltos |
| `v_entrada_sin_via` | Control: entradas a más de 2 m de un sendero |

Las consultas espaciales del ejemplo del ingeniero salen directo de estas tablas, por ejemplo:

```sql
-- ¿Qué oficinas administrativas hay en el Vallecito?
select a.codigo, a.nombre from v_ambiente a where a.sede = 'VALLECITO' and a.categoria = 'administrativo';

-- ¿Qué kioscos hay dentro del polígono de un edificio o una sede?
select a.nombre from ambiente a join tipo_ambiente t on t.id = a.tipo_ambiente_id, sede s
where t.codigo = 'KIOSCO' and s.codigo = 'CU' and st_contains(s.geom, a.geom);
```

## Seguridad

- **Cualquiera lee** (la app es pública). **Solo usuarios con sesión escriben** (RLS en todas las tablas).
- En Supabase Auth hay que **desactivar el registro público** y crear las cuentas del equipo por invitación.
- Fotos: el bucket `fotos` es de lectura pública; subir y borrar requiere sesión.

---

## Plantilla de campos para ArcMap

Los shapefiles solo aceptan nombres de campo de **hasta 10 caracteres**. En ArcMap se usan estos nombres y **se escriben códigos, no ids** (`TIPO = OFICINA`, `EDIFICIO = CAMPUS-ADM`); el ETL los convierte. Las listas (`ALIAS`, `SERVICIOS`) se separan con `;`. Los booleanos van como `S` / `N`. Sistema de coordenadas del shapefile: **GCS_WGS_1984**.

| Capa (geometría) | Campos |
|---|---|
| `sede` (polígono) | `CODIGO`, `NOMBRE`, `TIPO`, `MUNICIPIO`, `DIRECCION`, `GRUPO` |
| `edificio` (polígono) | `CODIGO`, `NOMBRE`, `ALIAS`, `SEDE`, `USO`, `PISOS`, `ASCENSOR`, `DESCRIP`, `GRUPO` |
| `ambiente` (punto) | `CODIGO`, `NOMBRE`, `ALIAS`, `TIPO`, `UNIDAD`, `EDIFICIO`, `SEDE`, `PISO`, `REFERENCIA`, `ENCARGADO`, `TELEFONO`, `HORARIO`, `SERVICIOS`, `DESCRIP`, `VERIFICADO`, `GRUPO` |
| `punto_interes` (punto) | `CODIGO`, `TIPO`, `NOMBRE`, `EDIFICIO`, `SEDE`, `PISO`, `ACCESIBLE`, `NOTA`, `EXT_AGENTE`, `EXT_KG`, `EXT_VENCE`, `VERIFICADO`, `GRUPO` |
| `area` (polígono) | `CODIGO`, `TIPO`, `NOMBRE`, `SEDE`, `UNIDAD`, `MATERIAL`, `CAPACIDAD`, `ACCESO`, `NOTA`, `VERIFICADO`, `GRUPO` |
| `via` (línea) | `CODIGO`, `TIPO`, `NOMBRE`, `SEDE`, `SUPERFICIE`, `TECHADO`, `ACCESIBLE`, `VERIFICADO`, `GRUPO` |
| `unidad` (sin geometría: Excel o CSV) | `CODIGO`, `NOMBRE`, `SIGLA`, `ALIAS`, `TIPO`, `PADRE`, `RESPONSABL`, `CARGO`, `DESCRIP`, `SERVICIOS`, `CORREO`, `WEB`, `GRUPO` |

`SEDE` se puede dejar vacío cuando hay `EDIFICIO`: la base lo completa.

## Tecnología recomendada

El ingeniero prefiere que los 22 grupos usen la misma tecnología, para poder integrar. Esta es la que usa el grupo Rectorado (2). **Lo único imprescindible para integrar es la base de datos**: si un grupo usa otro lenguaje para su app, igual puede respetar el modelo.

| Parte | Tecnología | Por qué |
|---|---|---|
| Levantamiento en campo | GPS del celular con **SW Maps** (exporta KML o Shapefile) | Gratis y guarda en WGS84 |
| Digitalización y plano | **ArcGIS Desktop 10.8 (ArcMap)** | Es el de la materia: leyenda, áreas y plano final |
| Base de datos | **PostgreSQL + PostGIS en Supabase** (plan gratis) | Base espacial en la nube, con API, inicio de sesión y almacenamiento de fotos incluidos |
| Rutas (punto 22) | **pgRouting** | Viene incluido en Supabase |
| Aplicación web | **React + Vite + TypeScript**, instalable en el celular (PWA) | Una sola app para PC y celular, con acceso al GPS y la brújula (punto 21) |
| Mapa en la web | **Leaflet** o **MapLibre GL** | Libres y gratis. Leen los datos de Supabase en GeoJSON |
| Publicación | **Cloudflare Pages** (o Vercel / Netlify) | Gratis, con HTTPS (el GPS del celular lo exige) |
| Código | **GitHub** | Versiones y trabajo en equipo |

## Cómo trabajar cada grupo, paso a paso

1. **Delimitar lo que les toca.** Listar las unidades y los lugares de su punto. Si aparece algo que no está en la lista, lo levanta el grupo al que le toca el edificio donde está, y avisa a los demás.
2. **Levantar en campo.** Con el GPS en WGS84, tomar un punto por lugar (en la puerta), la foto de la puerta y la de la fachada, y la ficha: nombre, unidad, responsable, piso, referencia para encontrarlo, horario, teléfono y servicios.
3. **Digitalizar en ArcMap** con los nombres de campo de la plantilla, en GCS_WGS_1984, con las convenciones de `codigo` y su número en `GRUPO`. Los senderos, con las tres reglas de la red.
4. **Crear su base:** un proyecto propio en Supabase. En el **SQL Editor**, ejecutar primero `create extension if not exists postgis with schema extensions;` y después el SQL del modelo completo.
5. **Cargar los datos:** subir los shapefiles a una tabla de paso (por ejemplo con QGIS o con `ogr2ogr` de GDAL) y pasarlos a las tablas del modelo convirtiendo los códigos en ids.
6. **Hacer su app** leyendo las vistas y funciones del modelo (`v_ambiente`, `v_leyenda`, `buscar`, `ruta`) con la librería `supabase-js`.
7. **Cuidar las claves:** la *anon key* de Supabase es pública por diseño; la contraseña de la base y la clave *service_role* **nunca** se comparten ni se suben a GitHub. En *Authentication* hay que **desactivar el registro público**: si no, cualquiera podría crearse una cuenta y modificar los datos.

## Coordinación entre grupos

- **El modelo es común; cada app es de su grupo.** Nadie necesita acceso al repositorio ni a la base de otro grupo.
- **Para intercambiar datos** (por ejemplo, entre grupos que comparten un edificio), se pasan **shapefiles o CSV con los campos de la plantilla**. Nunca contraseñas ni claves. Como cada fila lleva su `grupo_id`, el mérito queda siempre de quien la levantó.
- **Cambios al modelo:** si a un grupo le falta algo, que lo proponga al grupo Rectorado (2) antes de agregar columnas. Si el cambio sirve a todos, sale una versión nueva de este documento, y así nadie queda con un modelo distinto.
- **Capas base:** cuando estén listos, el grupo Rectorado (2) compartirá sus polígonos de sedes y edificios como capa base opcional. Quien prefiera dibujar los suyos, que use las mismas convenciones de `codigo`.

## Pendiente de verificar en campo

- Límites y municipio exacto de cada sede (el Vallecito podría no estar en el municipio de Santa Cruz de la Sierra).
- Dirección del Campus Universitario y de la Ciudad Universitaria.
