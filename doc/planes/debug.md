# Diagnóstico centralizado y arranque de RhomScripts

Estado: Cerrado. Familia única y versión implementadas y validadas en Lua y Mudlet real.

Última actualización: 2026-11-17.

## Objetivo y alcance

Centralizar en `rhomscripts/debug.lua` los estados, mensajes técnicos, informes y comandos de diagnóstico de RhomScripts. Simplificar la presentación del arranque y eliminar estadísticas y textos dispersos, conservando el comportamiento funcional y la accesibilidad.

El modo de depuración será compartido con la opción oficial `depuracion`. En el configurador se presentará como «Modo debug» en Interfaz, junto a Ventanas flotantes. La depuración específica MSP seguirá siendo una opción distinta, dentro de las preferencias oficiales.

Diseño aprobado e implementación autorizada el 2026-11-17. Decisiones definitivas: una única opción oficial de debug, familia única `rhomscripts`, historial de 500 mensajes reiniciado al recargar y salida técnica oficial gobernada por su propio filtro compartido. La validación combinada ha pasado; no se da por verificada la lectura externa.

## Evidencia previa a la implementación

- `init.lua` reúne coordinación, limpieza, mensajes de carga y contadores fijos. El total anunciado de seis módulos no se deriva del inventario efectivo.
- `arranque.lua` contiene un registro de estados con código, detalle, fecha y causa; devuelve copias, evita cambios duplicados y emite `rhomscripts.estado.cambiado`. También monitoriza señales oficiales y registra directamente `rhomestado`.
- `keys.lua` conserva los registros efectivos de teclas y declara `listkeys`.
- `aliases.lua` registra `estado`, pero sus informes dependen de un módulo debug que no se carga. Su propio `listalias` no se descubre porque el registrador vive en soporte y el descubrimiento recorre módulos funcionales.
- Los dos triggers activos de captura se gestionan en `comunicaciones_captura.lua`; hoy solo se consulta su cantidad.
- `audio.iniciar` imprime directamente el resumen del catálogo. `sonidos.lua` ya conserva claves, archivos e incidencias. La tabla de solicitudes de audio no prueba reproducción actual.
- La configuración propia guarda `oficial_depuracion` y la aplica a `RL_vars.opciones.depuracion`. Actualmente un cambio oficial puede ser sustituido al reaplicar preferencias propias.
- Lua incluye la biblioteca estándar `debug`: `require("debug")` no identifica de forma segura el archivo del proyecto.

## Responsabilidades y dependencias

### Fachada de diagnóstico

`debug.lua` tendrá cuatro responsabilidades relacionadas: almacenar estados, registrar mensajes técnicos, presentar informes y declarar los comandos de consulta. Las plantillas de texto y el estilo de salida estarán aquí. Los productores comunicarán hechos mediante códigos estables y datos, sin formar párrafos de diagnóstico en cada módulo.

Contrato de la fachada implementada:

- `iniciar_carga()`, `terminar_carga()` y `fallar_carga(error)`: registran y presentan los hitos del arranque.
- `estado.actualizar(componente, codigo, detalle, causa)`: sustituye el estado de un componente independientemente del modo debug.
- `mensaje(modulo, codigo, datos)`: registra el mensaje y lo muestra automáticamente solo cuando el modo compartido esté activo.
- `texto(modulo, texto)`: salida técnica libre para comprobaciones puntuales, con el mismo filtro y registro; las rutas habituales usarán códigos y plantillas.
- `consultar(tipo, filtro)` y `mostrar(tipo, filtro)`: obtienen copias estructuradas o presentan la consulta explícita, incluso con debug desactivado.

El registro y la presentación se separarán internamente, sin añadir jerarquías de clases ni un bus de eventos nuevo. Las transiciones de estado conservarán el evento público existente. Durante la transición, `arranque.estado` podrá delegar al registro único; no mantendrá una segunda copia.

Los módulos seguirán siendo dueños de sus decisiones funcionales. El monitor oficial permanecerá en `arranque.lua`: conexión, GMCP y servicios oficiales no pasarán a ser controlados por debug. La limpieza y propagación de errores seguirá perteneciendo al ciclo de vida del cargador y a los propietarios de recursos.

### Inventarios sin duplicación

Cada propietario expondrá una consulta de sus registros efectivos. Debug reunirá sus resultados al consultar; no conservará una copia paralela de los identificadores ni ejecutará `killKey`, `killAlias` o `killTrigger` por su cuenta.

