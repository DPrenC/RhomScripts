# Componentes comunes de interfaz

Estado: Cerrado.

Última actualización: 2026-11-19.

## Objetivo y alcance

Componer ventanas persistentes mediante árbol, lista, pestañas nativas visibles y botones de acción reutilizables. Cada dominio aporta datos, activación y sonidos. Conservar el ciclo modal y la asociación con Mudlet elegida en el configurador. No añadir buscador interno ni un modo de ventana exclusivo del mapa.

Adaptar configurador, destinos y los tres historiales. Incorporar gestión persistente de favoritos, copia y detalle de mensajes. Las respuestas a mensajes requieren comandos e identificación de autor verificados; este trabajo no autoriza inventarlos. Se conserva su indisponibilidad hasta disponer de ese contrato.

## Criterios de aceptación

- Un clic selecciona una fila; Enter o doble clic ejecutan su activación una sola vez. Los botones tienen acciones independientes y se activan con clic, Enter o Espacio.
- Derecha recorre los botones disponibles del elemento; Izquierda vuelve hasta la lista. Arriba y Abajo no cambian de elemento mientras el foco está en sus botones.
- En árboles, izquierda/derecha pliegan/despliegan y Tab recorre árbol y botones. En listas con pestañas, Tab y Mayús+Tab cambian de pestaña; no hay botones generales ni navegación nueva con Ctrl+Tab.
- Las pestañas son controles nativos visibles y se pueden seleccionar con ratón. Se recuerda la pestaña por identificador durante la sesión; al reabrir se selecciona su primer elemento.
- Las actualizaciones conservan elemento y foco por identidad. Las llegadas no simulan navegación. Si desaparece el elemento seleccionado, se elige siguiente o anterior y se devuelve el foco desde las acciones a la lista, comunicándolo.
- Los componentes eligen `ui.clic_1` al recorrer listas y árboles, `ui.boton_1` al pulsar botones y `ui.pestana` al cambiar de pestaña. Mover el foco entre lista y botones o entre botones es silencioso. Cada sistema sigue definiendo el resto de sonidos.
- Una búsqueda oficial con resultados abre Resultados y selecciona el primero. Sin coincidencias limpia Resultados y comunica el estado sin abrir la ventana ni borrar favoritos. Escape permite volver a Mudlet para otra búsqueda.
- Añadir y eliminar favoritos persiste antes de anunciar éxito. Un fallo no publica el cambio ni reemplaza un archivo ilegible por uno vacío.
- Activar un mensaje abre detalle de texto completo de solo lectura, con copia independiente de las llegadas y descartes posteriores. Escape y X vuelven al historial.
- Preparar controles antes de ready sin foco ni audio; reutilizar al abrir/cerrar y retirar correctamente al recargar, incluso desde un detalle.

## Etapas y siguiente paso

- [x] Componentes comunes y política sonora propia del configurador.
- [x] Adaptación del mapa, favoritos y memoria de pestañas.
- [x] Adaptación de historiales, detalle y copia.
- [x] Pruebas focalizadas, integración combinada y actualización de manuales.

Siguiente paso de comprobación manual: contrastar la experiencia de navegación y lectura con teclado físico y lector externo. No queda implementación pendiente dentro del alcance; las respuestas a mensajes continúan en su contrato diferido.

## Entrega y validación

Entrega integrada: `ui.lista` comparte selección por identidad, actualización de filas, botones contextuales y pestañas nativas con un panel persistente. Se cachean textos y tokens para evitar escrituras nativas de filas no modificadas. Cada dominio aporta los sonidos específicos de sus eventos; navegación y pulsación usan la política común. El detalle de mensajes es silencioso y utiliza el foco y contenido nativos. `ui.detalle` conserva una instantánea de solo lectura. El cierre global es escalonado: termina el diálogo hijo antes de cerrar el padre, y evita aperturas pendientes durante la recarga.

`scripts/validate.ps1`: diez controles aprobados, 150 casos en Lua 5.1 y 150 en LuaJIT. `scripts/run_mudlet_validation.py --map-keyboard postmessage`: 150 casos aprobados en Mudlet 5.1.1. Probe de historiales: 44 casos aprobados con wxWidgets 3.2.8. [Comandos, artefactos, versiones y límites](../validacion.md#componentes-comunes-de-interfaz-18-de-noviembre-de-2026).

Manuales actualizados: [navegación común](../usuario/componentes-interfaz.md), [mapa](../usuario/mapa.md) y [comunicaciones](../usuario/comunicaciones.md). No se conectó al juego ni se modificó el portapapeles del escritorio. No se hicieron commits ni se modificó el índice Git.

## Política sonora común, 19 de noviembre de 2026

`ui.lua` centraliza `clic_1` para listas y árboles y `boton_1` para pulsar botones. Se eliminan los eventos sonoros de movimiento entre botones y regreso a la lista; configurador, mapa e historiales conservan el resto de su política. Los ajustes numéricos y booleanos siguen siendo nodos gestionados por el configurador, con sus sonidos propios. [Validación y límites de esta corrección](../validacion.md#sonidos-comunes-de-listas-y-botones-19-de-noviembre-de-2026). Estado: implementado y validado localmente y en Mudlet; siguiente paso manual: teclado físico y lector externo.

Corrección posterior del mismo día: los reguladores de volumen usan `ui.clic_2`; se mantienen los sonidos propios de los demás ajustes. [Pruebas y límites](../validacion.md#sonido-de-los-reguladores-de-volumen-19-de-noviembre-de-2026).

## Sonido de pestañas compartido, 19 de noviembre de 2026

`ui.sonido_pestana()` centraliza el recurso `ui.pestana`, utilizado por `ui.lista` al cambiar de pestaña visible y por los atajos de cambio de categoría de comunicaciones. Los callbacks de canales no reproducen un segundo sonido. El WAV aportado se renombra a `Pestana.wav` conservando los bytes para cumplir el contrato ASCII y la apertura de archivos en Windows. Preparación, actualización y selección idéntica siguen sin avisos. Estado: implementado y validado localmente y en Mudlet 5.1.1. Siguiente paso manual: teclado físico y escucha con lector externo. [Validación](../validacion.md#sonido-compartido-de-pestañas-19-de-noviembre-de-2026).

## Sobrescritura del sonido de pestañas, 19 de noviembre de 2026

Corrección de alcance: `ui.lista` acepta `sonido_pestana` como clave opcional, con `ui.pestana` por defecto. `ui.sonido_pestana(clave)` reproduce el recurso elegido. Comunicaciones declara `ui.seleccion_canal` para sus ventanas y atajos; mapa conserva el valor común sin configuración adicional. No se duplica el código de navegación ni se reproduce el sonido dos veces. Estado: implementado y validado localmente y en Mudlet 5.1.1. Siguiente paso manual: teclado físico y escucha con lector externo. [Evidencia](../validacion.md#sonido-propio-de-las-pestañas-de-comunicaciones-19-de-noviembre-de-2026).
