# Mapa: lista accesible de destinos

La siguiente fase de acciones, favoritos y memoria de pestañas se desarrolla en el [plan de componentes comunes](componentes-interfaz.md). Ese plan sustituye las decisiones anteriores sobre búsquedas vacías y selección de pestaña al reabrir; esta ficha conserva el alcance y la evidencia de la primera entrega.

Estado: Cerrado para esta fase; corrección de Enter validada. Botones y memoria de pestañas diferidos.

Última actualización: 2026-11-18.

## Objetivo y alcance

Crear `rhomscripts/mapa.lua` para presentar los destinos encontrados por el paquete oficial en una ventana nativa de RhomScripts con dos pestañas: Resultados y Favoritos. La búsqueda abre automáticamente la ventana en Resultados si hay coincidencias y en Favoritos si Resultados está vacío; Enter inicia el viaje al destino seleccionado, Escape oculta la ventana y Ctrl+Mayús+M recupera la ventana. Con el sistema activado, los destinos no se imprimen en la terminal.

La opción de Configuración, Interfaz permite activar o desactivar el sistema. Desactivado conserva la presentación oficial; activado sustituye sus funciones en memoria sin editar archivos oficiales. Resultados se pierde al recargar; Favoritos se guarda en un JSON propio. Esta primera fase conserva el buscador y el motor de movimiento oficiales. No incorpora un mapa propio, edición de salas ni cálculo propio de rutas. El manual y el historial describen la fase implementada; la evidencia se registra al completar la validación.

## Evidencia del código actual

- En la copia local de `RLMud_Config.zip`, `RLMud_Config.xml` define el alias `irsala` con patrón `^irsala (.*)$`, que llama a `RL_mostrar_links_viaje_room(matches[2], false)`. `sigilarsala` llama a la misma función con `true`.
- `RL_mostrar_links_viaje_room(room, sigilar)` llama a `RL_buscar_salas(room)`, recibe una tabla de ID de sala a nombre y presenta cada entrada con `cechoLink` y `cecho`. No emite un evento con los resultados.
- `RL_buscar_salas(nombre)` admite nombre y nombre con salidas entre corchetes. Con salidas normaliza el orden y las marcas de puertas, y compara el nombre completo sin distinguir mayúsculas. No sustituir este comportamiento por otro buscador.
- La presentación añade las salidas mediante `RL_dame_string_salidas(id, true)` si el nombre no las incluye. El viaje usa `RL_speed_walk_to(id)` y su variante sigilosa `RL_speed_walk_sigilar_to(id)`.
- `ui.lua` ofrece ventana persistente, Escape, foco y ciclo de vida modal. `comunicaciones_historial.lua` usa `wxListCtrl` nativo de selección única. No hay todavía un constructor común de listas.
- `keys.lua` descubre las pulsaciones declaradas por cada módulo; no se encontró una declaración activa de Ctrl+Mayús+M. La integración debe comprobar también colisiones en el perfil real.