- Teclas: módulo, nombre, descripción, grupo, combinación declarada, código y modificadores efectivos, identificador y estado de registro.
- Aliases: módulo, nombre, sintaxis de uso, descripción, patrón PCRE, acción identificable, identificador y estado.
- Triggers: módulo, nombre, propósito, patrón PCRE, acción identificable, identificador y estado. No mostrar contenido capturado de las comunicaciones.
- Módulos: nombre, responsabilidad funcional o de soporte, dependencias, fase alcanzada, resultado y error si existe. Los totales se derivan de estos datos.
- Sonidos: grupo de catálogo, clave, archivo relativo, disponibilidad e incidencias. Identificar «archivo accesible/catalogado» sin afirmar que esté decodificado o reproduciéndose. No atribuir un sonido a un único módulo si lo comparten varios.
- Recursos auxiliares: manejadores, temporizadores y ventanas deben poder incorporarse mediante el mismo contrato de consulta cuando exista información real del propietario; no inventar disponibilidad ni contadores.

Los informes agruparán por módulo y ordenarán por nombre de recurso, con encabezados y campos textuales. Para sonidos, el grupo del catálogo y los consumidores conocidos se distinguirán del módulo que administra audio. Habrá resumen de cantidades y filtro opcional por módulo. No se examinarán todos los registros internos del paquete oficial: se mostrará el estado de su integración y sus opciones pertinentes.

### Carga y ciclo de vida

`init.lua` conservará la composición, el orden de dependencias, la coordinación asíncrona y la limpieza. Se apoyará en una secuencia declarativa de módulos y pasos con resultados reales. Debug recibirá los hitos; no será un segundo cargador.

El archivo debug se cargará explícitamente desde la raíz mediante `loadfile(ruta)()`, con comprobación y propagación del error de carga. Se expondrá como `RhomScripts.modules.debug` usando una variable local llamada `depuracion`; se conservarán `_G.debug` y `package.loaded.debug` de Lua.

Preparar los comandos de diagnóstico antes de esperar al paquete oficial permitirá consultar una espera o un fallo parcial. El registrador admitirá este registro temprano y la incorporación posterior de comandos funcionales sin duplicar los de debug. Cada alias tendrá un solo propietario y un solo identificador.

En una recarga se retirarán los recursos de la generación anterior antes de instalar los nuevos. Un fallo de retirada conservará los identificadores pendientes y el diagnóstico, y se propagará. Vaciar mensajes nunca retirará recursos. No se convertirá un fallo obligatorio en un arranque parcial anunciado como correcto.

El propio fallo de carga de debug necesitará un aviso mínimo de emergencia en el cargador, pues el módulo todavía no estará disponible. Esta excepción de arranque no justifica duplicar el resto de la presentación.

## Comportamiento propuesto

### Salida automática

Con debug desactivado y una carga correcta, RhomScripts emitirá únicamente:

1. «RhomScripts · Cargando…» al empezar, antes de la espera oficial.
2. «RhomScripts · Carga correcta.» cuando todos los pasos obligatorios hayan terminado.

Usar tipografía y color sobrios mediante `cecho`, con el resultado expresado también en palabras, restaurando el formato al terminar. Sin barras decorativas, animaciones, repintados ni porcentajes ficticios. Conservar los sonidos de éxito y error y los avisos mediante `announce(texto)` estándar, evitando añadir lecturas duplicadas por el nuevo módulo.

Con debug activado se añadirán los detalles hoy emitidos y los estados estructurados, con módulo y momento identificables. No reproducir automáticamente todo el historial al activar el modo; el usuario podrá consultarlo.

Los errores reales seguirán mostrándose y propagándose con debug desactivado. Ante recursos opcionales degradados, presentar una advertencia breve y reflejar «carga con avisos» en lugar de afirmar éxito completo; el detalle quedará en las consultas. Estar desconectado o esperar datos GMCP no equivale a error ni a carga fallida.

La interacción funcional seguirá visible: lectura y copia, ayuda de teclas, ficha, controles y confirmaciones del configurador. El modo debug no filtrará esos textos.

### Estado e historial

El estado actual se indexará por módulo y componente, conservará código, datos, instante y causa, y devolverá copias. Actualizaciones idénticas no producirán mensajes repetidos. El historial es un búfer circular de los últimos 500 mensajes, reiniciado en cada recarga: registrar mensajes también con debug desactivado sin crecimiento ilimitado ni escrituras a disco.

Registrar solamente metadatos técnicos necesarios. No capturar líneas de juego, conversaciones, GMCP completo, credenciales ni volcados arbitrarios de objetos. Los errores se conservarán como diagnóstico de sesión; cualquier futura exportación requerirá un alcance y tratamiento de datos propios.

