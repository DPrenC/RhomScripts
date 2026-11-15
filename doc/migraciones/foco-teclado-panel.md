# Foco y teclado del panel: requisito y limitación verificada

## Requisito del usuario

Al abrir el configurador, el foco de teclado debe pasar a su lista. Las cuatro flechas deben controlar el configurador mientras el foco permanezca dentro de él. Tab y Mayús+Tab deben recorrer sus acciones, incluidos aceptar/guardar y cancelar, y permitir salir a la entrada y al texto de Mudlet sin cerrar el configurador. Al salir, las flechas deben recuperar el comportamiento de esas ventanas; al volver al panel, deben volver a manejar el configurador. No equivale a mantener globalmente capturadas las teclas mientras el menú esté abierto.

## Estado y alcance de la investigación

Consulta del 7 de noviembre de 2026. La [última release estable oficial](https://github.com/Mudlet/Mudlet/releases/latest) dirige a [Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/releases/tag/Mudlet-5.1.1). Se contrastaron los archivos de Geyser instalados en esa versión, las copias de documentación de `doc/mudlet/` y el fuente oficial del tag estable. No se modificó Mudlet instalado ni código funcional del proyecto durante esta investigación.

La implementación de RhomScripts conecta las operaciones de navegación y la representación visual, pero no implementa un contexto de teclado ligado al foco real del panel. La evidencia previa de callbacks reales no demuestra que una pulsación física llegue a ellos.

## Causa de arriba y abajo

En [TCommandLine.cpp, función event](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TCommandLine.cpp#L252), los casos `Qt::Key_Down` y `Qt::Key_Up` sin modificadores llaman directamente a `historyMove`, aceptan el evento y retornan antes de llamar a `keybindingMatched`: líneas 510–574. Control+arriba/abajo también se procesa de forma especial. Enter, Escape y Tab sin modificadores tienen igualmente procesamiento propio. Registrar un `tempKey` para una de estas teclas no garantiza interceptarla en la entrada.

La revisión del inicio de `event` y `claimsShortcutOverride` no encontró una opción de configuración para dar prioridad a todos los atajos. `ShortcutOverride` solo reclama el atajo de modo cursor y coincidencias de atajos de cambio de perfil; el tratamiento anticipado del teclado numérico solo se aplica cuando viene `KeypadModifier`. No son un interruptor para capturar las flechas normales del panel.

## Teclado nativo de etiquetas

En [TLabel.cpp](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLabel.cpp#L169), `keyboardOperable()` requiere las etiquetas accesibles activadas y que el modelo actúe como botón. `updateKeyboardAccess()` concede foco mediante Tab a esos botones. En `keyPressEvent`, líneas 250–282, Espacio y Enter ejecutan la pulsación nativa del botón; las otras teclas, incluidas las flechas, pasan al comportamiento de QLabel. No se invoca un callback Lua de teclado.

`focusInEvent` y `focusOutEvent`, líneas 301–321, actualizan el widget y el estado interno de navegación, pero no emiten un evento Lua de entrada/salida de foco de esa etiqueta.

La navegación nativa de los botones con etiquetas accesibles usa [TMainConsole::keyboardButtons, focusButtonAfter y leaveKeyboardButtons](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TMainConsole.cpp#L1581). Ordena botones por posición y puede volver a la entrada o al modo cursor. Ese comportamiento explica que Tab permita alcanzar botones, pero no proporciona a Lua una notificación que conecte el foco actual con la selección de RhomScripts. Los botones de una ventana flotante no forman parte de la cadena de Tab de la ventana principal.

## APIs comprobadas

`tempKey([modifier], keyCode, luaCode)` crea un atajo y devuelve un identificador numérico que se retira con `killKey(id)`. La sección consultada no establece versión mínima individual. El contrato no dice que actúe como filtro de eventos de cualquier widget ni que pueda reclamar teclas ya consumidas por la entrada. [Manual oficial](https://wiki.mudlet.org/w/Manual:Lua_Functions#tempKey); copia local: [Lua_Functions.txt](../mudlet/Lua_Functions.txt), sección `tempKey`.

`hasFocus()` no acepta un nombre de control y devuelve un booleano sobre el foco de Mudlet/perfil. No permite saber si está enfocada la lista, un botón, la entrada o el texto. La sección consultada no indica versión mínima. [Manual oficial](https://wiki.mudlet.org/w/Manual:Lua_Functions#hasFocus); copia local: [Lua_Functions.txt](../mudlet/Lua_Functions.txt), sección `hasFocus`; [implementación del tag estable](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLuaInterpreterUI.cpp#L2147).

`sysProfileFocusChangeEvent` informa del cambio de perfil, no del movimiento entre controles de un mismo perfil. No resuelve este requisito. [Motor oficial de eventos](https://wiki.mudlet.org/w/Manual:Event_Engine#sysProfileFocusChangeEvent); copia local: [Event_Engine.txt](../mudlet/Event_Engine.txt).

`setTextEditTabMovesFocus(name, state)` controla si Tab cambia de control o inserta un tabulador en un editor de texto creado mediante `createTextEdit`; está documentada desde 4.21. No asigna foco a una etiqueta ni añade un callback de flechas. La implementación devuelve `true` si aplica el cambio y `nil, motivo` si no encuentra el editor. [Manual oficial](https://wiki.mudlet.org/w/Manual:Lua_Functions#setTextEditTabMovesFocus); copia local: [Lua_Functions.txt](../mudlet/Lua_Functions.txt); [fuente estable](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLuaInterpreterUI.cpp#L973).

`openUserWindow(name[, loadLayout[, autoDock[, area]]])` abre y muestra una ventana, devuelve `true` o `nil, motivo`, y organiza su acoplamiento. `raiseWindow(name)` devuelve un booleano y sube el elemento en el orden de apilado. `showWindow(name)` devuelve un booleano y muestra el elemento. La sección consultada no fija mínima individual para estos contratos. No se encontró asignación explícita de foco a la lista o a una etiqueta en estas rutas: [openUserWindow y placeUserWindow](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TMainConsole.cpp#L641), [raiseWindow](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TMainConsole.cpp#L3263), [showWindow](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TMainConsole.cpp#L3342). No deben presentarse como funciones de enfoque.

## API ausente en el tag comprobado

Se revisó el registro Lua en [TLuaInterpreter.cpp](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLuaInterpreter.cpp#L6860), sus implementaciones UI y `GeyserLabel.lua` de la instalación 5.1.1. No están registradas `setLabelFocus`, `setLabelKeyCallback`, `setLabelFocusCallback` ni una API genérica `setFocus`/`getFocusedWidget`. Los métodos equivalentes de Geyser.Label tampoco están definidos. Esta conclusión se limita al tag estable comprobado, no afirma que no puedan añadirse en futuras versiones.

No se debe inventar ninguna de estas funciones, simularla con stubs ni proteger su ausencia con una alternativa silenciosa. Los callbacks de entrar/salir del ratón no son eventos de foco de teclado.

## Consecuencia y decisión pendiente

Con el contrato público Lua/Geyser verificado en 5.1.1 no se ha encontrado una forma de completar el requisito exacto: asignar el foco inicial a la lista, recibir flechas en sus etiquetas y cambiar el contexto al atravesar Tab hacia la entrada o el texto. Falta un enlace nativo entre foco/eventos de teclado y Lua, o un componente nativo de lista que lo proporcione.

Añadir ese enlace al cliente, emplear un componente externo o cambiar los atajos/interacción son alcances diferentes. Esta ficha no autoriza modificar Mudlet instalado, usar ganchos globales del sistema ni sustituir las flechas solicitadas por atajos alternativos. La decisión debe presentarse al usuario con la limitación concreta.

Una ampliación nativa mínima debería permitir enfocar programáticamente un control concreto, informar a Lua de su entrada y salida de foco y entregar sus pulsaciones con un resultado explícito de consumir o propagar. Tab y Mayús+Tab deben continuar por la cadena nativa, sin quedar atrapados; los cambios entre controles del propio panel deben conservar su contexto, mientras que la salida hacia entrada/texto debe retirarlo. Es un contrato conceptual que requeriría diseño, implementación y pruebas en Mudlet; no son APIs ya disponibles ni nombres que RhomScripts deba llamar ahora.

Los 65 casos previos en Mudlet y los 77 por runtime local certificaban callbacks, estado y representación; no certificaban captura física de arriba/abajo ni transferencia de foco con Tab. El informe del usuario demuestra que esa parte del comportamiento quedó sin satisfacer.

## Análisis de controles clásicos dentro del panel

Ampliación del análisis solicitada el 7 de noviembre de 2026, sin cambios funcionales. La idea de utilizar una lista real es adecuada: al recibir foco mediante Tab, una vista de elementos procesa sus flechas y conserva una selección propia; al salir del control, las teclas se entregan al siguiente control enfocado. No necesita una captura global de flechas. Qt proporciona este comportamiento en sus vistas de elementos, con propiedades para configurar la navegación por Tab y el modo de selección: [QAbstractItemView](https://doc.qt.io/qt-6/qabstractitemview.html), [QListView](https://doc.qt.io/qt-6/qlistview.html). La integración con el estado de RhomScripts seguiría necesitando notificación del cambio de selección y retirada de los atajos globales que interfieran.

Mudlet utiliza Qt. Un control Qt estándar no es necesariamente un control Win32 de clase `EDIT` o `SysListView32`; puede proporcionar el papel accesible y el comportamiento de teclado esperados sin emplear esas clases de Windows. La elección más coherente para una ampliación del cliente sería una lista Qt integrada, no mezclar arbitrariamente ventanas Win32 con la jerarquía de Geyser.

Cuadros de edición: sí están expuestos. `createTextEdit([parentWindow,] name, x, y, width, height)` crea un editor multilínea dentro de una ventana o ScrollBox; está documentado desde 4.21 y devuelve `true` o `nil, motivo`. `Geyser.TextEdit:new(cons, parent)` organiza su creación. El objeto interno es `TTextBox`, derivado de `QPlainTextEdit`: [TTextBox.h del tag estable](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TTextBox.h), [API oficial](https://wiki.mudlet.org/w/Manual:UI_Functions#createTextEdit), copia [Lua_Functions.txt](../mudlet/Lua_Functions.txt). `setTextEditTabMovesFocus(name, true)` permite salir mediante Tab. Un editor de solo lectura sigue siendo un editor: moverse entre sus líneas no produce un índice de elemento ni una selección de lista comunicable a Lua mediante esta API.

Botones del panel: `Geyser.Button` hereda de `Geyser.Label`, no crea un `QPushButton` independiente. Los botones accesibles del panel actual son etiquetas con activación nativa por Enter/Espacio cuando las etiquetas accesibles están habilitadas. Las APIs `tempButton` y `tempButtonToolbar` gestionan botones de barras de herramientas; no constituyen una API de creación de botones arbitrarios dentro del contenedor del panel. [GeyserButton.lua estable](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/mudlet-lua/lua/geyser/GeyserButton.lua), [TLabel.cpp estable](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLabel.cpp), [manual tempButton](https://wiki.mudlet.org/w/Manual:Lua_Functions#tempButton).

Listas, presentaciones con columnas, árboles y desplegables: no se encontró API pública de Lua/Geyser para crear `QListView`, `QListWidget`, `QTreeWidget`, `QTableWidget` o `QComboBox` en el tag 5.1.1. Se contrastó el catálogo de funciones registrado en [TLuaInterpreter.cpp](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLuaInterpreter.cpp) y las clases de Geyser instaladas. Dar aspecto de lista a un grupo de etiquetas, o asignar un papel accesible de botón, no las transforma en un control de selección de elementos.

Carga de interfaces Qt: aunque el cliente incluye `QUiLoader`, su uso en [TMainConsole.cpp](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TMainConsole.cpp) corresponde a diálogos internos de Mudlet. No se encontró una función pública Lua para cargar un archivo `.ui` con controles arbitrarios y conectar sus señales. La presencia de DLL de Qt no proporciona por sí sola un enlace Lua a sus clases.

Controles Win32 directos: no se encontró un puente público de Mudlet a `CreateWindowEx`, al identificador nativo del padre y a sus notificaciones de selección. La instalación comprobada incluye `lua51.dll` y no un binding Lua de Qt, Win32 o FFI que proporcione esa integración. `libffi-8.dll` presente en la instalación no equivale a un módulo `ffi` de Lua. `package.loadlib` carga funciones que siguen el protocolo de llamada de Lua; no convierte automáticamente una función arbitraria de Windows en una función Lua: [manual Lua 5.1](https://www.lua.org/manual/5.1/manual.html#pdf-package.loadlib).

Conclusión bajo las restricciones actuales: es posible incorporar editores de texto reales y los botones accesibles ya soportados, pero no la lista estándar solicitada usando exclusivamente Lua sobre Mudlet 5.1.1 sin componentes nativos adicionales. Exponer un componente de lista Qt y sus cambios de selección sería una ampliación nativa más específica que crear un sistema general de captura de teclado; con ella la navegación Tab/flechas podría apoyarse en Qt. No se ha implementado ni probado esa ampliación y no se modifica el cliente instalado. Este análisis se basa en documentación, fuente estable e inspección de la instalación, sin una nueva prueba interactiva de controles en esta revisión.
