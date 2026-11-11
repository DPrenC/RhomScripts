# Lector de líneas

El lector está activo al arrancar. Ctrl+1 a Ctrl+9 lee la línea de ese índice desde el final del búfer principal de Mudlet; Ctrl+Shift+1 a Ctrl+Shift+9 la copia. `leerlinea N` y `copiarlinea N` permiten usar cualquier índice entero positivo disponible. No envían comandos al juego. Las teclas de copia usan por ahora la correspondencia fija de español de España en [keys](teclado.md); otras distribuciones no están contempladas.

Los índices cuentan solo líneas con contenido: se omiten cadenas vacías y líneas formadas únicamente por espacios, tabulaciones u otros caracteres de espacio reconocidos por Lua. La posición 1 es la última línea con contenido; la posición 2 es la anterior con contenido, aunque haya blancos entre ambas. Se incluye el texto local de la consola; no se filtran exclusivamente mensajes recibidos del servidor. No se modifica el cursor, el foco ni el desplazamiento de la consola.

La lectura y la copia conservan exactamente el texto de la línea seleccionada, incluidos sus espacios iniciales y finales. Al copiar se escribe el texto una sola vez en el portapapeles, se anuncia ese texto, se solicita el sonido `ui.portapapeles` y se anuncia «Copiado», en ese orden. Se mantienen las llamadas estándar a announce, sin espera de finalización de voz ni cambios de cola o interrupción. Si esa clave no está disponible, la copia y el anuncio siguen disponibles. Los errores de las APIs se propagan.

Si el índice es inválido o queda fuera del búfer, se anuncia el motivo. No se copia el aviso al portapapeles ni se reproduce el sonido de copia. Si no existen suficientes líneas con contenido, se anuncia «No hay línea disponible». No hay caché alternativa; el búfer se recorre desde el final en bloques de hasta 64 líneas, deteniéndose al encontrar el índice solicitado.

Las 18 pulsaciones se declaran en `lector.pulsaciones`, grupo `lectura`, y se registran mediante keys. `listkeys` las enumera. Con la ayuda de Ctrl+Shift+H activa, solo se anuncia su descripción; no se consulta ni copia texto ni se reproduce sonido. La recarga retira todos los registros antes de instalar los nuevos.

API Lua: `decir(texto)`, `copiar(texto, aviso)`, `buscar_linea(indice)`, `leer_linea(indice)` y `copiar_linea(indice)`. Buscar/leer/copiar línea devuelven el texto, o `nil, motivo` si el índice no está disponible; omitir el índice equivale a 1. Se mantienen temporalmente `buscarLinea`, `leerLinea` y `copiarLinea` para consumidores archivados; los dos últimos conservan su retorno histórico `true` tras una llamada sin error.

Se usan directamente [getLastLineNumber](https://wiki.mudlet.org/w/Manual:Lua_Functions#getLastLineNumber), [getLines](https://wiki.mudlet.org/w/Manual:Lua_Functions#getLines), [setClipboardText](https://wiki.mudlet.org/w/Manual:Lua_Functions#setClipboardText) y [announce](https://wiki.mudlet.org/w/Manual:Lua_Functions#announce). Documentación oficial cotejada en Doc/mudlet/Lua_Functions.html: getLines devuelve una tabla relativa, con extremo final exclusivo y nombre de ventana desde 3.17; setClipboardText está disponible desde 4.10 y announce desde 4.17. No se documenta versión mínima para getLastLineNumber ni retorno de setClipboardText.


## Verbalización con prioridad

`lector.verbalizar(mensaje, prioridad)` recibe texto no vacío y `lector.prioridades.ALTA` (cadena `alta`). Valida ambos argumentos y llama directamente a `announce(mensaje)`, disponible desde Mudlet 4.17 según la documentación oficial local. La prioridad está preparada como contrato; todavía no selecciona colas ni interrupciones. Comunicaciones utiliza este método para sus mensajes explícitos. Las funciones anteriores de lectura y copia conservan su comportamiento.
