# Validación de RhomScripts

## Sonido propio de las pestañas de comunicaciones, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles aprobados, 152 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmp_faqenhy/local.json`; integración STATUS OK con 150 casos en Mudlet 5.1.1/Lua 5.1, última estable consultada por el ejecutor, informe `.tools/mudlet-integration/runs/ddb42ced369b4936a04f20dbb3076639/result.txt`. El caso de componentes reales verifica el valor predeterminado `ui.pestana`, sobrescritura por `ui.seleccion_canal`, una sola solicitud por cambio y silencio al seleccionar la misma pestaña. El mapa conserva su sonido predeterminado y anuncios.

`scripts/run_wxlua_probe.py --comunicaciones`: STATUS OK, 44 casos en Mudlet 5.1.1/wxWidgets 3.2.8; informe `.tools/wxlua-probe/runs/a43e51b66708428d856d156ecd725884/result.txt`. Las pruebas compartidas de categorías esperan `ui.seleccion_canal` tanto en global como en otros canales; se mantienen navegación nativa, Tab, Room y recarga. Perfiles aislados desconectados y portapapeles conservado. Pendientes teclado físico y escucha con lector externo.

## Sonido compartido de pestañas, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados, 152 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmpwra1fqji/local.json`; integración STATUS OK con 150 casos en Mudlet 5.1.1/Lua 5.1, última estable consultada por el ejecutor, informe `.tools/mudlet-integration/runs/9b5b8de81b504f1cbc6f0014fc7c40f4/result.txt`. El componente común y el mapa verifican una solicitud `ui.pestana` por cambio efectivo, sin solicitudes al preparar o seleccionar la misma pestaña; se mantienen los anuncios, el título y las optimizaciones anteriores. El catálogo comprueba la clave y la ruta real `UI/Pestana.wav`.

`scripts/run_wxlua_probe.py --comunicaciones`: STATUS OK, 44 casos en Mudlet 5.1.1/wxWidgets 3.2.8, informe `.tools/wxlua-probe/runs/4122a1031e684f399a4597b363a058b6/result.txt`. Incluye pestañas nativas, Tab y categorías de canales/Room. Los atajos utilizan `ui.sonido_pestana()` y el callback nativo evita un segundo aviso.

El WAV aportado se renombró de Pestaña.wav a Pestana.wav para mantener el contrato ASCII y evitar la incidencia de apertura del nombre Unicode observada en los dos runtimes locales. Se conservó el contenido del archivo. Perfiles aislados y desconectados; portapapeles sin cambios. Pendientes teclado físico y percepción auditiva con lector externo.

## Anuncio y refresco de pestañas del mapa, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados, 152 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmph6gxiwt6/local.json`; integración STATUS OK con 150 casos en Mudlet 5.1.1/Lua 5.1, última estable consultada por el ejecutor, informe `.tools/mudlet-integration/runs/a42c1d7fa59c46088e9ebce1e608c946/result.txt`.

La regresión real verifica tres cambios consecutivos por la política Tab/Mayús+Tab: un announce con el nombre de destino por cambio, ningún sonido, tres llamadas a selección de página (sin reselección desde refrescar), y reutilización de la misma tabla de filas al volver a Favoritos. Seleccionar la misma pestaña no vuelve a anunciarla. Se mantienen las pruebas de títulos, botones alternables, borrado y separación por personaje. El mapa cachea las filas según el conjunto de datos y evita actualizar la lista completa si solo cambian las acciones; no reescribe etiquetas ni nombres idénticos.

Esta evidencia acredita menos trabajo repetido, no una reducción medida de latencia percibida respecto a canales. Pendientes teclado físico, comparación de rapidez y lectura con lector externo. Perfil aislado desconectado y portapapeles conservado.

## Acciones y navegación del mapa, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados, 152 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmplexc8_mg/local.json`; integración STATUS OK con 150 casos en Mudlet 5.1.1/Lua 5.1, última estable consultada por el ejecutor, informe `.tools/mudlet-integration/runs/1135173f734b4772a07ba2d8f27469d6/result.txt`.

Se comprueban Tab y Mayús+Tab mediante la política nativa sin solicitudes de sonido, los títulos reales en cada pestaña y al reabrir, el mismo botón visible y habilitado alternando Añadir/Eliminar con foco conservado en Resultados, y Eliminar en Favoritos. Se observa un solo announce, «Eliminado de favoritos.», al eliminar tanto desde Resultados como desde Favoritos; sigue pasando la persistencia por personaje. El título usa `wxTopLevelWindow:SetTitle(const wxString& title)` heredado por wxDialog, firma verificada en la referencia oficial ya recogida en el contrato histórico de panel de canales, y solo se actualiza si difiere. Perfil aislado desconectado, sin modificar portapapeles. Pendientes teclado físico y percepción de títulos, voz y audio con lector externo.

## Favoritos del mapa por personaje, 19 de noviembre de 2026

`scripts/validate.ps1`: diez controles aprobados, 152 casos por runtime Lua 5.1 y LuaJIT, sintaxis, Luacheck sin avisos, documentación, políticas, empaquetado y Git; informe `.tools/validation/runs/tmpq2pzq7gj/local.json`.

`scripts/run_mudlet_validation.py`: STATUS OK, 150 casos en Mudlet 5.1.1/Lua 5.1 (última estable verificada por el ejecutor), informe `.tools/mudlet-integration/runs/fe6dcbf81a294eee9054c832fe557a96/result.txt`. La regresión con wx real y GMCP sintético cambia de Personaje A a Personaje B con la ventana abierta, comprueba la lista nativa, borra un favorito y lee el JSON real para confirmar su retirada y la conservación del otro personaje. También verifica pérdida y recuperación de nombre, rechazo de altas sin identidad y recarga.

Las pruebas locales comprueban conversión del formato 1 a formato 2 vacío, eliminación persistida tras nueva carga, aislamiento entre personajes y fallos de sustitución o limpieza del respaldo sin publicar el cambio. Ficha notifica después de actualizar el nombre; mapa retira su handler al recargar. Perfiles aislados y desconectados, sin tocar archivos de perfiles de usuario ni el portapapeles. Pendientes identidad recibida del servidor real, teclado físico y lector externo.

## Sonidos propios del mapa, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados y 150 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmp76i7zsv0/local.json`; integración STATUS OK con 149 casos en Mudlet 5.1.1/Lua 5.1 (última estable consultada por el ejecutor), informe `.tools/mudlet-integration/runs/13f5e99f7735466d895d080820daa9c5/result.txt`.

La instrumentación delega al reproductor real y comprueba `ui.abrir_mapa` en apertura/reapertura, `ui.plegar` al cancelar y una sola solicitud `ui.seleccionar_mapa` al confirmar un destino válido mediante aceptación nativa o viaje sigiloso. Se preservan el motor oficial, la navegación y los botones comunes. Perfil aislado desconectado y portapapeles conservado. Pendientes teclado físico y percepción auditiva con lector externo.

## Selector de interfaz del mapa, 19 de noviembre de 2026

Selector circular con valores booleanos persistidos para conservar perfiles anteriores. Rhomscripts es el valor predeterminado para configuraciones nuevas o sin esta opción.

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados, 150 casos por runtime Lua 5.1 y LuaJIT, integración STATUS OK con 149 casos en Mudlet 5.1.1/Lua 5.1, última estable consultada por el ejecutor. Informes `.tools/validation/runs/tmpojff4qxk/local.json` y `.tools/mudlet-integration/runs/b182af0c2c3f45878a319d640d60e0d3/result.txt`. Comprueba persistencia compatible, rechazo de valores ajenos, circularidad y selección confirmada independiente del borrador; el mapa real comprueba sustitución y restauración de la presentación oficial al guardar.

`scripts/run_wxlua_probe.py --configurador`: STATUS OK, 20 casos en Mudlet 5.1.1/wxWidgets 3.2.8, informe `.tools/wxlua-probe/runs/892acc4629804c6bbf45e226f7531bc2/result.txt`. Verifica las etiquetas «Interfaz del mapa», «Rhomscripts» y «Config oficial», Enter directo, circularidad por Arriba/Abajo y una solicitud `ui.boton_2` por cambio. El primer ensayo esperaba Activado/Desactivado en su comprobador de ajustes; se actualizó esa expectativa al texto del selector. Perfil aislado y desconectado, sin modificar portapapeles. Pendientes teclado físico y experiencia auditiva con lector externo.

## Sonido de los reguladores de volumen, 19 de noviembre de 2026

Cambio focalizado en la política del configurador: las opciones `volumen_` solicitan `ui.clic_2` al cambiar; los demás ajustes numéricos, los booleanos y los avisos de límite conservan sus claves. `scripts/validate.ps1`: diez controles aprobados, 150 casos por runtime Lua 5.1 y LuaJIT, informe `.tools/validation/runs/tmpmsek5ybv/local.json`. `scripts/run_wxlua_probe.py --configurador`: STATUS OK, 19 casos en Mudlet 5.1.1/Lua 5.1 y wxWidgets 3.2.8, informe `.tools/wxlua-probe/runs/bd1c5fbadf934c27ba170f12c45732cf/result.txt`. Se comprobaron solicitudes `ui.clic_2` al aumentar y reducir volumen, los extremos y el sonido anterior en otros ajustes. Perfil aislado desconectado; teclado físico y percepción auditiva con lector externo pendientes.

## Sonidos comunes de listas y botones, 19 de noviembre de 2026

`scripts/validate.ps1 -Mudlet`: diez controles locales aprobados, 150 casos por runtime Lua 5.1 y LuaJIT, Luacheck sin avisos e integración STATUS OK con 149 casos en Mudlet 5.1.1/Lua 5.1 (última estable comprobada por el ejecutor oficial). Informes: `.tools/validation/runs/tmpoi9kf07y/local.json` y `.tools/mudlet-integration/runs/3d86d1850915460795d180e06d627c59/result.txt`.

La regresión usa controles wx reales e instrumenta el reproductor delegando al audio productivo: selección nativa con una solicitud `ui.clic_1`, pulsación nativa y Enter con una solicitud `ui.boton_1`, y desplazamientos entre botones o entre lista y botones sin solicitudes sonoras. Preparación y actualizaciones siguen sin clic. Los avisos de límite y pestaña permanecen a cargo del dominio. Se conserva el error de reproducción sin silenciarlo. La prueba del catálogo se actualizó a los WAV del mapa ya renombrados en el árbol de trabajo; la primera ejecución falló al esperar el antiguo `ui.ir_sala`.

`scripts/run_wxlua_probe.py --configurador`: STATUS OK, 19 casos en Mudlet 5.1.1/wxWidgets 3.2.8, informe `.tools/wxlua-probe/runs/d8876973ebc2473fbd07df13bf8465fe/result.txt`. Verifica pulsación de Guardar y Cancelar con `boton_1` seguida del efecto propio, navegación del árbol, ajustes numéricos y booleanos, reapertura y errores de guardado. Perfiles aislados y desconectados; portapapeles conservado. Pendientes teclado físico, percepción auditiva y lector externo.

## Componentes comunes de interfaz, 18 de noviembre de 2026

`scripts/validate.ps1` terminó con diez controles aprobados y ningún fallo: sintaxis Lua 5.1 y LuaJIT, Luacheck 1.2.0 sin avisos, políticas de API, instrucciones, documentación, empaquetado y comprobaciones de Git. Las suites de comportamiento completaron 150 casos por runtime. Informe: `.tools/validation/runs/tmpe1h8i1sh/local.json`. El puente de serialización de las pruebas conserva los arrays JSON al convertir tablas Lua consecutivas; no sustituye la comprobación con yajl real.

`./.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py --map-keyboard postmessage` completó 150 casos en Mudlet 5.1.1, Lua 5.1 y wxWidgets 3.2.8. El ejecutor consultó la API oficial de releases y comprobó que la instalación probada correspondía a la última estable. Perfil nuevo, aislado y desconectado. Informe final: `.tools/mudlet-integration/runs/59fcffbbc32e452593703a5b930bec62/result.txt`.

