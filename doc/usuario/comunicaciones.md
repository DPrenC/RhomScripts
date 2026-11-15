# Historial de canales

Comunicaciones recibe los mismos eventos GMCP que el paquete oficial y mantiene historiales temporales. Active «Recibir comunicaciones GMCP» en la configuración. El panel oficial puede permanecer oculto.

## Teclado

- Mayús+F1: abrir el historial en la última categoría utilizada, con el mensaje más reciente seleccionado. La primera visita a cada pestaña tras abrir también empieza en su mensaje más reciente.
- Alt+F1: leer el último mensaje recibido de la categoría seleccionada, con la ventana abierta o cerrada.
- Ctrl+coma y Ctrl+punto: categoría anterior y siguiente desde el juego, con aviso sonoro y nombre del canal.
- Tab y Mayús+Tab: categoría siguiente y anterior dentro de la ventana.
- Arriba/Abajo, Inicio/Fin y RePág/AvPág: navegar por los mensajes.
- Ctrl+F1 alterna el silencio del canal seleccionado. Desde global silencia todos los abiertos. Si todos están silenciados, los reactiva.
- Escape o X: ocultar la ventana, conservando el historial y la categoría.

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

La validación y sus límites se registran en [validación del proyecto](../validacion.md). El diseño y los contratos internos están en [panel de canales](../migraciones/panel-canales.md).


Cuando no hay mensajes se muestra «No hay mensajes en el canal XXXX», con el nombre del canal; el mismo texto identifica la lista para el lector y se utiliza al solicitar el último mensaje. Arriba/Abajo reproducen Límite cuando el historial está vacío o se intenta superar su primer/último mensaje. Los desplazamientos válidos mantienen el sonido habitual de navegación.


Los historiales muestran primero el mensaje más nuevo. Cada llegada se inserta arriba, conservando por identidad el mensaje seleccionado. Inicio va al más reciente y Fin al más antiguo. Alt+F1 sigue leyendo el último recibido. Los descartes por retención retiran los mensajes antiguos del final.


Encender un canal reproduce Comunicaciones/Canal on.wav; apagarlo reproduce Comunicaciones/Canal off.wav. Los eventos repetidos sin cambio no repiten el sonido.


Al cambiar de canal con Tab, Ctrl+coma/punto o ratón suena Selección canal y se verbaliza «canal» seguido del nombre, por ejemplo «canal chat» o «canal global», aunque esté vacío o silenciado. El aviso de canal vacío sigue disponible visualmente y al pedir el último mensaje con Alt+F1.


Las aperturas o cierres masivos emiten un solo sonido por tipo de cambio. Los eventos consecutivos se agrupan hasta que transcurren 250 ms sin nuevos eventos del mismo tipo. El primer aviso es inmediato; una operación posterior independiente vuelve a sonar. Desconectar o recargar retira los temporizadores de agrupación.


Si todos los canales están cerrados, el historial muestra «Todos los canales apagados», también como nombre accesible de la lista. Tab, Mayús+Tab y Ctrl+coma/punto reproducen Límite sin cambiar la categoría. Los mensajes conservados siguen disponibles en global.


El título fijo de la ventana es «Historial de canales». No cambia al seleccionar otra pestaña ni se verbaliza explícitamente al abrir. Se conservan el sonido de apertura y el anuncio «canal X» al cambiar de categoría.

## Historial Room y telepatía

- Mayús+F2 abre Historial Room. Sus pestañas son global, Jugadores y PNJs. Los mensajes de esta primera versión se guardan en global. Jugadores y PNJs quedan vacías hasta incorporar la clasificación de emisores.
- Ctrl+Mayús+coma y Ctrl+Mayús+punto cambian a la pestaña anterior y siguiente de Room. Funcionan también desde el juego y conservan la categoría elegida para la próxima apertura. En Room también se puede usar Tab, Mayús+Tab o el ratón. El lector anuncia «Room global», «Room Jugadores» o «Room PNJs».
- Alt+F2 lee el último mensaje de la pestaña seleccionada de Room, incluida global. Si está vacía, lo indica.
- Ctrl+F2 alterna el silencio de la pestaña seleccionada de Room. En global alterna el silencio general. Jugadores y PNJs conservan su ajuste por separado para la futura clasificación.
- Mayús+F3 abre Historial de telepatía, con una sola lista. Alt+F3 lee su último mensaje y Ctrl+F3 alterna la lectura automática.

Los atajos de lectura y silencio funcionan desde el juego y dentro del historial correspondiente. El silencio de comunicaciones usa `ui.comunicacion_mute` al activarse y `ui.comunicacion_unmute` al reactivar la lectura.

El lector confirma «canal X, silenciado» o «canal X, lectura activada», incluido «canal global». En los otros historiales anuncia «Room silenciada», «Telepatía silenciada» o el nombre del historial seguido de «lectura activada».

Los historiales nuevos reciben texto mediante triggers de Mudlet y reproducen Room o Telepatía por cada mensaje recibido, también con el historial oculto o con la lectura automática silenciada. La línea original permanece en la consola. Si Mudlet ya lee esa salida, puede oírse junto al aviso de RhomScripts.

Las tres ventanas comparten navegación, sonidos de interacción y selección por mensaje. Cada ventana es independiente y se abre de forma modal. Al abrir, la lista empieza por el mensaje más reciente. Una llegada con la ventana abierta conserva la selección. Room y telepatía conservan hasta 500 mensajes cada uno, en memoria. La desconexión o la recarga vacían los historiales y restablecen el silencio. [Diseño de Room y telepatía](../migraciones/historiales-room-telepatia.md).
