# Diseño del panel de canales de RhomScripts

Estado: primera iteración implementada el 9 de noviembre de 2026; evidencia de validación y límites en doc/validacion.md. Fecha: 9 de noviembre de 2026. Tab para cambiar de canal confirmado por el usuario. Se incluyen Responder, Responder en privado y Copiar; el usuario confirma que sus acciones se dejan sin implementar por ahora. Este documento concreta el panel de canales de la [biblioteca de ventanas](biblioteca-ventanas.md); la accesibilidad con lector externo y el teclado físico siguen pendientes de comprobación.

## 1. Alcance y procedencia

Ventana nativa propia con historiales dinámicos de los canales oficiales, botones Responder, Responder en privado y Copiar sin acciones implementadas, teclado, sonidos y retención limitada. Los mensajes viven únicamente en memoria. Cerrar la ventana o una pestaña conserva el historial; recargar RhomScripts o terminar la sesión lo descarta. Solo las preferencias de retención se guardan en config.json. La categoría seleccionada y los silencios son estado temporal de comunicaciones.lua, compartido por la ventana y los atajos externos.

La fuente funcional de este trabajo es el paquete oficial y la petición actual del usuario. No se reactiva el módulo archivado de comunicaciones ni sus clasificaciones fijas, triggers de texto, telepatía o conversaciones de sala. Los nombres de canales proceden del servidor.

Fuente oficial examinada: https://mudlet.reinosdeleyenda.es/RLMud_Config.zip, descargada el 9 de noviembre de 2026. SHA-256 del ZIP: b98d315642f784789485f6d536a5c83bdb8aa4557e827e4da4dd2c205dd201a4. SHA-256 de RLMud_Config.xml: 0bca1cf09f614e04f418782d8ee52c894622e878b6821c6da4d17591477dd750. Análisis estático de los scripts RL_gui_widget_comm_*, RL_gui_GMCP_* de canales y RL_activar_comunicaciones, incluidos sus eventHandlerList. No se ha conectado al juego.

## 2. Presentación y lectura

Título: «RhomScripts. Canales.». Ventana redimensionable mediante el ciclo de vida de ui.lua y la preferencia existente de ventanas flotantes.

Orden de lectura: pestaña actual, historial, acciones del mensaje seleccionado y estado breve. La barra superior mantiene visibles los nombres de las pestañas que quepan y permite desplazarse por las restantes. Solo se muestra el historial del canal activo. Si hay muchos canales, no se comprimen los nombres hasta volverlos ilegibles; Tab sigue alcanzándolos todos.

Primera pestaña permanente: «Todos los canales», identificador interno global. Después, canales abiertos en orden alfabético estable; las altas y bajas no cambian la selección si el canal seleccionado continúa abierto. Se mantienen los identificadores exactos del servidor aunque cambie la etiqueta de presentación.

El área central es una lista nativa de selección única con cabecera: «Canal» y «Mensaje». En Todos, Canal identifica el origen; en una pestaña individual puede ocultarse esa columna redundante. Orden: mensajes recientes arriba y antiguos abajo. Se permite leer y copiar el texto completo aunque una celda quede recortada visualmente.

A la derecha de la lista, un panel compacto «Acciones del mensaje seleccionado» con tres botones nativos: Responder, Responder en privado y Copiar, en ese orden. Se actualiza su asociación al cambiar de fila. Son controles asociados a cada mensaje, mediante tres controles compartidos; no se crean tres controles por cada fila ni se dibujan palabras que aparenten ser botones. Sus nombres accesibles incluyen acción y contexto suficiente del mensaje. En esta primera entrega se presentan como no disponibles, sin callbacks de envío, copia ni apertura de editor. No se asigna una acción ficticia para simular que funcionan.

Aspecto propuesto: superficies neutras, tipografía del sistema, espacio generoso, separadores discretos, pestaña activa y fila seleccionada claramente diferenciadas, foco nativo visible y botones de tamaño cómodo. Respetar alto contraste y escalado de Windows. El color puede reforzar la selección, pero nombres, foco y estado comunican la misma información.

