# Historial de canales

Comunicaciones recibe los mismos eventos GMCP que el paquete oficial y mantiene historiales temporales. Active «Recibir comunicaciones GMCP» en la configuración. El panel oficial puede permanecer oculto.

## Teclado

- Mayús+F1: abrir el historial en la última categoría y selección utilizadas.
- Alt+F1: leer el último mensaje recibido de la categoría seleccionada, con la ventana abierta o cerrada.
- Ctrl+coma y Ctrl+punto: categoría anterior y siguiente desde el juego, con aviso sonoro y nombre del canal.
- Tab y Mayús+Tab: categoría siguiente y anterior dentro de la ventana.
- Arriba/Abajo, Inicio/Fin y RePág/AvPág: navegar por los mensajes.
- Ctrl+Mayús+S: alternar silencio del canal seleccionado. Desde global silencia todos los abiertos; si todos están silenciados, los reactiva.
- Escape o X: ocultar la ventana, conservando historial, categoría y selección.

La pestaña global reúne los mensajes de los canales abiertos. Los avisos individuales de apertura y cierre actualizan las pestañas al llegar. En esos avisos se ignoran los identificadores genéricos `gremio`, `bando`, `ciu` y `clan`. La lista completa `Comm.Canales` reconcilia todas las pestañas con las claves recibidas. Cerrar la ventana no cierra canales. Una llegada no cambia de categoría ni mueve la selección. Alt+F1 consulta siempre el último mensaje retenido y puede diferir de la fila que esté leyendo en la lista.

Los tres botones Responder, Responder en privado y Copiar se muestran deshabilitados: sus acciones se incorporarán en otra iteración.

## Voz y silencio

Cada mensaje recibido de un canal abierto se guarda y se envía una vez a `lector.verbalizar` con prioridad alta, salvo que ese canal esté silenciado. El silencio conserva el historial y permite leer expresamente con Alt+F1. La prioridad todavía no cambia colas ni interrupciones: se utiliza announce estándar.

Al cerrar y reabrir un canal, iniciar una nueva sesión o recargar RhomScripts, el silencio vuelve a estar desactivado. Cerrar y abrir únicamente la ventana conserva los silencios. Los canales nuevos comienzan audibles aunque antes se silenciaran todos los demás.

La lectura automática de Mudlet de la consola principal puede sumarse a estos anuncios cuando el paquete oficial también imprime los canales allí. La opción «Mostrar canales en la consola principal» controla esa copia oficial; este módulo no cambia la configuración global del lector de Mudlet.

## Sonido de los mensajes

Cada mensaje nuevo admitido en el historial reproduce el sonido de su canal, incluso si su lectura automática está silenciada. El catálogo distingue los bandos, interbandos, ciudadanías, gremios y los canales con sonido propio. Los canales `GRUPO-nombre` usan Grupo y los canales sin asignación, incluidas las familias, usan Clan. Las pestañas conservan los identificadores del servidor.

Cuando el servidor reenvía mensajes históricos, el primero de cada canal suena de inmediato. Los históricos siguientes del mismo canal se guardan sin repetir el aviso hasta que pasan 250 ms sin otro histórico de ese canal. Los mensajes nuevos siguen sonando individualmente durante ese intervalo.

## Conservación

En la rama Canales del configurador se ajustan Mensajes por canal (500 inicialmente) y Mensajes totales (5000 inicialmente). El total cuenta registros únicos, sin duplicarlos por aparecer en global. Se retiran primero los más antiguos. Al reducir los límites se recorta el historial existente después de guardar.

Cerrar un canal conserva su historial dentro de esos límites y deja de admitir mensajes para él. Al reabrir se recupera lo retenido. La desconexión y la recarga descartan los historiales; únicamente los límites se guardan en config.json. Los históricos reenviados por el servidor pueden aparecer de nuevo y se ordenan por recepción.

La validación y sus límites se registran en [validación del proyecto](../../Doc/validacion.md). El diseño y los contratos internos están en [panel de canales](../../Doc/migraciones/panel-canales.md).


Cuando no hay mensajes se muestra «No hay mensajes en el canal XXXX», con el nombre del canal; el mismo texto identifica la lista para el lector y se utiliza al solicitar el último mensaje. Arriba/Abajo reproducen Límite cuando el historial está vacío o se intenta superar su primer/último mensaje. Los desplazamientos válidos mantienen el sonido habitual de navegación.


Los historiales muestran primero el mensaje más nuevo. Cada llegada se inserta arriba, conservando por identidad el mensaje seleccionado. Inicio va al más reciente y Fin al más antiguo. Alt+F1 sigue leyendo el último recibido. Los descartes por retención retiran los mensajes antiguos del final.


Encender un canal reproduce Comunicaciones/Canal on.wav; apagarlo reproduce Comunicaciones/Canal off.wav. Los eventos repetidos sin cambio no repiten el sonido.


Al cambiar de canal con Tab, Ctrl+coma/punto o ratón suena Selección canal y se verbaliza «canal» seguido del nombre, por ejemplo «canal chat» o «canal global», aunque esté vacío o silenciado. El aviso de canal vacío sigue disponible visualmente y al pedir el último mensaje con Alt+F1.


Las aperturas o cierres masivos emiten un solo sonido por tipo de cambio. Los eventos consecutivos se agrupan hasta que transcurren 250 ms sin nuevos eventos del mismo tipo. El primer aviso es inmediato; una operación posterior independiente vuelve a sonar. Desconectar o recargar retira los temporizadores de agrupación.


Si todos los canales están cerrados, el historial muestra «Todos los canales apagados», también como nombre accesible de la lista. Tab, Mayús+Tab y Ctrl+coma/punto reproducen Límite sin cambiar la categoría. Los mensajes conservados siguen disponibles en global.


El título fijo de la ventana es «Historial de canales». No cambia al seleccionar otra pestaña ni se verbaliza explícitamente al abrir. Se conservan el sonido de apertura y el anuncio «canal X» al cambiar de categoría.