Un módulo no alcanzado por un fallo previo constará como «no iniciado por dependencia» o «pendiente», nunca como error propio. Se distinguirán módulos cargados, inicializados, en espera, inactivos y con error. Los archivos archivados no se cargarán para poder enumerarlos.

### Comandos propuestos

Familia principal, siempre disponible con independencia del modo debug:

- `rhomscripts`: ayuda de las consultas y modo compartido actual.
- `rhomscripts estado [modulo]`: estados actuales, esperas, inactivos y avisos.
- `rhomscripts modulos [modulo]`: carga y dependencias, con totales derivados.
- `rhomscripts keys [modulo]`: teclas agrupadas por módulo.
- `rhomscripts alias [modulo]`: comandos y patrones agrupados por módulo.
- `rhomscripts triggers [modulo]`: registros efectivos de captura.
- `rhomscripts sonidos [grupo]`: catálogo y problemas de archivos.
- `rhomscripts mensajes [modulo]`: últimos 500 mensajes técnicos de esta carga.
- `rhomscripts version`: versión de distribución y fecha, mantenidas únicamente en debug; el evento `rhomscripts.ready` usa esa misma fuente. Valor actual: `1.0, 17/11/2026`.

La única entrada de consultas es `rhomscripts`; se retiran `rhomdebug`, `estado`, `rhomestado` y todos los accesos `list…`. Los listados usan bloques por recurso sin depender de columnas alineadas. Se conserva el anuncio explícito del resumen de estado sin anuncios masivos de inventarios.

### Modo compartido y configurador

La única autoridad es `RL_vars.opciones.depuracion == true`, consultada directamente tanto por el filtro de RhomScripts como por el sistema oficial. Antes de que exista la tabla de opciones oficiales, el filtro propio considera debug desactivado. No hay copia confirmada propia ni sondeo periódico. La salida técnica del paquete sigue utilizando su propio mecanismo y la misma opción; no se interceptan las funciones generales de salida.

El configurador presenta una opción virtual `oficial_depuracion`, con etiqueta «Modo debug», categoría Interfaz y `persistente = false`. Leer obtiene el estado oficial; Guardar persiste primero las preferencias propias y llama después a `RL_fijar_opcion("depuracion", valor)` cuando corresponde. Se comprueba el retorno y se conserva un guardado pendiente si falla tras modificar la memoria. Cancelar no aplica el borrador. Mientras el usuario no haya editado ese campo, la sesión obtiene su valor oficial actualizado para no sobrescribir un cambio externo; editarlo o Restablecer predeterminados expresa intención de aplicar el valor del borrador.

La migración de JSON 1 y 2 retira el campo histórico `oficial_depuracion` y reescribe las restantes preferencias conservadas. No aplica ese valor antiguo al paquete. `configuracion.reset()` omite la opción virtual: inicializar el módulo no desactiva la depuración oficial.

La depuración MSP sigue siendo un filtro específico oficial: su fuente llama a `RL_debug`, por lo que requiere también el modo general. No fusionar ambos valores.

## Fuentes verificadas