El estado informa del canal, posición y cantidad de mensajes conservados, y de la conexión. Un historial vacío presenta «No hay mensajes en este canal». En esta primera entrega los tres botones permanecen deshabilitados porque sus acciones no se implementan. En una fase posterior su disponibilidad dependerá de la selección y del destino. Los cambios de estado no provocan anuncios repetidos durante la navegación.

## 3. Teclado y selección

- Mayús+F1: mostrar la ventana de historial en la última categoría y fila utilizadas; si ya está abierta, mantener su estado y enfocarla. No alternar su cierre.
- Alt+F1: verbalizar el último mensaje retenido de la categoría seleccionada, aunque la ventana esté oculta. No confundir el último recibido con la fila seleccionada al navegar por mensajes antiguos.
- Ctrl+coma: categoría anterior desde fuera de la ventana, circular. Ctrl+punto: siguiente, circular. Actualizan la misma selección que usa Tab; no abren la ventana ni solicitan foco.
- Ctrl+F1 alterna el silencio del canal seleccionado, dentro y fuera de la ventana. En global silencia todos los canales abiertos si alguno está audible. Si todos están silenciados, los reactiva.
- Tab: siguiente canal, circular. Mayús+Tab: anterior, circular. Ambos vuelven al mensaje seleccionado del canal de destino.
- Arriba/Abajo: mensaje anterior/siguiente. Cuando las acciones estén implementadas, si el foco está en cualquiera de sus botones, conservar esa acción horizontal al cambiar de mensaje.
- Derecha: Mensaje → Responder → Responder en privado → Copiar. Izquierda: recorrido inverso. En los extremos permanecer y reproducir Límite. Este orden concreta la propuesta actual; sustituye para este panel el orden Copiar/Responder del diseño genérico anterior.
- Inicio/Fin: primer/último mensaje; RePág/AvPág: desplazamiento por bloques, conservando la acción horizontal.
- Enter o Espacio sobre un botón: ejecutar su acción únicamente en la futura fase funcional. En la primera entrega los botones están deshabilitados; las flechas no fuerzan foco sobre controles deshabilitados y el foco permanece en la lista. Enter sobre el mensaje no envía ni copia.
- Escape y X: ocultar la ventana y devolver el foco al juego, conservando los mensajes y la categoría.
- Clic en pestaña, fila o botón: misma operación y validaciones que el teclado. Alt+Tab y los atajos del sistema conservan su función.

Al iniciar el módulo, la categoría seleccionada es global. Cambiarla con Ctrl+coma/punto antes de abrir determina qué categoría se mostrará. Cada apertura conserva la categoría actual y selecciona su mensaje más reciente. La primera visita a cada pestaña durante esa apertura también selecciona su mensaje más reciente. Las visitas siguientes, mientras la ventana está abierta, restauran la selección de esa pestaña.

La llegada de mensajes no mueve el foco, no cambia de pestaña ni desplaza la selección. Inicio permite ir voluntariamente al más reciente; Fin lleva al más antiguo. Si la retención elimina el seleccionado, seleccionar el superviviente más cercano e informar una vez; nunca reutilizar la posición de fila como identidad del mensaje.

La lectura ordinaria corresponde a los controles nativos y al lector externo. announce(texto) se reserva para confirmaciones y estados que el control no comunique; se conserva su comportamiento estándar. Cada mensaje entrante aceptado se envía además a lector.verbalizar(texto, "alta"), salvo silencio de su canal, tanto dentro como fuera de la ventana. No cambiar las preferencias globales de voz de Mudlet. La copia oficial a la consola principal puede provocar lectura adicional por Mudlet: la nueva lectura automática no debe darse por libre de duplicados sin comprobar la combinación de opciones y el lector externo.

## 4. Acciones

