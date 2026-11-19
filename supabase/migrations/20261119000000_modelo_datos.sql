-- =============================================================================
-- Migración 1: modelo de datos común del SIG UAGRM
-- Propuesto por el grupo Rectorado (2) a los 22 grupos. Explicación tabla por
-- tabla en docs/diseno-bd.md.
--
-- Reglas comunes:
--   * Nombres en español, snake_case, tablas en singular.
--   * id entero + "codigo" de texto único y legible (sirve para recargar
--     shapefiles y para juntar datos de varios grupos sin choques).
--   * Geometría en la columna "geom", WGS84 (EPSG:4326). Polígonos MultiPolygon.
--   * area_m2 / longitud_m se calculan solas (geography = metros reales).
--   * grupo_id en cada tabla de datos: qué grupo levantó la fila.
--   * creado_en / actualizado_en en todas las tablas.
-- =============================================================================

create extension if not exists pgrouting with schema extensions;
create extension if not exists unaccent  with schema extensions;

set search_path = public, extensions;

-- -----------------------------------------------------------------------------
-- Función común: mantiene actualizado_en al día en cada UPDATE.
-- -----------------------------------------------------------------------------
create or replace function public.tocar_actualizado_en()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Dentro de otro trigger (p. ej. armar_red al rellenar origen/destino) no cuenta como edición.
  if pg_trigger_depth() > 1 then
    return new;
  end if;
  new.actualizado_en := now();
  return new;
end;
$$;

