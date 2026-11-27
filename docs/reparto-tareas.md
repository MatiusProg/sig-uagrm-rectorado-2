# Reparto de tareas — Rectorado (2)

> **Grupo Rectorado (2)** · SIG INF442-SA · 2026-2
>
> **Acordado el 26-11-2026.** Presentación: **sábado 5 de diciembre, 08:00**.
>
> La forma de registrar en campo está en la [Guía de campo](guia-campo.md).

## Qué nos toca levantar

Solo el **Edificio Administrativo del Campus y sus alrededores**:

- Las oficinas del edificio: DAEF y sus 5 sub-unidades, Auditoría Interna, Desarrollo Humano y cualquier otra oficina que haya en el edificio.
- Lo que hay dentro y alrededor: entradas, gradas, rampas, extintores, botiquines, salidas de emergencia, baños y bebederos.
- Los senderos desde la entrada del Campus hasta el edificio, y alrededor de él.
- Las canchas, jardines y parqueos de alrededor, y los edificios vecinos (solo foto y datos).

## Quién hace qué

Todos hacen campo. Luis y Karen hacen menos, porque arman la base de datos, la app y el plano.

| Persona | Rol | Campo |
|---|---|---|
| **Cristian** | Interior: **planta baja** | Viernes y lunes |
| **Douglas** | Interior: **primer piso y superiores** | Viernes, sábado y lunes |
| **Yeison** | Exterior: entradas, puntos de seguridad y senderos | Viernes y sábado |
| **Luis** | Base de datos, carga de datos, rutas (punto 22) y coordinación | Primera hora del viernes |
| **Karen** | App web, dibujo en ArcMap y plano final | Sábado: canchas, jardines y parqueos |

### Cristian — interior, planta baja

