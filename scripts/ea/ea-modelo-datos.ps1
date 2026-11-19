param(
    # Borra el paquete y lo genera de nuevo.
    [switch]$Rehacer,
    [string]$Modelo  = (Join-Path $PSScriptRoot '..\..\docs\diagramas\SIG-UAGRM.eapx'),
    # El esquema real, volcado de la base con scripts/ea/esquema.sql.
    [string]$Esquema = (Join-Path $PSScriptRoot '..\..\docs\diagramas\esquema.json'),
    [string]$Png     = (Join-Path $PSScriptRoot '..\..\docs\diagramas\png\Modelo de datos - SIG UAGRM.png'),
    # Si crear EA por COM falla (CO_E_SERVER_EXEC_FAILURE), abrir EA SIN proyecto y usar esto.
    [switch]$UsarEAAbierto
)

# =========================================================================
# Modelo de dominio (modelo de datos) del SIG UAGRM, en Enterprise Architect.
# Convenciones de GUIA-DE-DIAGRAMAS.md, sección 4.2:
#   - una clase por TABLA, nombre en MAYÚSCULAS, sin operaciones;
#   - columnas privadas, la PK primero, tipo de PostgreSQL en mayúsculas y
#     estereotipo PK / FK;
#   - asociaciones sin dirección, del padre al hijo, con un verbo en
#     MAYÚSCULAS que se lee PADRE VERBO HIJO, y cardinalidad en los dos
#     extremos: el padre 1 (0..1 si la FK admite NULL), el hijo 0..*
#     (0..1 si la FK es única).
#
# Las tablas, columnas, tipos y claves salen de la base (esquema.json), nunca
# a mano. Este script solo agrega lo que la base no dice: el verbo de cada
# relación, la disposición y las notas. Una FK sin verbo detiene el script.
#
# grupo_id va como columna FK en toda tabla de datos, pero la LÍNEA hacia
# GRUPO no se dibuja (serían 11 líneas cruzando el diagrama). La nota del
# diagrama lo explica.
#
# EA tiene que estar CERRADO (salvo con -UsarEAAbierto): si está abierto, su
# copia en memoria pisa lo que escribe el script, sin error.
# Este archivo se guarda en UTF-8 con BOM (si no, las tildes entran rotas).
# =========================================================================

$ErrorActionPreference = 'Stop'

$tablas = [IO.File]::ReadAllText([IO.Path]::GetFullPath($Esquema), [Text.Encoding]::UTF8) | ConvertFrom-Json
$Modelo = [IO.Path]::GetFullPath($Modelo)
$Png    = [IO.Path]::GetFullPath($Png)

if ($UsarEAAbierto) { $ea = [Runtime.InteropServices.Marshal]::GetActiveObject('EA.App').Repository }
else                { $ea = New-Object -ComObject EA.Repository }