Decisión confirmada: mostrar tres botones nativos, Responder, Responder en privado y Copiar, pero dejar sus acciones sin implementar por ahora. No abrir editor, enviar comandos, escribir en el portapapeles ni emitir confirmaciones de operaciones que no se realizan. Conservar nombres accesibles y estado deshabilitado; no ocultarlos al lector. El recorrido horizontal completo queda diseñado para cuando se activen las acciones.

Significado futuro de Responder: dirigirse al canal de origen del mensaje seleccionado, también desde Todos. Significado futuro de Responder en privado: dirigirse al autor de ese mensaje concreto. No utilizar el último remitente global ni deducir el autor a partir del texto visible. Copiar actuará sobre el texto completo del mensaje seleccionado, sin escapes ANSI ni etiquetas de controles.

El editor, el teclado de edición, las confirmaciones, el protocolo de envío y los sonidos de estas operaciones se diseñarán al abordar su implementación. Queda diferida la propuesta anterior de editor integrado. Será necesario verificar el verbo de envío del canal y una identificación fiable del autor para responder en privado; el contrato mínimo analizado de los mensajes oficiales solo acredita canal y mensaje.

## 5. Integración oficial y pestañas dinámicas

Suscripción: reutilizar la gestión existente de Comm bajo el usuario RhomScripts en arranque.lua y la opción «Recibir comunicaciones GMCP». El panel puede funcionar con la interfaz oficial oculta. No modificar funciones oficiales ni capturar el texto de sus consolas. No registrar una segunda suscripción independiente.

- gmcp.Comm.Canales: reconciliar el conjunto completo de canales abiertos con las claves recibidas. Añadir y retirar pestañas por diferencias, conservando mensajes y selección. No reproducir el borrado de consolas del paquete oficial. Conservar silenciado en canales que siguen abiertos; los nuevos comienzan en false y las bajas lo restablecen a false. Recibir otra lista completa no equivale a recargar todos los canales.
- gmcp.Comm.EnciendeCanal: abrir inmediatamente la pestaña indicada por canal, restaurando sus mensajes retenidos e inicializando silenciado=false en la transición cerrado → abierto. Un alta repetida conserva la pestaña y el silencio.
- gmcp.Comm.ApagaCanal: retirar inmediatamente la pestaña indicada por canal, conservando su historial y restableciendo el silencio a false. Si estaba seleccionada, pasar a global.
- gmcp.Comm.MensajeCanal: si el canal está abierto, añadir un registro al canal indicado y a Todos mediante referencias al mismo registro. Si está cerrado, descartar el mensaje sin guardarlo en ninguno de los dos historiales.
- gmcp.Comm.MensajeCanalHistorico: aplicar el mismo filtro de canal abierto y almacenamiento, marcado como histórico. No asumir fecha del servidor ni deduplicar solo por coincidencia de texto.

Los avisos individuales de alta y baja omiten las claves exactas `gremio`, `bando`, `ciu` y `clan`. La lista completa `Comm.Canales` se aplica íntegra. Si una operación masiva carece de eventos con los nombres concretos y de una lista nueva, puede ser necesario reanunciar Comm manualmente.

Los mensajes requieren canal y mensaje válidos. Solo se almacenan para canales confirmados abiertos por Comm.Canales o EnciendeCanal. Si el canal está cerrado, o todavía no está confirmado abierto, descartar tanto mensajes nuevos como históricos; no añadirlos a Todos, crear historial ni abrir pestaña por recibir un mensaje. Tras reabrir, aceptar las nuevas recepciones, incluidos históricos que el servidor vuelva a enviar. La validez y los diagnósticos de datos malformados se definirán al verificar el protocolo real.

Lo esperable es que el servidor deje de enviar mensajes al cerrar el canal; no se ha verificado conectado al juego. El filtro local asegura que cualquier recepción tardía o inesperada posterior al cierre no se guarde. Una reconciliación completa también marca como cerrados los canales ausentes. Cerrar la ventana propia no equivale a cerrar un canal: los canales abiertos siguen recibiendo y almacenando mientras la ventana esté oculta. La condición de abierto procede del estado reconciliado actual, no de la mera existencia de datos GMCP antiguos.