La integración verifica controles preparados sin mostrar, páginas nativas con contenido real, dos botones habilitados con acciones distintas, navegación horizontal, selección fija desde botones, inserción por identidad sin desplazar foco, retirada múltiple con siguiente superviviente, acciones deshabilitadas y reutilización de controles. Comprueba snapshot de detalle de solo lectura, vuelta al historial, favoritos persistentes, memoria de pestaña, ausencia de apertura automática sin resultados y apertura pospuesta con resultados. Mensajes Windows dirigidos a la lista aislada activan Return normal y numérico una vez y capturan `norte` y `sigilar norte` del motor oficial sin enviarlos al juego.

Se comprobó la recarga desde el detalle abierto sobre el historial real: ambos HWND permanecen vivos mientras sus llamadas modales están en pila; primero retorna el hijo y después el padre, luego se destruyen y se emite ready una vez, sin duplicar los 40 atajos, tres aliases y dos triggers. Una prueba intermedia detectó bloqueo al ejecutar EndModal del padre mientras seguía activo el bucle hijo. Se corrigió el cierre escalonado y el informe final acredita la regresión. Las ejecuciones intermedias de diagnóstico quedaron en directorios aislados; una instalación oficial también mostró el fallo intermitente de carpeta de paquete ya existente, sin ocultarlo ni modificar el instalador productivo.

`./.tools/venv/Scripts/python.exe scripts/run_wxlua_probe.py --comunicaciones`: 44 casos aprobados en la misma versión de Mudlet y wxWidgets. Informe: `.tools/wxlua-probe/runs/4dc9540c624348ee9723720a2ab34e8d/result.txt`, con 35 pulsos Qt durante diálogos. Comprueba dimensiones útiles de lista y página, botón Copiar visible, selección de pestaña por eventos nativos y Tab, reapertura, texto íntegro y persistente del detalle, llegada con foco en Copiar y retirada del mensaje sin copiar otro. La copia usa el lector productivo con un doble explícito de setClipboardText; el portapapeles real no se modifica.

Se mantienen pendientes teclado físico, experiencia auditiva y lectura percibida con lector externo. Los datos de juego son sintéticos y no hubo conexión al servidor. Responder y Responder en privado siguen indisponibles por falta de contrato de envío y autor acreditado. [Plan cerrado](planes/componentes-interfaz.md), [navegación común](usuario/componentes-interfaz.md), [mapa](usuario/mapa.md) y [comunicaciones](usuario/comunicaciones.md).

El objetivo es la última versión estable de Mudlet, comprobada en releases oficiales. No se mantienen adaptaciones que oculten APIs ausentes. La validación local usa los compiladores reales Lua 5.1 y LuaJIT suministrados por Lupa; no es una emulación de sintaxis con un parser aproximado.

## Preparación en Windows

Se necesita Python 3.11 o posterior en Windows x64.

Ejecutar desde la raíz: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup_validation.ps1`.

Se crea `.tools/venv`, con dependencias fijadas en `scripts/requirements-validation.txt`. Luacheck 1.2.0 se descarga del mantenedor y se verifica por SHA-256. Java 17 de Eclipse Temurin se instala de forma portátil en `.tools/java` con el checksum oficial para ejecutar Muddler. No se modifica el PATH del sistema.

Para preparar o actualizar Mudlet: `.\.tools\venv\Scripts\python.exe scripts/setup_mudlet.py`. Consulta la última release estable oficial, verifica el digest del instalador y utiliza instalación silenciosa por usuario. La instalación permanece disponible para el usuario; no es parte del repositorio.

## Comprobaciones locales

Durante la edición, ejecutar los casos que cubran el cambio. Para los perfiles se puede ejecutar `python scripts/sync_agents.py --check`, y para RhomLoader, `.\.tools\venv\Scripts\python.exe scripts/test_packaging.py`. Quien integra ejecuta o asigna `.\scripts\validate.ps1` una vez sobre el resultado combinado.

- Compilar cada archivo de producción y pruebas con Lua 5.1 y LuaJIT, sin ejecutar el fuente durante esta comprobación.
- Ejecutar Luacheck sobre código y pruebas con cero avisos. Las APIs de prueba se declaran únicamente en su ámbito.
- Comprobar sincronización de perfiles Codex/Copilot, detección de perfiles retirados, YAML, TOML, patrones de aplicación y destinos de enlaces locales de documentos propios.
- Buscar defensas de existencia prohibidas en las APIs auditadas. Este control estático no es un análisis exhaustivo del flujo; se complementa con pruebas negativas.
- Compilar expresiones reales con PCRE2 y ejecutar los casos de infraestructura en ambos runtimes: lectura, copia, capturas, listas, audio, persistencia simulada, teclado numérico, APIs ausentes y carga repetida.
- Empaquetar RhomLoader en una copia temporal, inspeccionar el ZIP/XML y comprobar dos construcciones concurrentes con rutas distintas. Un fallo provocado debe conservar los fuentes y el paquete anterior.
- Ejecutar `git diff --check` para el árbol de trabajo y `git diff --cached --check` para el índice. Los archivos sin seguimiento quedan fuera de ambos diffs. La opción `-SkipGit` registra Git como omitido.

Cada ejecución imprime la ruta relativa del informe local en `.tools/validation/runs/`, ignorado por Git. Una aserción fallida hace terminar la validación con error. En las evidencias compartidas se registran el comando, las versiones, el resultado y los límites con rutas relativas y datos sintéticos.

En Visual Studio Code también se pueden ejecutar las tareas del proyecto: preparación, validación local, validación real en Mudlet y actualización de documentación. No se ejecutan automáticamente al abrir la carpeta.

## Pruebas reales en Mudlet

Ejecutar `.\scripts\validate.ps1 -Mudlet`. Para otra instalación, añadir `-MudletExe "ruta\Mudlet.exe"`.

La integración reutiliza el RhomLoader que acaba de comprobar la suite local. Si se invoca directamente `scripts/run_mudlet_validation.py`, el ejecutor prepara su propio paquete de prueba.

El ejecutor consulta la última release estable y exige que la versión probada coincida. Crea una configuración nueva para cada ejecución bajo `.tools/mudlet-integration/runs/`, abre un perfil sin servidor mediante `--offline` y verifica desde Lua que la ruta real del perfil corresponde a esa carpeta. No reutiliza instalaciones de paquetes de ensayos anteriores, no abre ni modifica perfiles del usuario y no conecta al juego.

Comprueba carga, firmas reales de persistencia, lectura del buffer, capturas PCRE mediante feedTriggers, llamada real a announce, reproducción por clave, parada confirmada por el motor tras procesar eventos, retirada de registros, eventos de grupo visibles desde el módulo público, instalación del paquete real RhomLoader, recarga y error ante API ausente. Los registros se instrumentan delegando a las APIs reales; no se sustituyen por dobles.

Por defecto no se lee ni modifica el portapapeles global del escritorio. La copia se comprueba con el doble local y queda registrada como omitida en la integración estándar. La prueba real optativa se ejecuta con `.\.tools\venv\Scripts\python.exe scripts/run_mudlet_validation.py --clipboard-text-only`: requiere preparar antes el portapapeles con texto prescindible, pues la API conserva únicamente texto y no otros formatos. Intenta restaurar ese texto al finalizar normalmente; una terminación forzada no garantiza restauración. No activar esta opción para contenido que se necesite conservar.

El proceso termina tras recoger resultados, sin cerrar otras instancias. Cada ejecución guarda result.txt, process.log y su paquete en su carpeta UUID, para evitar interferencias entre pruebas simultáneas. `.tools/mudlet-integration/latest.json` apunta a la última ejecución completada; el ejecutor muestra la ruta exacta. Solo se detiene el proceso creado para esta prueba.

## Familia única y versión

Comprobado el 17 de noviembre de 2026. `./scripts/validate.ps1 -Mudlet` pasó los diez controles locales, incluidos 138 casos en Lua 5.1 y 138 en LuaJIT 2.1.1760617492. La integración completada con `./.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py` pasó 125 casos en Mudlet 5.1.1, última estable contrastada por el ejecutor. Perfil aislado, sin conexión al juego ni modificación del portapapeles.

Los comandos reales de la familia `rhomscripts` se ejecutaron mediante `expandAlias`, incluidos todos los informes, el filtro por módulo, `version` y el prefijo con mayúscula. El inventario contiene una sola declaración de diagnóstico y ningún nombre anterior; después de recargar quedan 39 teclas, 3 aliases (consultas y dos comandos del lector) y 2 triggers. La consulta muestra y anuncia `1.0, 17/11/2026`, igual al argumento emitido por `rhomscripts.ready`; ambos leen `debug.version()`.

Las dos primeras integraciones pasaron estas consultas y se detuvieron después en una prueba heredada que preguntaba inmediatamente por una reproducción de 0,1306 segundos, antes de volver al bucle Qt. La prueba conserva ruta, volumen y parámetros reales; la observación del motor se trasladó al tramo asíncrono con `ui.carga_ok` (1,2718 segundos), usando `audio.reproducir` real y comprobando la clave exacta tras procesar Qt. Se conservan las comprobaciones posteriores de parada y recarga modal. No se modificó la reproducción productiva para obtener el resultado.

Informe local: `.tools/validation/runs/tmp15ucf4q7/local.json`. Integración final completa: `.tools/mudlet-integration/runs/102f110a6cf1497884f81198817a72de/result.txt`. Sintaxis en ambos runtimes y Luacheck comprobados de nuevo sobre el ajuste de la prueba. Pendientes la pulsación física y la lectura percibida con lector externo. [Manual](usuario/debug.md#comandos) y [plan](planes/debug.md#simplificación-de-consultas-y-versión-17-de-noviembre-de-2026).

## Debug centralizado

Comprobado el 17 de noviembre de 2026 con `./scripts/validate.ps1 -Mudlet`: diez controles locales superados, 136 casos en Lua 5.1, 136 en LuaJIT 2.1.1760617492 y 122 casos en Mudlet 5.1.1. El ejecutor contrastó la última release estable oficial antes de abrir un perfil nuevo aislado y desconectado. Herramientas: Python 3.13.15, Lupa 2.6, enlace PCRE2 0.5.3 y Luacheck 1.2.0 sin avisos. Sintaxis comprobada en 36 archivos con ambos compiladores Lua.

Se verificaron el modo oficial único y su persistencia mediante el setter real, el traslado al configurador, borrador y cancelación, cambios oficiales externos, migración de la antigua copia JSON, salida automática de dos hitos sin debug, mensajes ocultos consultables, búfer FIFO de 500 entradas, recarga sin mensajes anteriores, biblioteca estándar `debug` intacta e inventarios de recursos efectivos con copias independientes. Los comandos se ejecutaron mediante `expandAlias(command, false)` real sobre aliases registrados, con salida comprobada: ayuda, filtro por módulo y accesos directos. [API oficial de expansión](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#expandAlias).

Las regresiones provocaron fallos de registro y retirada: el identificador de una tecla que no pudo retirarse continuó visible y pudo limpiarse después; un fallo tardío con salida ausente conservó el error original, completó la retirada y añadió el fallo de presentación antes de relanzar. La revisión independiente detectó y permitió corregir el orden de proveedores, el filtro de estado modular y la limpieza anterior a la presentación. Los recuentos finales fueron 39 teclas, 10 aliases y 2 triggers.

Las primeras ejecuciones reales detectaron dos supuestos de las pruebas locales: `cecho` real llama internamente varias veces a `echo`, y el error interno de esa cadena no tiene por qué nombrar literalmente `echo`. Se corrigió la instrumentación para contar llamadas superiores y exigir el contexto de error secundario, conservando las comprobaciones de error original y limpieza. La ejecución final indicada a continuación pasó completa.

Informes locales finales: `.tools/validation/runs/tmpo4g91w9e/local.json` y `.tools/mudlet-integration/runs/16ae7e6a33ec4550ac659d87eb2ded87/result.txt`. El ZIP oficial probado conserva SHA-256 `b98d315642f784789485f6d536a5c83bdb8aa4557e827e4da4dd2c205dd201a4`. El empaquetado RhomLoader aislado y sus pruebas concurrentes pasaron; los paquetes y registros brutos permanecen ignorados, sin publicar ni modificar el índice de Git.

No se conectó al juego ni se modificó el portapapeles. Se comprobaron llamadas reales de salida, lector externo y audio, pero no la lectura percibida, el aspecto visual ni las pulsaciones físicas. [Manual de debug](usuario/debug.md) y [ficha de implementación](planes/debug.md).

## Función común de copia, 17 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó en Lua 5.1, LuaJIT y Mudlet 5.1.1. Las pruebas comprobaron que las copias de línea y ficha escriben una sola vez, anuncian el contenido exacto seguido de «Copiado» y solicitan después el sonido del grupo Interfaz. La integración usó `announce` y el motor de sonido reales en un perfil desconectado. Se instrumentó la escritura para conservar el portapapeles. Queda pendiente comprobar cómo se oyen ambos anuncios con el lector externo. [Contrato de copia](contratos-mudlet.md#copia-de-texto-al-portapapeles)

Informes locales en `.tools/validation/runs/tmpvi2ux24e/local.json` y `.tools/mudlet-integration/runs/0494e74369884bfcb5fa80ae624e7853/result.txt`.

## Identidad y copia de la ficha, 17 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó en Lua 5.1, LuaJIT y Mudlet 5.1.1. La prueba verificó las consultas de identidad tras recibir GMCP sintético, el registro de Alt+Mayús+1, Alt+Mayús+2 y Alt+Mayús+0, el texto enviado a la función de portapapeles instrumentada y la llamada de audio real con `ui.portapapeles`. El perfil estuvo desconectado y se conservó el portapapeles de Windows. Queda pendiente comprobar la pulsación física y el pegado desde el perfil de juego.

Informes locales en `.tools/validation/runs/tmpkt_0kw32/local.json` y `.tools/mudlet-integration/runs/49ff90b6ea9f4227a39b341f27b94d9f/result.txt`.

## Aviso de valores ausentes, 17 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó en Lua 5.1, LuaJIT y Mudlet 5.1.1. Con paquetes sintéticos se verificó que Alt+1, Alt+2 y Alt+0 conservan la posición de cada valor ausente, verbalizan el cero recibido y llaman una vez a `announce` con `importantmostrecent`. La prueba usó un perfil aislado y desconectado.

Informes locales en `.tools/validation/runs/tmp2gvtw5p1/local.json` y `.tools/mudlet-integration/runs/21bc835a8d654396a7c0493f5b275c77/result.txt`.

## Lectura de vida, 17 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó en Lua 5.1, LuaJIT y Mudlet 5.1.1. Con paquetes sintéticos se verificó que la ficha mantiene la máxima cuando recibe solo la actual, conserva el par al recargar y descarta la vida de la sesión anterior al renegociar GMCP. La función de Alt+1 llamó a `announce` con `1\120` después de una actualización que solo contenía la vida actual. La prueba se ejecutó en un perfil aislado y desconectado. La comprobación durante una partida y con pulsación física queda pendiente.

Informes locales en `.tools/validation/runs/tmpu0u6a35j/local.json` y `.tools/mudlet-integration/runs/5df19cf8af424fe5b4bf31b0503271a6/result.txt`. [Contrato de la ficha](planes/ficha-gmcp.md#contrato)

## Atajos de información, 17 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó en Lua 5.1, LuaJIT y Mudlet 5.1.1. La integración registró 36 atajos propios y verificó el texto exacto, el orden, la omisión de pares incompletos, la conservación de ceros y la llamada real a `announce` con `importantmostrecent`. Se usaron datos sintéticos en un perfil desconectado. La pulsación física y la interrupción percibida con lector externo quedan pendientes.

Informes locales en `.tools/validation/runs/tmpk3epu6i3/local.json` y `.tools/mudlet-integration/runs/0538f5a3061b4bb3a47705fcca1ed046/result.txt`. [Guía de los atajos](usuario/teclado.md#información-del-personaje)

## Ficha GMCP, 16 de noviembre de 2026

`./scripts/validate.ps1 -Mudlet` pasó diez controles locales, con 117 casos en Lua 5.1 y 117 en LuaJIT 2.1.1760617492. La integración pasó 104 casos en Mudlet 5.1.1, última versión estable verificada al ejecutar. Siete casos corresponden a la ficha. [Contrato de captura](planes/ficha-gmcp.md#contrato)

`feedTelnet` procesó paquetes sintéticos en un perfil aislado y desconectado. Se verificaron el evento padre con ruta exacta, paquetes nuevos y anidados, conservación de tipos, copias independientes, recarga, reinicio de sesión y fusión superficial de `Char.Status` tras renegociar. Las transiciones de conexión y despedida se simularon con eventos. Queda pendiente comprobar paquetes en partida.

Informes locales en `.tools/validation/runs/tmp8j07no6u/local.json` y `.tools/mudlet-integration/runs/3f2fe8bf53f948c8a70a100983c31b3d/result.txt`.

## Arranque oficial, comprobado el 7 de noviembre de 2026

Las pruebas locales del inicializador usan un doble explícito de paquetes, descargas, eventos y temporizadores: espera sin GMCP, paquete ya activo, instalación, errores, timeout, cancelación de una espera al recargar y ausencia de APIs. Las regresiones habituales usan estado oficial simulado y no certifican por sí solas el paquete real.

La integración real empieza sin RLMud_Config en un perfil nuevo y desconectado. Ejecuta `oficial.lua`, descarga mediante `downloadFile` de Mudlet, instala el ZIP real, espera la señal de opciones y comprueba que retira sus manejadores y temporizadores antes de continuar. Contrasta el XML instalado con una descarga HTTPS independiente del ZIP oficial y registra su SHA-256 y URL en `official-source.json`. Después ejecuta carga, fallos, avisos y recarga de RhomScripts y RhomLoader. No se conecta al juego ni se prueban suscripciones o datos GMCP del servidor. Las tareas internas del paquete oficial, incluido el mapa, no se reproducen con stubs.

La ejecución real de esta revisión pasó con Mudlet 5.1.1, última estable comprobada por el ejecutor. Evidencias detalladas en `.tools/mudlet-integration/runs/1a0e6183695443829fe1a5f26c8c8b1e/`. La descarga y la inicialización no requirieron negociación GMCP. No se modificaron las preferencias ni el perfil del usuario.

## Preferencias oficiales, comprobadas el 7 de noviembre de 2026

`scripts/validate.ps1` superó los nueve controles, incluidos 67 casos por runtime (Lua 5.1 y LuaJIT), Luacheck sin avisos y empaquetado aislado. Se comprueban la migración JSON 1 a 2, conservación de volúmenes, booleanos, fuente predeterminada y límites, edición/Escape sin aplicar, JSON antes de acciones, fallo de guardado sin aplicación, aplicación fallida con menú abierto y reintento, y retirada de las desactivaciones de consentimiento en `configurarficha`.

`scripts/run_mudlet_validation.py` superó 55 casos en Mudlet real 5.1.1, perfil nuevo y desconectado, ejecución `.tools/mudlet-integration/runs/68130e0bc6f3409ebc1277872de726bc/`. Incluye GUI y canales con una sola reconstrucción, repetición sin reconstrucción adicional, fuente sin recrear consolas, suscripción local con GUI oculta, preferencias pendientes sin GMCP, API ausente y reintento del guardado oficial, corrección de deriva al recargar y los casos del menú compartidos con el doble. Los estados pendientes no se presentan como recepción de servidor ni presencia Discord observadas. Los datos del juego, las macros por clase conectadas, Discord y los consentimientos remotos no se han probado conectando al juego. No se toca el portapapeles ni el perfil personal del usuario.

## Panel visual compartido, comprobado el 7 de noviembre de 2026

Corrección posterior aportada por el usuario: la prueba física demuestra que el control del teclado según el foco no funciona. Arriba/abajo continúan en la entrada o el texto; izquierda/derecha pueden seguir actuando sobre el configurador. Las pruebas siguientes verifican las funciones y callbacks, no la entrega física de las teclas al control enfocado. Ese requisito permanece sin implementar y no debe considerarse cubierto por `STATUS OK`.

Evidencia histórica del panel Geyser retirado; no valida el configurador nativo actual. `scripts/validate.ps1 -Mudlet` pasó nueve controles locales, con 77 casos en Lua 5.1 y 77 en LuaJIT, y 65 casos de integración real en Mudlet 5.1.1, última estable comprobada por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/29bbd73944e6438f98de5841e3e2fd17/result.txt`. Incluye panel Geyser real, selección y acciones delegadas, ajustes, prioridad del configurador, confirmación, cancelación, texto escapado, ventana flotante de 375 píxeles de alto, contenido desplazable, ocultación, recarga y API ausente.