- [ZIP oficial de Reinos](https://mudlet.reinosdeleyenda.es/RLMud_Config.zip), descargado el 2026-11-17. SHA-256: `b98d315642f784789485f6d536a5c83bdb8aa4557e827e4da4dd2c205dd201a4`, coincide con la referencia de [contratos](../contratos-mudlet.md). XML: `RL_debug(a, txt)` consulta `RL_dame_opcion("depuracion") == true`; `RL_fijar_opcion(opcion, valor)` guarda y emite `rlmud_fijar_opcion_` más el nombre con el valor como argumento; `RL_borrar_opcion(opcion)` guarda y emite el evento equivalente de borrado. No constan versiones mínimas para estas funciones del paquete.
- [Manual oficial de salida](https://wiki.mudlet.org/w/Manual:Lua_Functions#cecho), copia local [Lua_Functions.txt](../mudlet/Lua_Functions.txt): `cecho([window], text)` acepta etiquetas de color y formato; `<reset>` restablece colores. No se requiere un retorno para la propuesta ni consta versión mínima general en la sección consultada.
- [Manual de accesibilidad](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#announce), copia local [Miscellaneous_Functions.txt](../mudlet/Miscellaneous_Functions.txt): conservar la llamada estándar `announce(texto)`.
- [Publicación oficial de Mudlet 5.1.1](https://www.mudlet.org/2026/11/mudlet-5-1-1-2/), última estable localizada en la consulta del 2026-11-17. La ejecución final ha contrastado y probado Mudlet 5.1.1; véase la evidencia de entrega.

## Criterios de aceptación y validación prevista

- Carga normal con debug desactivado: dos hitos propios, sin detalles técnicos automáticos; consultas completas disponibles.
- Debug activado: detalles de preparación, catálogo, registros y carga visibles y asociados a su módulo.
- Estado almacenado con debug desactivado; cambios iguales no duplican mensajes; historial limitado a 500 mensajes y reiniciado al recargar.
- Todos los inventarios derivan de recursos efectivos; patrones, identificadores, módulos y totales coherentes. No afirmar reproducción o negociación sin evidencia.
- Fallo de dependencia: error visible, limpieza comprobada, fallo relanzado, módulos no alcanzados correctamente diferenciados y consultas conservadas cuando el diagnóstico ya se preparó.
- Doble carga, recarga durante espera y fallo durante retirada: sin alias, teclas, triggers, handlers ni temporizadores duplicados o huérfanos.
- Biblioteca estándar `debug` intacta, incluidos los consumidores de `debug.traceback`.
- Cambio oficial y guardado/cancelación del configurador conforme a la decisión de sincronización. La migración descarta la antigua copia propia de debug sin alterar el valor oficial, que conserva la autoridad y su persistencia.
- Pruebas focalizadas de datos, límites, inventarios y errores; suite de integración final según [validación](../validacion.md). Mudlet real aislado y desconectado para registros, eventos, presentación y recarga. Registrar la versión probada y separar observación visual, lectura externa y simulación.

## Etapas y siguiente paso

- [x] Inspeccionar arranque, estados, registros, configurador y contrato oficial.
- [x] Preparar propuesta y consultar decisiones de comportamiento.
- [x] Resolver decisiones y ajustar esta ficha.
- [x] Implementar registro, consultas, plantillas y modo compartido.
- [x] Integrar inventarios y simplificar init/arranque sin mover decisiones funcionales a debug.
- [x] Validar resultado combinado y revisión independiente, actualizar manual, contratos e historial de cambios.

Decisiones cerradas: modo único oficial con persistencia oficial; familia única `rhomscripts`; 500 mensajes en memoria reiniciados al recargar; el paquete oficial conserva su filtro y su propia presentación.

Siguiente paso: entrega completada; el uso físico con lector externo mantiene los límites descritos en la evidencia.

## Entrega inicial y límites

Implementación aplicada y documentada en el [manual de debug](../usuario/debug.md) y el [historial de cambios](../CHANGELOG.md#sin-publicar), conservando los cambios previos de ficha, lector y teclado. `./scripts/validate.ps1 -Mudlet` ha superado diez controles locales, 136 casos en Lua 5.1, 136 en LuaJIT 2.1.1760617492 y 122 casos en Mudlet 5.1.1. La revisión independiente no dejó bloqueos pendientes. Se corrigieron durante la integración dos supuestos de la instrumentación: contar como llamadas distintas los `echo` internos de `cecho` y exigir que el error interno real mencionase literalmente `echo`. Las pruebas comprueban ahora las llamadas superiores y el contexto de propagación, sin omitir errores. Consultar la [evidencia integrada](../validacion.md#debug-centralizado) para el resultado final y sus límites. No se ha comprobado aquí la lectura percibida con lector externo.

## Simplificación de consultas y versión, 17 de noviembre de 2026

Cambio autorizado: sustituir los accesos duplicados por `rhomscripts [consulta] [filtro]`, sin aliases de compatibilidad. `debug.version()` conserva `1.0, 17/11/2026`; init consulta esa función al emitir ready. La versión se muestra y anuncia mediante `rhomscripts version`. La familia admite mayúsculas o minúsculas en el comando y el nombre de consulta. Los comandos funcionales del lector permanecen fuera del diagnóstico.

Validación de esta ampliación: diez controles locales superados, 138 casos en cada runtime y 125 casos en Mudlet 5.1.1 aislado y desconectado. Se verificaron los comandos reales, una sola declaración de diagnóstico sin nombres antiguos, mayúsculas y coherencia de versión entre texto, anuncio y evento ready. Recuentos: 39 teclas, 3 aliases (familia de consultas y dos comandos del lector) y 2 triggers. La prueba de audio se corrigió para observar la clave real tras procesar Qt, conservando sus comprobaciones de parámetros y parada; no se cambió código productivo de audio. [Evidencia](../validacion.md#familia-única-y-versión).
