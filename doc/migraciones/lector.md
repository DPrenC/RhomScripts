# Ficha de comportamiento: lector

Estado: implementado; resultados de validación en [validación](../validacion.md).

Origen: scripts_vipmud/start.set, FCopiar (24–28), Control-1…9 (58–66) y Ctrl-Shift-1…9 (70–78). Se revisa el lector Lua archivado y se devuelve a rhomscripts/lector.lua, integrado en init.lua.

Entrada: pulsaciones de lectura/copia y comandos leerlinea N/copiarlinea N. Sin conexión ni comandos enviados al servidor. El dominio consulta el búfer principal directamente; historial.lua permanece archivado y no se registra su trigger global.

La lectura llama a `announce(texto)` y salta blancos al contar. La copia de línea llama a `lector.copiar(texto)`, que escribe en el portapapeles una vez, anuncia el texto y «Copiado» con el procesamiento estándar y solicita `ui.portapapeles`. Los errores de las APIs se propagan. [Contrato de copia](../contratos-mudlet.md#copia-de-texto-al-portapapeles)

Estado: no mantiene caché ni captura permanente. keys conserva los identificadores de sus 18 pulsaciones para ayuda, listado y recarga; aliases conserva los dos comandos.

Diferencias respecto al lector Lua archivado: elimina el respaldo que confundía posiciones al descartar blancos; conserva espacios; exige índices enteros positivos finitos; fuera de rango devuelve nil y no copia el aviso. Sustituye la ruta de audio retirada por la clave actual. Mantiene las funciones públicas previas y añade buscar_linea. No implementa las búsquedas de texto de otras teclas de start.set.

Interpretación del búfer: por indicación del usuario se cuentan solo líneas con contenido de Mudlet, omitiendo blancos intermedios/finales y líneas de solo espacios. Se incluyen prompts y texto local. No se afirma equivalencia completa con el filtrado interno de %lastline de VIPMud. Contrato de uso en [lector](../usuario/lector.md).

Casos locales: orden, blancos, espacios, límites e índices inválidos, copia exacta, avisos, clave sonora, comandos, APIs ausentes y las 18 combinaciones en modo normal y ayuda. Integración real: líneas con y sin salto final, feedTriggers, callbacks de tempKey y recarga. La copia del portapapeles se prueba con el doble local; la integración normal no altera el portapapeles personal. Teclado físico y percepción del lector externo requieren comprobación de uso.

Corrección de las teclas de copia: por petición del usuario se fija únicamente el teclado español de España. keys convierte Ctrl+Shift+1…9 a los códigos efectivos 33, 34, 183, 36, 37, 38, 47, 40 y 41, sin cambiar la declaración del lector ni las etiquetas de ayuda/listkeys. No hay detección ni traducción entre distribuciones. Las colisiones se validan después de aplicar esa correspondencia. Pruebas compartidas comprueban nueve callbacks, ayuda sin efectos, listado y colisiones; el doble comprueba las nueve copias exactas y solicitud del sonido. La integración real comprueba registro/retirada/recarga y reproducción real de ui.portapapeles, sin tocar el portapapeles personal. No equivale a una comprobación de pulsaciones físicas.
