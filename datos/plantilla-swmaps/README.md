# Plantilla de SW Maps

`RECT2_Campo_v1.swmr` es la plantilla de solo lectura para levantar datos con **SW Maps** (Android). Trae 5 capas con los mismos nombres de campo que la [plantilla del modelo](../../docs/diseno-bd.md#plantilla-de-campos-para-arcmap):

| Capa | Geometría | Campos |
|---|---|---|
| `ambiente` | Punto | CODIGO, TIPO, NOMBRE, EDIFICIO, PISO, REFERENCIA, NOTA, FOTO_PTA, FOTO_INT |
| `punto_interes` | Punto | CODIGO, TIPO, NOMBRE, EDIFICIO, PISO, ACCESIBLE, NOTA, EXT_AGENTE, EXT_KG, EXT_VENCE, FOTO |
| `via` | Línea | CODIGO, TIPO, NOMBRE, SUPERFICIE, ACCESIBLE, NOTA, TECHADO |
| `area` | Polígono | CODIGO, TIPO, NOMBRE, MATERIAL, CAPACIDAD, ACCESO, NOTA, FOTO |
| `edificio` | Polígono | CODIGO, NOMBRE, ALIAS, USO, PISOS, ASCENSOR, DESCRIP, FOTO_FACH |

Las listas de `TIPO` son las del catálogo de la base. Cómo se usa: [`docs/guia-campo.md`](../../docs/guia-campo.md).

Para cambiarla: editar las capas en un proyecto de SW Maps, exportar con *Export Template* como `RECT2_Campo_v2` y reemplazar este archivo.