Al activar el módulo con una conexión vigente, tomar la lista actual de Comm.Canales. No convertir el último valor de MensajeCanal o MensajeCanalHistorico almacenado en gmcp en una supuesta lista de mensajes anteriores. Registrar y retirar los manejadores mediante identificadores, con recarga sin acumulación.

Cerrar la ventana no apaga canales. Abrir/cerrar canales se sigue haciendo mediante los comandos del juego; esta entrega no añade botones de suscripción. Un cambio de canal recibido no roba el foco ni activa su pestaña automáticamente.

## 6. Memoria, retención y sesiones

Opciones propuestas en una rama «Canales» del configurador: «Mensajes por canal», valor inicial 500, rango 100–5000, paso 100; «Mensajes totales», valor inicial 5000, rango 100–20000, paso 100. Ambas persistentes. El máximo total puede ser menor que el máximo por canal: es un límite adicional y prevalece cuando se alcanza.

El límite por canal cuenta tanto canales abiertos como cerrados. El total cuenta mensajes únicos de toda la sesión; Todos referencia esos mismos registros. Al superar cualquiera, retirar primero los registros más antiguos por secuencia de llegada y eliminar sus referencias en todas las vistas. No mantener copias de texto ni listas de identificadores descartados que crezcan indefinidamente. La reducción de límites se aplica al guardar correctamente las preferencias.

Un canal cerrado conserva solo los mensajes que sigan dentro de ambos límites. Si queda vacío, se puede retirar su estado interno; no acumular objetos de pestañas o controles por cada nombre de canal visto durante toda la sesión. La promesa de conservación al reabrir está sujeta a estos límites.

Cada canal mantiene abierto y silenciado como estados independientes; silenciado comienza en false. Cada mensaje tiene identificador monotónico local, canal exacto, texto normalizado y marca de histórico. El orden es el de recepción, también para históricos: no se atribuye una cronología del servidor sin datos que la acrediten.

Propuesta de frontera de sesión: desconexión del juego, cierre del perfil o recarga de RhomScripts vacían mensajes, canales y borradores. Volver a conectar comienza otra sesión. Un reinicio de la GUI oficial o un nuevo Comm.Canales durante la misma conexión conserva el historial. Un servidor puede reenviar históricos tras reconectar: recibirlos de nuevo no es persistencia local.

## 7. Sonidos

Todos se solicitan mediante el motor de audio, con claves del grupo UI. Véase la [guía de sonidos](../usuario/sonidos.md).

- Mostrar ventana: ui.abrir_com, «Abrir com.wav».
- Escape o X: ui.cerrar_com, «Cerrar com.wav».
- Alta real de un canal tras la sincronización inicial: ui.on.
- Baja real de canal: ui.off.
- Cambiar a canal individual: ui.seleccion_canal, tanto con Tab/Mayús+Tab o ratón dentro como con Ctrl+coma/punto fuera.
- Cambiar a Todos: ui.seleccion_canal_defecto por cualquiera de esas rutas. Anunciar el nombre de la categoría y su estado de silencio mediante lector.verbalizar con prioridad alta; no leer automáticamente su último mensaje al cambiar. Si solo existe Todos y no cambia la categoría, no emitir sonido de cambio.
- `ui.comunicacion_mute` suena al silenciar y `ui.comunicacion_unmute` al reactivar, con una única confirmación de voz mediante `lector.verbalizar` y prioridad alta. En global suena un solo aviso para el cambio conjunto.
- Cambiar de mensaje: ui.lista.
- Cambiar de acción: ui.clic_2.
- Copiar, Responder y Responder en privado: sin sonidos de operación en esta primera entrega, porque sus acciones quedan sin implementar.
- Límite de navegación: ui.limite. Error de operación: ui.error.

