# Contratos de Mudlet utilizados por RhomScripts

Objetivo permanente: última versión estable disponible. Referencia comprobada en esta revisión: Mudlet 5.1.1, el 6 de noviembre de 2026. Este número registra evidencia; no sustituye la política de actualizar y verificar.

Las funciones se llaman directamente. Una función inexistente debe producir error; no se comprueba su presencia para omitirla o sustituirla. Las recomendaciones de compatibilidad genéricas de la wiki no cambian esta decisión del proyecto.

## Dependencia oficial de Reinos, 7 de noviembre de 2026

`getPackages()` devuelve la tabla de nombres instalados (4.12+). `installPackage(location or url)` instala un paquete; en la versión objetivo devuelve `true` al tener éxito, o `nil` y mensaje al fallar (retorno de éxito corregido desde 4.20). `downloadFile(saveto, url)` descarga sin bloquear, con HTTPS desde 3.0. `sysDownloadDone(event, filename, ...)` identifica el archivo terminado y `sysDownloadError(event, reason, filename, ...)` identifica el fallido. Se filtra por ruta propia antes de instalar, para no consumir descargas del mapa o sonidos oficiales.

`registerAnonymousEventHandler(event, functionReference)` devuelve un identificador (3.5+ para funciones directas e identificador); se retira con `killAnonymousEventHandler(id)`. `tempTimer(seconds, function)` devuelve un identificador, que se retira con `killTimer(id)` si aún está pendiente. Un temporizador cero difiere la continuación hasta después de la pila de eventos actual. `sysInstallPackage(event, packageName, filename)` (3.1+) no sustituye la inicialización de opciones y no se emite simplemente por abrir un perfil.