Se observó el árbol accesible de Windows con nombres y papeles de botón. La captura gráfica y los clics de escritorio no pudieron completarse por errores de la herramienta; los callbacks se validan por instrumentación con delegación real. El uso físico con lector externo y el comportamiento tras desplazamiento manual requieren observación adicional. Véase [contrato y límites de la interfaz](migraciones/interfaz-visual.md). No se conectó al juego ni se tocaron perfiles personales o portapapeles.

## Prueba nativa de wxLua, comprobada el 7 de noviembre de 2026

`scripts/validate.ps1 -Mudlet` pasó nueve controles locales (77 casos en cada runtime) y 65 casos generales en Mudlet 5.1.1, ejecución `.tools/mudlet-integration/runs/523e2e2ae71b426ba2c1872533ba195a/result.txt`. El nuevo alias se registra sin cargar la DLL durante el arranque.

La integración específica se ejecuta con `.\.tools\venv\Scripts\python.exe scripts/run_wxlua_probe.py`. Pasó tres aperturas con cinco elementos, foco nativo inicial, selección, cierres Aceptar/Cancelar/X, limpieza y recarga Lua conservando el módulo nativo. Mudlet 5.1.1/Lua 5.1, wxWidgets 3.2.8, 31 pulsos Qt durante el ensayo; evidencia `.tools/wxlua-probe/runs/e4652d46892440a7b2399d6299cb1ded/result.txt`. La prueba interactiva terminó con Aceptar y 361 pulsos; el usuario comunicó que su comprobación manual funciona correctamente. La automatización del escritorio solo observó el árbol accesible: no consiguió enviar teclas por un error de su herramienta.

Biblioteca AMD64 instalada junto a los scripts, sin modificar Mudlet ni distribuir otra Lua. Fuentes, licencias, compilación reproducible y límites de esta prueba están en [la ficha wxLua](migraciones/prueba-wxlua.md). No valida uso multiperfil ni conexión al juego.

## cffi-lua y ventanas asociadas, comprobadas el 7 de noviembre de 2026

Ampliación del 8 de noviembre: `ventanasflotantes=true` por defecto y rama Interfaz del configurador. El constructor común asocia según valores confirmados; false usa `wxDIALOG_NO_PARENT`, sin cargar cffi para crear la ventana. Las configuraciones 1/2 antiguas añaden true sin perder preferencias y false se conserva. Un fallo al asociar destruye el diálogo incompleto y relanza el error.

Validación general: nueve controles locales, 66 casos por runtime y 54 casos reales, Mudlet 5.1.1, `.tools/mudlet-integration/runs/254d45fa7f514078aec89531134c69d7/result.txt`. Configurador: quince casos y 125 pulsos Qt, `.tools/wxlua-probe/runs/1590373345eb4ef79199056524caaf62/result.txt`, incluidos árbol Interfaz, borrador sin efectos, Cancelar, Guardar false, próxima apertura independiente y limpieza ante fallo del constructor. Prueba wx: seis casos y 58 pulsos, `.tools/wxlua-probe/runs/5936026c99d64e8aa1fc941fa5ff6549/result.txt`. Prueba cffi: ocho casos y 31 pulsos, `.tools/wxlua-probe/runs/bf9a958d9ecc42c7bf9d4793c38e9202/result.txt`.