Las altas/bajas reales pueden sonar con la ventana oculta. La carga inicial o una reconciliación con varios cambios no debe producir una ráfaga: agrupar en un aviso por tipo de cambio y un texto breve cuando sea necesario. Si cerrar el canal seleccionado fuerza el paso a Todos, emitir un solo sonido terminal de baja, sin sumar el de cambio de pestaña. Preparar controles, refrescar datos o retirar registros por retención no produce sonidos de navegación.

Las claves `ui.abrir_historial` y `ui.cerrar_historial` quedan reservadas para las ventanas de otros historiales.

## 8. Implementación posterior y validación

Distribución confirmada: rhomscripts/comunicaciones.lua para modelo, selección compartida, silencios, eventos, pulsaciones y ventana con tres botones deshabilitados; componentes reutilizables de lista/pestañas y navegación en ui.lua; límites en configuracion.lua y configurador; integración de carga, preparación, retirada de manejadores y recarga en rhomscripts/init.lua; método público de verbalización en rhomscripts/lector.lua. No reactivar módulos archivados para obtener funciones auxiliares. Los contratos públicos propuestos de comunicaciones son mostrar_historial(), leer_ultimo(), cambiar_categoria(delta) y alternar_silencio(); las pulsaciones se publicarán mediante el registro keys existente. No representan todavía funciones disponibles. Las llamadas a APIs externas requieren verificación documental antes de implementarse.

Preparar la ventana, lista y botones antes de ready, ocultos y sin foco. Las pestañas son datos dinámicos; cambiar de canal actualiza el contenido de la misma lista y conserva su identidad. Actualizar inserciones, retiradas y cambios sin reconstruir toda la ventana o el historial al abrir. No añadir sondeos periódicos para mantener una ventana oculta.

La biblioteca actual intercepta Tab de forma común para recorrer controles. Será necesario añadir una política por ventana para que este panel cambie de canal sin alterar el configurador. Los atajos externos se registran mediante keys; los atajos que deben funcionar dentro del diálogo wx se atienden también por su política local, sin ejecutar dos veces la operación. La interacción modal wx con los eventos GMCP de Qt deberá probarse: la recepción y actualización deben continuar mientras el panel esté abierto.

Casos de aceptación: carga sin conexión y con Comm ya presente; apertura/cierre/reapertura de canales; reconciliaciones repetidas; canal seleccionado desaparecido; llegada durante navegación; históricos y textos idénticos legítimos; mensajes con ANSI y Unicode; presencia y estado accesible deshabilitado de los tres botones, sin envío ni copia; descarte de mensajes nuevos e históricos tras cerrar un canal y reanudación tras abrirlo; límites por canal y total, incluidos canales cerrados; reducción de límites; desconexión y nueva sesión; panel oficial oculto; cierre/reapertura sin reconstrucción; doble carga y errores de API; eventos durante diálogo abierto; teclado físico y lector externo.

Al implementar: verificar firmas y retornos oficiales antes de usar APIs, ejecutar scripts/validate.ps1 y pruebas pertinentes en Mudlet real con perfil aislado y desconectado. Comprobar la última versión estable oficial y registrar la realmente probada. Los eventos sintéticos acreditan integración local, no recepción desde el servidor. La accesibilidad exige comprobar lectura, filas y foco con lector externo.

Se han implementado modelo, integración y ventana, con pruebas de comportamiento locales y nativas; consultar la evidencia final de esta iteración en doc/validacion.md. La versión nativa registrada actualmente en el manifiesto local es wxLua 3.2.0.2 con wxWidgets 3.2.8; esto no acredita la viabilidad ya probada del nuevo panel.

## 9. Decisiones pendientes

Confirmado: tres botones separados, Responder al canal, Responder en privado al autor y Copiar. Sus acciones quedan sin implementar por ahora. La fase funcional futura deberá concretar editor, protocolo, autor fiable y navegación efectiva por los botones habilitados.

