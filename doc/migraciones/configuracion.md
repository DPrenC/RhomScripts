# Configuración persistente y configurador accesible

Estado: implementado, validado localmente y en Mudlet real 5.1.1.

Origen: diseño solicitado por el usuario el 6 de noviembre de 2026. Es funcionalidad nueva; no se atribuye equivalencia a un original VIPMud.

## Contrato

`configuracion.lua` conserva los valores en memoria y define las opciones admitidas. `configurador.lua` construye los submenús de volúmenes y del paquete oficial desde esas definiciones. El JSON es persistencia, no una segunda fuente de estado en ejecución. Los consumidores futuros consultarán `configuracion.get(id)`; modificarán mediante `set(id, valor)` y guardarán explícitamente mediante `save()` cuando corresponda. Las definiciones de opciones no deben modificarse durante la ejecución.

El archivo es `getMudletHomeDir() .. "/config.json"`, fuera de las carpetas reemplazables de paquetes. Formato actual 2: objeto con `version = 2` y objeto `valores` con los cuatro volúmenes y las doce preferencias oficiales declaradas. Un documento válido de formato 1 se migra conservando sus volúmenes y añadiendo los valores predeterminados oficiales. General, interfaz y combate tienen valor predeterminado 80; ambiente, 70. Todos admiten enteros de 0 a 100 en pasos de 5. En los volúmenes, cero representa silencio cuando se conecte el motor; esta etapa no conecta esos volúmenes con la reproducción. Las preferencias oficiales sí se aplican al guardar y al arrancar, según el [contrato de aplicación](../contratos-mudlet.md#aplicación-de-preferencias-oficiales-7-de-noviembre-de-2026). Son booleanas salvo la fuente, cuyo cero indica valor dinámico predeterminado y cuyo rango explícito es de 8 a 50 puntos. Todos los componentes permanecen seleccionables.

Al iniciar, `load()` lee y valida el documento completo. Si falta, crea los valores predeterminados. Si tiene sintaxis o estructura inválidas, anuncia el error y sustituye el documento completo por valores predeterminados. No conserva copias de archivos defectuosos. Un error de E/S conserva los valores en memoria y bloquea escrituras hasta una carga satisfactoria, para evitar sobrescribir un archivo que no pudo leerse. Todos los errores recuperables se anuncian y se escriben en la consola, y devuelven `nil, mensaje`. Las APIs ausentes producen error Lua.

El guardado codifica en un temporal y comprueba escritura y cierre antes de sustituir el destino. En Windows, donde `os.rename` no sustituye el destino existente, hay una ventana entre retirada y renombrado: no se afirma atomicidad absoluta. Si el destino falta al siguiente inicio, `load()` intenta recuperar y validar `config.json.tmp` antes de generar valores predeterminados. Si el principal existe, tiene prioridad sobre el temporal. Un temporal inválido también se regenera sin copias. No se asegura durabilidad ante fallos físicos del disco.

## Menú y teclado

Ctrl+Shift+C abre el configurador y deja de copiar en las listas clásicas. Su apertura registra únicamente sus siete atajos: apertura, cuatro flechas, Enter y Escape. El cierre retira esos registros y restaura los atajos normales de RhomScripts. Las listas del juego conservan sus datos y posición. No se registran flechas izquierda/derecha, Enter ni Escape del configurador cuando está cerrado.

El menú principal ofrece «Volúmenes, submenú», «Paquete oficial RLMud_Config, submenú», «Guardar cambios» y «Restablecer valores predeterminados». Arriba y abajo recorren las entradas; derecha o Enter entran. Cada opción anuncia nombre y valor actual. Durante el ajuste, arriba incrementa y abajo disminuye; los límites no dan la vuelta. Izquierda o Enter terminan el ajuste y conservan su valor en memoria. Izquierda desde una sublista vuelve a su entrada del nivel superior. «Guardar cambios» se activa exclusivamente con Enter, persiste el estado actual, aplica las preferencias oficiales y cierra el menú si no falla la aplicación, restaurando los atajos habituales. Un fallo posterior al guardado se anuncia con ese contexto y se relanza; el menú permanece abierto para reintentar, sin revertir acciones realizadas. Derecha sobre esa acción solo anuncia cómo activarla. Escape recarga el JSON y cierra desde cualquier nivel, descartando los ajustes sin guardar; si previamente se guardó, recupera ese último guardado.

Restablecer abre una confirmación inicialmente en No. Arriba o abajo alterna No/Sí; derecha o Enter acepta la selección; izquierda cancela. Se restablece memoria y se marca pendiente de guardado explícito. Escape desde la confirmación cierra sin confirmar la restauración, recuperando el JSON y descartando los ajustes pendientes.

Si falla «Guardar cambios», el menú permanece abierto y conserva los cambios pendientes; Enter sobre esa opción reintenta. Si falla la lectura con Escape, el menú permanece abierto y se anuncia el fallo, sin escribir los ajustes; Escape reintenta la lectura. La recarga mantiene las reparaciones existentes de documentos ausentes o defectuosos, que generan predeterminados y no persisten los ajustes descartados. Una recarga de scripts con menú abierto descarta sus ajustes pendientes antes de sustituir módulos; si falla la recuperación del JSON, aborta antes de retirar sus registros. No se envían comandos al juego. Los sonidos del menú se solicitan mediante audio.reproducir con claves UI. Los anuncios utilizan `announce(texto)` estándar.

## APIs verificadas

### Sonidos UI incorporados posteriormente

En esta etapa se incorporaron doce WAV de UI aportados por el usuario y se alcanzaron 23 claves. Para la ubicación, las claves y la forma vigentes de solicitar esos sonidos, véase la [guía de sonidos](../usuario/sonidos.md). El configurador utiliza el reproductor común y el menú sigue disponible si falta un sonido.

Asignación: abrir → `ui.abrir`; arriba/abajo en listas y confirmaciones → `ui.lista`; entrar en sublista o confirmación → `ui.desplegar`; volver de sublista o terminar ajuste con izquierda → `ui.plegar`; iniciar ajuste → `ui.seleccionar`; modificar número → `ui.interruptor`; intentar superar límites o izquierda en la raíz → `ui.limite`; terminar ajuste con Enter, confirmar restauración o guardar correctamente → `ui.aceptar`; rechazar/cancelar restauración o salir con Escape → `ui.cancelar`; error al guardar o recargar para salir → `ui.error`; derecha sobre Guardar cambios → `ui.tecla_bloqueada`. Las acciones de salida emiten aceptar o cancelar, sin duplicar con `ui.cerrar`. Cada acción conserva sus anuncios textuales y no incorpora políticas nuevas de cola/interrupción.

- `yajl.to_string(datos)` devuelve JSON como cadena; `yajl.to_value(texto)` convierte JSON a valores Lua. La documentación no especifica versión mínima. Antes del análisis protegido de datos externos se realiza una llamada directa con `{}`: una API ausente se propaga, no se interpreta como archivo defectuoso. [Manual oficial](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#yajl.to_string); copia local en [Miscellaneous_Functions.txt](../mudlet/Miscellaneous_Functions.txt).
- `getMudletHomeDir()` devuelve el directorio del perfil. `tempKey([modificador,] código, función)` registra un atajo y devuelve identificador; `killKey(id)` lo retira. Contratos existentes en [contratos-mudlet.md](../contratos-mudlet.md), documentación oficial local en [Mudlet_Object_Functions.txt](../mudlet/Mudlet_Object_Functions.txt).
- `io.open`, lectura/escritura/cierre, `os.rename` y `os.remove`: [Lua 5.1](https://www.lua.org/manual/5.1/manual.html). `lfs.attributes(ruta, "mode")`: [LuaFileSystem](https://lunarmodules.github.io/luafilesystem/manual.html#reference). Se llama directamente a la API existente, sin alternativas de compatibilidad.

Consulta de documentación y release: 6 de noviembre de 2026. La API oficial de GitHub confirmó `Mudlet-5.1.1` como última release estable durante la tarea; la respuesta de la caché web para `/releases/latest` discrepaba y no se utilizó para seleccionar ejecutable.

## Validación del 6 de noviembre de 2026

Comando: `scripts/validate.ps1 -Mudlet`. Resultado: nueve comprobaciones locales sin fallos, compilación y comportamiento en Lua 5.1 y LuaJIT, Luacheck sin avisos, PCRE2, contratos, empaquetado temporal y `git diff --check`. Integración real en Mudlet 5.1.1/Lua 5.1: `STATUS OK`, 42 casos, incluidos 15 de configuración y configurador. Evidencia local ignorada por Git: `.tNols/mudlet-integration/runs/df7541eeae1544eba5816a90b7e1d855/result.txt`.

Casos propios: creación; persistencia explícita sin relectura por cambio; rechazo de valores inválidos; regeneración de JSON defectuoso; errores de apertura, lectura y cierre; bloqueo de escrituras tras lectura fallida; fallos de sustitución y promoción del temporal intacto sin reescritura; límites y anuncios; restauración confirmada; guardado exclusivamente con Enter, cierre al guardar y restauración de atajos, y reintento tras fallo; Escape sin escritura recupera el último guardado, incluso tras un ajuste posterior; lectura fallida al cancelar mantiene el menú abierto y permite reintentar; APIs JSON/announce ausentes; aislamiento del contexto de teclas y recarga que descarta cambios pendientes. Los errores de E/S se provocan en puntos concretos delegando las demás operaciones al sistema real. El JSON usa yajl nativo en Mudlet y un puente Python json con conversiones explícitas en las pruebas locales.

La revisión independiente detectó dos riesgos de pérdida de configuración, corregidos y cubiertos por las pruebas de bloqueo de lectura y recuperación del temporal. La recuperación promueve el temporal validado mediante `os.rename`, sin volver a abrirlo para escritura.

La ampliación sonora se verifica instrumentando `audio.reproducir` y `playSoundFile` con delegación a sus implementaciones reales. Se comprueba una solicitud por acción, clave semántica, grupo UI, ausencia de opciones de volumen y ausencia de sonido de cierre duplicado. El catálogo y el paquete temporal instalado contienen 23 claves y 23 archivos accesibles. El caso adicional comprueba apertura, navegación, ajustes y límites, confirmaciones, guardado/cancelación y errores de E/S; la ausencia de `playSoundFile` produce error también desde el configurador. No se afirma calidad audible ni interacción física con el lector de pantalla.

## Límites

`config.lua`, `rl_config.lua` y `modes.lua` antiguos permanecen intactos. No se migran sus datos ni se conectan las preferencias a esos modos. No se ofrece aún categoría Modos. La conexión de volúmenes se hará posteriormente solo con el reproductor por claves; no se modifica el audio antiguo. El control bNoleano y las selecciones de modos se incorporarán al definir sus opciones reales.

La integración automatizada invoca callbacks registrados mediante `tempKey` real; no equivale a pulsaciones físicas ni demuestra percepción auditiva con el lector externo. Las pruebas se ejecutan en perfil aislado y desconectado.