Se corrigió el foco inicial independiente: `wxEvtHandler:CallAfter(función)` programa una única activación y foco tras mostrar el diálogo; al cerrar se invalida la acción pendiente. El binding lo expone desde wxWidgets 2.9.5, sin retorno. [Override oficial](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxbase_override.hpp). El sondeo mide heartbeat desde la ventana mostrada, sin incluir construcción o carga; sus primeras variantes detectaron problemas de temporización del propio ensayo y foco, conservados como intentos fallidos. Teclado físico y lectura percibida requieren comprobación de uso.

Repetición final tras proteger los botones durante el cierre: siete casos superados, 21 pulsos Qt, `.tools/wxlua-probe/runs/fe42da690f9b445292609d28e630bef8/result.txt`. Nueve controles locales repetidos sin fallos.

`scripts/run_wxlua_probe.py --cffi` pasó siete casos en Mudlet 5.1.1, última estable comprobada, Lua 5.1 y wxWidgets 3.2.8, con 18 pulsos Qt. Evidencia: `.tools/wxlua-probe/runs/a27c5f0f7a48421887cf8729df6b44f6/result.txt`. El PID 15064 leído mediante cffi coincidió con el proceso creado por el ejecutor. El ejecutor exige PE AMD64 y SHA-256 idéntico al manifiesto de cffi.dll.

Se observaron carga/cdef/ABI, HWND wx válido sin conversión a número, enumeración del proceso, propietario real, asociación y restauración, rechazo de ventanas ajenas/autoasociación/ciclos, caché entre recargas y botones nativos de la demostración. Al minimizar la ventana Qt del perfil aislado se ocultó la ventana wx asociada; al restaurarla reapareció. No se minimizaron otras instancias ni se modificaron perfiles personales.

La asignación NULL sobre un propietario ya NULL dio error Win32 1400; se confirmó también con una ventana oculta propia creada desde ctypes. Se evita esa operación redundante por comparación de estado y siguen propagándose errores de asociaciones reales. La asociación fue probada tanto entre ventanas wx como con la ventana Qt de Mudlet.

La integración general posterior pasó nueve controles locales, 63 casos por runtime Lua y 51 casos reales en Mudlet 5.1.1: `.tools/mudlet-integration/runs/60c6f6e0a3b541b89662a0f388df258a/result.txt`, con 132 teclas, 57 alias y 610 triggers. Incluye carga y recarga del alias nuevo sin cargar cffi.dll en el arranque.

No se prueba todavía seguimiento de posición, política de Alt+Tab, lectura con lector externo, teclas físicas ni uso simultáneo en varios perfiles. El configurador no adopta automáticamente la asociación. Compilación, contratos y uso: [cffi y ventanas asociadas](migraciones/cffi-ventanas.md).

## Actualización de sesiones antiguas

Esta actualización exige cerrar y reabrir el perfil una vez si tenía cargados los registradores anteriores. Aquellos no conservaban identificadores para retirar sus registros. El nuevo init.lua rechaza esa primera recarga con un error explícito antes de registrar nada; así evita duplicados sin eliminar alias, teclas o triggers de otros paquetes. Desde un perfil reabierto, rl permite las recargas habituales.

## Límites de las evidencias

El doble local no reproduce todo Mudlet: los eventos de Qt, la precedencia exacta del motor, codificaciones del servidor y medios asíncronos requieren integración real. La persistencia local comprueba contrato y uso de datos; la serialización efectiva se verifica con table.save/load en Mudlet.

El usuario utiliza lector de pantalla externo. No se contempla SAPI ni compatibilidad con SAPI. Se conserva announce(texto) estándar; las políticas por tipo de mensaje para cola o interrupción quedan para otra tarea. Aceptar la llamada no demuestra que el usuario la haya oído correctamente. La integración verifica que el motor recibe y detiene sonidos; la calidad audible, lateralidad percibida, volumen, interacción con el lector externo y pulsaciones físicas requieren comprobación de uso.

Estos casos cubren infraestructura representativa, no la equivalencia completa de los 72 originales VIPMud ni todos los dominios. Cada migración debe añadir sus casos y evidencia con `doc/migraciones/plantilla.md`.

## Documentación

Actualizar las copias oficiales con `.\scripts\update_docs.ps1`. Consultar `doc/mudlet/README.md` y `doc/contratos-mudlet.md`. No eliminar los manuales históricos para actualizar la referencia actual.

## Configurador nativo, comprobado el 7 de noviembre de 2026

Revisión de eficiencia y errores: diez casos nativos superados, 67 pulsos Qt, Mudlet 5.1.1/wxWidgets 3.2.8, ejecución `.tools/wxlua-probe/runs/77918c9ee11948d39ce92dab1c9e6cec/result.txt`. Se verifican cero consultas de selección al manejar las flechas de un ajuste, omisión de etiquetas idénticas, un único announce ante fallo de escritura, guardia de cierre durante `wxEVT_DESTROY` real, ausencia de reapertura o acciones reentrantes, propagación de fallo tras Destroy con limpieza de campos y reapertura posterior.

`wxEVT_DESTROY` está expuesto en [los bindings oficiales instalados](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_event.i). El ensayo delega a la destrucción nativa y verifica el callback real. También superados los nueve controles locales y 51 casos generales reales: `.tools/mudlet-integration/runs/11c6b9d13cba402fb396e0643ce94068/result.txt`. No se presenta una mejora porcentual de rapidez: se comprueba trabajo evitado, sin medir la latencia percibida. Se conservan los límites de teclado físico y lector externo.

Revisión más reciente de sonidos y mensajes: entrada al ajuste con un único Desplegar y anuncio exacto «Ajustando valor.»; salida con Plegar y sin announce redundante del nombre del nodo. Selección y pérdida de foco también pliegan el ajuste. Guardar y Cancelar no añaden Plegar a su sonido terminal. Ayuda, confirmaciones y errores abreviados, conservando información sobre preferencias ya guardadas.

Nueve controles locales y siete casos nativos superados, Mudlet 5.1.1/wxWidgets 3.2.8, 54 pulsos Qt: `.tools/wxlua-probe/runs/fbb95eeb3fa64a04bce560a57148b394/result.txt`. Se comprueban audio exacto al entrar/salir, anuncio breve único, ausencia de anuncio redundante al salir y regresiones de edición, persistencia, errores y recarga. La percepción con lector externo y las pulsaciones físicas permanecen fuera de esta automatización.

Corrección más reciente tras doble lectura observada por el usuario: al cambiar se actualiza únicamente el nodo, sin announce adicional ni segunda etiqueta de estado. Si un límite numérico impide el cambio, announce comunica una vez el valor. Los booleanos ahora alternan circularmente en ambas direcciones y no producen Límite. Al entrar, el anuncio de instrucciones no repite el valor del nodo. El sonido Interruptor se conserva para cada cambio booleano y los números mantienen límites.

Nueve controles locales superados y siete casos nativos en Mudlet 5.1.1/wxWidgets 3.2.8, con 51 pulsos Qt: `.tools/wxlua-probe/runs/d0300c3ee3274a419bb7970646a4c13a/result.txt`. Se comprueba ausencia de announce explícito cuando cambia el nodo, anuncio único de su valor cuando no cambia y alternancia repetida de booleanos con Interruptor. La percepción final de una sola lectura requiere comprobarla con el lector externo; las revisiones anteriores no habían observado esa interacción.

Corrección posterior de límites y lectura: alcanzar un extremo numérico no solicita Límite; solo intentar superarlo lo solicita. Cada pulsación de ajuste anuncia únicamente el número sin unidad, nombre ni la palabra «límite» (Activado/Desactivado para booleanos). El nodo muestra ese mismo valor durante el ajuste y recupera su etiqueta completa al salir, evitando actualizar su nombre accesible con el texto completo en cada cambio.

Nueve controles locales superados; siete casos nativos superados en Mudlet 5.1.1/wxWidgets 3.2.8, con 52 pulsos Qt, ejecución `.tools/wxlua-probe/runs/423c1fe9b5f04642a9c66e21257e5ecd/result.txt`. El ensayo comprueba anuncio único, texto exacto del anuncio/estado/nodo y sonidos exactos al cambiar, alcanzar e intentar superar extremos; incluye el salto de fuente 0/8 y el anuncio literal «0». Conserva los límites de comprobación física y del lector externo indicados más abajo. Las descripciones siguientes conservan revisiones anteriores.

Revisión posterior de flechas y sonidos: título «RhomScripts. Configuración.», Derecha entra en ajuste, Arriba/Abajo modifican e Izquierda vuelve a navegación. Se prueban selección estable, salida al cambiar de nodo o perder foco, booleanos con Interruptor, números con Botón y Límite al alcanzar los extremos o intentar sobrepasarlos. `wxEVT_KILL_FOCUS` está expuesto en [los bindings oficiales instalados](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_event.i); su callback continúa con `Skip()` después de terminar el ajuste.

`scripts/validate.ps1 -Mudlet` pasó nueve controles locales (63 casos en cada runtime) y 51 casos generales reales, ejecución `.tools/mudlet-integration/runs/bfe74ccf75ae4440bc05286b86888778/result.txt`. El catálogo comprobado contiene 29 claves y 28 archivos únicos, sin recursos UI sin indexar. Configurador: Clic 1.

`scripts/run_wxlua_probe.py --configurador` pasó siete casos en Mudlet 5.1.1, última estable consultada, y wxWidgets 3.2.8, con 51 pulsos Qt: `.tools/wxlua-probe/runs/5b97471a6c6345dca33c2522706a1442/result.txt`. El caso nuevo llama al mismo controlador utilizado por el hook con constantes wx reales y verifica controles y reproducción reales; no inyecta teclas físicas ni sustituye esa comprobación o la del lector externo.