function Cerrar-Modelo {
    try { $ea.CloseFile() } catch { }
    if (-not $UsarEAAbierto) { try { $ea.Exit() } catch { } }
    try { [Runtime.InteropServices.Marshal]::ReleaseComObject($ea) | Out-Null } catch { }
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
trap {
    Write-Host "ERROR: $($_.Exception.Message)  [línea $($_.InvocationInfo.ScriptLineNumber)]"
    Cerrar-Modelo
    exit 1
}

if (-not (Test-Path $Modelo)) {
    New-Item -ItemType Directory -Force (Split-Path $Modelo) | Out-Null
    if (-not $ea.CreateModel(0, $Modelo, 0)) { throw "No se pudo crear $Modelo" }
}
if (-not $ea.OpenFile($Modelo)) { throw "No se pudo abrir $Modelo" }

# ---- disposición: tres filas, y las líneas corren por los espacios entre filas ----
# Arriba lo que reparte (SEDE, UNIDAD), en el medio las capas del mapa y abajo
# sus catálogos y FOTO. Cada caja va en una columna (puede ser media columna).
$FILAS = @(
    @(@('unidad', 0.5), @('sede', 2), @('grupo', 4.6)),
    @(@('area', 0), @('ambiente', 1), @('edificio', 2), @('punto_interes', 3), @('via', 4)),
    @(@('tipo_area', 0), @('tipo_ambiente', 1), @('foto', 2), @('tipo_punto', 3), @('tipo_via', 4), @('via_nodo', 5))
)
$X0 = 40; $PASO_X = 380; $ANCHO_CAJA = 290; $Y_NOTA = -150; $HUECO_ARRIBA = 260; $HUECO_ABAJO = 240; $PASO_CANAL = 28
$ESTILO = 'BFol=0;LCol=0;BCol=15136253;font=Calibri;bold=0;black=0;italic=0;ul=0;charset=0;pitch=34;fontsz=90;'

# Las líneas que no son rectas: salen del padre, bajan (o suben) a un canal
# horizontal del hueco entre filas y entran al hijo en vertical. Así ninguna
# atraviesa una caja. canal: 'arriba' (k = 0 el más alto) o 'abajo' (k = 0 el
# más bajo); so / eo: corrimiento horizontal en la caja de salida y de llegada.
$RUTAS = @{
    'area.sede_id'           = @{ canal = 'arriba'; k = 0; so = -100; eo =  50 }
    'via.sede_id'            = @{ canal = 'arriba'; k = 1; so =  100; eo =   0 }
    'ambiente.sede_id'       = @{ canal = 'arriba'; k = 2; so =  -40; eo =  50 }
    'punto_interes.sede_id'  = @{ canal = 'arriba'; k = 3; so =   40; eo =   0 }
    'area.unidad_id'         = @{ canal = 'arriba'; k = 4; so =  -50; eo = -50 }
    'ambiente.unidad_id'     = @{ canal = 'arriba'; k = 5; so =   50; eo = -50 }
    'foto.area_id'           = @{ canal = 'abajo';  k = 0; so =   60; eo = -90 }
    'foto.ambiente_id'       = @{ canal = 'abajo';  k = 1; so =   60; eo = -45 }
    'foto.punto_interes_id'  = @{ canal = 'abajo';  k = 1; so =  -60; eo =  45 }
    'via.origen'             = @{ canal = 'abajo';  k = 2; so =  -40; eo =  60 }
    'via.destino'            = @{ canal = 'abajo';  k = 3; so =   40; eo = 100 }
}

# ---- el verbo de cada FK ("tabla.columna"), se lee PADRE VERBO HIJO ------
$VERBOS = @{
    'edificio.sede_id'               = 'CONTIENE'
    'unidad.padre_id'                = 'AGRUPA'
    'ambiente.tipo_ambiente_id'      = 'CLASIFICA'
    'ambiente.unidad_id'             = 'OCUPA'
    'ambiente.edificio_id'           = 'ALBERGA'
    'ambiente.sede_id'               = 'UBICA'
    'punto_interes.tipo_punto_id'    = 'CLASIFICA'
    'punto_interes.edificio_id'      = 'CUENTA_CON'
    'punto_interes.sede_id'          = 'UBICA'
    'area.tipo_area_id'              = 'CLASIFICA'
    'area.sede_id'                   = 'INCLUYE'
    'area.unidad_id'                 = 'ADMINISTRA'
    'via.tipo_via_id'                = 'CLASIFICA'
    'via.sede_id'                    = 'TIENE'
    'via.origen'                     = 'INICIA'
    'via.destino'                    = 'TERMINA'
    'foto.edificio_id'               = 'SE_MUESTRA_EN'
    'foto.ambiente_id'               = 'SE_MUESTRA_EN'
    'foto.punto_interes_id'          = 'SE_MUESTRA_EN'
    'foto.area_id'                   = 'SE_MUESTRA_EN'
}

$NOTAS = @{
    grupo         = 'Los 22 grupos del sorteo. id = número del punto del enunciado (2 = Rectorado 2). Sin integrantes: la base es pública.'
    sede          = 'Campus, sedes de provincia e instalaciones externas. geom vacía hasta digitalizarla. area_m2 se calcula sola.'
    edificio      = 'codigo: M236 si es módulo numerado; si no, <SEDE>-<SIGLA>. pisos cuenta la planta baja. centro y area_m2 se calculan solos.'
    unidad        = 'El organigrama, sin geometría. codigo = código del padre + sigla (DAEF-AF). padre_id nulo = unidad de primer nivel.'
    ambiente      = 'Cada lugar concreto. sede_id se completa con la del edificio. piso: 0 = planta baja. Se rechaza a más de 10 m del edificio.'
    punto_interes = 'Entradas, extintores, botiquines, sanitarios. accesible = el elemento está adaptado; llegar sin escaleras lo calcula la vista.'
    area          = 'Canchas, jardines, parqueos. sede_id se completa por ubicación. area_m2 se calcula sola.'
    via           = 'Red de senderos y vías (pgRouting). origen y destino los arma armar_red(), no se cargan a mano.'
    via_nodo      = 'Nodos de la red de rutas, generados por armar_red().'
    foto          = 'Exactamente una de las cuatro FK tiene valor. ruta = <GRUPO>/<CODIGO>/<archivo> en el bucket fotos.'
}

$NOTA_DIAGRAMA = 'Modelo de datos común del SIG UAGRM (propuesta del grupo Rectorado 2). Todas las geometrías en WGS84 (EPSG:4326). ' +
                 'grupo_id va como FK en toda tabla de datos; la relación es siempre GRUPO 0..1 — 0..* filas y su línea se omite para que el diagrama se lea.'

# =========================================================================

$porTabla = @{}; foreach ($t in $tablas) { $porTabla[$t.tabla] = $t }
$enFilas = @($FILAS | ForEach-Object { $_ } | ForEach-Object { $_[0] })
foreach ($t in $tablas) { if ($enFilas -notcontains $t.tabla) { throw "La tabla $($t.tabla) no tiene lugar en `$FILAS" } }

if ($ea.Models.Count -eq 0) { $r = $ea.Models.AddNew('SIG UAGRM', 'Package'); [void]$r.Update(); $ea.Models.Refresh() }
$raiz = $ea.Models.GetAt(0)
if ($raiz.Name -ne 'SIG UAGRM') { $raiz.Name = 'SIG UAGRM'; [void]$raiz.Update() }

$NOMBRE_PKG = 'Modelo de datos'
if ($Rehacer) {
    for ($i = $raiz.Packages.Count - 1; $i -ge 0; $i--) { if ($raiz.Packages.GetAt($i).Name -eq $NOMBRE_PKG) { $raiz.Packages.DeleteAt($i, $false) } }
    $raiz.Packages.Refresh()
}
$pkg = $null; foreach ($p in $raiz.Packages) { if ($p.Name -eq $NOMBRE_PKG) { $pkg = $p } }
if ($pkg) { Write-Output "  El paquete '$NOMBRE_PKG' ya existe: usar -Rehacer para generarlo de nuevo."; Cerrar-Modelo; return }
$pkg = $raiz.Packages.AddNew($NOMBRE_PKG, 'Package'); [void]$pkg.Update(); $raiz.Packages.Refresh()

$nomDia = 'Modelo de Dominio - Base de datos SIG UAGRM'
$dia = $pkg.Diagrams.AddNew($nomDia, 'Logical')
$dia.Notes = 'Una clase por tabla, sacada de la migración supabase/migrations/20261119000000_modelo_datos.sql.'
[void]$dia.Update(); $pkg.Diagrams.Refresh()

# ---- las clases ---------------------------------------------------------
function Alto($nombre) { 60 + $porTabla[$nombre].columnas.Count * 18 }
function MaxAlto($fila) { ($fila | ForEach-Object { Alto $_[0] } | Measure-Object -Maximum).Maximum }

$yArribaBase = $Y_NOTA - (MaxAlto $FILAS[0])           # las cajas de arriba se alinean por abajo
$yMedioTope  = $yArribaBase - $HUECO_ARRIBA             # las del medio, por arriba
$yMedioBase  = $yMedioTope - (MaxAlto $FILAS[1])
$yAbajoTope  = $yMedioBase - $HUECO_ABAJO               # las de abajo, por arriba

$id = @{}; $caja = @{}
for ($fi = 0; $fi -lt $FILAS.Count; $fi++) {
    foreach ($par in $FILAS[$fi]) {
        $nombre = $par[0]
        $t = $porTabla[$nombre]
        if (-not $t) { throw "No está la tabla $nombre en el esquema" }
        $e = $pkg.Elements.AddNew($nombre.ToUpper(), 'Class')
        if ($NOTAS[$nombre]) { $e.Notes = $NOTAS[$nombre] }
        [void]$e.Update()
        $pos = 0
        foreach ($c in $t.columnas) {
            $a = $e.Attributes.AddNew($c.col, $c.tipo)
            $a.Visibility = 'Private'; $a.Pos = $pos; $pos++
            $est = @(); if ($c.pk) { $est += 'PK' }; if ($c.fk) { $est += 'FK' }
            if ($est.Count) { $a.Stereotype = $est -join ',' }
            [void]$a.Update()
        }
        $e.Attributes.Refresh()
        $alto = Alto $nombre
        $x = [int]($X0 + $par[1] * $PASO_X)
        if ($fi -eq 0) { $tope = $yArribaBase + $alto } elseif ($fi -eq 1) { $tope = $yMedioTope } else { $tope = $yAbajoTope }
        $do = $dia.DiagramObjects.AddNew("l=$x;r=$($x + $ANCHO_CAJA);t=$tope;b=$($tope - $alto);", '')
        $do.ElementID = $e.ElementID; $do.Style = $ESTILO
        [void]$do.Update()
        $id[$nombre] = $e.ElementID
        $caja[$nombre] = @{ cx = $x + $ANCHO_CAJA / 2; t = $tope; b = $tope - $alto }
    }
}

# ---- las asociaciones ---------------------------------------------------
$n = 0; $conector = @{}
foreach ($t in $tablas) {
    foreach ($c in $t.columnas) {
        if (-not $c.fk) { continue }
        if ($c.fk -eq 'grupo') { continue }
        $clave = "$($t.tabla).$($c.col)"
        $verbo = $VERBOS[$clave]
        if (-not $verbo) { throw "La FK $clave no tiene verbo en `$VERBOS" }
        $con = $ea.GetElementByID($id[$c.fk]).Connectors.AddNew($verbo, 'Association')
        $con.SupplierID = $id[$t.tabla]
        $con.Direction = 'Unspecified'
        [void]$con.Update()
        $conector[$clave] = @{ id = $con.ConnectorID; padre = $c.fk; hijo = $t.tabla }
        $con.ClientEnd.Cardinality   = $(if ($c.nulo)  { '0..1' } else { '1' });    [void]$con.ClientEnd.Update()
        $con.SupplierEnd.Cardinality = $(if ($c.unico) { '0..1' } else { '0..*' }); [void]$con.SupplierEnd.Update()
        $n++
    }
}

# ---- la nota del diagrama -----------------------------------------------
$nota = $pkg.Elements.AddNew('', 'Note'); $nota.Notes = $NOTA_DIAGRAMA; [void]$nota.Update()
$do = $dia.DiagramObjects.AddNew("l=$X0;r=$($X0 + 4 * $PASO_X + $ANCHO_CAJA);t=-20;b=-110;", '')
$do.ElementID = $nota.ElementID; [void]$do.Update()
$dia.DiagramObjects.Refresh()

# ---- el recorrido de las líneas que no son rectas --------------------------
$dia = $ea.GetDiagramByID($dia.DiagramID)
foreach ($clave in $RUTAS.Keys) {
    $r = $RUTAS[$clave]; $k = $conector[$clave]
    if (-not $k) { throw "La ruta $clave no corresponde a ninguna FK" }
    if ($r.canal -eq 'arriba') { $y = $yArribaBase - 40 - $r.k * $PASO_CANAL } else { $y = $yAbajoTope + 40 + $r.k * $PASO_CANAL }
    $x1 = [int]($caja[$k.padre].cx + $r.so); $x2 = [int]($caja[$k.hijo].cx + $r.eo)
    $dl = $null
    foreach ($l in $dia.DiagramLinks) { if ($l.ConnectorID -eq $k.id) { $dl = $l } }
    if (-not $dl) { $dl = $dia.DiagramLinks.AddNew('', ''); $dl.ConnectorID = $k.id }
    $dl.Style = 'Mode=3;Color=-1;LWidth=0;'
    $dl.Path  = "${x1}:${y};${x2}:${y};"
    [void]$dl.Update()
}
$dia.DiagramLinks.Refresh()

# ---- PNG ----------------------------------------------------------------
New-Item -ItemType Directory -Force (Split-Path $Png) | Out-Null
$ea.GetProjectInterface().PutDiagramImageToFile($dia.DiagramGUID, $Png, 1) | Out-Null

Write-Output ("  {0}: {1} tablas, {2} asociaciones. PNG: {3}" -f $nomDia, $tablas.Count, $n, $Png)
Cerrar-Modelo
Write-Output 'OK'
