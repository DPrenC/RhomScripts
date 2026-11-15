# Biblioteca de ventanas nativas de RhomScripts

Estado: configurador implementado; listas y comunicaciones permanecen propuestas. Navegación horizontal confirmada por el usuario. Fecha: 7 de noviembre de 2026. Permanecen pendientes las reglas de Responder y la elección de algunos recursos sonoros. Esta ficha sustituye la idea de una ventana distinta por cada servicio por composición de componentes comunes. No da por probadas las variantes nuevas por haber pasado la demostración mínima de wxLua.

## 1. Objetivo y alcance

Presentar comunicaciones, historiales y configuración mediante controles nativos de wxLua. Arriba/Abajo recorren filas o nodos visibles; en el modo de ajuste del configurador modifican el valor seleccionado. Derecha/Izquierda recorren acciones o entran/salen del ajuste; Escape cierra desde cualquier posición. Tab tiene un recorrido específico por tipo de ventana. No se añaden atajos globales de Mudlet para imitar el foco de los controles.

La DLL instalada ya incluye ListBox, ListCtrl, TreeCtrl y Notebook. Esta biblioteca inicial no necesita recompilarla. El prototipo y sus evidencias siguen en [prueba-wxlua.md](prueba-wxlua.md). Se mantiene el diálogo modal: para volver al juego se oculta la ventana. Desde el 8 de noviembre las ventanas de módulos activos se construyen durante el arranque y permanecen ocultas en memoria; reabrir reutiliza controles y actualiza solo datos distintos. La persistencia de objetos no cambia la modalidad de presentación.

## 2. Componentes mínimos, mediante composición

`ui.lua`: entrada pública de ventanas y componentes. Reúne preparación previa, presentación/ocultación, registro y destrucción por recarga, foco, Escape, árbol reutilizable, perfil sonoro y operaciones Win32 (`ui.nativo`). Conserva validaciones de ventana y asociación durante el uso. El constructor del árbol recibe nombre accesible y raíz del dominio; no contiene textos fijos del configurador.

`arranque.lua`: carga wxLua y cffi, declara las funciones Win32 y comprueba ABI Windows x64 antes del arranque. Conserva las instancias nativas entre recargas. También comprueba, instala si falta y espera la inicialización local del paquete oficial. Las cargas nativas son obligatorias incluso sin abrir ventanas.

El árbol se construye con `ui.arbol(wx, padre, sonido, nombre, raiz)`; los sonidos del configurador se solicitan con `ui.sonido_configurador(evento)`. Ambos usan el mismo módulo de ventanas. Lista, grupos de Notebook y barra de acciones permanecen pendientes; se incorporarán en este archivo cuando se implementen, sin crear ahora componentes vacíos.

Los adaptadores permanecen junto a cada dominio: comunicaciones, eventos, estados y configurador. Proporcionan datos, operaciones y actualizaciones. No se crea una clase por cada canal, tipo de mensaje o sonido, ni un bus global de eventos, ni un lenguaje declarativo de formularios. Un constructor recibe parámetros y devuelve una instancia con operaciones de mostrar, actualizar y cerrar; sus nombres y firmas definitivos se fijarán al implementar, no son APIs disponibles ahora.

No se envolverá cada control de wxLua en una clase nueva. Lista y Árbol son componentes de RhomScripts porque incorporan selección, acciones, navegación, accesibilidad y sonido comunes.

## 3. Contrato de datos y acciones

Cada grupo tiene un identificador estable y un título. Cada elemento tiene un identificador estable, texto de presentación y los datos de dominio necesarios para sus acciones. El adaptador conserva la relación con el mensaje u opción original; el texto visible no se utiliza para deducir identificadores, autor o destino.

La ventana recibe grupos, proveedor de elementos, acciones del elemento seleccionado, perfil sonoro y callbacks del dominio. El dominio conserva la autoridad de los datos. La vista mantiene una representación y el foco, no una segunda configuración o historial independiente.