La revisión final pasó `scripts/validate.ps1 -Mudlet`: nueve controles locales, 63 casos en Lua 5.1 y 63 en LuaJIT, y 51 casos generales en Mudlet 5.1.1, última estable consultada por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/f00b78de0df34fdaae48e6707ab28d7c/result.txt`. El recuento cambia al retirar los casos del panel y sustituir la navegación anterior por pruebas del borrador. Se verifican 26 claves sonoras con archivos existentes.

Tras ajustar el reparto de texto de los mensajes de estado, el ensayo nativo pasó de nuevo sus seis casos con 45 pulsos Qt: `.tools/wxlua-probe/runs/77c5301834c848ef8102cad09c3f54a8/result.txt`. En un intento previo la selección inicial había cambiado al primer volumen antes de la comprobación diferida; ese intento se registra como fallido y no se atribuye una causa comprobada. La repetición completa pasó; no se ha simulado entrada física ni impedido interacción externa con la ventana de prueba.

El panel Geyser y el alias `rhompanel` se han retirado. El configurador utiliza ahora un diálogo wxLua con TreeCtrl y botones Guardar y Cancelar. La edición mantiene un borrador: cancelar descarta lo no guardado sin leer el archivo; guardar valida y escribe JSON antes de aplicar las preferencias oficiales.

Comando específico: `.\.tools\venv\Scripts\python.exe scripts/run_wxlua_probe.py --configurador`. Resultado: seis casos superados en Mudlet 5.1.1, última estable consultada por el ejecutor, Lua 5.1 y wxWidgets 3.2.8. Se observaron 40 pulsos de temporizador Qt durante las aperturas modales. Evidencia: `.tools/wxlua-probe/runs/92c0bba5a817429c97a9cf866e88f811/result.txt` y su archivo `.progress`.

Los casos comprueban identidad y selección del árbol real, foco inicial y recorrido circular Árbol/Guardar/Cancelar en ambos sentidos, representación de fuente predeterminada, confirmación No/Sí para restablecer, cancelación sin I/O, escritura anterior a la aplicación, fallo de escritura con diálogo abierto, aplicación fallida con preferencias ya guardadas y reintento, y cierre por X tras recargar Lua conservando la DLL. Guardar, Cancelar y error de escritura solicitan un solo sonido por acción; se delega a la reproducción real. Los botones se activan mediante wxCommandEvent real; la selección y el foco se verifican en los controles nativos.

La aplicación oficial se instrumenta únicamente en este ensayo de interfaz para comprobar el orden JSON/aplicación; sus efectos pertenecen a la integración general. El fallo de aplicación se provoca llamando a `guardar` dentro de pcall con el diálogo real abierto: se comprueban el error relanzado, el estado y el reintento, sin afirmar haber observado la presentación nativa de errores de wxLua en un callback de botón.

El ciclo de foco se invoca mediante la operación de la ventana; esto no demuestra que las teclas físicas Tab, Mayús+Tab o las flechas lleguen al manejador. El binding wxKeyEvent instalado no expone un setter del código de tecla y no se inventan eventos de teclado. Las pulsaciones físicas, Escape y la lectura percibida con lector externo requieren comprobación manual de este configurador. La prueba manual previa del usuario correspondía a la demostración wxLua de cinco elementos. No se conecta al juego ni se lee o modifica el portapapeles.

## Registro de pulsaciones y ayuda, 8 de noviembre de 2026

Migrado keys.lua al contrato `pulsaciones`, documentado en [teclado](usuario/teclado.md). Se ignoran las tablas antiguas key_bindings sin migrar ni desconectar sus módulos. Ctrl+Shift+H alterna ayuda; las demás pulsaciones registradas anuncian su descripción sin ejecutar la función mientras está activa. Grupo es solo metadato. No hay personalización.

`./scripts/validate.ps1 -Mudlet` superó los nueve controles locales, con 75 casos en cada runtime Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado aislado y diff check. La integración real pasó en Mudlet 5.1.1, última estable verificada por el ejecutor contra la API oficial de releases, perfil nuevo y desconectado. Evidencia: `.tools/mudlet-integration/runs/e391b338325540c9b044c3531b9285b5/result.txt`.

Nueve casos específicos comprueban registro de una tecla y combinaciones con uno/dos modificadores, entrada y salida de ayuda mediante su callback, descripciones exactas y ausencia de efectos en ayuda, duplicados, datos inválidos, funciones y APIs fallidas, limpieza parcial y doble registro. Las pruebas de dominio que dependían de teclas antiguas invocan ahora las funciones directamente: no certifican esos atajos, retirados del registro. Se invocan callbacks registrados por tempKey real; no se han simulado ni observado pulsaciones físicas. La percepción con lector externo queda para comprobación de uso. No se conecta al juego ni se modifica el perfil o portapapeles personal.

### Pulsación del configurador, 8 de noviembre de 2026

Migrada únicamente la declaración del configurador a pulsaciones: Ctrl+Shift+C, configurador.abrir, grupo sistema. La suite compartida verifica la referencia a la función real y que en ayuda anuncia su descripción sin abrir ni crear una sesión. `scripts/validate.ps1 -Mudlet` superó los nueve controles locales y la integración en Mudlet 5.1.1, última estable verificada por el ejecutor, con dos teclas registradas al cargar y recargar. Evidencia: `.tools/mudlet-integration/runs/6e02c7081e214aad850ec6e38ab64e97/result.txt`. Registro y callbacks reales; no demuestra entrega física de Ctrl+Shift+C ni lectura percibida con el lector externo.

## Arranque reducido y archivo de módulos, 8 de noviembre de 2026

init.lua solo publica configuracion, configurador y keys. RhomScripts.soporte conserva audio, oficial y aliases como infraestructura; solo se registra listkeys, sin comandos históricos del registrador. Se mantienen las preferencias oficiales y los recursos nativos necesarios para el configurador. Ya no se cargan config.lua ni modes, ni se crea rl_config.lua. Se retiran las referencias de debug, contadores y registro de triggers del arranque. Los archivos y preferencias personales antiguos no se borran.

Los 26 módulos desconectados se trasladaron a la carpeta raíz `rhomscripts old`, fuera de la ruta de carga y de la comprobación estática de producción. La suite anterior de dominios se conserva allí en tests/behavior.lua como evidencia histórica, sin ejecutarla como validación actual. Las pruebas optativas wx/cffi añaden esa ruta exclusivamente en sus propios perfiles de ensayo para encontrar sus demostraciones archivadas; init.lua no registra esos comandos.

`scripts/validate.ps1 -Mudlet` superó los nueve controles locales y la integración en Mudlet 5.1.1, última estable verificada por el ejecutor, en perfil aislado y desconectado. Resultado final: dos teclas, un alias y cero triggers propios. Evidencia: `.tools/mudlet-integration/runs/19c6cfc230da4059b62ed797c1957490/result.txt`. Se comprueban tres módulos exactos, ausencia de configuración antigua, limpieza de registros de una instancia anterior, errores de APIs, nueva configuración, teclado y recarga mediante RhomLoader. Los triggers y servicios propios del paquete oficial no forman parte de esos recuentos. No se ha comprobado teclado físico ni lectura percibida; las suites de dominios archivados dejan de ejecutarse en el alcance activo.

## Configurador unificado, 8 de noviembre de 2026

Integrado el borrador en `rhomscripts/configurador.lua`, con `nueva_sesion()` para edición sin abrir la ventana. Eliminado `configurador_modelo.lua`; se conserva únicamente su limpieza de caché en init.lua para recargar desde la versión anterior. Sesión y ventana comparten el índice de definiciones y el formato de valores, sin alterar persistencia, avisos ni cierre. Actualizadas las pruebas existentes para utilizar el módulo unificado.

`scripts/validate.ps1 -Mudlet` superó los nueve controles locales y la integración real en Mudlet 5.1.1, última estable consultada por el ejecutor contra releases oficiales, con dos teclas, un alias y cero triggers propios. Evidencia: `.tools/mudlet-integration/runs/61f66e860fd4451986b669e0209c7ebf/result.txt`. Tras el ajuste final del formato compartido se repitieron los nueve controles locales y pasaron los quince casos del diálogo nativo, wxWidgets 3.2.8 y 120 pulsos Qt: `.tools/wxlua-probe/runs/31213a24bf814530928984430bc40e6b/result.txt`.

Comandos: `scripts/validate.ps1`, `scripts/validate.ps1 -Mudlet` y `.tools/venv/Scripts/python.exe scripts/run_wxlua_probe.py --configurador`. Perfil aislado y desconectado; se comprueban Guardar, Cancelar, Restablecer, límites, fallos de escritura/aplicación y recarga. No se han observado pulsaciones físicas ni lectura percibida con el lector externo.

## Ventanas y comprobaciones unificadas, 8 de noviembre de 2026

`ui.lua` reúne ventanas, árbol, sonidos de interfaz y operaciones Win32 (`ui.nativo`). `comprobaciones.lua` concentra cargas nativas y preparación oficial. wxLua y cffi se cargan obligatoriamente antes de los módulos funcionales y se conservan entre recargas; la UI valida identificadores y asociaciones al usarlos. `oficial.lua` conserva preferencias y vigilancia durante la sesión. Se mantienen tres módulos funcionales publicados, dos teclas, un alias y cero triggers propios. Quedan nueve archivos Lua activos.

`scripts/validate.ps1 -Mudlet` superó nueve controles locales y la integración real en Mudlet 5.1.1, última estable consultada contra releases oficiales por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/3bb98ea131fd49968f4665fd85984b9b/result.txt`. Los casos nuevos verifican carga real de wx/cffi al inicio, ABI de 64 bits, reutilización sin nuevas cargas y errores por DLL o package.loadlib ausentes. Los casos compartidos también comprueban que un fallo de preparación bloquea módulos, ready y aviso de éxito. El doble local aísla explícitamente la preparación DLL; no simula controles wx ni Win32 y no constituye evidencia de compatibilidad nativa.

El primer ensayo de configurador falló por pasar el segundo retorno de assert a AddRoot al parametrizar el texto raíz (`.tools/wxlua-probe/runs/12c63c77a6a34f76a4365b903f9b2572/result.txt`). Se corrigió validando los textos antes de construir el control. La repetición pasó quince casos, wxWidgets 3.2.8 y 116 pulsos Qt: `.tools/wxlua-probe/runs/da6a2d7d61ac4e22a9215b9a0ee73781/result.txt`. Incluye guardar/cancelar/restablecer, errores, asociación, destrucción y recarga.

Los sondeos adicionales pasaron ocho casos cffi con 29 pulsos Qt (`.tools/wxlua-probe/runs/f8a2728ab82449f8ad1f28a04c330ac7/result.txt`) y seis casos wxLua con 60 pulsos (`.tools/wxlua-probe/runs/4fb4e0f961d34a30aeba9c312cd3eca9/result.txt`). Comprueban identificación de Mudlet, asociación/restauración, rechazo de ciclos y ventanas ajenas, minimización y conservación de bibliotecas entre recargas. Solo usan perfiles aislados y desconectados; no se modificó el portapapeles. Pulsaciones físicas y lectura percibida con lector externo siguen fuera de la automatización.

Comandos: `scripts/validate.ps1 -Mudlet` y `.tools/venv/Scripts/python.exe scripts/run_wxlua_probe.py` con `--configurador`, `--cffi` o sin opción. No se reconstruyó el cargador local porque lee los fuentes externos y no cambia su contrato.

## Ventanas preconstruidas y persistentes, 8 de noviembre de 2026

Política aplicada al arranque: `ui.preparar()` construye las ventanas y controles de los módulos activos, ocultos y antes del registro de teclas y ready. El configurador prepara la vista sin borrador; abrir conserva ventana, árbol, botones y manejadores, renueva el borrador y escribe únicamente etiquetas diferentes. Guardar/Cancelar/X/Escape ocultan y descartan la sesión. La posición se calcula al preparar y una preferencia de asociación distinta se aplica en la próxima presentación sin reconstruir. Las ventanas de canales/historial aún no están implementadas; adoptarán este contrato documentado en la guía Lua.

`scripts/validate.ps1 -Mudlet` pasó los nueve controles locales (Lua 5.1, LuaJIT 2.1.1760617492, Luacheck sin avisos y resto de contratos) y la integración real en Mudlet 5.1.1, última estable consultada por el ejecutor contra releases oficiales. Evidencia final `.tools/mudlet-integration/runs/665731252fa6472fa28786ada3f00fd3/result.txt`. Comprueba controles ocultos al terminar el arranque, retirada de ventanas y registros anteriores, persistencia de bibliotecas y recarga pedida desde CallAfter dentro de ShowModal real: HWND vivo hasta retornar, destrucción posterior y una única nueva ventana/ready, sin publicar el borrador descartado. La prueba local de fallo de destructor verifica que la limpieza de teclas y aliases continúa y que el error se conserva.

Configurador: dieciocho casos superados, wxWidgets 3.2.8 y 112 pulsos Qt, `.tools/wxlua-probe/runs/ccf529ea84ca4e50ab30fa7c4da07114/result.txt`. Observa preparación idempotente sin audio/anuncio ni cambio de foco, identidad estable de ventana y controles, cero constructores durante abrir, cero cambios de texto con valores idénticos y solo un identificador modificado al cambiar una preferencia confirmada. Incluye navegación, guardar/cancelar/restablecer, fallos y destrucción explícita. El primer intento (`.tools/wxlua-probe/runs/3d5ed1689b2e4bbc892c6930b31186f5/result.txt`) falló porque el contador del ensayo también contaba una ventana auxiliar creada expresamente por su acción; se acotó el contador a la operación de abrir, sin cambiar el código funcional.