Fuentes oficiales: [paquetes y eventos anónimos](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions), [eventos](https://wiki.mudlet.org/w/Manual:Event_Engine), [descargas](https://wiki.mudlet.org/w/Manual:Lua_Functions#downloadFile) y [temporizadores](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#tempTimer). Las fuentes copiadas están en [Miscellaneous_Functions.txt](mudlet/Miscellaneous_Functions.txt), [Event_Engine.txt](mudlet/Event_Engine.txt), [Lua_Functions.txt](mudlet/Lua_Functions.txt) y [Mudlet_Object_Functions.txt](mudlet/Mudlet_Object_Functions.txt). Las versiones mínimas no indicadas aquí no están especificadas por la sección consultada.

Fuente del paquete: [ZIP oficial](https://mudlet.reinosdeleyenda.es/RLMud_Config.zip), corroborado en el [foro del juego](https://www.reinosdeleyenda.es/foro/respuesta/335480/). Descarga comprobada el 7 de noviembre de 2026: 694912 bytes, SHA-256 `b98d315642f784789485f6d536a5c83bdb8aa4557e827e4da4dd2c205dd201a4`; XML `0bca1cf09f614e04f418782d8ee52c894622e878b6821c6da4d17591477dd750`, idéntico al perfil inspeccionado. Es una referencia de esta revisión, no una versión fijada por el runtime.

En esa copia, `RL_inicializar` emite `rlmud_config_loaded`, `RL_opciones` carga las preferencias y emite `rlmud_opciones_inicializadas`. No existe una señal global de finalización de todos los servicios. El adaptador espera la señal local y difiere su continuación; para un paquete ya inicializado comprueba `RL_vars.name`, `path` y `opciones`. Esto acredita estado local de inicialización, no recepción GMCP, habilitación de cada grupo ni finalización de descargas. No fuerza reinicios ni comprueba existencia de funciones para ocultar errores.

## Aplicación de preferencias oficiales, 7 de noviembre de 2026

`getConnectionInfo()` devuelve host, puerto y conectado (API 4.2+, tercer booleano 4.12+). Una conexión TCP no confirma negociación GMCP; para las acciones que necesitan el servidor se comprueba además el estado de dominio `gmcp.Core.Hello`. `getFontSize([windowName])` devuelve el tamaño actual de consola (3.4+). `isActive(name, "keybind")` devuelve un contador, no un booleano; el tipo keybind está documentado desde 3.2. `enableKey(name)` y `disableKey(name)` controlan una tecla o grupo; las secciones consultadas no especifican su versión mínima. Fuentes: [conexión](https://wiki.mudlet.org/w/Manual:Lua_Functions#getConnectionInfo), [fuente](https://wiki.mudlet.org/w/Manual:Lua_Functions#getFontSize) y [grupos de teclas](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#disableKey), conservadas en las copias locales citadas arriba.

El gestor nativo `gmod` se verifica en el [fuente oficial GMCP.lua de Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/mudlet-lua/lua/GMCP.lua), conservado como [GMCP.lua](mudlet/GMCP.lua), con [procedencia y hash](mudlet/gmcp-source.json). Esta fuente acredita la versión de referencia, no una versión mínima. `gmod.isRegisteredModule(module)` devuelve false o una tabla de usuarios. `gmod.enableModule(user, module)` registra al usuario y solicita el módulo si no existía. `gmod.disableModule(user, module)` retira al usuario y solo elimina la suscripción cuando no quedan usuarios. No tienen retorno booleano de éxito; disable devuelve `"no registered module"` si no existía. Registran estado local también offline; no acreditan respuesta del servidor.

RhomScripts usa el usuario `RhomScripts` para Comm. Al desactivar comunicaciones retira el usuario oficial vacío y el propio, sin retirar usuarios de otros paquetes. Tras una reconstrucción de GUI se aplica la elección de comunicaciones. Los manejadores de eventos conservan una copia de los últimos valores guardados, no las ediciones pendientes del menú; se retiran al recargar.

El contrato de las funciones `RL_*` procede del XML del ZIP oficial identificado arriba. Las opciones se modifican en lote en `RL_vars.opciones` y se guardan mediante `RL_salvar_opciones(true)`; se comprueba su retorno. No se usa el setter individual para fuente: su evento llama a un listener que accede a un panel que puede estar ausente y no actualiza correctamente cada consola. `RL_gui_reinicializar()` se llama como máximo una vez por aplicación para interfaz/canales; el cambio de fuente usa `RL_gui_fijar_tamanyo_fuente_consola(canal, size)`, con rango oficial 8–50, sin borrar historiales. Cero en nuestro JSON elimina la opción de fuente y conserva el tamaño predeterminado dinámico.

Las macros activadas sin ficha quedan pendientes y su grupo deshabilitado hasta contar con los datos; `RL_macros_activar(true)` ejecuta la activación oficial. `RL_inicializar_MSP()` prepara MSP y puede descargar sonidos; `RL_msp_stop_all()` detiene todos los sonidos, por lo que solo se ejecuta al desactivar o si quedan reproducciones oficiales. `RL_discord_inicializar()` necesita negociación; desactivar su opción retira el temporizador oficial, sin restablecer la presencia global de otros paquetes. No se fabrican respuestas de servidor para probar estas ramas como integración real.

El JSON propio de formato 2 se guarda antes de ejecutar las acciones oficiales. Un fallo posterior añade contexto, conserva el menú abierto y se relanza. Un guardado oficial pendiente se reintenta aunque la tabla en memoria ya coincida con el objetivo. El formato 1 válido se migra conservando los cuatro volúmenes. Las preferencias iniciales son las oficiales y todo sigue activable para pruebas. El alias `configurarficha` deja de enviar las tres desactivaciones de consentimiento remoto, sin sustituirlas por activaciones ni equiparar permiso GUI del servidor con GUI local.

## Perfil y persistencia

`getMudletHomeDir()` ya devuelve el directorio del perfil actual. No añadir `/profiles/nombre` otra vez. Configuración anterior de modos: `getMudletHomeDir() .. "/rl_config.lua"`. Las preferencias nuevas de `configuracion.lua` se guardan por separado en `getMudletHomeDir() .. "/config.json"`; no se migra ni se modifica todavía `modes.lua`.

`yajl.to_string(datos)` devuelve una cadena JSON; `yajl.to_value(texto)` decodifica la cadena. La documentación no especifica versión mínima. El configurador usa un objeto de formato versionado, valida tipos/rangos y regenera documentos defectuosos sin copias. El análisis protegido del contenido va precedido de una llamada directa con `{}` para que una API ausente se propague. [Fuente oficial](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#yajl.to_string), copia en [Miscellaneous_Functions.txt](mudlet/Miscellaneous_Functions.txt) y [contrato completo de configuración](migraciones/configuracion.md).

`table.save(ruta, tabla)` guarda la tabla; `table.load(ruta, destino)` rellena una tabla existente. No se usa el retorno como tabla cargada y no se prueban firmas alternativas. `loadTable` y `saveTable` no son APIs aprobadas para este proyecto.

Fuentes: [perfil](https://wiki.mudlet.org/w/Manual:File_System_Functions#getMudletHomeDir), [table.load](https://wiki.mudlet.org/w/Manual:Table_Functions#table.load) y [table.save](https://wiki.mudlet.org/w/Manual:Table_Functions#table.save). Copias en [File_System_Functions.txt](mudlet/File_System_Functions.txt) y [Table_Functions.txt](mudlet/Table_Functions.txt). Firmas verificadas también mediante integración real.

## Buffer y lector de pantalla

`getLastLineNumber("main")` obtiene el índice de la última línea. `getLines("main", inicio, fin)` devuelve una tabla; el extremo final es exclusivo, verificado en Mudlet 5.1.1. Para una línea se usa `(índice, índice + 1)`.

`announce(texto[, procesamiento])` anuncia texto mediante la accesibilidad de Mudlet; documentado desde 4.17. Se usa con lector de pantalla externo, sin SAPI ni compatibilidad con SAPI. Se conserva announce(texto) estándar; la cola o interrupción según el mensaje se diseñará después. `setClipboardText(texto)` y `getClipboardText()` permiten probar copia y restauración.

Fuentes: [getLines](https://wiki.mudlet.org/w/Manual:Text_Window_Functions#getLines), [getLastLineNumber](https://wiki.mudlet.org/w/Manual:Text_Window_Functions#getLastLineNumber) y [announce](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#announce). Copia conjunta en [Lua_Functions.txt](mudlet/Lua_Functions.txt).

## Registros, teclado y regex

`tempKey([modificador,] código, función)`, `tempAlias(patrón, función)` y `tempRegexTrigger(patrón, función)` devuelven identificadores. Guardarlos y retirarlos con `killKey`, `killAlias` y `killTrigger` antes de recargar. Temporal significa que el registro no persiste al cerrar; no significa que se retire solo al volver a ejecutar el código.

El teclado numérico usa los códigos normales, por ejemplo `mudlet.key["8"]`, combinados con `mudlet.keymodifier.Keypad`. No inventar `Num8`, `Numpad8` o `Keypad8`. Los códigos del doble proceden del [archivo oficial de la release](mudlet/keycodes-source.json), conservado como [KeyCodes.lua](mudlet/KeyCodes.lua).

`feedTriggers(texto)` introduce texto en el motor real. Las capturas PCRE usan `matches[1]` para la coincidencia completa y `matches[2]` para el primer grupo. No evaluar estos patrones con `string.find`, que interpreta patrones Lua.

init.lua mantiene un único catálogo de módulos e invalida sus cachés una vez antes de cargar. Las dependencias anticipadas no se vuelven a crear al publicarlas después en RhomScripts.modules. Los eventos de grupo y las teclas F4/Shift+F4 deben compartir la misma instancia de eventos también tras recargar.

Fuentes: [registro de objetos](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions), [feedTriggers](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#feedTriggers) y [variables globales](https://wiki.mudlet.org/w/Manual:Lua_Functions#Global_variables). Copias en [Mudlet_Object_Functions.txt](mudlet/Mudlet_Object_Functions.txt) y [Miscellaneous_Functions.txt](mudlet/Miscellaneous_Functions.txt).

## Audio

`audio.reproducir(clave, opciones)` llama directamente a `playSoundFile` con la ruta, el volumen efectivo, el identificador y la etiqueta de RhomScripts. La firma con tabla está documentada desde Mudlet 4.15. Los errores devueltos por Mudlet se comunican y la ausencia de la función produce error.

`playSoundFile(tabla)` también admite `loops` y, desde Mudlet 5.1, `pan` entre -100 y 100. La interfaz de reproducción por clave deja estas opciones pendientes.

`stopSounds({key = clave})` o `stopSounds({tag = etiqueta})` detienen los sonidos correspondientes. `getPlayingSounds(filtro)` permite observar el estado real. Qt procesa cambios de estado de forma asíncrona: la prueba de parada cede al bucle de eventos antes de comprobar que el bucle ha terminado.

Fuentes: [playSoundFile](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#playSoundFile), [stopSounds](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#stopSounds) y [getPlayingSounds](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#getPlayingSounds). Copia en [Miscellaneous_Functions.txt](mudlet/Miscellaneous_Functions.txt). Las llamadas, reproducción registrada y parada se comprobaron en 5.1.1; la calidad audible continúa siendo una prueba de uso.

### Catálogo de sonidos integrado, 11 de noviembre de 2026

Mudlet incluye LuaFileSystem. El [manual de Mudlet](https://wiki.mudlet.org/w/Manual:File_System_Functions) lo confirma y la [copia local](mudlet/File_System_Functions.txt) conserva esa referencia. El [manual de LuaFileSystem](https://lunarmodules.github.io/luafilesystem/manual.html#reference) documenta las firmas siguientes. Las fuentes consultadas no fijan una versión mínima de Mudlet para estas funciones.

- `lfs.dir(ruta)` devuelve un iterador y un objeto directorio. Cada paso devuelve el nombre de una entrada o `nil` al terminar. Una ruta que no es un directorio provoca error.
- `lfs.symlinkattributes(ruta, "mode")` devuelve el tipo del objeto o `nil` con un diagnóstico si la consulta falla. El manual indica que en Windows equivale a `lfs.attributes`; la distinción de enlaces simbólicos depende de la plataforma.
- `lfs.currentdir()` devuelve el directorio actual o `nil` con un diagnóstico. Se usa para resolver rutas relativas a rutas completas.
- `io.open(ruta, "rb")` devuelve un archivo abierto o `nil` con diagnóstico. La comprobación de apertura acredita que el archivo se puede abrir. Fuente: [manual Lua 5.1](https://www.lua.org/manual/5.1/manual.html#pdf-io.open).

El comportamiento actual se describe en [Sonidos de RhomScripts](usuario/sonidos.md) y su comprobación real en [validación del catálogo integrado](validacion.md#catálogo-de-sonidos-integrado-11-de-noviembre-de-2026). Última release estable consultada el 11 de noviembre de 2026: [Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/releases/tag/Mudlet-5.1.1).

## Ventanas persistentes wxLua, revisión documental del 8 de noviembre de 2026

La política solicitada es construir las ventanas ocultas al preparar los módulos, conservar sus controles al cerrar y destruirlas durante la recarga. Las preferencias de usuario y los borradores siguen perteneciendo a sus módulos. Esta sección verifica las APIs y sus restricciones; no constituye evidencia de ejecución del cambio.

Referencia de bibliotecas: wxLua 3.2.0.2, commit `d80dddbd78a1f93ea5f40e163f6d246da28a65ed`, y wxWidgets 3.2.8/MSW, coincidentes con el manifiesto instalado. La versión mínima histórica de Show, IsShown, Destroy, ShowModal, EndModal e IsModal no se fija en las secciones consultadas; se acredita su presencia en esas versiones. Las declaraciones de [wxWindow en el binding](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_windows.i) y [wxDialog en el binding](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_dialogs.i) exponen directamente los métodos siguientes.

`ventana:Show(booleano)` devuelve true cuando cambia la visibilidad y false si ya tenía la solicitada; false al ocultar una ventana ya oculta es un resultado normal. `ventana:IsShown()` devuelve su estado mostrado/oculto. Los diálogos superiores nacen ocultos, lo que permite preparar controles sin mostrarlos. `ventana:Destroy()` devuelve true si el objeto se ha eliminado o su eliminación queda pendiente; las ventanas superiores pueden borrarse durante el procesamiento posterior de eventos. Destruir el padre destruye sus controles hijos. Tras solicitar destrucción se debe impedir reutilizar sus referencias. [Contrato wxWindow 3.2.8](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/interface/wx/window.h).

`dialogo:IsModal()` devuelve booleano. `dialogo:ShowModal()` devuelve el entero de resultado cuando termina su bucle; `dialogo:EndModal(codigo)` no devuelve valor, establece ese resultado y oculta el diálogo sin destruirlo. EndModal exige un diálogo modal y ShowModal no admite una segunda entrada modal simultánea. Show(false) también permite ocultar un diálogo modal, pero EndModal es la salida normal cuando debe fijarse un resultado. [Contrato wxDialog 3.2.8](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/interface/wx/dialog.h).

El [fuente MSW de wxDialog 3.2.8](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/src/msw/dialog.cpp) mantiene el estado modal hasta que retorna ShowModal, incluso después de llamar EndModal. Por ello la guardia de cierre debe impedir una reapertura o un segundo cierre durante ese intervalo. La ruta de cierre propia debe consumir el evento, sin delegar después a una acción predeterminada que contradiga la conservación del diálogo. Esta es una consecuencia de la implementación consultada, pendiente de validación en el perfil aislado.

`objeto:CallAfter(funcion)` no devuelve valor y programa una ejecución posterior. El binding lo habilita desde wxWidgets 2.9.5; retiene la función Lua y la libera al ejecutarla, propagando su error. Se verifican la [declaración wxLua](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxbase_base.i), el [override Lua](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxbase_override.hpp) y la [documentación de wxEvtHandler](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/interface/wx/event.h). Un foco diferido debe validar la apertura concreta y el estado vigente: una función pendiente de una apertura anterior no debe activar una reapertura posterior ni una ventana destruida.

Freeze() y Thaw() existen y no devuelven valor, pero deben equilibrarse incluso ante error. Congelan el repintado y no constituyen una garantía de silencio del lector externo. No son necesarios para construir una ventana superior oculta; incorporarlos requiere una necesidad observada y limpieza garantizada. No se atribuye una mejora de accesibilidad o rendimiento por su mera disponibilidad.

Copias exactas de las ocho fuentes consultadas y manifiesto con URL, tamaño y SHA-256: `.tools/doc-reference-cache/wx-persistencia-2026-11-08/manifest.json`. No se han actualizado ni sustituido los manuales históricos. La integración Qt/wx, la repetición de aperturas y cierres, la recarga y la lectura percibida requieren sus pruebas correspondientes.