Las acciones son objetos de datos pequeños: identificador, etiqueta, disponibilidad y función que actúa sobre el identificador del elemento seleccionado. El control valida de nuevo ese identificador al activar una acción; un mensaje retirado no debe hacer que una acción pendiente se aplique a otro mensaje que ahora ocupe la misma posición.

La barra Copiar/Responder contiene dos botones reales compartidos por la selección. Se muestran asociados a la fila actual y sus nombres accesibles proporcionan contexto. Cambiar de fila actualiza sus destinos. No se crean dos botones por cada mensaje ni se simulan botones dibujando palabras en columnas de ListCtrl.

Los mensajes entrantes actualizan el proveedor y notifican a la ventana mediante una llamada directa mientras esté abierta. Se conserva la selección por identificador, además de su posición dentro de cada grupo. Las inserciones no roban el foco ni siguen automáticamente al último mensaje. Si se elimina el seleccionado por retención, se elige el vecino disponible y se informa del cambio. Se conserva el orden cronológico de presentación actual; cambiar ese orden no forma parte de este diseño.

Los límites de retención siguen perteneciendo al dominio. «Todos los canales» referencia los mismos mensajes de los canales, ordenados por una secuencia de llegada; no vuelve a capturarlos ni mezcla room o telepatía. Los textos pueden copiarse sin depender de las columnas o del ancho visual.

## 4. Teclado común

Al abrir, el foco está en la lista o el árbol. Al cambiar de grupo se conserva su selección y vuelve el foco a su contenido.

Arriba/Abajo recorren elementos, también cuando se esté sobre una acción de fila. Decisión confirmada por el usuario: se conserva la misma acción horizontal. Si el foco está en Responder y se baja una fila, continúa en Responder, ahora sobre el nuevo mensaje; no vuelve al texto. Se conserva la acción por identificador, no por una posición que pueda corresponder a otra operación. La operación consulta el mensaje seleccionado actualizado al activarse. Si no puede realizarse para ese mensaje, se informa del motivo y no se sustituye por otra acción ni por el último remitente global. Los extremos no ejecutan nada y conservan fila y acción.

En listas con acciones, Derecha pasa del texto a Copiar y después a Responder; Izquierda recorre el camino inverso. En los extremos se permanece y se solicita el aviso de límite definido. Enter o Espacio sobre una acción la activa. Navegar nunca ejecuta una acción. Enter sobre el texto no responde ni copia implícitamente.

Copiar/Responder quedan fuera del recorrido ordinario de Tab, pero pueden recibir foco programático con las flechas. Room y telepatía tienen una sola lista y no incorporan controles adicionales en Tab. Tab y Mayús+Tab no cambian allí a los botones de fila. Escape cierra, sin botones de Aceptar, Cancelar o Cerrar añadidos al contenido; la X nativa, si está presente, sigue la misma ruta de cierre.

En canales, Tab cambia al siguiente grupo y Mayús+Tab al anterior, de forma circular. El recorrido solo contiene los grupos: Todos los canales, Chat, Bando y los demás disponibles. No incluye las acciones de fila ni obliga a pasar por la cabecera de pestañas. Cambiar una pestaña con ratón utiliza la misma operación.

En el configurador, Tab recorre Árbol, Guardar y Cancelar; Mayús+Tab realiza el recorrido inverso. Enter sobre Guardar guarda y aplica; sobre Cancelar descarta y cierra. Escape equivale a Cancelar desde cualquier nodo, valor o botón. No existe una fila «Guardar cambios» en el árbol.

Solo se interceptan las teclas necesarias dentro de la ventana correspondiente. Los atajos del sistema, como Alt+Tab, no se capturan. Las teclas no manejadas continúan por la ruta nativa. Up/Down se dejan a la lista o árbol cuando ya tienen foco y no hay un ajuste activo; se traducen a movimiento de fila cuando el foco está en la barra de acciones.

## 5. Composición por caso de uso

Room: una instancia Ventana con Lista, grupo room, acciones Copiar/Responder y perfil comunicaciones. Sin controles adicionales en Tab; Escape sale.