Sondeos comunes: seis casos wxLua / 58 pulsos (`.tools/wxlua-probe/runs/f60761b329ed4b7d9f3a1a9646e2b863/result.txt`) y ocho casos cffi / 30 pulsos (`.tools/wxlua-probe/runs/058772ea6a7b44bf9f731177e03ff145/result.txt`) superados. Las demostraciones archivadas preparan explícitamente sus ventanas para seguir comprobando el constructor común, sin habilitarlas en el arranque del proyecto.

Comandos: `scripts/validate.ps1 -Mudlet` y `.tools/venv/Scripts/python.exe scripts/run_wxlua_probe.py` con `--configurador`, `--cffi` o sin opción. Perfiles aislados, desconectados y sin tocar portapapeles personal. Se verifica trabajo evitado y reutilización de objetos; no se ha medido una mejora porcentual de latencia. Pulsaciones físicas y lectura percibida con lector externo requieren comprobación de uso. No se reconstruyó RhomLoader: continúa leyendo los fuentes externos.

## Lector reincorporado, 8 de noviembre de 2026

Movido lector.lua desde rhomscripts old al arranque activo, sin reactivar historial ni su caché/trigger. Cuatro módulos funcionales, veinte teclas, tres comandos (listkeys, leerlinea N, copiarlinea N) y cero triggers propios. Las 18 pulsaciones del lector usan keys, grupo lectura, ayuda y retirada en recarga. Véase [ficha del lector](migraciones/lector.md).

`scripts/validate.ps1 -Mudlet` superó los nueve controles locales, con 78 casos en cada runtime Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado aislado y diff check. La integración final se ejecutó con `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py` y pasó 69 casos en Mudlet real 5.1.1, última estable consultada contra releases oficiales, perfil nuevo y desconectado. Evidencia: `.tools/mudlet-integration/runs/0331a3e1dcbf42b9890d66582b076d98/result.txt`.

Verificados orden de nueve posiciones, texto sin salto final mediante echo, blancos y espacios, recepción completa con feedTriggers, callbacks registrados mediante tempKey real, ayuda sin efectos del dominio, limpieza y recarga mediante RhomLoader. La copia exacta, los índices inválidos, APIs ausentes y ausencia de catálogo se comprueban con el doble local; no se toca el portapapeles personal. No se observan pulsaciones físicas ni percepción del lector externo. Se cuentan líneas físicas, incluido el cursor vacío tras un salto final.

Los primeros ensayos del nuevo caso feedTriggers fallaron por esperar una línea sin terminar como si echo y recepción completaran igual el búfer (`e287ae577b7e4b119f8e3dd9ce46bfa2`, `c2456de298604d73a8846489833092c6`). Se corrigió el ensayo para terminar ambas líneas recibidas con salto. Un intento posterior falló durante la instalación oficial, antes del lector, porque el instalador encontró la carpeta RLMud_Config ya creada (`6130a06fc115438d843cc0f5caea0fe3`); una nueva ejecución aislada pasó sin cambiar el instalador. No se presenta ese intento como una validación superada ni se considera corregida esa incidencia del instalador en esta tarea.

RhomLoader no se reconstruye: sigue leyendo los fuentes locales externos. No se conecta al juego ni se modifica el índice de Git.

## Recuento del lector sin blancos, 8 de noviembre de 2026

Corrección de criterio indicada por el usuario: los índices cuentan únicamente líneas con contenido. Se omiten líneas vacías y de solo espacios, incluidas las intermedias y finales. Lectura, copia, aliases y funciones públicas usan el mismo recorrido inverso del búfer en bloques de hasta 64 líneas, sin caché. Los espacios de una línea con contenido se conservan. Esta revisión sustituye la semántica de posiciones físicas descrita en la evidencia anterior.

`scripts/validate.ps1 -Mudlet` pasó los nueve controles locales, con 79 casos por runtime Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado y diff check, y 69 casos reales en Mudlet 5.1.1, última estable verificada contra releases oficiales por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/2e17642dcdfd4b55bae93198279a6f5e/result.txt`.

El caso local prueba nueve líneas separadas por setenta blancos cada una, saltos entre bloques, búfer vacío o de solo espacios y ausencia de suficientes líneas sin sobrescribir el portapapeles. Mudlet real verifica nueve posiciones con blancos intercalados, salto final, espacios conservados y recepción feedTriggers. Continúan pasando ayuda y recarga, con veinte teclas, tres comandos y cero triggers propios. Perfil aislado y desconectado. Copia probada con el doble local; no se modifica el portapapeles personal. No se observan teclado físico ni percepción del lector externo.

## Ctrl+Shift+1…9 para español de España, 8 de noviembre de 2026

Por petición del usuario se aplica una correspondencia fija únicamente para español de España, sin detección ni traducción de distribuciones. keys conserva los dígitos declarados y las etiquetas Ctrl+Shift+1…9, pero registra los códigos efectivos 33, 34, 183, 36, 37, 38, 47, 40 y 41 con Control+Shift. Las colisiones se comprueban sobre los símbolos efectivos. No hay cambios en el lector, su recuento sin blancos ni las otras combinaciones.

`scripts/validate.ps1 -Mudlet` pasó los nueve controles locales, 81 casos en cada runtime Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado aislado y diff check. La integración pasó 71 casos en Mudlet real 5.1.1, última estable comprobada por el ejecutor contra releases oficiales. Evidencia: `.tools/mudlet-integration/runs/bf36d565aec143b0971ef4b0fdf127fc/result.txt`.

Las pruebas compartidas comprueban los nueve códigos registrados mediante tempKey, ejecución y ayuda sin efectos, etiquetas numéricas de listkeys y rechazo de colisiones con símbolos o modificadores en distinto orden. Las pruebas locales recorren los nueve callbacks activos y verifican texto exacto copiado, aviso y solicitud del sonido ui.portapapeles. La integración reproduce ese recurso mediante playSoundFile real y comprueba retirada/recarga con veinte teclas, tres aliases y cero triggers propios. Solo se usan perfiles aislados y desconectados; el portapapeles personal permanece intacto. La prueba real invoca callbacks registrados; no se han validado físicamente las nueve pulsaciones ni su percepción con lector externo.

El diagnóstico anterior registró 33 y 34 con Control+Shift en el perfil de prueba (`.tools/keyboard-probe/98628e02d0164ff9a74f2d9a9e2a65b4/keys.txt`). No valida por sí solo las nueve teclas: los otros símbolos corresponden a la tabla fija de español de España. Fuentes de códigos: doc/mudlet/KeyCodes.lua (incluido periodcentered = 183); firma de tempKey y ciclo de retirada: doc/mudlet/Lua_Functions.html. El motor de Mudlet compara código y modificadores exactamente: [TKey.cpp de 5.1.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TKey.cpp). No se añade traducción Win32 ni dependencias nuevas.

RhomLoader continúa leyendo los fuentes externos; no se reconstruye ni se modifica el índice de Git. Para aplicar al perfil habitual, recargar con rl.

## Texto, sonido y confirmación al copiar, 8 de noviembre de 2026

lector.copiar escribe una sola vez mediante setClipboardText, anuncia el texto copiado, solicita ui.portapapeles y anuncia Copiado (o el aviso explícito de su API pública), en ese orden. copiar_linea deja de pasar Línea copiada. No introduce temporizadores, espera del fin de voz ni cambios de procesamiento de announce. La secuencia de llamadas no demuestra que la voz termine antes del sonido.

`scripts/validate.ps1 -Mudlet` pasó los nueve controles locales, 82 casos en cada runtime Lua 5.1 y LuaJIT 2.1.1760617492, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado y diff check. Pasaron 71 casos en Mudlet real 5.1.1, última estable verificada contra releases oficiales por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/3c6bc08823e248a487ff309c33d34175/result.txt`.

Nuevo caso local instrumenta con delegación las tres operaciones y exige exactamente cuatro llamadas: una escritura exacta al portapapeles, anuncio de ese texto, sonido, anuncio Copiado. Siguen pasando los nueve callbacks españoles, ayuda, ausencia de catálogo, índices inválidos, APIs ausentes y recarga. La integración observa APIs reales de voz/audio y registros; conserva intacto el portapapeles personal. No certifica el orden audible percibido por el lector externo.