Fuente del paquete: [descarga oficial](https://mudlet.reinosdeleyenda.es/RLMud_Config.zip). La implementación se cotejó además con una descarga oficial del 17 de noviembre de 2026; procedencia y hash en el [contrato](../contratos-mudlet.md#destinos-del-mapa). Consultar también los [contratos existentes](../contratos-mudlet.md).

## Diseño implementado y etapas posteriores

### Captura antes de imprimir

Añadir una preferencia persistente «Lista de destinos de RhomScripts» en Configuración, Interfaz. Valor inicial implementado: desactivada, para conservar la presentación vigente hasta que se elija la nueva. Aplicarla al guardar el configurador; Cancelar no cambia el estado activo.

Si está activada, instalar un adaptador de `RL_mostrar_links_viaje_room` después de inicializar el paquete oficial. Guardar la función original para retirarlo limpiamente. El adaptador recibe el criterio y el modo, llama directamente a `RL_buscar_salas`, normaliza el resultado y solicita mostrar la ventana. No llama a la presentación original, por lo que no se generan sus enlaces ni sus líneas en la terminal.

Al desactivar, retirar la sustitución y recuperar la función oficial; cerrar la ventana propia, cancelar aperturas pendientes y mantener el JSON de favoritos. No dejar un adaptador permanente que decida entre las dos presentaciones. El atajo propio permanece registrado para participar en la ayuda de teclado, pero al estar desactivado informa de ello sin abrir la ventana ni modificar el comportamiento oficial. Activar y desactivar no inicia viajes ni elimina favoritos.

Mantener los alias oficiales: añadir alias propios con los mismos patrones podría ejecutar ambas rutas. No interceptar globalmente `cecho` o `cechoLink`, ni borrar líneas después de imprimirlas. El eco del comando escrito y los avisos de viaje son distintos de la lista de destinos y quedan fuera de esta supresión.

La función compartida también recibe `sigilarsala`: conservar el modo sigiloso en los resultados y en su activación evita cambiar accidentalmente ese comando. Restaurar la función original durante la retirada solo si el adaptador instalado sigue siendo el propietario de ese punto. Si otro paquete lo ha cambiado, no sobrescribir ese cambio. Comprobar la reinstalación o recarga del paquete oficial con RhomScripts activo; no darla por resuelta con la recarga propia.

### Datos y lista nativa

Cada destino tendrá ID de sala, nombre, salidas, etiqueta accesible y modo de viaje. El ID es la identidad; el texto y el índice visible no identifican una sala. No fusionar destinos de igual nombre. Orden implementado: nombre y, a igualdad de nombre, ID numérico, para que la lista sea estable.

Preparar una ventana «Destinos del mapa» con `ui.nueva`, pestañas Resultados y Favoritos y selección única durante el arranque, antes de registrar teclas y emitir ready. Reutilizar la ventana y los controles. Si conviene extraer un constructor pequeño `ui.lista`, limitarlo a esta necesidad; no refactorizar los historiales como parte de la entrega.

En esta fase ambas pestañas contienen listas normales nativas de selección única, siguiendo el patrón de `wxListCtrl` existente. Mantener flechas verticales para los destinos y Tab/Mayús+Tab para cambiar de pestaña, siguiendo el patrón de historiales. Enter sobre un destino inicia el viaje.

Los botones por fila «Añadir a favoritos» y «Eliminar de favoritos», y su navegación con flechas derecha e izquierda, quedan diferidos expresamente. No añadir ahora botones ni acciones alternativas de alta o baja de favoritos mediante otros atajos o menús. Conservar el diseño de persistencia y consulta de Favoritos; la gestión desde la interfaz corresponde a la etapa posterior.

Cada fila debe poder leerse por sí sola: nombre, salidas y número de sala para distinguir coincidencias. Incluir el modo sigiloso en el contexto accesible cuando proceda. El título o estado informa del criterio y la cantidad. Navegación nativa con flechas, Inicio, Fin y páginas; sin anunciar de nuevo cada fila si el control ya la comunica al lector.

Una búsqueda nueva reemplaza Resultados, actualiza los elementos por ID sin reconstruir el control y selecciona su primer destino. Toda apertura, incluida la automática tras una búsqueda y la solicitada con Ctrl+Mayús+M, selecciona Resultados si contiene destinos y Favoritos si Resultados está vacío, incluso cuando Favoritos también esté vacío. La memoria de la última pestaña utilizada queda aplazada. Conservar la selección de cada pestaña durante la misma carga y no repetir búsquedas al reabrir. Guardar Resultados solo en memoria hasta la recarga.

### Favoritos persistentes

Guardar Favoritos en `getMudletHomeDir() .. "/destinos_favoritos.json"`, separado de `config.json` y de los archivos del paquete oficial. Es un archivo por perfil, con formato versionado y una lista de destinos. Conservar ID, nombre, salidas y modo normal o sigiloso para mantener la acción elegida al guardar. Propuesta de identidad: ID y modo; no duplicar la misma combinación. No guardar etiquetas decorativas ni posiciones de controles.

Para la etapa posterior de gestión: añadir y eliminar guardarán inmediatamente, sin esperar a Guardar en el configurador. Confirmar el éxito de la escritura antes de anunciar que terminó la acción. Un fallo de lectura o escritura debe explicarse y propagarse; no reemplazar silenciosamente un JSON dañado por uno vacío. Un archivo ausente significa que todavía no hay favoritos.

En esa etapa, después de añadir, conservar la fila de Resultados y reflejar que ya está guardada. Al eliminar, seleccionar el siguiente favorito, o el anterior si se elimina el último; tratar el conjunto vacío sin índices inválidos. Una búsqueda vacía nunca borra Favoritos.

Antes de viajar a un favorito, comprobar que el ID sigue existiendo en el mapa cargado y detectar una posible reasignación de sala tras actualizar el mapa. No resolver automáticamente a otra sala por tener el mismo nombre. Conservar el favorito e informar cuando no pueda utilizarse. Se comparan nombre y salidas normalizadas antes de viajar. No se detecta una reasignación que conserve exactamente esos mismos datos; este límite queda documentado en el contrato.

### Colores

Intentar conservar los colores de la representación oficial sin depender de ellos para la accesibilidad. La fuente revisada marca «Viajar aquí» y «Sigilar aquí» en amarillo y restaura el color normal para nombre y salidas. El color normal depende de la configuración de la terminal, por lo que no equivale a un RGB fijo.

Verificar cómo trasladar esa paleta a los controles nativos y a los estados de selección y foco. Mantener texto y foco legibles con el tema del sistema y alto contraste. No forzar texto amarillo sobre un fondo que lo haga ilegible; si no se puede reproducir la paleta conservando legibilidad, usar colores nativos y registrar el límite. En esta fase se usan los colores nativos; no se reproduce el amarillo de enlaces que no existen en la nueva presentación.

### Apertura y activación

Al recibir destinos, actualizar los datos y abrir automáticamente. Si ya está abierta la lista, actualizarla sin anidar `ShowModal`. Si hay otra ventana modal de RhomScripts, conservar la búsqueda más reciente y posponer la apertura hasta que se cierre; añadir una notificación de cierre al ciclo común de UI, sin temporizador periódico ni robo de foco dentro de otro diálogo.

Enter y Enter numérico aceptan la selección una sola vez. Ocultar el diálogo y esperar a que retorne su bucle modal antes de llamar al motor oficial; esto evita enviar movimientos desde un callback de tecla con el diálogo todavía activo. Un fallo debe propagarse, conservando los resultados para consulta. Las funciones oficiales y de Mudlet se llaman directamente, sin alternativas silenciosas si faltan.

Escape y X ocultan sin viajar y conservan datos y selección. Cerrar esta lista no detiene un viaje iniciado anteriormente; `stop` conserva su función oficial. Ctrl+Mayús+M abre o trae al frente la lista, sin alternarla a cerrada.

Si una búsqueda no tiene coincidencias, vaciar Resultados y comunicar «No se encontraron destinos» mediante accesibilidad estándar; nunca dejar destinos antiguos como si pertenecieran a la búsqueda nueva. Favoritos permanece disponible. Toda apertura con Resultados vacío selecciona Favoritos automáticamente, también tras una recarga y aunque no haya favoritos. Si ambas pestañas están vacías, mostrar ese estado en Favoritos sin iniciar búsqueda ni viaje.

### Integración y recarga

`mapa.lua` será propietario del adaptador, los datos, la selección, la ventana y su declaración `pulsaciones`. `init.lua` lo cargará después de preparar el paquete oficial y antes de `ui.preparar()` y `keys.registrar()`. Añadir su retirada a la recarga y a la limpieza de fallos.

Descartar Resultados y su selección en cada recarga propia. Leer Favoritos desde su JSON. Invalidar aperturas y aceptaciones pendientes al retirar una generación. La recarga no debe producir viajes ni abrir automáticamente la ventana. No mantener callbacks del módulo retirado.

No se asignan nuevos sonidos en esta fase; cualquier reutilización de los WAV de destinos requiere revisar su función conforme al contrato de audio.

## Criterios de aceptación y validación prevista

- Una y varias coincidencias abren la lista automáticamente sin imprimir enlaces ni filas de destinos. El eco del comando no cuenta como resultado duplicado.
- Se conservan nombre, salidas, ID y modo; los nombres repetidos permiten elegir cada sala por separado.
- Enter normal y numérico ejecutan una sola llamada con el ID correcto; seleccionar una fila no inicia movimiento. Escape y X no viajan.
- Ctrl+Mayús+M recupera los últimos resultados y la selección sin buscar de nuevo; participa en la ayuda central de teclado.
- Activar en Interfaz instala la sustitución y desactivar restaura la presentación oficial sin editar el paquete. Cancelar el configurador no aplica el cambio; comprobar también guardar y recargar.
- Resultados y Favoritos son listas normales independientes, sin botones en esta fase. Toda apertura selecciona Resultados si contiene destinos; si Resultados está vacío, selecciona Favoritos aunque también esté vacío. No recordar la última pestaña utilizada en esta fase. Comprobar reapertura manual y apertura automática tras búsqueda, incluida una nueva búsqueda mientras se usa Favoritos.
- Los favoritos sobreviven a cierre, recarga y reapertura del perfil mediante su JSON; Resultados desaparece al recargar. En esta fase comprobar lectura, archivo ausente y JSON inválido; diferir las pruebas de duplicados, eliminación y escritura interactiva hasta incorporar la gestión de favoritos.
- Una búsqueda vacía conserva Favoritos. La lista vacía y un favorito con ID ausente no producen viajes erróneos.
- Comprobar la paleta oficial, selección, foco y alto contraste; conservar accesibilidad cuando sea necesario recurrir a colores nativos.
- Una búsqueda vacía invalida los destinos anteriores y lo comunica. Repetir búsquedas con la lista abierta no anida diálogos.
- Un resultado recibido durante otra ventana se muestra al cerrarla; la recarga cancela aperturas o aceptaciones pendientes.
- Doble carga y fallo de inicialización retiran adaptadores y recursos sin duplicados. Una función necesaria ausente produce error.
- Validar los datos y las transiciones con casos focalizados; después, comprobar el adaptador contra el XML oficial real, sin fabricar APIs para obtener un resultado positivo.
- Usar Mudlet real aislado y desconectado para lista, foco, teclado, supresión de salida y recarga. Probar el motor con mapa sintético y captura controlada de envíos, distinguiéndolo de un viaje real. No conectar al juego sin petición.
- Comprobar lectura y manejo con lector externo y teclado físico, registrando los límites si no están disponibles. Verificar las APIs en fuentes oficiales y la última versión estable de Mudlet al implementar; registrar la versión realmente probada.

## Etapas y siguiente paso

- [x] Analizar el punto de integración oficial y el patrón nativo existente.
- [x] Verificar las listas nativas normales y la selección de pestaña según haya resultados. Se conservan los colores nativos; teclado físico, lector y alto contraste quedan pendientes de comprobación manual.
- [x] Implementar el adaptador activable, Resultados y lectura del JSON de Favoritos; integrar configuración, arranque, teclado y retirada.
- [x] Validar casos focalizados y el resultado integrado con el flujo de validación del proyecto, con los límites indicados abajo.
- [x] Actualizar manual de mapa, teclado, historial y contratos con el comportamiento efectivamente entregado.
- [ ] Etapa posterior: memoria de la última pestaña utilizada.
- [ ] Etapa posterior: botones por fila para añadir y eliminar favoritos, navegación derecha/izquierda y escritura persistente de esas acciones.

Siguiente paso de desarrollo: incorporar los botones de gestión de favoritos cuando se solicite. Quedan también la memoria de pestañas y las comprobaciones manuales indicadas en la evidencia.

## Entrega y límites

Entregados `mapa.lua`, la integración en arranque y configurador, la notificación de cierre modal en `ui.lua`, el [manual](../usuario/mapa.md), la entrada del [historial](../CHANGELOG.md#sin-publicar) y las pruebas de `scripts/tests/mapa.lua`.

Validación final del 17 de noviembre de 2026:

- `scripts/validate.ps1`: 10 comprobaciones superadas, cero fallos; 38 archivos compilados con Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos y 147 casos de comportamiento por runtime. Incluye documentación, política de APIs, empaquetado local y Git. Informe `.tools/validation/runs/tmpwr8mb74o/local.json`.
- `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py`: 136 casos en Mudlet 5.1.1 y Lua 5.1, perfil aislado desconectado. Registros finales: 40 teclas, 3 alias y 2 triggers. Informe `.tools/mudlet-integration/runs/142beb8de87f4cb0960d287642fd95db/result.txt`.
- En Mudlet se verificaron controles ocultos al arrancar, JSON real, alias oficiales, ausencia de filas en terminal, aceptación única tras retornar el diálogo, viaje normal y sigiloso con el motor oficial sobre mapa sintético, salidas con puertas y orden diferente, restauración, borrador del configurador, Guardar, apertura pospuesta y recarga con Resultados vacío y Favoritos conservado. Los temporizadores de movimiento se cancelaron antes de enviar comandos.
- La revisión independiente no dejó hallazgos pendientes de código tras corregir la comparación de salidas normalizadas.

La primera integración encontró que reaplicaciones de preferencias pendientes en otras pruebas recargaban el mapa durante la ventana y eliminaban las salas sintéticas. El módulo rechazó esos destinos desaparecidos; el ejecutor deja terminar las operaciones pendientes antes de crear el escenario de mapa.

Límites: no se conectó al juego ni se modificó el portapapeles. La reparación tras `sysInstallPackage` se comprobó emitiendo ese evento sintéticamente; no se reinstaló por completo el paquete durante una ventana abierta. Teclado físico, lectura percibida con lector externo y alto contraste requieren comprobación manual. Favoritos es solo de consulta: no hay altas, bajas ni escritura desde UI en esta fase.

## Revisión de Enter

Se revisa un fallo comunicado al pulsar Enter: la ventana puede cerrarse sin iniciar el viaje. La evidencia anterior invocaba `mapa.aceptar()` directamente, por lo que no acreditaba el recorrido de un evento de teclado nativo.

Se conecta `wxEVT_COMMAND_LIST_ITEM_ACTIVATED` al destino identificado por el evento y se consume la activación, conservando la protección contra duplicados. Además se utiliza el resultado de `ShowModal`: una aceptación estándar `wxID_OK` recupera el destino seleccionado aunque no haya pasado por el manejador de teclado propio. Escape y Cancelar no inician viajes. La acción del enlace oficial se conserva: `RL_speed_walk_to(id)` o `RL_speed_walk_sigilar_to(id)`.

Una prueba dirigida con mensajes Windows al HWND de la lista reprodujo la ausencia de aceptación antes de corregirla y, tras la corrección, comprobó los comandos `norte` y `sigilar norte` capturados del motor oficial. Esos mensajes no equivalen a teclado físico ni garantizan el recorrido del hook global `CHAR_HOOK`. Validación de la corrección, 18 de noviembre de 2026:

- `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py`: 137 casos aprobados en Mudlet 5.1.1/Lua 5.1. Incluye aceptación estándar `wxID_OK` sin captura previa y cierre `wxID_CANCEL` sin viaje. Evidencia `.tools/mudlet-integration/runs/115828a9bae849deaa5b44bebb895429/result.txt`.
- `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py --map-keyboard postmessage`: 139 casos aprobados; mensajes Windows dirigidos exclusivamente al HWND de la lista aislada producen `ITEM_ACTIVATED`, una sola aceptación y los envíos del motor oficial `norte` y `sigilar norte`, capturados sin conexión al juego. Se comprobaron Return normal y numérico. Evidencia `.tools/mudlet-integration/runs/cca388780dba4215ab8e9bbea547bb35/result.txt`.
- `scripts/validate.ps1`: sintaxis, documentación, política de APIs, Luacheck, 147 casos por runtime Lua 5.1 y LuaJIT y Git aprobados. El control de empaquetado falló al sustituir un archivo temporal; el reintento focalizado `.tools/venv/Scripts/python.exe scripts/test_packaging.py` pasó sus cuatro casos. Informe de la ejecución general `.tools/validation/runs/tmpvuk21udy/local.json`; se conserva ese fallo inicial en lugar de reescribir la evidencia.
- La revisión independiente no encontró regresiones en la protección contra duplicados ni en la separación entre aceptación y cancelación.

El diagnóstico optativo `--map-keyboard sendinput` exige primer plano y foco en el diálogo de prueba. Se abortó antes de inyectar teclas porque otra aplicación tenía el primer plano. No se han comprobado teclas físicas ni lectura percibida con lector externo. PostMessage no acredita el hook global de teclado ni permite validar Escape por esa vía; la cancelación se comprueba por su resultado modal y callbacks. No se modificó el perfil del usuario ni se conectó al juego.

## Selector de interfaz, 19 de noviembre de 2026

Alcance: sustituir la presentación booleana por «Interfaz del mapa», selector circular entre «Rhomscripts» (predeterminado) y «Config oficial», con `boton_2` al cambiar. Se conserva la clave y los valores booleanos persistidos para respetar selecciones existentes. No cambia el motor oficial de búsqueda o viaje. Criterios: circularidad en ambas direcciones, etiquetas accesibles, persistencia y aplicación al guardar, cancelación sin efectos y sonido correcto. Estado: implementado y validado localmente y en Mudlet 5.1.1. Siguiente paso manual: teclado físico y lector externo. [Manual](../usuario/mapa.md) y [evidencia](../validacion.md#selector-de-interfaz-del-mapa-19-de-noviembre-de-2026).

## Sonidos propios, 19 de noviembre de 2026

Apertura con `ui.abrir_mapa`, confirmación de destino válido con `ui.seleccionar_mapa` y salida provisional con `ui.plegar`. Se conserva `ui.clic_1` para recorrer la lista; confirmar desde la aceptación nativa o desde la acción de fila solicita el mismo sonido una sola vez, después de validar el destino. Estado: validado localmente y en Mudlet 5.1.1. Siguiente paso manual: teclado físico y percepción con lector externo. [Evidencia](../validacion.md#sonidos-propios-del-mapa-19-de-noviembre-de-2026).

## Favoritos por personaje, 19 de noviembre de 2026

Alcance: formato JSON versión 2, con `personajes` indexado por el nombre obtenido de `ficha.obtener("nombre")`. El formato antiguo se vacía al convertirlo, por decisión del usuario. Cambiar de personaje o perder la identidad refresca los favoritos sin compartirlos; sin nombre no se permite guardar. Añadir o eliminar persiste solo la lista propia conservando las demás. Criterios: aislamiento entre dos personajes, eliminación también en disco, migración vacía, recarga y ausencia de identidad. Estado: implementado y validado, con 152 casos locales por runtime y 150 casos en Mudlet 5.1.1 desconectado. [Evidencia y límites](../validacion.md#favoritos-del-mapa-por-personaje-19-de-noviembre-de-2026). Siguiente paso manual: identidad del servidor real, teclado físico y lector externo.

## Acciones y navegación, 19 de noviembre de 2026

Tab y Mayús+Tab cambian de pestaña sin sonido. El título refleja Resultados o Favoritos, actualizado solo cuando cambia. En Resultados, el mismo botón alterna entre Añadir y Eliminar de favoritos conservando su identidad y foco; Favoritos conserva Eliminar. La retirada voluntaria suprime el aviso genérico de la lista y confirma únicamente «Eliminado de favoritos.». Estado: implementado y validado localmente y en Mudlet 5.1.1. Siguiente paso manual: teclado físico y lectura percibida con lector externo. [Pruebas y límites](../validacion.md#acciones-y-navegación-del-mapa-19-de-noviembre-de-2026).

## Anuncio y refresco de pestañas, 19 de noviembre de 2026

Alcance: anunciar una vez el nombre de la pestaña al cambiar por teclado o selección nativa; evitar selecciones de pestaña redundantes, reutilizar textos y filas mientras no cambie su conjunto y no reescribir nombres o etiquetas idénticos. Conservar título por pestaña, ausencia de sonido, selección y acciones de favoritos por personaje. Estado: implementado y validado localmente y en Mudlet 5.1.1. Siguiente paso manual: comparar rapidez y lectura con teclado físico y lector externo. [Evidencia](../validacion.md#anuncio-y-refresco-de-pestañas-del-mapa-19-de-noviembre-de-2026).