Telepatía: la misma composición, grupo telepatía, manteniendo remitente y destino de cada mensaje. No debe responder al último remitente global cuando se ha elegido un mensaje antiguo.

Canales: una Ventana con Lista de varios grupos y barra Copiar/Responder, perfil comunicaciones. Tab cambia de lista y cada una conserva su selección. Las llegadas a un canal no activan otra página ni cambian lo seleccionado en «Todos».

Eventos y estados: una Ventana con Lista, un grupo y acción Copiar, perfil historiales. Sin botones de aceptación o cancelación añadidos. El comportamiento opcional de Enter para volver al origen del mensaje queda expresamente diferido, tal como indicó el usuario. Necesita distinguir la entrada de órdenes de la salida textual de Mudlet y conservar una referencia válida al buffer, no buscar una frase posiblemente repetida.

Configurador: Ventana con Árbol y botones Guardar/Cancelar, perfil configurador. Las ramas usan Derecha para desplegar e Izquierda para plegar. Corrección posterior confirmada por el usuario: en las hojas, Derecha entra en un modo de ajuste e Izquierda sale conservando la misma opción seleccionada. Mientras se ajusta, Arriba aumenta y Abajo disminuye los números; en booleanos, ambas flechas alternan de forma circular; fuera del ajuste recorren filas. Cambiar de selección o perder el foco termina el ajuste sin descartar el borrador. Los pasos y rangos proceden de las definiciones actuales, incluido cero como predeterminado cuando corresponda. Al alcanzar un extremo numérico solo se reproduce Botón. Intentar sobrepasarlo reproduce Límite sin modificar el valor. Durante el ajuste se lee únicamente el número (Activado/Desactivado para booleanos), sin nombre, unidad ni la palabra «límite». El nodo nativo comunica los cambios; no se duplican con announce ni con una etiqueta de estado adicional. Si un límite numérico impide el cambio, announce comunica el valor una sola vez. La etiqueta del nodo también muestra solo ese valor hasta salir del ajuste.

Restablecer predeterminados, ya existente, debe conservar su confirmación. Puede representarse como nodo de acción con confirmación dentro del diálogo; no se añade otro botón al recorrido de Tab. Escape debe cerrar toda la edición, no limitarse a retroceder un nivel.

## 6. Configuración: edición y cierre

Para que Escape cierre siempre, cancelar no debe depender de que una lectura del JSON tenga éxito. Se propone una sesión de edición con un borrador de cambios gestionado por el configurador, no por los controles. Las vistas consultan ese borrador; el estado confirmado de configuración no cambia por recorrer o editar controles.

Guardar valida el borrador y conserva el orden actual: escritura JSON antes de aplicar acciones oficiales. Un fallo de escritura mantiene la ventana abierta y el borrador para reintentar, sin aplicar componentes oficiales. Si falla la aplicación después de escribir, debe indicarse claramente que las preferencias ya están guardadas y permitir reintentar. Cancelar después de ese punto no puede prometer deshacer el archivo guardado ni efectos oficiales ya ejecutados.

Escape/Cancelar descartan únicamente la edición no guardada y cierran sin I/O de restauración. Este es un cambio intencional respecto al configurador actual, que recarga el JSON al salir y permanece abierto si falla la lectura. Responde al nuevo requisito de Escape siempre sale. No se amplía aquí la política de recarga de archivos externos durante una edición.

## 7. Sonidos y lector

Los eventos comunes son abrir, cerrar, mover fila, cambiar lista, mover acción, cambiar valor, desplegar, plegar, copiar, guardar y error. La UI solicita cada sonido una sola vez después de una transición real. Un repintado, una actualización programática o la llegada de mensajes no genera sonido de navegación. Los límites son un evento específico, no un movimiento ficticio.