Confirmado: módulo comunicaciones enlazado desde init, apertura Mayús+F1, lectura Alt+F1, categorías anterior/siguiente Ctrl+coma/punto y silencio Ctrl+Mayús+S, también conjunto desde Todos. Comprobar colisiones con los registros activos y el paquete oficial antes de implementarlas. Se retira la propuesta de Ctrl+Mayús+M. Un alias rhomcanales queda opcional. Propuestas revisables sin implementación: límites iniciales y rangos y orden alfabético de pestañas. El usuario autorizó implementar esta primera iteración; las acciones de los tres botones siguen expresamente diferidas.


## 10. Verbalización pública y prioridades

Contrato propuesto: lector.verbalizar(mensaje, prioridad). mensaje es una cadena de texto plano; prioridad es un nombre simbólico. Se establece lector.prioridades.ALTA = "alta" para evitar números sin significado. No añadir todavía niveles sin uso ni asignarles tiempos, colas o interrupciones. Todos los textos emitidos explícitamente por comunicaciones, incluidos los mensajes recibidos, la lectura solicitada, los cambios de categoría, el silencio, los estados vacíos y los errores comunicados al usuario, pasan por ese método con prioridad alta. Los nombres y estados que lee el lector a partir de controles nativos siguen siendo accesibilidad propia del control.

El esqueleto funcional, cuando se implemente, validará el mensaje y la prioridad admitida y llamará directamente a announce(mensaje). La prioridad forma parte del contrato pero no modifica todavía el comportamiento de voz. No crear una función vacía que pierda mensajes ni simular prioridades mediante otra API. Mantener intactos los consumidores existentes de lector y su contrato de copia; esta tarea no migra sus llamadas ni añade SAPI.

Flujo de recepción: comprobar canal abierto y datos; crear un solo registro; incorporarlo al canal y a Todos; aplicar retención y actualizar vista sin mover foco; si silenciado=false, invocar una sola vez lector.verbalizar con prioridad alta. La referencia adicional en Todos no provoca una segunda verbalización. Aplicar también a MensajeCanalHistorico, conforme a la recepción pedida por el usuario. Leer el contenido normalizado del mensaje, sin escapes ANSI. El nombre del canal puede anunciarse como contexto si el texto recibido no lo incorpora; no duplicar prefijos existentes.

Alt+F1 consulta el último registro retenido de la categoría seleccionada en el instante de la pulsación y lo verbaliza con prioridad alta, incluso si el canal está silenciado. Si no hay mensajes, comunica «No hay mensajes en [categoría]» por el mismo método. Si está seleccionado Todos, consulta el último registro conjunto, incluidos los recibidos de canales silenciados, porque es una petición explícita. La selección de categoría y de fila son independientes: Alt+F1 no altera ninguna de las dos.

## 11. Silencio temporal de canales

El silencio afecta exclusivamente a la verbalización automática de mensajes recibidos. Conserva la suscripción al canal, el almacenamiento, la pestaña, la navegación, los sonidos de interfaz y la lectura explícita con Alt+F1. La pestaña y el estado accesible indican «silenciado» mediante texto, sin depender de color o iconos.

Ctrl+F1 sobre un canal alterna su estado de silencio. Sobre global aplica una operación conjunta a los canales abiertos. Si alguno está audible, silencia todos. Si todos están silenciados, los reactiva todos. Global es una vista agregada sin un estado de silencio propio. Si no hay canales abiertos, informa de ello y conserva el estado. La confirmación se verbaliza una vez con prioridad alta y el cambio usa `ui.comunicacion_mute` o `ui.comunicacion_unmute`.

Al cerrar un canal, volverlo a abrir, iniciar una nueva sesión o recargar RhomScripts, su silencio queda en off, representado por silenciado=false. Abrir o cerrar solo la ventana conserva los flags. Una alta repetida o reconciliación sin cambio no los reinicia. Después de silenciar desde Todos, los canales que se abran más tarde empiezan igualmente audibles; no existe un silencio global persistente.

