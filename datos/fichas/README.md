# Fichas de oficinas

`fichas-oficinas.csv` es la planilla donde se pasan los datos de cada oficina levantada en campo. Se abre con Excel. La llena Cristian con las notas de todos y se la devuelve a Luis.

- Una fila por oficina. Las 8 conocidas ya vienen cargadas.
- `CODIGO` une la ficha con el punto de SW Maps. Si una oficina nueva no tiene código, dejarlo vacío: lo asigna Luis.
- `PISO`: 0 = planta baja, 1 = primer piso, −1 = sótano.
- `SERVICIOS`: varios separados con `;`.
- `LEVANTADO_POR` y `FECHA` (AAAA-MM-DD): quién tomó los datos y cuándo.

Qué preguntar en cada oficina: ver [`docs/guia-campo.md`](../../docs/guia-campo.md).