Comunicaciones comparte sonidos de apertura, cierre y navegación para room, telepatía y canales. El panel usa `ui.abrir_com`, `ui.cerrar_com`, `ui.clic_1` y `ui.seleccion_canal`. El configurador usa `ui.abrir_config` y `ui.cerrar_config`. Las claves `ui.abrir_historial` y `ui.cerrar_historial` quedan disponibles para otros historiales.

El perfil configurador incluye además desplegar, plegar y cambio de valor, con las claves existentes correspondientes. Guardar y Cancelar producen un único aviso terminal; no se añade otro sonido de cierre a una confirmación que ya cumpla esa función. Los sonidos de recepción de mensajes o combate siguen en su dominio, independientes de que la ventana esté abierta.

Durante la migración se asignará un solo propietario a cada aviso: los sonidos de interacción que pasen a UI se retirarán de las rutas equivalentes del configurador o las listas. Copiar también deberá conservar un único aviso. Los sonidos no se implementan en la DLL.

Los controles nativos conservan nombres, papeles, estado y foco accesibles. La lectura automática del lector no se reemplaza por otro motor de voz. Se conserva `announce(texto)` estándar cuando se necesiten mensajes de aplicación; no se diseñan colas ni interrupciones. Debe comprobarse que la lectura existente no duplique innecesariamente lo anunciado por el control nativo.

## 8. Adaptaciones necesarias en el código actual

`comunicaciones.lua` conserva cadenas y el último remitente de telepatía por separado. Los registros nuevos deben conservar autor/canal/destino desde la captura original. La actual función `responder(texto)` responde al último remitente y no puede conectarse sin cambios a un mensaje antiguo. Las reglas de respuesta de room, canales y mensajes sin autor fiable, y si se prepara la entrada o se abre un editor, quedan por definir antes de implementar Responder. La acción no debe adivinar un destinatario ni enviar un mensaje vacío.

`listas.lua` mantiene una única lista activa y cambia esa lista al agregar datos de otro tipo. Las nuevas páginas no deben utilizar esa variable como selección compartida. El adaptador deberá proporcionar grupos independientes y conservar sus identificadores; no es necesario reescribir los demás consumidores de listas en la primera entrega.

Los historiales de eventos, estados y líneas son texto sin referencias estables al buffer. Los estados de personajes están en `combate.lua`; `stats.lua` conserva además un historial diferente de cambios de vida. Hay que identificar sus proveedores, sin deducirlos solo del nombre del archivo.

`configurador.lua` mezcla actualmente navegación, anuncios, sonidos, edición y la fila Guardar. Su adaptación debe exponer operaciones de dominio, no simular pulsaciones para llegar a esa fila desde el nuevo botón. La persistencia sigue en `configuracion.lua`. La vista Geyser anterior no debe permanecer activa en paralelo ni añadir atajos globales mientras la ventana wx gestiona el foco.

## 9. Contratos nativos verificados y límites

Se consultaron los bindings incluidos en la compilación wxLua commit `d80dddbd78a1f93ea5f40e163f6d246da28a65ed` y wxWidgets 3.2.8. `wxWindow:DisableFocusFromKeyboard()` no devuelve valor y está expuesto para wxWidgets desde 3.1.5; retira el control de la navegación ordinaria, sin impedir `SetFocus()`, que tampoco devuelve valor. Permite acciones reales fuera de Tab. No se debe usar una desactivación total del foco para ese fin. [Bindings de ventanas](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_windows.i), [implementación de foco](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/include/wx/window.h).

