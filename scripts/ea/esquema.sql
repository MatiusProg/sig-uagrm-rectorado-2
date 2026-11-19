-- Vuelca el esquema público (tablas, columnas, tipos y claves) en JSON para ea-modelo-datos.ps1.
-- Uso: psql "<conexión>" -At -f scripts/ea/esquema.sql > docs/diagramas/esquema.json
with cols as (
  select c.relname as tabla, a.attnum, a.attname as col,
         upper(format_type(a.atttypid, a.atttypmod)) as tipo, not a.attnotnull as nulo,
         exists (select 1 from pg_constraint k where k.conrelid = c.oid and k.contype = 'p' and a.attnum = any(k.conkey)) as pk,
         (select r.relname from pg_constraint k join pg_class r on r.oid = k.confrelid
           where k.conrelid = c.oid and k.contype = 'f' and k.conkey = array[a.attnum] limit 1) as fk,
         exists (select 1 from pg_constraint k where k.conrelid = c.oid and k.contype in ('u','p') and k.conkey = array[a.attnum]) as unico
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
  where n.nspname = 'public' and c.relkind = 'r')
select jsonb_pretty(jsonb_agg(jsonb_build_object('tabla', tabla, 'columnas', cs) order by tabla))
from (select tabla, jsonb_agg(jsonb_build_object('col', col, 'tipo', replace(replace(tipo, 'CHARACTER VARYING', 'VARCHAR'), 'TIMESTAMP WITH TIME ZONE', 'TIMESTAMPTZ'),
                                                 'pk', pk, 'fk', fk, 'nulo', nulo, 'unico', unico) order by attnum) cs
      from cols group by tabla) t;
