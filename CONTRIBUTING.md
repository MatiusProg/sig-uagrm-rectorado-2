# Reglas de trabajo y despliegue

## Ramas

| Rama | Para qué | Se despliega en | Cómo se cambia |
|------|----------|-----------------|----------------|
| `main` | Versión estable, la que se muestra al ingeniero | **prod**: Supabase prod + web de producción | Solo por Pull Request desde `develop`, con **1 aprobación** y CI en verde |
| `develop` | Integración del trabajo del equipo | **dev**: Supabase dev + web de vista previa | Solo por Pull Request, con CI en verde |
| `feat/...`, `fix/...`, `datos/...`, `docs/...` | Trabajo de cada persona | — | Push libre |

Las ramas `main` y `develop` están protegidas: no se puede hacer push directo, force-push ni borrarlas.

## Flujo diario

```bash
git checkout develop && git pull
git checkout -b feat/capa-oficinas      # nombre corto y descriptivo
# ... trabajar, commits pequeños ...
git push -u origin feat/capa-oficinas
# En GitHub: abrir Pull Request hacia develop
```

Para pasar a producción, se abre un Pull Request de `develop` a `main`. Conviene hacerlo antes de cada revisión o demo con el ingeniero.

## Base de datos (lo más delicado)

1. **Nunca** se cambian tablas desde el panel de Supabase. Todo cambio es una **migración nueva**:
   ```bash
   npx supabase migration new nombre_del_cambio
   # editar supabase/migrations/<fecha>_nombre_del_cambio.sql
   ```
2. **Nunca** se edita una migración que ya fue fusionada a `develop`. Si hubo un error, se corrige con otra migración.
3. El CI aplica todas las migraciones en un Postgres limpio. Si falla, el PR no se puede fusionar.
4. Al fusionar a `develop`, la migración se aplica en **dev**. Al fusionar a `main`, en **prod**.
5. Todas las geometrías van en **WGS84 (EPSG:4326)**.

## Commits

En español, en imperativo y concretos: `Agrega capa de extintores`, `Corrige área del edificio administrativo`.

## Secretos

- Las claves **nunca** se suben al repositorio. Para desarrollar en local, copia `web/.env.example` a `web/.env.local`.
- Los secretos de despliegue viven en *GitHub → Settings → Environments* (`dev` y `prod`).
- La *anon key* de Supabase es pública por diseño. Lo que protege los datos son las políticas **RLS** de cada tabla.