`wxEVT_CHAR_HOOK` permite tratar las excepciones de teclado antes del manejo ordinario. `GetKeyCode()` y `GetModifiers()` devuelven enteros; `event:Skip(true)` continúa el manejo nativo y omitir Skip consume el evento. `DoAllowNextEvent()` no está expuesto en este binding y no debe llamarse. [Bindings de eventos](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_event.i), [contrato nativo](https://github.com/wxWidgets/wxWidgets/blob/v3.2.8/interface/wx/event.h).

`wxListBox` ofrece filas nativas y selección con índices desde cero. `wxTreeCtrl` ofrece nodos; `Expand`, `Collapse`, `SelectItem` y `EnsureVisible` no devuelven valor e `IsExpanded` devuelve booleano. `wxNotebook:ChangeSelection(size_t)` devuelve el índice anterior y permite coordinar el cambio de página desde el controlador. Tab no cambia de página por defecto: ese recorrido es comportamiento propio de esta biblioteca. No aparece `wxSimplebook` en los bindings examinados. [Controles y árbol](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_controls.i), [Notebook](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_windows.i). Los constructores devuelven sus objetos; no consta mínima individual adicional para estos métodos en el binding consultado.

La disponibilidad de estas APIs no demuestra todavía accesibilidad ni funcionamiento de la combinación propuesta. La prueba mínima validó diálogo/lista/botones y heartbeat; faltan las rutas horizontales, exclusión de acciones de Tab, cambio de grupos, árbol, edición y datos entrantes. Los nuevos ensayos deben realizarse en Mudlet real, perfil aislado y desconectado.

## 10. Orden de implementación y aceptación

Primero Ventana + Lista + barra de acciones + perfil sonoro, con proveedor de prueba y sin órdenes de juego. Validar foco inicial, cuatro flechas, Escape, Tab vacío en una lista y botones accesibles por flechas, sin ejecuciones ni sonidos duplicados.

Después varias listas y proveedor de comunicaciones, preservando selección por ID cuando llegan mensajes. Verificar Tab/Mayús+Tab, acciones sobre mensajes antiguos, actualizaciones de «Todos», retención y retirada de listeners al cerrar. Responder no se activa sin definir sus reglas de destino y composición.

Después adaptar eventos/estados con la misma Lista y Copiar. El salto al buffer sigue diferido.

Por último Árbol/configurador, con borrador, Guardar y Cancelar, retirada de la fila Guardar, navegación horizontal de valores, confirmación de restablecimiento y pruebas de errores de escritura/aplicación. Mantener pruebas de recarga y propagación de APIs ausentes. El usuario autorizó después implementar primero este configurador y retirar el panel Geyser. No se conectó al juego ni se implementaron las demás variantes.

## 11. Configurador implementado

Desde el 8 de noviembre, el constructor común consulta la preferencia confirmada `ventanasflotantes` (booleano, predeterminado true, categoría interfaz). El árbol añade «Interfaz → Ventanas flotantes». Activada asocia las nuevas ventanas a la raíz Qt de esta instancia mediante cffi; desactivada crea diálogos sin propietario implícito, usando `wxDIALOG_NO_PARENT`, sin efectuar asociación nativa; cffi ya se prepara en el arranque. No se modifica la asociación de ventanas ya abiertas ni se toman valores del borrador. La migración de configuraciones 1/2 antiguas conserva sus valores y añade true solo si falta el campo nuevo.

Revisión de eficiencia: el ajuste tramita las flechas antes de consultar la selección wx, las definiciones se buscan por ID y el árbol conserva las etiquetas escritas para omitir actualizaciones idénticas. Los mensajes de estado solo recalculan el diseño si cambian; la salida anuncia sin redibujar un diálogo que ya se cierra. Los errores de escritura tienen un único propietario del anuncio, en persistencia. La fase `cerrando` impide acciones y reaperturas durante la destrucción y el procesamiento de eventos; los campos se limpian incluso si esa destrucción falla, sin silenciar el error. Son reducciones de trabajo comprobadas por flujo y pruebas, sin una cifra de mejora de tiempo medida.

Revisión de mensajes: al entrar en cualquier ajuste se anuncia únicamente «Ajustando valor» y suena Desplegar. Al salir suena Plegar y se restaura la etiqueta completa del nodo, sin anuncio redundante. El cierre por Guardar o Cancelar conserva un solo sonido terminal. Se abrevian confirmación, cancelación, errores y ayuda; se conserva la distinción entre error al guardar y preferencias guardadas con fallo de aplicación.

`ui.lua` proporciona ciclo de vida, árbol con identificadores estables y perfil sonoro. `configurador.lua` integra el borrador de edición y conecta estos componentes; `nueva_sesion()` permite crear una sesión sin abrir la ventana. `configuracion.guardar_valores()` valida y escribe antes de publicar los valores confirmados. No se han construido todavía Lista ni la barra de acciones.

La ventana se titula «RhomScripts. Configuración.». El árbol contiene Volúmenes, Interfaz, Paquete oficial RLMud_Config y Restablecer valores predeterminados. Esta última rama permite confirmar con No o Sí y Enter. Derecha entra en el ajuste de una hoja; arriba/abajo modifican el valor e izquierda sale del ajuste. La fila Guardar desaparece: Guardar y Cancelar son botones nativos. Solo queda Ctrl+Shift+C como atajo de apertura; no se registran flechas globales para este diálogo.

Los sonidos del configurador usan Abrir config.wav, Cerrar config.wav y Clic 1.wav. Los cambios booleanos reproducen Interruptor y los numéricos Botón, también al alcanzar los extremos. Intentar sobrepasar un extremo produce solo Límite. Ramas, error y aceptación reutilizan recursos existentes. El catálogo reindexado contiene 29 claves y cubre los 28 WAV existentes. Ningún WAV se ha renombrado ni regenerado.

Se han retirado `interfaz.lua`, el alias `rhompanel` y las llamadas de las listas al panel. La recarga destruye una instancia antigua si aún existía y limpia su caché. Las listas conservan sus atajos y acciones anteriores, sin panel visual.

El ensayo específico se ejecuta con `.\.tools\venv\Scripts\python.exe scripts/run_wxlua_probe.py --configurador`. Comprueba controles wx reales, foco, árbol, borrador, confirmación, escritura, aplicación fallida, reintento, audio, cierre y recarga. Los cambios de foco se solicitan a los controles reales: esto no demuestra recepción física de Tab o flechas ni lectura con el lector externo. La aplicación oficial está instrumentada en este ensayo; sus efectos se verifican en la integración general. Véase [validación](../validacion.md).

La ventana tiene un bucle modal wx y teclado propio. No se afirma que deshabilite todas las ventanas Qt de Mudlet al cambiar de aplicación. El uso simultáneo entre perfiles sigue pendiente.

## 10. Política común de preparación y reutilización, 8 de noviembre de 2026

La carga prepara las ventanas de todos los dominios activos antes de ready, mediante `ui.preparar()` y el `preparar()` idempotente de cada dominio. Cada constructor crea controles y enlaza manejadores una sola vez. El registro de UI permite retirar también ventanas ocultas al recargar. No se mantienen suscripciones o temporizadores de actualización periódica por el mero hecho de ocultarlas.

El configurador prepara etiquetas desde preferencias confirmadas sin crear sesión de edición. Al mostrar crea un borrador nuevo, compara las etiquetas con el árbol existente y conserva todos los objetos; las etiquetas idénticas no llaman a SetItemText. Guardar/Cancelar/X/Escape terminan y ocultan el diálogo, descartando el borrador y el ajuste activo. Mantiene el comportamiento de volver al grupo Volúmenes al abrir. Listas, canales e historiales siguen pendientes; su implementación deberá conservar controles e identidades y aplicar cambios incrementales de datos, sin reconstrucción al mostrar.

La posición se calcula una vez al preparar. Una preferencia confirmada de ventanas flotantes diferente se aplica al mostrar la ventana existente, sin reconstruirla ni cambiarla durante la edición. CallAfter usa una generación por apertura para que un callback atrasado no enfoque una sesión posterior.

Destruir es una operación de recarga/limpieza, separada de cerrar. No se permite destruir mientras ShowModal sigue en la pila. Si se solicita recarga con una ventana abierta, se cancela su edición y se programa la continuación mediante un temporizador identificado; se vuelve a comprobar el estado antes de retirar los objetos. Las DLL se conservan. La limpieza intenta retirar los recursos independientes aunque una retirada falle, y propaga el error con contexto.