-- =============================================================================
-- 0. grupo: los 22 grupos del sorteo. id = número del punto del enunciado.
-- =============================================================================
create table public.grupo (
  id             smallint primary key check (id between 1 and 22),
  codigo         text not null unique check (codigo ~ '^[A-Z0-9]{2,10}$'),
  tema           text not null,
  contacto       text,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
comment on table public.grupo is 'Los 22 grupos del sorteo. id = número del punto del enunciado. Los integrantes NO se guardan aquí (la base es pública).';

-- =============================================================================
-- 1. sede: campus, sedes de provincia e instalaciones sueltas en la ciudad.
-- =============================================================================
create table public.sede (
  id             smallint generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9_]{2,20}$'),
  nombre         text not null,
  tipo           text not null check (tipo in ('campus', 'sede_provincial', 'instalacion_externa')),
  municipio      text default 'Santa Cruz de la Sierra',
  direccion      text,
  geom           geometry(MultiPolygon, 4326) check (geom is null or st_isvalid(geom)),
  area_m2        numeric(12,1) generated always as (round(st_area(geom::geography)::numeric, 1)) stored,
  grupo_id       smallint references public.grupo (id),
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
comment on table public.sede is 'Campus, sedes de provincia e instalaciones externas. geom puede quedar vacía hasta digitalizarla.';

-- =============================================================================
-- 2. edificio: módulos y bloques.
-- =============================================================================
create table public.edificio (
  id             integer generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  nombre         text not null,
  alias          text[] not null default '{}',
  sede_id        smallint not null references public.sede (id),
  uso            text check (uso in ('academico', 'administrativo', 'servicios', 'deportivo', 'mixto')),
  pisos          smallint check (pisos >= 1),
  ascensor       boolean,
  descripcion    text,
  geom           geometry(MultiPolygon, 4326) check (geom is null or st_isvalid(geom)),
  centro         geometry(Point, 4326) generated always as (st_pointonsurface(geom)) stored,
  area_m2        numeric(12,1) generated always as (round(st_area(geom::geography)::numeric, 1)) stored,
  grupo_id       smallint references public.grupo (id),
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
comment on table  public.edificio is 'Módulos y bloques. codigo: M + número si es módulo numerado (M236); si no, <SEDE>-<SIGLA> (CAMPUS-ADM).';
comment on column public.edificio.pisos is 'Cantidad de plantas, contando la planta baja. Un edificio de una sola planta tiene pisos = 1.';
comment on column public.edificio.centro is 'Punto dentro del polígono: etiqueta del mapa y destino del punto 21.';

-- =============================================================================
-- 3. unidad: el organigrama (sin geometría; la ubicación la da ambiente).
-- =============================================================================
create table public.unidad (
  id                integer generated always as identity primary key,
  codigo            text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  nombre            text not null,
  sigla             text,
  alias             text[] not null default '{}',
  tipo              text not null check (tipo in ('autoridad', 'direccion', 'departamento', 'organo_especial',
                                                  'gremio', 'postgrado', 'facultad', 'carrera', 'instituto', 'centro')),
  padre_id          integer references public.unidad (id),
  responsable       text,
  cargo_responsable text,
  descripcion       text,
  servicios         text[] not null default '{}',
  correo            text,
  web               text,
  grupo_id          smallint references public.grupo (id),
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now(),
  check (padre_id is null or padre_id <> id)
);
comment on table public.unidad is 'Organigrama. codigo = codigo del padre + "-" + sigla (DAEF-AF). Responsable como texto: cambia poco y no se consulta aparte.';

-- =============================================================================
-- Catálogos de la leyenda: uno por capa, misma estructura.
-- =============================================================================
create table public.tipo_ambiente (
  id             smallint generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9_]+$'),
  nombre         text not null,
  categoria      text not null check (categoria in ('administrativo', 'academico', 'investigacion_extension',
                                                    'tecnologia', 'servicios', 'salud_seguridad')),
  color          text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  icono          text,
  orden          smallint not null default 0,
  descripcion    text,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.tipo_punto (
  id             smallint generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9_]+$'),
  nombre         text not null,
  categoria      text not null check (categoria in ('acceso', 'seguridad', 'servicios_basicos')),
  color          text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  icono          text,
  orden          smallint not null default 0,
  descripcion    text,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.tipo_area (
  id             smallint generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9_]+$'),
  nombre         text not null,
  categoria      text not null check (categoria in ('deportivo', 'area_verde', 'estacionamiento')),
  color          text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  icono          text,
  orden          smallint not null default 0,
  descripcion    text,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table public.tipo_via (
  id             smallint generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9_]+$'),
  nombre         text not null,
  categoria      text not null check (categoria in ('peatonal', 'vehicular')),
  color          text not null check (color ~ '^#[0-9A-Fa-f]{6}$'),
  icono          text,
  orden          smallint not null default 0,
  descripcion    text,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- =============================================================================
-- 5. ambiente: cada lugar concreto (oficina, laboratorio, biblioteca, kiosco).
-- =============================================================================
create table public.ambiente (
  id               integer generated always as identity primary key,
  codigo           text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  nombre           text not null,
  alias            text[] not null default '{}',
  tipo_ambiente_id smallint not null references public.tipo_ambiente (id),
  unidad_id        integer references public.unidad (id),
  edificio_id      integer references public.edificio (id),
  sede_id          smallint not null references public.sede (id),
  piso             smallint check (piso between -3 and 30),
  referencia       text,
  encargado        text,
  telefono         text,
  horario          text,
  servicios        text[] not null default '{}',
  descripcion      text,
  verificado_en    date,
  geom             geometry(Point, 4326) not null,
  grupo_id         smallint references public.grupo (id),
  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now()
);
comment on table  public.ambiente is 'Cada lugar concreto que alguien busca. codigo: <EDIFICIO>-<SIGLA>, o <SEDE>-<SIGLA> si está al aire libre.';
comment on column public.ambiente.piso is '0 = planta baja, 1 = primer piso, -1 = sótano.';
comment on column public.ambiente.verificado_en is 'Vacío = todavía no se verificó en campo.';

-- =============================================================================
-- 6. punto_interes: entradas, extintores, botiquines, sanitarios…
-- =============================================================================
create table public.punto_interes (
  id                integer generated always as identity primary key,
  codigo            text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  tipo_punto_id     smallint not null references public.tipo_punto (id),
  nombre            text,
  edificio_id       integer references public.edificio (id),
  sede_id           smallint not null references public.sede (id),
  piso              smallint check (piso between -3 and 30),
  accesible         boolean,
  nota              text,
  extintor_agente   text check (extintor_agente in ('PQS', 'CO2', 'AGUA', 'ESPUMA', 'K')),
  extintor_kg       numeric(4,1) check (extintor_kg > 0),
  extintor_vence    date,
  verificado_en     date,
  geom              geometry(Point, 4326) not null,
  grupo_id          smallint references public.grupo (id),
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);
comment on column public.punto_interes.accesible is 'El elemento EN SÍ está adaptado (sanitario adaptado, rampa). Si se puede LLEGAR sin escaleras lo calcula v_punto_interes con el piso y edificio.ascensor.';
comment on column public.punto_interes.extintor_agente is 'Solo para extintores (opcional).';

-- =============================================================================
-- 7. area: canchas, jardines, parqueos.
-- =============================================================================
create table public.area (
  id             integer generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  tipo_area_id   smallint not null references public.tipo_area (id),
  nombre         text,
  sede_id        smallint references public.sede (id),
  unidad_id      integer references public.unidad (id),
  material       text check (material in ('cesped_natural', 'cesped_sintetico', 'cemento', 'tierra', 'pavimento', 'ripio')),
  capacidad      smallint check (capacidad >= 0),
  acceso         text not null default 'publico' check (acceso in ('publico', 'restringido')),
  nota           text,
  verificado_en  date,
  geom           geometry(MultiPolygon, 4326) not null check (st_isvalid(geom)),
  area_m2        numeric(12,1) generated always as (round(st_area(geom::geography)::numeric, 1)) stored,
  grupo_id       smallint references public.grupo (id),
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
comment on column public.area.sede_id is 'Se completa sola: la sede cuyo polígono contiene al área.';

-- =============================================================================
-- 8. via: senderos y vías internas. Forman la red de rutas (punto 22).
-- =============================================================================
create table public.via_nodo (
  id   integer generated always as identity primary key,
  geom geometry(Point, 4326) not null unique
);
comment on table public.via_nodo is 'Nodos de la red de rutas. Los arma armar_red(); no se cargan a mano.';

create table public.via (
  id             integer generated always as identity primary key,
  codigo         text not null unique check (codigo ~ '^[A-Z0-9]+(-[A-Z0-9]+)*$'),
  tipo_via_id    smallint not null references public.tipo_via (id),
  nombre         text,
  sede_id        smallint references public.sede (id),
  superficie     text check (superficie in ('asfalto', 'cemento', 'adoquin', 'tierra', 'ripio')),
  techado        boolean,
  accesible      boolean,
  verificado_en  date,
  geom           geometry(LineString, 4326) not null,
  longitud_m     numeric(10,1) generated always as (round(st_length(geom::geography)::numeric, 1)) stored,
  origen         integer references public.via_nodo (id) on delete set null,
  destino        integer references public.via_nodo (id) on delete set null,
  grupo_id       smallint references public.grupo (id),
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
comment on table  public.via is 'Senderos y vías. Reglas: snapping activado, cortar en cada cruce, cada ENTRADA toca un sendero.';
comment on column public.via.accesible is 'false si tiene gradas: se excluye de las rutas para silla de ruedas.';

-- =============================================================================
-- 9. foto: enlaces a Supabase Storage (bucket "fotos").
-- =============================================================================
create table public.foto (
  id               integer generated always as identity primary key,
  edificio_id      integer references public.edificio (id) on delete cascade,
  ambiente_id      integer references public.ambiente (id) on delete cascade,
  punto_interes_id integer references public.punto_interes (id) on delete cascade,
  area_id          integer references public.area (id) on delete cascade,
  ruta             text not null unique check (ruta ~ '^[A-Z0-9]+/[A-Z0-9-]+/[a-z0-9_.-]+\.(jpg|jpeg|png|webp)$'),
  tipo             text not null check (tipo in ('fachada', 'puerta', 'interior', 'referencia')),
  principal        boolean not null default false,
  descripcion      text,
  tomada_en        date,
  grupo_id         smallint references public.grupo (id),
  creado_en        timestamptz not null default now(),
  actualizado_en   timestamptz not null default now(),
  check (num_nonnulls(edificio_id, ambiente_id, punto_interes_id, area_id) = 1)
);
comment on column public.foto.ruta is 'Ruta en el bucket "fotos": <GRUPO>/<CODIGO del elemento>/<archivo> (RECT2/CAMPUS-ADM-DAEF/puerta.jpg).';

create unique index foto_principal_edificio_uq on public.foto (edificio_id)      where principal and edificio_id is not null;
create unique index foto_principal_ambiente_uq on public.foto (ambiente_id)      where principal and ambiente_id is not null;
create unique index foto_principal_punto_uq    on public.foto (punto_interes_id) where principal and punto_interes_id is not null;
create unique index foto_principal_area_uq     on public.foto (area_id)          where principal and area_id is not null;

-- =============================================================================
-- Índices: espaciales (GiST) y de claves foráneas.
-- =============================================================================
create index sede_geom_idx          on public.sede          using gist (geom);
create index edificio_geom_idx      on public.edificio      using gist (geom);
create index ambiente_geom_idx      on public.ambiente      using gist (geom);
create index punto_interes_geom_idx on public.punto_interes using gist (geom);
create index area_geom_idx          on public.area          using gist (geom);
create index via_geom_idx           on public.via           using gist (geom);
create index via_nodo_geom_idx      on public.via_nodo      using gist (geom);

create index edificio_sede_idx        on public.edificio (sede_id);
create index unidad_padre_idx         on public.unidad (padre_id);
create index ambiente_tipo_idx        on public.ambiente (tipo_ambiente_id);
create index ambiente_unidad_idx      on public.ambiente (unidad_id);
create index ambiente_edificio_idx    on public.ambiente (edificio_id);
create index ambiente_sede_idx        on public.ambiente (sede_id);
create index punto_interes_tipo_idx   on public.punto_interes (tipo_punto_id);
create index punto_interes_edif_idx   on public.punto_interes (edificio_id);
create index punto_interes_sede_idx   on public.punto_interes (sede_id);
create index area_tipo_idx            on public.area (tipo_area_id);
create index area_sede_idx            on public.area (sede_id);
create index area_unidad_idx          on public.area (unidad_id);
create index via_tipo_idx             on public.via (tipo_via_id);
create index via_sede_idx             on public.via (sede_id);
create index via_origen_idx           on public.via (origen);
create index via_destino_idx          on public.via (destino);
create index foto_edificio_idx        on public.foto (edificio_id);
create index foto_ambiente_idx        on public.foto (ambiente_id);
create index foto_punto_idx           on public.foto (punto_interes_id);
create index foto_area_idx            on public.foto (area_id);

-- =============================================================================
-- Reglas automáticas (triggers)
-- =============================================================================

-- ambiente y punto_interes: sede desde el edificio, piso válido y tolerancia GPS de 10 m.
create or replace function public.completar_ubicacion()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
declare
  e         public.edificio%rowtype;
  distancia double precision;
begin
  -- Si cambió de edificio y no se tocó la sede, la sede se recalcula.
  if tg_op = 'UPDATE' and new.edificio_id is distinct from old.edificio_id and new.sede_id = old.sede_id then
    new.sede_id := null;
  end if;

  if new.edificio_id is not null then
    select * into e from public.edificio where id = new.edificio_id;

    if new.sede_id is null then
      new.sede_id := e.sede_id;
    elsif new.sede_id <> e.sede_id then
      raise exception 'La sede no coincide con la del edificio %', e.codigo
        using hint = 'Deje sede_id vacío: se completa con la sede del edificio.';
    end if;

    if new.piso is not null and e.pisos is not null and new.piso > e.pisos - 1 then
      raise exception 'El edificio % tiene % planta(s): el piso más alto es %, no %',
        e.codigo, e.pisos, e.pisos - 1, new.piso
        using hint = '0 = planta baja, 1 = primer piso.';
    end if;

    if e.geom is not null then
      distancia := st_distance(new.geom::geography, e.geom::geography);
      if distancia > 10 then
        raise exception 'El punto % está a % m del edificio %', new.codigo, round(distancia::numeric), e.codigo
          using hint = 'Hasta 10 m se acepta (error del GPS). Revise el edificio elegido o la coordenada.';
      end if;
    end if;

  elsif new.sede_id is null then
    select s.id into new.sede_id
    from public.sede s
    where s.geom is not null and st_contains(s.geom, new.geom)
    limit 1;

    if new.sede_id is null then
      raise exception 'No se pudo deducir la sede de %', new.codigo
        using hint = 'Indique edificio_id o sede_id.';
    end if;
  end if;

  return new;
end;
$$;

-- area y via: sede por ubicación, si no se indicó.
create or replace function public.completar_sede_por_ubicacion()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
begin
  if new.sede_id is null then
    select s.id into new.sede_id
    from public.sede s
    where s.geom is not null and st_contains(s.geom, st_pointonsurface(new.geom))
    limit 1;
  end if;
  return new;
end;
$$;

create trigger ambiente_ubicacion      before insert or update on public.ambiente      for each row execute function public.completar_ubicacion();
create trigger punto_interes_ubicacion before insert or update on public.punto_interes for each row execute function public.completar_ubicacion();
create trigger area_sede               before insert or update on public.area          for each row execute function public.completar_sede_por_ubicacion();
create trigger via_sede                before insert or update on public.via           for each row execute function public.completar_sede_por_ubicacion();

-- actualizado_en en todas las tablas que lo tienen.
do $$
declare t text;
begin
  foreach t in array array['grupo', 'sede', 'edificio', 'unidad', 'tipo_ambiente', 'tipo_punto', 'tipo_area',
                           'tipo_via', 'ambiente', 'punto_interes', 'area', 'via', 'foto']
  loop
    execute format('create trigger %I before update on public.%I for each row execute function public.tocar_actualizado_en()',
                   t || '_actualizado_en', t);
  end loop;
end;
$$;

-- =============================================================================
-- Red de rutas (punto 22)
-- =============================================================================

-- Rehace los nodos: une los extremos que caen en el mismo punto (grilla de ~10 cm).
create or replace function public.armar_red()
returns integer
language plpgsql
set search_path = public, extensions
as $$
declare
  nodos integer;
begin
  update public.via set origen = null, destino = null where origen is not null or destino is not null;
  delete from public.via_nodo;

  insert into public.via_nodo (geom)
  select distinct st_snaptogrid(p, 0.000001)
  from (select st_startpoint(geom) as p from public.via
        union all
        select st_endpoint(geom) from public.via) extremos;

  update public.via v set
    origen  = (select n.id from public.via_nodo n where n.geom = st_snaptogrid(st_startpoint(v.geom), 0.000001)),
    destino = (select n.id from public.via_nodo n where n.geom = st_snaptogrid(st_endpoint(v.geom), 0.000001));

  select count(*) into nodos from public.via_nodo;
  return nodos;
end;
$$;
comment on function public.armar_red() is 'Rehace via_nodo y via.origen/destino. Corre sola al cambiar la geometría de las vías.';

create or replace function public.via_rearmar_red()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
begin
  perform public.armar_red();
  return null;
end;
$$;

-- "update of geom": rellenar origen/destino no vuelve a disparar el trigger.
create trigger via_red after insert or delete or update of geom on public.via
  for each statement execute function public.via_rearmar_red();

-- Ruta más corta (Dijkstra) entre dos coordenadas, más los elementos de
-- seguridad (extintores, botiquines…) a menos de radio_m de la ruta.
create or replace function public.ruta(
  o_lon double precision, o_lat double precision,
  d_lon double precision, d_lat double precision,
  solo_accesible boolean default false,
  radio_m integer default 25
)
returns jsonb
language plpgsql
stable
set search_path = public, extensions
as $$
declare
  n_origen  integer;
  n_destino integer;
  linea     geometry;
  total     numeric;
begin
  select id into n_origen  from public.via_nodo order by geom <-> st_setsrid(st_makepoint(o_lon, o_lat), 4326) limit 1;
  select id into n_destino from public.via_nodo order by geom <-> st_setsrid(st_makepoint(d_lon, d_lat), 4326) limit 1;

  if n_origen is null or n_destino is null then
    return jsonb_build_object('encontrada', false, 'motivo', 'No hay red de vías cargada.');
  end if;

  select st_linemerge(st_collect(v.geom order by r.seq)), sum(v.longitud_m)
    into linea, total
  from pgr_dijkstra(
         'select id, origen as source, destino as target, longitud_m::float8 as cost, longitud_m::float8 as reverse_cost
            from public.via where origen is not null and destino is not null'
         || case when solo_accesible then ' and accesible is not false' else '' end,
         n_origen, n_destino, false) r
  join public.via v on v.id = r.edge;

  if linea is null then
    return jsonb_build_object('encontrada', false, 'motivo', 'Los puntos no están conectados por la red.');
  end if;

  return jsonb_build_object(
    'encontrada', true,
    'longitud_m', round(total, 1),
    'ruta', st_asgeojson(linea)::jsonb,
    'seguridad', coalesce((
      select jsonb_agg(jsonb_build_object('codigo', p.codigo, 'tipo', tp.codigo, 'nombre', coalesce(p.nombre, tp.nombre),
                                          'geom', st_asgeojson(p.geom)::jsonb))
      from public.punto_interes p
      join public.tipo_punto tp on tp.id = p.tipo_punto_id
      where tp.categoria = 'seguridad'
        and st_dwithin(p.geom::geography, linea::geography, radio_m)), '[]'::jsonb)
  );
end;
$$;
comment on function public.ruta is 'Punto 22: ruta más corta por la red de vías (pgRouting) y elementos de seguridad cercanos.';

-- =============================================================================
-- Búsqueda por texto: "¿dónde queda…?" (nombre, alias, sigla y servicios)
-- =============================================================================
create or replace function public.buscar(q text)
returns table (capa text, codigo text, nombre text, detalle text, sede text, lon double precision, lat double precision)
language sql
stable
set search_path = public, extensions
as $$
  with t as (select '%' || unaccent(lower(trim(q))) || '%' as p)
  select 'ambiente', a.codigo, a.nombre, coalesce(u.nombre, ta.nombre), s.codigo, st_x(a.geom), st_y(a.geom)
  from public.ambiente a
  join public.tipo_ambiente ta on ta.id = a.tipo_ambiente_id
  join public.sede s           on s.id = a.sede_id
  left join public.unidad u    on u.id = a.unidad_id
  cross join t
  where unaccent(lower(concat_ws(' ', a.nombre, array_to_string(a.alias, ' '), array_to_string(a.servicios, ' '),
                                 u.nombre, u.sigla, array_to_string(u.alias, ' '), array_to_string(u.servicios, ' ')))) like t.p
  union all
  select 'edificio', e.codigo, e.nombre, e.uso, s.codigo, st_x(e.centro), st_y(e.centro)
  from public.edificio e
  join public.sede s on s.id = e.sede_id
  cross join t
  where e.centro is not null
    and unaccent(lower(concat_ws(' ', e.codigo, e.nombre, array_to_string(e.alias, ' ')))) like t.p
  limit 50;
$$;
comment on function public.buscar is 'Búsqueda alfanumérica: devuelve el texto y la coordenada para marcarla en el mapa.';

-- =============================================================================
-- Vistas (security_invoker: respetan RLS)
-- =============================================================================
create view public.v_leyenda with (security_invoker = true) as
  select 'ambiente' as capa, categoria, codigo, nombre, color, icono, orden from public.tipo_ambiente
  union all select 'punto_interes', categoria, codigo, nombre, color, icono, orden from public.tipo_punto
  union all select 'area',          categoria, codigo, nombre, color, icono, orden from public.tipo_area
  union all select 'via',           categoria, codigo, nombre, color, icono, orden from public.tipo_via;

-- Llegada sin escaleras: planta baja, o el edificio tiene ascensor.
create view public.v_ambiente with (security_invoker = true) as
  select a.*,
         ta.codigo as tipo, ta.nombre as tipo_nombre, ta.categoria, ta.color, ta.icono,
         u.codigo as unidad, u.nombre as unidad_nombre,
         e.codigo as edificio, e.nombre as edificio_nombre,
         s.codigo as sede,
         case when a.piso is null or a.piso = 0 then true
              when e.ascensor is not null then e.ascensor
         end as llegada_sin_escaleras
  from public.ambiente a
  join public.tipo_ambiente ta on ta.id = a.tipo_ambiente_id
  join public.sede s           on s.id = a.sede_id
  left join public.unidad u    on u.id = a.unidad_id
  left join public.edificio e  on e.id = a.edificio_id;

create view public.v_punto_interes with (security_invoker = true) as
  select p.*,
         tp.codigo as tipo, tp.nombre as tipo_nombre, tp.categoria, tp.color, tp.icono,
         e.codigo as edificio, s.codigo as sede,
         case when p.piso is null or p.piso = 0 then true
              when e.ascensor is not null then e.ascensor
         end as llegada_sin_escaleras
  from public.punto_interes p
  join public.tipo_punto tp   on tp.id = p.tipo_punto_id
  join public.sede s          on s.id = p.sede_id
  left join public.edificio e on e.id = p.edificio_id;

-- Control: ambientes aceptados (≤ 10 m) pero fuera del polígono de su edificio.
create view public.v_ambiente_fuera_de_edificio with (security_invoker = true) as
  select a.codigo, a.nombre, e.codigo as edificio,
         round(st_distance(a.geom::geography, e.geom::geography)::numeric, 1) as distancia_m
  from public.ambiente a
  join public.edificio e on e.id = a.edificio_id
  where e.geom is not null and not st_intersects(a.geom, e.geom);

-- Control: tramos sueltos (ninguno de sus extremos toca otra vía).
create view public.v_via_desconectada with (security_invoker = true) as
  select v.codigo, v.nombre, v.longitud_m
  from public.via v
  where not exists (select 1 from public.via o
                    where o.id <> v.id
                      and (o.origen in (v.origen, v.destino) or o.destino in (v.origen, v.destino)));

-- Control: entradas a más de 2 m de cualquier vía (la ruta no puede llegar).
create view public.v_entrada_sin_via with (security_invoker = true) as
  select p.codigo, p.nombre, e.codigo as edificio
  from public.punto_interes p
  join public.tipo_punto tp   on tp.id = p.tipo_punto_id and tp.codigo = 'ENTRADA'
  left join public.edificio e on e.id = p.edificio_id
  where not exists (select 1 from public.via v where st_dwithin(v.geom::geography, p.geom::geography, 2));

-- =============================================================================
-- Seguridad (RLS): cualquiera lee; solo usuarios con sesión escriben.
-- En Supabase Auth hay que desactivar el registro público (solo cuentas invitadas).
-- =============================================================================
do $$
declare t text;
begin
  foreach t in array array['grupo', 'sede', 'edificio', 'unidad', 'tipo_ambiente', 'tipo_punto', 'tipo_area',
                           'tipo_via', 'ambiente', 'punto_interes', 'area', 'via_nodo', 'via', 'foto']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)', t || '_lectura', t);
    execute format('create policy %I on public.%I for all to authenticated using (true) with check (true)', t || '_edicion', t);
  end loop;
end;
$$;

-- Storage: bucket público de fotos; solo usuarios con sesión suben o borran.
insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

create policy fotos_subir  on storage.objects for insert to authenticated with check (bucket_id = 'fotos');
create policy fotos_editar on storage.objects for update to authenticated using (bucket_id = 'fotos');
create policy fotos_borrar on storage.objects for delete to authenticated using (bucket_id = 'fotos');

-- =============================================================================
-- Datos iniciales
-- =============================================================================
insert into public.grupo (id, codigo, tema) values
  ( 1, 'RECT1',   'Oficinas administrativas del Rectorado (1)'),
  ( 2, 'RECT2',   'Oficinas administrativas del Rectorado (2)'),
  ( 3, 'RECT3',   'Oficinas administrativas del Rectorado (3)'),
  ( 4, 'VICE1',   'Oficinas administrativas del Vicerrectorado (1)'),
  ( 5, 'VICE2',   'Oficinas administrativas del Vicerrectorado (2)'),
  ( 6, 'ORGESP',  'Órganos especiales: Corte Electoral, Defensoría Universitaria, Guardería, Canal 11, etc.'),
  ( 7, 'FUP',     'Federación Universitaria de Profesores y asociaciones de docentes facultativos'),
  ( 8, 'POSTGR',  'Escuelas de postgrado'),
  ( 9, 'FACULT',  'Facultades: decanaturas y vicedecanaturas'),
  (10, 'DIRCAR',  'Direcciones de carrera'),
  (11, 'ACRED',   'Oficinas de acreditaciones'),
  (12, 'EXTINV',  'Oficinas de extensión e investigación de las facultades y la UAGRM'),
  (13, 'DTIC',    'DTIC, CPD facultativos'),
  (14, 'LABS',    'Laboratorios'),
  (15, 'BIBLIO',  'Bibliotecas'),
  (16, 'CENTROS', 'Centros internos'),
  (17, 'KIOSCOS', 'Quioscos y fotocopiadoras'),
  (18, 'DEPORT',  'Campos deportivos'),
  (19, 'COMIDA',  'Lugares de comida, comedores'),
  (20, 'PARQSAN', 'Parqueos, sanitarios'),
  (21, 'CELULAR', 'Información alfanumérica apuntando con el celular'),
  (22, 'RUTA',    'Camino del visitante desde un punto de inicio hasta un punto final');

insert into public.sede (codigo, nombre, tipo, direccion, grupo_id) values
  ('CAMPUS',    'Campus Universitario', 'campus',              null,                  2),
  ('CU',        'Ciudad Universitaria', 'campus',              null,                  2),
  ('VALLECITO', 'El Vallecito',         'campus',              null,                  2),
  ('MUSEO',     'Museo de Historia',    'instalacion_externa', 'Calle Junín #151',    2);

insert into public.tipo_ambiente (codigo, nombre, categoria, color, icono, orden) values
  ('OFICINA',        'Oficina administrativa',   'administrativo',          '#1F6FEB', 'briefcase',       10),
  ('SECRETARIA',     'Secretaría',               'administrativo',          '#1F6FEB', 'file-text',       11),
  ('CAJA',           'Caja',                     'administrativo',          '#1F6FEB', 'banknote',        12),
  ('AULA',           'Aula',                     'academico',               '#8250DF', 'presentation',    20),
  ('LABORATORIO',    'Laboratorio',              'academico',               '#8250DF', 'flask-conical',   21),
  ('BIBLIOTECA',     'Biblioteca',               'academico',               '#8250DF', 'library',         22),
  ('AUDITORIO',      'Auditorio',                'academico',               '#8250DF', 'mic',             23),
  ('INVESTIGACION',  'Investigación',            'investigacion_extension', '#CF222E', 'microscope',      30),
  ('EXTENSION',      'Extensión',                'investigacion_extension', '#CF222E', 'handshake',       31),
  ('CENTRO_INTERNO', 'Centro interno',           'investigacion_extension', '#CF222E', 'landmark',        32),
  ('CPD',            'Centro de procesamiento de datos', 'tecnologia',      '#2DA44E', 'server',          40),
  ('SALA_COMPUTO',   'Sala de cómputo',          'tecnologia',              '#2DA44E', 'monitor',         41),
  ('KIOSCO',         'Kiosco',                   'servicios',               '#BC4C00', 'store',           50),
  ('FOTOCOPIADORA',  'Fotocopiadora',            'servicios',               '#BC4C00', 'printer',         51),
  ('COMEDOR',        'Comedor',                  'servicios',               '#BC4C00', 'utensils',        52),
  ('GUARDERIA',      'Guardería',                'servicios',               '#BC4C00', 'baby',            53),
  ('CONSULTORIO',    'Consultorio médico',       'salud_seguridad',         '#DB2777', 'stethoscope',     60),
  ('ENFERMERIA',     'Enfermería',               'salud_seguridad',         '#DB2777', 'heart-pulse',     61);

insert into public.tipo_punto (codigo, nombre, categoria, color, icono, orden) values
  ('ENTRADA',           'Entrada',              'acceso',            '#24292F', 'door-open',       10),
  ('RAMPA',             'Rampa',                'acceso',            '#24292F', 'accessibility',   11),
  ('GRADAS',            'Gradas',               'acceso',            '#24292F', 'footprints',      12),
  ('EXTINTOR',          'Extintor',             'seguridad',         '#D1242F', 'fire-extinguisher', 20),
  ('BOTIQUIN',          'Botiquín',             'seguridad',         '#D1242F', 'briefcase-medical', 21),
  ('SALIDA_EMERGENCIA', 'Salida de emergencia', 'seguridad',         '#D1242F', 'log-out',         22),
  ('PUNTO_ENCUENTRO',   'Punto de encuentro',   'seguridad',         '#D1242F', 'users',           23),
  ('SANITARIO',         'Sanitario',            'servicios_basicos', '#0969DA', 'toilet',          30),
  ('BEBEDERO',          'Bebedero',             'servicios_basicos', '#0969DA', 'glass-water',     31);

insert into public.tipo_area (codigo, nombre, categoria, color, icono, orden) values
  ('CANCHA_FUTBOL',   'Cancha de fútbol',  'deportivo',       '#1A7F37', 'goal',           10),
  ('CANCHA_MULTIPLE', 'Cancha múltiple',   'deportivo',       '#1A7F37', 'volleyball',     11),
  ('PISTA_ATLETISMO', 'Pista de atletismo','deportivo',       '#1A7F37', 'timer',          12),
  ('PISCINA',         'Piscina',           'deportivo',       '#1A7F37', 'waves',          13),
  ('JARDIN',          'Jardín',            'area_verde',      '#82C91E', 'flower',         20),
  ('AREA_VERDE',      'Área verde',        'area_verde',      '#82C91E', 'trees',          21),
  ('PLAZA',           'Plaza',             'area_verde',      '#82C91E', 'tree-palm',      22),
  ('PARQUEO',         'Parqueo',           'estacionamiento', '#8C959F', 'square-parking', 30);

insert into public.tipo_via (codigo, nombre, categoria, color, icono, orden) values
  ('SENDERO',         'Sendero',          'peatonal',  '#A0522D', 'footprints', 10),
  ('ACERA',           'Acera',            'peatonal',  '#A0522D', 'footprints', 11),
  ('PASILLO_TECHADO', 'Pasillo techado',  'peatonal',  '#A0522D', 'umbrella',   12),
  ('VIA_INTERNA',     'Vía interna',      'vehicular', '#444C56', 'car',        20),
  ('CALLE',           'Calle / avenida',  'vehicular', '#444C56', 'car',        21);