Casos adicionales de aceptación: Mayús+F1 respeta la categoría elegida fuera y abre en su primer mensaje; Escape conserva la categoría; Ctrl+coma/punto cambian la selección sin mostrar ventana; Tab usa la misma operación y sonido; Alt+F1 lee el último recibido y no una fila antigua; canal vacío y Todos vacío; una llamada de voz por mensaje recibido, abierto y audible; recepción durante ventana modal; canal silenciado sigue guardando sin verbalizar; lectura explícita de silenciados; silencio conjunto mixto; reapertura y recarga restablecen silencio; eventos repetidos no lo restablecen; desaparición de la categoría elegida pasa a Todos; prioridad alta en todas las emisiones explícitas de comunicaciones; ausencia de announce produce error, sin mecanismos para ocultarlo.


## 12. Referencias de implementación

Método lector.verbalizar: announce(text[, processing]), disponible desde Mudlet 4.17; se omite processing. Texto plano: ansi2string(text) devuelve string sin escapes ANSI, disponible desde 4.10. Evidencia oficial descargada en doc/mudlet/Miscellaneous_Functions.txt (announce) y doc/mudlet/Lua_Functions.txt (ansi2string). Se utilizan directamente, sin alternativas ante API ausente.

Los controles nativos usan las firmas de wxLua 3.2.0.2/wxWidgets 3.2.8 recogidas en sus bindings de construcción locales: wxcore_controls.i para ListCtrl y wxcore_windows.i para Notebook. Referencias públicas: [wxListCtrl](https://docs.wxwidgets.org/3.2/classwx_list_ctrl.html), [wxNotebook](https://docs.wxwidgets.org/3.2/classwx_notebook.html) y [wxLua](https://github.com/pkulchenko/wxlua). InsertPage/DeletePage permiten mantener páginas conservadas; ChangeSelection cambia página sin emitir el evento de selección. Los controles y retornos se contrastan además en el ensayo nativo, sin sustituirlos por widgets simulados.


## 13. Ajuste de nombres y límites, 9 de noviembre de 2026

La categoría agregada se presenta como «global», sustituyendo el nombre anterior Todos los canales de este diseño. Si el historial no tiene mensajes, el texto visible y nombre accesible de la lista son «Historial de XXX vacío»; Alt+F1 y el cambio a un canal vacío utilizan ese mismo aviso. Arriba/Abajo conservan navegación nativa salvo intento de superar un extremo o historial vacío: en esos casos se consume la tecla y se solicita ui.limite una vez. No se insertan mensajes ficticios en el historial.


## 14. Orden descendente del historial

Por petición del usuario, todas las listas presentan del más nuevo al más antiguo. Cada recepción inserta una fila en la posición cero; la selección sigue vinculada al identificador del mensaje y no al índice desplazado. El modelo mantiene sus enlaces cronológicos para retención y consulta del último recibido. Los índices internos de llegada se convierten a posición visual mediante cantidad-1-índice, sin reindexar todos los registros en cada inserción. Las retiradas por retención se traducen también al orden inverso. No se reconstruye la lista por cada llegada.


## 15. Sonidos de canal y texto vacío

Las altas y bajas reales, incluidas las reconciliaciones, utilizan `comunicaciones.canal_on` y `comunicaciones.canal_off` (archivos `Canal on.wav` y `Canal off.wav` en `rhomscripts/sonidos/Comunicaciones/`). El silencio temporal conserva `ui.off` y `ui.on`. El texto vacío definitivo es «No hay mensajes en el canal XXXX», donde XXXX es el nombre del canal, también global, para estado visible, nombre accesible y verbalización.


## 16. Anuncio de cambio de canal, 10 de noviembre de 2026

Tab, Mayús+Tab, Ctrl+coma/punto y selección con ratón anuncian solo el nombre del canal mediante lector.verbalizar con prioridad alta, junto al sonido existente. No añaden texto de silencio, aviso de vacío ni lectura del último mensaje. Alt+F1 conserva la lectura explícita del último mensaje o «No hay mensajes en el canal XXXX».


Ajuste del anuncio, 10 de noviembre de 2026: el cambio de canal verbaliza «canal » seguido del nombre, incluidos «canal chat» y «canal global». Conserva el sonido y no añade lectura de mensajes ni aviso de vacío.


## 17. Avisos únicos en altas y bajas masivas, 10 de noviembre de 2026

Las altas y bajas individuales GMCP y las reconciliaciones comparten agrupación sonora por dirección. El primer evento reproduce canal_on/off inmediatamente; un temporizador de un solo uso bloquea repeticiones y cada evento posterior renueva su vencimiento a 250 ms. No se difiere ningún cambio de dominio ni historial. Se conserva como máximo un temporizador por dirección, sin sondeos periódicos. Detener, desconectar y reiniciar cancelan ambos recursos con killTimer y propagan errores; un fallo de alta posterior también limpia el lote. La operación posterior a la pausa vuelve a sonar. Se utilizan las firmas tempTimer(time, code[, repeating]) y killTimer(id), documentadas en doc/mudlet/Mudlet_Object_Functions.txt.


## 18. Todos los canales apagados, 10 de noviembre de 2026

Cuando la única categoría es global, cualquier intento de cambio mediante Tab/Mayús+Tab o Ctrl+coma/punto solicita ui.limite una vez y conserva la categoría. El estado visible y el nombre accesible de la lista muestran «Todos los canales apagados», tanto sin mensajes como conservando historiales de canales cerrados. No se eliminan esos mensajes ni se cambia la lectura explícita de Alt+F1. La etiqueta se actualiza automáticamente al cerrar o abrir canales y al preparar/mostrar la ventana.


## 19. Título accesible de la ventana, 10 de noviembre de 2026

El título es «Historial de canales. [canal activo]» y se actualiza solo al cambiar su texto, mediante wxTopLevelWindow:SetTitle(const wxString& title), heredado por wxDialog. Se retira el anuncio explícito de apertura: no se llama a lector.verbalizar ni announce para repetir el título. Las aperturas conservan sonido y foco nativo; el cambio de categoría mantiene su anuncio «canal X» acordado. Firmas de SetTitle/GetTitle verificadas en wxcore_appframe.i de los bindings oficiales de la compilación instalada.


## 20. Título fijo definitivo, 10 de noviembre de 2026

Se sustituye el título dinámico por «Historial de canales». Se establece solo al construir la ventana, sin llamadas a SetTitle durante cambios de pestaña, recepción ni apertura. No hay anuncio explícito de apertura. Se conserva el anuncio «canal X» del cambio de categoría.

## 21. Contexto y sonido de llegada

La clasificación se basa en las listas y en el disparador de canales de [Comunicaciones.set](../../scripts_vipmud/ScripsRL/Comunicaciones.set) y en el [módulo Lua archivado](../../rhomscripts%20old/comunicaciones.lua). Al cargar el módulo, los nombres agrupados por contexto se convierten en un índice inverso. Se unifican las mayúsculas ASCII y se tratan los espacios internos como guiones bajos para buscar. Se declaran ambas grafías de `sello_carmesí`. Un nombre con dos contextos produce un error al construir el índice.

Los bandos, interbandos, ciudadanías, gremios y canales con sonido propio usan claves del grupo de comunicaciones. Tras la consulta exacta se reconoce `GRUPO-nombre`. Las familias carecen de entradas en el índice y comparten con los demás canales sin asignación el sonido Clan. Los nombres de pestaña y las claves de historial se toman directamente de GMCP. Los disparadores de texto de los avisos especiales de VIPMud quedan fuera de esta migración.

El sonido se solicita una vez por mensaje nuevo aceptado, con independencia del silencio de lectura automática. Los históricos de un mismo identificador GMCP emiten un aviso inmediato y renuevan su temporizador de 250 ms por cada histórico posterior. Los temporizadores de cada canal son independientes y se retiran al detener o reiniciar el módulo, también al desconectar y recargar.