- **Viernes 27:** todas las oficinas de la planta baja. Por cada una: el punto en SW Maps en la puerta, la foto de la puerta y la ficha (lo que se pregunta está en la [tabla de qué anotar](#qué-anotar-de-cada-cosa)). Además, los extintores, botiquines, baños y bebederos de la planta baja, y el **croquis** de la planta baja.
- **Sábado 28:** pasar las fichas del viernes a la planilla `fichas-oficinas.csv` (se abre con Excel; Luis la manda por WhatsApp) y devolvérsela a Luis.
- **Lunes 30:** volver a las oficinas que estaban cerradas o donde faltó algún dato.

### Douglas — interior, primer piso y superiores

- **Viernes 27:** lo mismo que Cristian, pero en el primer piso y los de arriba. La DAEF está en el **primer piso**, según la web. Además: anotar si el edificio tiene **ascensor**, contar los **pisos** (contando la planta baja) y registrar las gradas.
- **Sábado 28:** senderos con Yeison.
- **Lunes 30:** completar lo que faltó en los pisos de arriba.

### Yeison — exterior

- **Viernes 27:** todas las **entradas** del edificio, si tienen escalones o rampa, y los puntos de alrededor (extintores de pasillos, salidas de emergencia, punto de encuentro). También la **foto de la fachada** del Edificio Administrativo y de los edificios vecinos.
- **Sábado 28:** con Douglas, los **senderos**: desde la entrada del Campus hasta el edificio, y alrededor de él. Un tramo por línea, cortando en cada cruce.

### Luis — base de datos y coordinación

- **Jueves 26:** mandar la plantilla de SW Maps, esta guía y la planilla de fichas.
- **Viernes 27:** la primera hora en campo con todos, para revisar que registren bien. Probar antes el registro de senderos. Después, el script que carga lo de SW Maps a Supabase.
- **Sábado 28 a lunes 30:** recibir los proyectos de cada uno, revisar los códigos y cargar a la base de desarrollo. **Lunes 30, fecha límite** para que Rectorado (1) y (3) manden sus datos.
- **Martes 1 y miércoles 2:** rutas (punto 22) en la app y corrección de senderos en ArcMap (para que la red de rutas quede conectada).
- **Jueves 3:** congelar los datos y pasar a producción.

### Karen — app y plano

- **Sábado 28 (campo, una hora):** las canchas, jardines y parqueos cercanos al edificio. Foto, material del piso, si es de uso público o restringido y, en los parqueos, contar los espacios.
- **Viernes 27 y sábado 28:** el mapa de la app (capas, colores, leyenda, ventana con la información al tocar un punto) con datos de prueba. En ArcMap, dibujar los **edificios** y las **áreas** cercanas sobre la imagen satelital.
- **Martes 1 y miércoles 2:** buscador ("¿dónde queda…?"), consultas espaciales y punto 21 (apuntar con el celular).
- **Jueves 3 y viernes 4:** plano final en ArcMap con leyenda y tabla, y exportarlo a PDF. Luis lo revisa.

## Qué anotar de cada cosa

**No hace falta medir con cinta.** Las superficies y las longitudes las calcula la base de datos a partir del mapa. En campo solo hay que **contar, mirar y preguntar**.

| Lo que encuentras | Qué anotar |
|---|---|
| **Oficina** | Nombre exacto y sigla, unidad de la que depende, responsable y cargo, horario de atención, teléfono o interno, trámites o servicios, piso, cómo llegar (referencia). Foto de la puerta con el letrero |
| **Edificio** | Cómo lo llama la gente (otros nombres), cuántos pisos tiene **contando la planta baja**, si tiene ascensor. Foto de la fachada entera |
| **Entrada** | Nombre (principal, lateral, trasera). Si se entra sin escalones o con rampa: `ACCESIBLE = S` |
| **Rampa / gradas** | Dónde están y en qué piso |
| **Extintor** | Piso, agente (PQS, CO2, agua…), kilos y **fecha de vencimiento** de la etiqueta (como `2027-03`) |
| **Botiquín, salida de emergencia, punto de encuentro** | Piso y una nota de dónde está |
| **Baño** | Piso, de varones o de mujeres (en NOTA), si está adaptado (barras, puerta ancha): `ACCESIBLE = S` |
| **Bebedero** | Piso y si funciona (en NOTA) |
| **Sendero** | Superficie (cemento, adoquín, tierra…), si es techado, si tiene gradas (`ACCESIBLE = N`) |
| **Cancha, jardín, parqueo** | Foto, material del piso, si es de uso público o restringido. En el parqueo, **contar los espacios** |

## Decisiones

| Tema | Decisión |
|---|---|
| Alcance | Solo el Edificio Administrativo y sus alrededores. Por ahora no hacemos capa base para los otros grupos |
| App de campo | **SW Maps** en Android, con la plantilla `RECT2_Campo_v1` (en `datos/plantilla-swmaps/`). Todos usan los mismos campos |
| Puntos | Se toman **en la puerta**. Adentro el GPS falla, así que la ubicación exacta de cada oficina sale del **croquis** |
| Polígonos | Edificios, canchas, jardines y parqueos **no se dibujan en campo**: los dibujan Luis y Karen en ArcMap. En campo solo foto y datos |
| Códigos | En campo solo se escriben los de la lista de oficinas conocidas. El resto queda vacío y Luis lo asigna |
| Datos de cada día | Cada uno manda su proyecto de SW Maps por WhatsApp (**Share Project**) y no lo borra hasta que Luis confirme |
| Punto 22 | Ruta tipo Google Maps (desde un inicio hasta un destino), con pgRouting |
| Fichas | Se anotan en papel o en las notas del celular. Cristian las pasa a la planilla `fichas-oficinas.csv` (Excel) y se la manda a Luis. No usamos Google Sheets |

## Cronograma

| Día | Qué |
|---|---|
| Jue 26 | Reparto, plantilla y guía al grupo |
| **Vie 27** | **Campo interior** (oficinas abiertas). App: mapa con datos de prueba |
| **Sáb 28** | **Campo exterior** (senderos). Fichas a la planilla |
| **Lun 30** | Completar lo que faltó. Fecha límite para Rectorado (1) y (3) |
| Mar 1 – Mié 2 | Dibujo en ArcMap, carga a la base, consultas y rutas en la app |
| **Jue 3** | **Se congelan los datos.** Pase a producción |
| Vie 4 | Plano en PDF y ensayo de la presentación |
| **Sáb 5, 08:00** | **Presentación** |
