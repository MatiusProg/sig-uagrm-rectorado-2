# Notas: sorteo del proyecto y clases de ActualMap

Resumen hecho a partir de las grabaciones. Las transcripciones automáticas completas, con errores de reconocimiento, están en [`transcripciones/`](transcripciones/).

---

## Sorteo del proyecto (23-10-2026)

### Lo que pidió el ingeniero
- **Sistema de referencia: todo en WGS84.** Lo repitió varias veces. "No es un simple dibujo": tiene que estar georreferenciado.
- **Precisión:** no es un trabajo de exactitud. Un metro de error no importa, pero cada objeto debe caer en el área donde realmente está.
- **Base cartográfica:** va a averiguar si la DTIC tiene una base. Si no la tiene, hay que conseguirla de algún lado.
- **Tiene que ser una aplicación web.** Si el resultado es bueno, la idea es hablar con el Decano y el Vicerrectorado para que la DTIC la publique en la página de la UAGRM, con los estudiantes como autores.
- **Unificar el stack:** prefiere que los 22 grupos se pongan de acuerdo en un solo lenguaje para poder integrar, aunque acepta otros si colaboran entre sí. Las tablas van a ser parecidas entre grupos, así que sugiere que los que saben de bases de datos diseñen un esquema común.
- **Alcance geográfico:** campus central (módulos) y **el Vallecito**. Agregar las sedes de provincia (Vallegrande, Camiri, Montero...) da un **plus**.
- **Datos vectoriales únicamente:** puntos, líneas y polígonos. Los edificios pueden ser punto o polígono. Las canchas y los jardines tienen que ser polígonos simples.
- **Información alfanumérica completa** al hacer clic. Por ejemplo, para la DTIC: qué hace y quién es el director; para un CPD: quién es el encargado.
- **Consultas** (deja la imaginación a los grupos):
  - Alfanuméricas: "¿dónde queda Informática?" debe responder con texto (director, etc.) **y** marcar el punto en el mapa.
  - Espaciales: "¿qué kioscos hay dentro del polígono de la Facultad de Computación?" o "¿qué oficinas administrativas hay en el Vallecito?".
- **Producto final:** plano digital con todas las capas, una **leyenda** (por ejemplo: puntos azules = facultades, rojos = investigación/extensión) y las **tablas de infraestructura** de la base. Basta con mostrar la versión digital.
- **Punto 21 (apuntar con el celular):** es como las apps para turistas. Apuntas al edificio, haces clic y muestra su información.
- **Punto 22:** tiene dos opciones. La primera es la ruta desde un inicio hasta un destino, tipo Google Maps. La segunda es una línea guía (para no videntes o para alguien en el monte) que suena una alarma si la persona se sale unos metros.
- **Dos actividades grandes:**
  1. Elaborar el plano: digitalizar en ArcMap. Ofrece ayuda, y también se le puede preguntar al Ing. Ubaldo.
  2. Desarrollar la aplicación con su base de datos.
- **Fecha de entrega:** la semana de exámenes finales (noviembre/diciembre). Desde el sorteo dijo "un mes y una semana", o sea **aprox. fines de noviembre o inicios de diciembre de 2026**. Hay que confirmar la fecha exacta.
- Se puede escribir al ingeniero con dudas.

### Mensaje posterior (WhatsApp, 4/11)
> Pueden ustedes conseguir con GPS la información geográfica de lo que les tocó en el sorteo. Y luego sobreponer a la base que si está correcto la referencia geográfica no tendrán problemas.

---

## Clases de ActualMap

### Herramientas que usa el ingeniero
- **ActualMap** (aplicaciones Windows) y **AspMap** (aplicaciones web). Los dos son de **VDS Technologies**, el mismo fabricante. Dijo que se puede dominar cualquiera de los dos.
- Se instalan en `C:\Program Files\VDS Technologies\`. El DLL que se usa en el proyecto está en `...\ActualMap .NET 4.0 Win32\ActualMap.dll`.
- La ayuda es el archivo `ActualMap.chm`. Tiene un tutorial ("Using ActualMap"), que es lo que se sigue en clase. En la carpeta `Samples` hay un **prototipo completo en C# y VB.NET**, dividido por módulos, del que se puede sacar código.
- **IDE: Visual Studio** completo (no VS Code), en español. El proyecto es **Visual Basic .NET de Windows Forms**, porque el tutorial está en VB.

### Clase 1 (09-09-2026): introducción
- Repaso de ArcMap: layout, título, escala, norte y **exportar a PDF con capas**.
- ¿Qué hace ActualMap? Mostrar capas (shapefiles, bases de datos), hacer pan y zoom, dibujar puntos, líneas y polígonos, identificar objetos (como la "i" de ArcMap), seleccionar por rectángulo, distancia o expresión, exportar la selección a shapefile, renderizar con etiquetas y exportar a imagen.
- Configuración en Visual Studio:
  1. Nuevo proyecto en Visual Basic.
  2. En el Cuadro de herramientas, *Agregar pestaña* y llamarla "ActualMap".
  3. *Elegir elementos* → buscar `ActualMap.dll` → aparecen los controles **Map**, Legend, etc.
  4. Arrastrar el control `Map` al formulario.
  5. Agregar `Imports ActualMap` e `Imports ActualMap.Windows`.
  6. En el código: `Map1.AddLayer(ruta & "bolivia.shp")`.
- El shapefile necesita su `.prj` para quedar bien posicionado.
- Simbología por código: `layer.Symbol.FillColor`, `LineColor`, `Size`. Etiquetas: `LabelField`, `LabelFont`, `LabelStyle.PolygonCenter`.

### Clase 2 (16-09-2026): herramientas y renderizado
- Una barra `ToolStrip` con botones **ZoomIn, ZoomOut, ZoomFull, Pan e Info**. Los íconos están en `Samples\...\Tools`.
- **Identify:** muestra los atributos del objeto en un **DataGrid**.
- **Renderizado por categoría** por código (el equivalente a Simbología → Categorías en ArcMap). Por ejemplo, colorear caminos según su tipo: asfalto, tierra o doble vía.
- Una lista de capas con *checkbox* para mostrar u ocultar.

### Clase 3 (23-09-2026): capas dinámicas y selección
- Crear **líneas dinámicamente** con `DynamicLayer`, `Shape` de tipo línea y `Points.Add(x, y)`. Las coordenadas se dan en lon/lat; Bolivia está entre X −69 y −57 e Y −22 y −10. El ingeniero dijo: "**el proyecto está basado en líneas**".
- **Selección por expresión** (tipo `WHERE`) sobre una capa, luego `Map1.Refresh()` y zoom a la selección.
- **Exportar la selección** como un nuevo shapefile, volver a cargarlo y cambiarle el color.
- Hay ejemplos de conexión a varios motores de base de datos y de selección espacial: por distancia, por buffer y por criterio espacial.
- El 2º parcial es práctico: consultas alfanuméricas y espaciales en laboratorio.

---

## Conclusiones para el grupo
1. El ingeniero enseña ActualMap/AspMap, pero **permite cualquier lenguaje** y exige que sea **web**. Su ruta "oficial" para web sería **AspMap (ASP.NET)**.
2. Lo **no negociable**: WGS84, datos vectoriales, atributos completos, consultas alfanuméricas y espaciales, leyenda y tablas, y que sea web.
3. Como los 22 grupos deben integrarse, conviene **proponer pronto un esquema de base común y un stack** a los demás grupos, empezando por Rectorado (1) y (3).
