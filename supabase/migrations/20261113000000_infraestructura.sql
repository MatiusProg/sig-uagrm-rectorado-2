-- Migración 0: infraestructura base (sin tablas del dominio todavía).
-- Las tablas del SIG se agregan en migraciones posteriores, una vez cerrado el diseño.

-- PostGIS en el esquema "extensions" (recomendación de Supabase: no en "public").
create extension if not exists postgis with schema extensions;

-- ping(): la usa el workflow keepalive.yml para generar actividad cada 3 días
-- y evitar que el plan gratis de Supabase pause el proyecto por inactividad.
create or replace function public.ping()
returns timestamptz
language sql
stable
security invoker
set search_path = ''
as $$
  select now();
$$;

comment on function public.ping() is 'Keep-alive: llamada periódica desde GitHub Actions.';

grant execute on function public.ping() to anon, authenticated;