Investigación independiente de la doble lectura comunicada por el usuario: RhomScripts activo no registra Arriba ni Ctrl+V ni modifica el campo de entrada. El XML oficial examinado tampoco tiene esas teclas ni anuncios de esa entrada. En [TCommandLine.cpp de Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TCommandLine.cpp#L1172-L1244), historyMove puede ejecutar handleAutoCompletion: anuncia el texto actual y luego una coincidencia del historial. Si son idénticos, ese recorrido permite dos anuncios del mismo texto sin duplicarlo en el campo. Es una causa posible deducida del fuente; no se ha reproducido el caso concreto con el lector del usuario. La comprobación pendiente es comparar una frase nueva escrita manualmente con una coincidencia ya presente en historial, sin enviarlas al juego, y conocer lector/versión. No se modifica el historial ni los anuncios globales de Mudlet para ocultar el síntoma.

El usuario confirmó después que una línea escrita manualmente también se lee dos veces al pulsar Arriba. Esto descarta que la duplicación dependa exclusivamente del texto que copia RhomScripts, pero no identifica por sí solo si intervienen autocompletado, historial o eventos de accesibilidad del control. Sigue pendiente conocer el lector y contrastar la ruta de navegación.


## Arranque y monitor de estado, comprobados el 9 de noviembre de 2026

`arranque.lua` sustituye a `comprobaciones.lua` y `oficial.lua`: conserva preparación nativa/oficial y preferencias, y añade registro central de diez componentes, evento `rhomscripts.estado.cambiado` y alias accesible `rhomestado`. El monitor continúa disponible durante la espera y tras un fallo de carga posterior a su preparación; la recarga retira sus recursos y los de las preferencias. La API y los límites se describen en [arranque y estado](usuario/arranque.md).

Comando: `scripts/validate.ps1 -Mudlet`. Nueve controles locales superados, 93 casos en Lua 5.1 y 93 en LuaJIT, Luacheck 1.2.0 sin avisos, PCRE2, empaquetado aislado y `git diff --check`. Integración real: `STATUS OK`, 81 casos en Mudlet 5.1.1/Lua 5.1, versión contrastada con la última release estable por el ejecutor. Evidencia: `.tools/mudlet-integration/runs/b4bb7eda5ae448f399e8604ee41a4b23/result.txt`.

Se verifican registros y retirada con APIs reales, carga/recarga, alias sin acumulación, instalación oficial real y propagación de errores. Las transiciones de conexión/GMCP/MSP se simulan invocando los callbacks del monitor y restaurando el estado externo, sin enviar eventos globales falsos a los servicios oficiales. Incluyen protocolo frente a saludo, señal local que no acredita Hello, datos por módulo, desconexión, toma inicial, copia independiente del estado, ruta MSP cambiada, error de descarga conservado y reintento tras API de eventos ausente. El alias se comprueba con el doble local: texto y announce coinciden, sin sonidos adicionales. No se conecta al juego ni se certifica recepción real de servidor, reproducción audible MSP o experiencia con lector externo. El perfil personal y el portapapeles permanecen intactos.


### Corrección del orden de eventos oficiales, 9 de noviembre de 2026

Los listeners del monitor reconcilian `rlmud_config_loaded` y `rlmud_opciones_inicializadas` con el mismo contrato local de nombre, ruta y opciones. Esto evita sobrescribir preparado con inicializando cuando el evento de opciones se emite dentro del evento de configuración. Se añade una regresión compartida que reproduce el orden observado y comprueba que una ruta vacía no acredita preparación.

`scripts/validate.ps1 -Mudlet`: nueve controles locales superados; 94 casos en Lua 5.1 y 94 en LuaJIT; 82 casos de integración en Mudlet 5.1.1, perfil aislado y desconectado. Evidencia: `.tools/mudlet-integration/runs/f6236bb6bf6a4cdba37bb283cf8bc790/result.txt`. El orden de recepción de los callbacks se simula explícitamente; carga, instalación oficial y recarga se ejecutan con APIs reales. No se conecta al juego.


## Comunicaciones e historial de canales, 9 de noviembre de 2026

Primera iteración de comunicaciones.lua conectada desde init.lua: canales GMCP dinámicos, registros compartidos entre canal y Todos, retención enlazada por canal y total, ventana wx preparada oculta y reutilizada, selección común entre atajos y pestañas, lectura automática y explícita por lector.verbalizar con prioridad alta, y silencio temporal por canal. Los tres botones se presentan deshabilitados conforme al alcance. La migración JSON añade límites ausentes conservando las preferencias existentes.

Validación local final: scripts/validate.ps1, nueve controles, 107 casos en Lua 5.1 y 107 en LuaJIT, Luacheck 1.2.0 sin avisos, PCRE2, contratos de API, documentación, empaquetado aislado y git diff --check. El control Git no incluye archivos sin seguimiento; los nuevos fuentes se incluyen en compilación y análisis estático.

Integración general: scripts/validate.ps1 -Mudlet y ejecutor scripts/run_mudlet_validation.py, STATUS OK, 95 casos en Mudlet 5.1.1/Lua 5.1, versión contrastada con la última release estable oficial. Evidencia: .tools/mudlet-integration/runs/14fce5dfb0354f038c90cc9177605c5e/result.txt. Instalación real del paquete oficial, SHA-256 b98d315642f784789485f6d536a5c83bdb8aa4557e827e4da4dd2c205dd201a4; carga y recarga reales, 25 teclas, cinco aliases y cero triggers propios. La prueba previa de audio consultaba el motor inmediatamente: se movió su comprobación a un callback Qt posterior al inicio, manteniendo las aserciones de reproducción y parada y sin cambiar el motor de producción. Algunas ejecuciones intermedias fallaron durante la instalación oficial en perfiles nuevos por una carpeta de destino ya existente; la causa no quedó determinada y no se alteró arranque.lua para ocultar ese fallo.

Ensayo específico: .tools/venv/Scripts/python.exe scripts/run_wxlua_probe.py --comunicaciones, STATUS OK, 21 casos con wxLua 3.2.0.2/wxWidgets 3.2.8 y Mudlet 5.1.1. Evidencia: .tools/wxlua-probe/runs/0b34f05a3e8c4bc4bb7d32a3f8a3e6df/result.txt. Comprueba controles reales, preparación oculta, reutilización, selección y categoría, botones deshabilitados, llamadas a la política local de teclado, GMCP por manejadores reales con datos sintéticos, retirada y reintento de handlers, API ANSI ausente y desconexión. Un temporizador Qt ejecutado durante ShowModal emite el evento GMCP y comprueba la nueva fila sin cerrar el diálogo: QT_HEARTBEAT 3. Se corrigió una duplicación de filas al refrescar sin mensajes nuevos y se añadieron regresiones de silencio, cambio de otro canal y reapertura.

Revisión independiente: 10000 operaciones aleatorias de modelo, semilla 20261109, contrastadas paso a paso con un modelo Python separado, sin discrepancias. Ensayo focal de rendimiento en Lua 5.1: 100000 mensajes con 5000 retenidos en 0.437 segundos, extremos 95001 y 100000 correctos; evidencia .tools/analisis-canales/performance.txt. Ambos son simulaciones con dobles explícitos de dependencias de dominio y entrada ya plana: no miden conversión ANSI, UI, voz ni servidor. El modelo retira registros mediante enlaces, sin desplazar el historial completo; la lista aplica inserciones y retiradas conservando controles, con compactación acotada al límite cuando hay descartes.

Límites: no se conecta al juego, no se certifica el formato completo del servidor ni la recepción física de teclas, ni la experiencia de lectura con el lector externo. La copia oficial a main y su lectura automática pueden añadir voz a la verbalización propia. No se cambian preferencias globales de Mudlet ni se lee o escribe el portapapeles. No se hicieron commits ni se modificó el índice Git; el empaquetado de validación usa una copia aislada.


### Nombre global, historiales vacíos y extremos de navegación

9 de noviembre de 2026: scripts/validate.ps1 supera los nueve controles, incluidos 107 casos por runtime. El ensayo scripts/run_wxlua_probe.py --comunicaciones supera 23 casos en Mudlet 5.1.1 y wxWidgets 3.2.8: nombre de pestaña global, aviso visible/accesible de historial vacío, lectura solicitada vacía y dos sonidos de límite por Arriba/Abajo en vacío; con dos mensajes, solo suenan al intentar superar el primero o último, manteniendo navegación válida. Evidencia: .tools/wxlua-probe/runs/790ad447a1764e74a7d8719706d13ba3/result.txt. Controles y sonido reales, invocación de política local de teclas; siguen pendientes teclado físico y lector externo.


### Historiales del más nuevo al más antiguo

9 de noviembre de 2026: nueve controles locales superados y 24 casos del ensayo nativo en Mudlet 5.1.1/wxWidgets 3.2.8, STATUS OK. Evidencia: .tools/wxlua-probe/runs/ea498d2574af4d5aaca6e1177edf941e/result.txt. Se comprueba el identificador de cada fila en orden inverso, inserción arriba durante el diálogo, selección conservada tras la llegada, mismo orden al reabrir, 100 mensajes retenidos tras 105 inserciones y descarte de los antiguos al final; flechas y sonidos de límite siguen pasando. Las funciones wxListCtrl:GetItemData(long item) usadas para observar la identidad de las filas constan en el binding wxcore_controls.i de la versión instalada. Las pruebas invocan la política local; teclado físico y lector externo siguen pendientes.


### Sonidos de Comunicaciones y texto de canal vacío

9 de noviembre de 2026: scripts/validate.ps1 supera los nueve controles (107 casos por runtime), catálogo real de 31 claves/30 archivos y pruebas de fuentes existentes. El ensayo nativo --comunicaciones supera 25 casos en Mudlet 5.1.1/wxWidgets 3.2.8, STATUS OK, evidencia .tools/wxlua-probe/runs/63c6b450422a451e98c8f8fca0501e91/result.txt. Altas/bajas directas y reconciliadas solicitan las claves comunicaciones.canal_on/off delegando al reproductor real, y los eventos duplicados no repiten sonido; los recursos están presentes. El aviso vacío visible/accesible y Alt+F1 usan «No hay mensajes en el canal XXXX». No acredita percepción auditiva con el lector externo ni eventos del servidor real.


### Cambio de canal: anuncio solo del nombre, 10 de noviembre de 2026

Nueve controles locales superados y 26 casos del ensayo nativo --comunicaciones en Mudlet 5.1.1/wxWidgets 3.2.8, STATUS OK. Evidencia: .tools/wxlua-probe/runs/8a6752f9f01249c88de99fac38102d20/result.txt. Regresión compartida comprueba un solo anuncio con el nombre al cambiar a canal vacío o silenciado y al canal global; con mensajes conserva el nombre sin leer contenido. Alt+F1 sigue comunicando el aviso de vacío a petición. No se acredita experiencia perceptiva con lector externo.


Prefijo de anuncio de canal, 10 de noviembre de 2026: scripts/validate.ps1 supera los nueve controles; las regresiones compartidas comprueban «canal chat» y «canal global» al cambiar de categoría, incluidos canales vacíos y silenciados. Cambio exclusivamente textual en las dos rutas existentes (teclado y ratón), sin nuevas APIs ni alteración de navegación.


### Un aviso sonoro por ráfaga de canales, 10 de noviembre de 2026

Nueve controles locales superados, 108 casos por runtime (Lua 5.1 y LuaJIT) y Luacheck sin avisos. Ensayo --comunicaciones: STATUS OK, 27 casos en Mudlet 5.1.1/wxWidgets 3.2.8, evidencia .tools/wxlua-probe/runs/c243d8eaf47d4d1990407f293fd1e958/result.txt. La regresión emite treinta eventos GMCP reales con datos sintéticos de encendido y treinta de apagado, combinados con transiciones directas/reconciliadas: un sonido on y uno off en toda la ráfaga. Tras procesar temporizadores Qt, otra operación vuelve a sonar; detener/reiniciar el registro retira los temporizadores y permite avisos nuevos. No conecta al juego ni certifica percepción audible o lector externo.


### Todos apagados y límite de cambio de canal, 10 de noviembre de 2026

Nueve controles locales superados y ensayo nativo --comunicaciones STATUS OK con 29 casos en Mudlet 5.1.1/wxWidgets 3.2.8. Evidencia: .tools/wxlua-probe/runs/428d923786514b48bb40f897ebd6bc18/result.txt. Se verifican cuatro avisos ui.limite para Tab/Mayús+Tab y Ctrl+coma/punto, categoría global invariable, apertura del diálogo con «Todos los canales apagados» visible y accesible, y el mismo estado al cerrar todos conservando mensajes anteriores. La primera ejecución de la nueva prueba esperaba solo los cien mensajes de chat y se corrigió para contar también el mensaje de ciudadanía retenido en global; producción no descartaba datos. No prueba teclado físico ni lector externo.


### Título dinámico sin anuncio explícito de apertura, 10 de noviembre de 2026

Nueve controles locales superados; ensayo nativo STATUS OK, 29 casos en Mudlet 5.1.1/wxWidgets 3.2.8, evidencia .tools/wxlua-probe/runs/714ddca3589a44318b9952f2c5522e3e/result.txt. Se comprueba GetTitle al abrir global, cambiar a canal vacío y a ciudadanía, y reabrir chat. La instrumentación delega al método público real y observa cero llamadas explícitas de voz durante la apertura y reapertura. El lector externo y su anuncio automático del título no se simulan ni se certifican.


### Título fijo Historial de canales, 10 de noviembre de 2026

Nueve controles locales superados y ensayo nativo STATUS OK, 29 casos en Mudlet 5.1.1/wxWidgets 3.2.8. Evidencia: .tools/wxlua-probe/runs/5ed3d7f1cf3e4b63a75e456f2ae604a6/result.txt. GetTitle conserva «Historial de canales» al abrir, cambiar categorías y reabrir; no se emite voz explícita de apertura. Se retiraron las llamadas de actualización del título para evitar los anuncios nativos constantes comunicados por el usuario. La experiencia con lector externo sigue pendiente de confirmar.


### Investigación de pestañas conservadas al apagar, 10 de noviembre de 2026

El usuario comunica que siguen visibles las pestañas tras apagar canales. Se amplió el ensayo nativo para observar GetPageCount/GetPageText, además del modelo y las filas: treinta altas individuales GMCP llevan a 31 pestañas y treinta bajas a una sola, global. Se repite el cierre por eventos individuales sobre canales con mensajes retenidos: queda solo global y conserva todos los registros. STATUS OK, 29 casos en Mudlet 5.1.1/wxWidgets 3.2.8, evidencia .tools/wxlua-probe/runs/0bb1ac6ca04b40aa8e558fbccc0cebd8/result.txt. El problema de la sesión del usuario no se ha reproducido ni se considera corregido; pendiente contrastar comando utilizado, Comm.ApagaCanal, Comm.Canales y categorías del módulo tras el cierre real. No se cambia la interpretación del protocolo basándose en supuestos.


### Sincronización de RhomSounds, 10 de noviembre de 2026

El catálogo cubre exactamente los 61 archivos actuales (32 UI y 29 Comunicaciones) con 62 claves, sin rutas ausentes ni archivos sin indexar y respetando las mayúsculas. Canal on/off se encuentran ahora en UI; se conservan sus claves públicas. Se retiran las claves de recursos desaparecidos y el configurador usa ui.boton_1 para números y ui.boton_2 para booleanos, según indicación del usuario. No se modifican los WAV.

`scripts/validate.ps1 -Mudlet`: nueve controles locales superados, cero fallos; sintaxis Lua 5.1/LuaJIT, Luacheck y comportamiento correctos. Integración real STATUS OK en Mudlet 5.1.1, última estable consultada por el ejecutor: carga completa, instalación del paquete temporal, reproducción y recarga. Evidencia: `.tools/mudlet-integration/runs/e1a6085f53d445e38d84a6bf34813383/result.txt`.

`scripts/run_wxlua_probe.py --configurador`: STATUS OK, 18 casos en Mudlet 5.1.1/wxWidgets 3.2.8, incluidos ajustes numéricos y booleanos con las nuevas claves. Evidencia: `.tools/wxlua-probe/runs/2cfb076ab8f143c98fb49989e99ccfc7/result.txt`. Perfiles aislados y desconectados; teclado físico, percepción audible y lector externo no certificados.


Unificación posterior solicitada por el usuario: `ui.clic_1` sustituye a `ui.lista` y `ui.configurador_nav` en navegación de comunicaciones y configurador. El catálogo queda en 61 claves para 61 archivos, con una única clave por archivo. Las evidencias anteriores de esta sección corresponden al estado previo de 62 claves.


Validación final con 61 claves únicas para 61 archivos: `scripts/validate.ps1 -Mudlet` supera los nueve controles locales e integración STATUS OK en Mudlet 5.1.1, ejecución `.tools/mudlet-integration/runs/1fbe66c6c4b440a1b8f2760a855fca41/result.txt`. Los ensayos nativos de comunicaciones (29 casos, `.tools/wxlua-probe/runs/111de301c90c4a2ab0411fae0a957a89/result.txt`) y configurador (18 casos, `.tools/wxlua-probe/runs/8613912d51c74427a008ba40f09ee874/result.txt`) terminan STATUS OK. Un primer ensayo del configurador falló en el control temporal del latido Qt antes de comprobar la navegación (`0aebea4424e94c659ffaa5091ccc9563`); repetido por separado y sin cambios adicionales, pasó. No se certifican teclado físico, percepción audible ni lector externo.

## Contexto y sonidos de llegada de comunicaciones, 10 de noviembre de 2026

Nueve controles locales superados, con 110 casos en Lua 5.1 y 110 en LuaJIT. `scripts/run_wxlua_probe.py --comunicaciones` termina con STATUS OK en Mudlet 5.1.1, última estable comprobada, con wxWidgets 3.2.8 y 32 casos. Se verifican las claves sonoras, el sonido con la lectura silenciada, las tandas por canal incluso con dos canales que comparten sonido, los mensajes nuevos durante una tanda y el vencimiento del temporizador Qt. Las pruebas usan eventos GMCP sintéticos y delegan en el reproductor de Mudlet. Evidencia: `.tools/wxlua-probe/runs/59053a5a2de44a48b77b2a6fd16cbbf5/result.txt`.

La integración general de `scripts/validate.ps1 -Mudlet` se detuvo dos veces antes de cargar los módulos. El instalador del paquete oficial informó que ya existía `RLMud_Config` en el perfil aislado. El ZIP tiene el mismo SHA-256 que en la ejecución anterior que pasó. Evidencia del segundo intento: `.tools/mudlet-integration/runs/4158dbc459554fd39d9d74a094dea767/result.txt`. Quedan sin comprobar la integración general de esta revisión, la conexión al juego y la percepción audible.

11 de noviembre de 2026. `scripts/validate.ps1` supera nueve controles, con 110 casos por runtime. El ensayo `scripts/run_wxlua_probe.py --comunicaciones` supera 32 casos en Mudlet 5.1.1 y wxWidgets 3.2.8. Comprueba los grupos de las llamadas de recepción y de encendido y apagado, y el mismo aviso de selección para global y el resto de canales. El catálogo resuelve ambos WAV en `Sounds/Comunicaciones/` y sus hashes se conservaron durante el traslado. Evidencia: `.tools/wxlua-probe/runs/83c06c3884684927a93ee3c62b905482/result.txt`. Se usó un perfil aislado, sin servidor ni comprobación de percepción audible.

## Catálogo de sonidos integrado, 11 de noviembre de 2026

`scripts/validate.ps1 -Mudlet` superó los nueve controles locales, con 108 casos por runtime en Lua 5.1 y LuaJIT. La integración ejecutó 95 casos en Mudlet 5.1.1 con Lua 5.1, en un perfil aislado y desconectado. El resultado fue `STATUS OK`, con 25 teclas, cinco aliases y cero triggers propios. Evidencia: `.tools/mudlet-integration/runs/40be39b2608a46058e37f73548f84a50/result.txt`.

El traslado conservó las 61 claves y los 61 WAV, verificados por SHA-256 antes y después. Los ensayos comprueban claves y grupos representativos, carpeta ausente o inválida, altas y bajas, colisiones, errores ante APIs ausentes, volúmenes, reproducción y parada reales y recarga mediante RhomLoader. Véase [Sonidos de RhomScripts](usuario/sonidos.md).

Los sondeos `scripts/run_wxlua_probe.py --configurador` (18 casos) y `scripts/run_wxlua_probe.py --comunicaciones` (33 casos) pasaron en Mudlet 5.1.1 con wxWidgets 3.2.8. Evidencias: `.tools/wxlua-probe/runs/747a608ffc0446a7a1f675e70cb72e64/result.txt` y `.tools/wxlua-probe/runs/540727a1f23b4f67bd57708cc57a50cb/result.txt`. Quedan pendientes el teclado físico, la percepción audible, el lector de pantalla externo y el comportamiento conectado al juego.

Como antecedente, el catálogo separado se validó en Mudlet 5.1.1 el 6 de noviembre. La instalación y extracción de cinco sonidos y la ausencia de reproducción durante la lectura se comprobaron en 21 casos, con evidencia en `.tools/mudlet-integration/runs/5f50c110c35c4193ad803658c4644c11/result.txt`. La ampliación a once claves comprobó los avisos de inicio y fallo en 27 casos, con evidencia en `.tools/mudlet-integration/runs/7f98089f57234660888d3c835358a405/result.txt`. La recepción de la primera reproducción por clave y su parada constan en `.tools/mudlet-integration/runs/85d1dff3ed9c469eb1ad8bedf332b330/result.txt`. Los tres ensayos se ejecutaron en perfiles aislados y desconectados.

Se restauraron los nombres originales de los seis WAV de apertura y cierre, con el mismo SHA-256 para cada archivo. Las claves se adaptaron a esos nombres. `scripts/validate.ps1 -Mudlet` superó los nueve controles locales y la integración en Mudlet 5.1.1 (`c6b5dad776594aae91f2a15b0ee1dd30`). Los sondeos del configurador (`dd13118aa13043b6b9768a1dbb40f8ac`) y comunicaciones (`ef26a5532ce64d58adaf5675db55c19c`) comprobaron los sonidos de apertura y cierre en perfiles aislados y desconectados.

## Historiales de Room y telepatía, 12 de noviembre de 2026

`scripts/validate.ps1 -SkipGit -Mudlet` pasó con 110 casos por runtime local, Luacheck sin avisos y Git omitido por falta de metadatos. La integración en Mudlet 5.1.1 ejecutó 97 casos y confirmó la retirada y el reemplazo de registros al recargar. Se observaron 34 teclas, cinco aliases y dos triggers propios. Evidencia en `.tools/mudlet-integration/runs/ceef3e3a25d74a01a80c30d80bb0a98e/result.txt`.

`scripts/run_wxlua_probe.py --comunicaciones` pasó 40 casos en Mudlet 5.1.1 y wxWidgets 3.2.8. `feedTriggers` comprobó la clasificación entre historiales, los duplicados legítimos, los avisos, los silencios y las llegadas en diálogo modal. Los callbacks de los atajos se invocaron con los códigos correspondientes, incluido el mapeo español de coma y punto con Mayús. Se comprobaron el foco inicial, la selección, la desconexión y la recarga. Evidencia en `.tools/wxlua-probe/runs/286bec01234449c1aaba156f9c984e15/result.txt`.

Un ensayo del almacén en Lua 5.1 y LuaJIT, con dobles explícitos de audio y lector, confirmó el límite independiente de 500 mensajes por historial, el descarte de los más antiguos y una llamada de audio por mensaje. Los ensayos reales usaron perfiles aislados y desconectados. Quedan pendientes las líneas recibidas del juego, el teclado físico y la escucha con lector externo. [Contrato de Room y telepatía](migraciones/historiales-room-telepatia.md).

La corrección de los atajos pasó `scripts/validate.ps1 -SkipGit -Mudlet` en Mudlet 5.1.1 con 33 teclas, cinco aliases y dos triggers, y el sondeo `scripts/run_wxlua_probe.py --comunicaciones` en wxWidgets 3.2.8. Se verificaron Alt+F2 en global y una pestaña vacía, Ctrl+F2 en global y PNJs, las dos claves de sonido y la retirada de Ctrl+Mayús+S. Evidencias en `.tools/mudlet-integration/runs/c0056a8cd341461393a85f82c0929de1/result.txt` y `.tools/wxlua-probe/runs/9303bdd25e8f44f2962fe842363cb39f/result.txt`. Los atajos se comprobaron mediante callbacks en un perfil aislado.

## Destinos del mapa, 17 de noviembre de 2026

La primera fase de `mapa.lua` pasó `scripts/validate.ps1`: 10 comprobaciones, cero fallos, 147 casos por runtime Lua 5.1 y LuaJIT, sintaxis, Luacheck, documentación, empaquetado y Git. Informe local: `.tools/validation/runs/tmpwr8mb74o/local.json`.

La integración `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py` pasó 136 casos en Mudlet 5.1.1, última estable consultada en la API oficial, con perfil aislado desconectado. Informe: `.tools/mudlet-integration/runs/142beb8de87f4cb0960d287642fd95db/result.txt`. Se verificaron controles nativos, JSON, alias, supresión de filas en terminal, viaje normal y sigiloso sobre mapa sintético con el motor real y sin enviar movimientos, salidas normalizadas, configuración, apertura pospuesta y recarga. Registros finales: 40 teclas, 3 alias y 2 triggers.

La emisión sintética de `sysInstallPackage` acredita la reparación del adaptador ante ese evento, no una reinstalación completa del paquete mientras se usa la ventana. No hubo conexión al juego ni modificación del portapapeles. Quedan teclado físico, lector externo y alto contraste. Los botones y la escritura de favoritos desde UI están diferidos. [Diseño, detalle y límites](planes/mapa.md#entrega-y-límites) y [manual](usuario/mapa.md).

## Enter en destinos del mapa, 18 de noviembre de 2026

Se corrigieron dos rutas que la primera validación no cubría: la activación nativa de `wxListCtrl` y la aceptación estándar del diálogo sin captura previa. El enlace oficial sigue llamando a `RL_speed_walk_to(id)` o `RL_speed_walk_sigilar_to(id)`; se utilizan esas mismas acciones.

La integración estándar pasó 137 casos en Mudlet 5.1.1/Lua 5.1 (`.tools/mudlet-integration/runs/115828a9bae849deaa5b44bebb895429/result.txt`). El diagnóstico `.tools/venv/Scripts/python.exe scripts/run_mudlet_validation.py --map-keyboard postmessage` pasó 139 casos: Return normal y numérico enviados al HWND aislado activan la fila y producen una sola llamada al motor, con `norte` y `sigilar norte` capturados sin conexión. Evidencia `.tools/mudlet-integration/runs/cca388780dba4215ab8e9bbea547bb35/result.txt`.

`scripts/validate.ps1` aprobó nueve controles y falló en la sustitución de un archivo durante el empaquetado (`.tools/validation/runs/tmpvuk21udy/local.json`). Se repitió únicamente ese control con `.tools/venv/Scripts/python.exe scripts/test_packaging.py`: cuatro casos aprobados. Los 147 casos de comportamiento por runtime, sintaxis, Luacheck, documentación, política de APIs y Git pasaron en la ejecución general.

El modo optativo `--map-keyboard sendinput` abortó antes de inyectar porque el primer plano pertenecía a otra aplicación. No se intentó cambiar el foco de esa aplicación. Quedan teclado físico y lector externo; PostMessage no acredita el hook global de teclado ni Escape por esa vía. [Detalle y límites](planes/mapa.md#revisión-de-enter).
