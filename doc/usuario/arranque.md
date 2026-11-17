# Arranque y monitor de estado

`arranque.lua` reúne la preparación antes contenida en `comprobaciones.lua` y la aplicación de preferencias de `oficial.lua`. `init.lua` conserva la secuencia de carga y limpieza; `debug.lua` reúne los estados y la presentación. La configuración oficial no conecta al juego. Con debug desactivado, la carga normal presenta únicamente «Cargando…» y «Carga correcta.»; los avisos y errores siguen comunicándose. [Modo compartido y comandos de diagnóstico](debug.md).

## Consulta

`rhomscripts estado` muestra y anuncia el resumen. Su declaración pertenece a debug y la instala el registrador central de aliases.

El resumen ordena los diez componentes y añade los avisos registrados. Los comandos se preparan antes de la espera oficial, de modo que pueden consultarse durante esa espera o tras un fallo posterior. Se retiran y vuelven a registrar al recargar. No abren ventanas ni reproducen sonidos. `rhomscripts estado gmcp` filtra el componente y lo presenta como informe textual.

Desde Lua: `RhomScripts.modules.debug.estado.consultar()` devuelve una copia completa del registro. `RhomScripts.soporte.arranque.estado` conserva la misma API como fachada del registro único. `estado.consultar("gmcp")` devuelve una copia del componente GMCP. Cada entrada contiene `codigo`, `detalle`, `actualizado` (segundos Unix) y `causa`. Modificar las copias no modifica el registro. El estado es de sesión y no se guarda en disco; una recarga lo reconstruye con la información disponible.

Componentes, en orden de lectura:

- `scripts`: iniciando, cargados o error.
- `paquete`: comprobando, descargando, instalando, esperando, inicializando, preparado, ausente o error.
- `preferencias`: pendientes, aplicando, aplicadas o error; el detalle conserva las acciones dependientes del servidor que siguen pendientes.
- `conexion`: conectada o desconectada.
- `gmcp`: esperando, habilitado, activo, deshabilitado, finalizado o desconectado.
- `ficha`, `estado_personaje` y `comunicaciones`: pendiente o recibido, por separado.
- `msp`: pendiente, desactivado o inicializado localmente.
- `recursos_msp`: pendiente, sin verificar, descargando, extrayendo, disponibles o error. «Disponibles» confirma extracción del ZIP, no reproducción audible ni integridad de cada sonido.

## Funciones públicas

Estado:

- `estado.consultar([componente])`: copia del registro o de una entrada.
- `estado.actualizar(componente, codigo, detalle, causa)`: modifica una entrada y devuelve si cambió. Solo emite un evento si cambian el código o el detalle. La causa identifica el último cambio efectivo.
- `estado.resumen()`: texto del resumen, sin salida ni anuncio.
- `estado.mostrar()`: imprime y anuncia el resumen y devuelve ese texto.

Monitorización:

- `monitorizacion.iniciar()`: registra observadores y toma el estado inicial. Llamarlo de nuevo mientras está activo no duplica recursos. Los aliases de consulta se preparan por separado desde debug.
- `monitorizacion.detener()`: retira exclusivamente sus observadores; conserva el último registro para consulta programática.

Preparación:

- `cargar_wx()`, `cargar_nativo()` y `bibliotecas()`: preparación nativa obligatoria. Conservan las instancias DLL entre recargas.
- `nuevo()`: crea un controlador de preparación oficial con `iniciar(continuar, fallar)` y `cancelar()`. La espera de inicialización local tiene un máximo de 60 segundos.

Preferencias oficiales:

- `aplicar_configuracion(configuracion)`: aplica las preferencias guardadas y devuelve los mensajes pendientes; los fallos se registran y se propagan.
- `vigilar()`: observa las señales oficiales para reaplicar las preferencias guardadas; no utiliza los cambios de un borrador abierto.
- `cancelar_configuracion()`: retira esos observadores y la reaplicación diferida.

Los observadores del monitor y de las preferencias tienen responsabilidades distintas. La recarga cancela ambos y la preparación pendiente antes de crear la nueva instancia. Ante un fallo de carga se cancela la preparación y la reaplicación de preferencias; el registro y los aliases de diagnóstico ya preparados se conservan para poder consultar el error.

## Notificaciones y evidencias

Un cambio emite `rhomscripts.estado.cambiado`, con argumentos `componente`, `codigo` y `detalle`. Un consumidor puede escuchar ese evento y consultar el registro; no necesita repetir comprobaciones. Todavía no hay barra de estado.

`sysConnectionEvent` confirma conexión, no negociación. `sysProtocolEnabled`, con argumento `GMCP`, confirma el protocolo; `gmcp.Core.Hello` confirma recepción del saludo. `rl_gmcp_hello` es una señal interna del paquete oficial y también se emite desde caminos de inicialización local: nunca activa por sí sola el estado GMCP.

La ficha y el estado se confirman con `gmcp.Char.Ficha` y `gmcp.Char.Status`. Las comunicaciones se confirman con `gmcp.Comm.Canales`, `gmcp.Comm.MensajeCanal` o `gmcp.Comm.MensajeCanalHistorico`. La desconexión, deshabilitación de GMCP y despedida retiran las confirmaciones anteriores. Una nueva conexión empieza esperando, aunque permanezcan tablas antiguas. Al cargar el monitor dentro de una conexión ya existente, se consulta el saludo y los datos disponibles en memoria; no se atribuye una hora de recepción anterior desconocida.

`rlmud_config_loaded` y `rlmud_opciones_inicializadas` informan de preparación local. La confirmación del controlador comprueba además nombre, ruta y opciones. Las preferencias aplicadas se registran desde la propia operación de aplicación, no se infieren de un evento de GUI.

Ambos eventos reconcilian el estado del paquete con su nombre, ruta y tabla de opciones. El paquete puede emitir `rlmud_opciones_inicializadas` de forma anidada durante `rlmud_config_loaded`; recibir después la señal exterior no hace retroceder un paquete localmente preparado a inicializando.

MSP se determina por las opciones y las estructuras oficiales. La descarga y extracción se siguen con `sysDownloadDone`, `sysDownloadError`, `sysUnzipDone` y `sysUnzipError`, filtrados por el ZIP MSP actual. No se atribuyen al MSP descargas de mapa u otros paquetes. El paquete no emite un evento propio al comenzar cada descarga o reproducir correctamente un sonido; el monitor no certifica esas acciones ni observa todos los cambios arbitrarios de tablas externas. No usa sondeo periódico.

Contratos de eventos: [documentación oficial local de Mudlet](../mudlet/Event_Engine.txt), secciones de los eventos citados. `sysUninstallPackage` está documentado desde 3.1; los eventos de extracción, desde 4.6. Las secciones de protocolo no especifican versión mínima. La semántica de los eventos `rlmud_*` se ha comprobado en el XML del paquete oficial instalado el 9 de noviembre de 2026. Véanse también los [contratos de integración](../contratos-mudlet.md).
