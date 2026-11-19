# Manual de usuario de RhomScripts

La [navegación común de ventanas](componentes-interfaz.md) describe árboles, listas, pestañas y acciones de los elementos.

La [lista de destinos del mapa](mapa.md) permite consultar los resultados de `irsala` y `sigilarsala` en una ventana nativa, activable desde Interfaz.

## Estado

Documentación inicial. El paquete público separado y sus actualizadores están diseñados y pendientes de implementación. No existe todavía aquí un manual de instalación de esa distribución.

El arranque carga `debug`, `configuracion`, `configurador`, `ficha`, `lector`, `comunicaciones`, `mapa` y `keys`. El [diagnóstico centralizado](debug.md) reúne estados, mensajes e inventarios. Los [historiales de comunicaciones](comunicaciones.md) reciben los canales oficiales mediante GMCP y capturan Room y telepatía mediante dos triggers propios. El [lector de líneas](lector.md) permite leer y copiar con Ctrl+1…9 y Ctrl+Shift+1…9, además de los comandos `leerlinea N` y `copiarlinea N`. Ctrl+Shift+C abre el configurador, Ctrl+Shift+H alterna la ayuda y `rhomscripts keys` enumera sus pulsaciones. Los comandos y triggers de los módulos pendientes siguen desconectados, incluidas las demostraciones `pruebawx` y `pruebacffi`. Sus archivos se conservan en la carpeta raíz `rhomscripts old` para futuras migraciones.

Audio, interfaz nativa, integración oficial y registro de comandos son dependencias internas. `RhomScripts.modules` contiene los ocho sistemas activos, incluido debug. `RhomScripts.soporte` conserva arranque, audio, UI y registro de comandos para retirarlos al recargar. El paquete oficial sigue funcionando según sus preferencias.

Las preferencias propias del arranque se guardan en `config.json`; el modo debug se comparte directamente con el paquete oficial y utiliza su persistencia. Ya no se carga `config.lua` ni se lee o escribe `rl_config.lua`, ni se inicializa `modes`. Se conservan ese archivo de configuración y sus consumidores pendientes en el fuente; tampoco se elimina ningún archivo personal antiguo del perfil.

## Arranque con el paquete oficial de Reinos

Antes de cargar los módulos, `init.lua` utiliza `arranque.lua` para preparar wxLua y cffi y comprobar que `RLMud_Config` está instalado. Si falta, descarga el ZIP desde `https://mudlet.reinosdeleyenda.es/RLMud_Config.zip` y lo instala en el perfil actual. Una instalación nueva necesita acceso a Internet, pero no se conecta al juego. Un paquete ya instalado no se vuelve a descargar.

El arranque espera la inicialización local del paquete, sin esperar GMCP. Escucha `rlmud_opciones_inicializadas` y deja terminar la pila de eventos oficial antes de continuar; si ya estaba inicializado, comprueba su estado local existente. «Activo» significa opciones locales preparadas, no negociación con el servidor ni descargas de mapa o sonidos completadas. Esas tareas continúan a cargo del paquete oficial.

Con debug desactivado muestra y anuncia únicamente los hitos propios de inicio y carga correcta; los detalles de paquete, esperas y registros se conservan para consulta y se muestran automáticamente con debug activado. Si falla la descarga, la instalación o la inicialización, informa del error y no continúa la carga. La espera máxima es de 60 segundos. Para reintentar después de resolver el problema, usar `rl` con RhomLoader o volver a cargar `init.lua`.

`RhomScripts.loading` identifica una carga pendiente; `RhomScripts.initialized` solo pasa a verdadero al completar los módulos. `RhomScripts.arranque_oficial.estado` distingue pendiente, esperando, activo, error o cancelado. La recarga retira nuestros manejadores y temporizadores anteriores; una descarga antigua no inicia otra carga. Pueden quedar ZIP temporales de intentos interrumpidos en el perfil, con prefijo `rhomscripts-oficial-`.

El inicializador activa la captura de ficha al comenzar, carga la configuración y espera al paquete oficial antes de aplicar preferencias e iniciar los módulos con interfaz. Conserva la misma instancia de configuración para el menú. Las opciones que necesitan GMCP quedan pendientes hasta que llegue la información. Comunicaciones consume los eventos GMCP de canales.

## Consulta de la ficha GMCP

La ficha guarda en memoria los paquetes que Mudlet recibe en `gmcp.Char`. Empieza a recoger datos al cargar los scripts. Una recarga conserva la copia ya recibida. Una conexión nueva, la desconexión, la despedida GMCP o la desactivación del protocolo vacían esa copia.

Desde la entrada de Mudlet se puede consultar la clase con `lua display(RhomScripts.modules.ficha.obtener("clase"))`. También están disponibles `vida_actual` y `vida_maxima`, y se admiten rutas de cualquier campo recibido, como `Stats.fue` o `Ficha.nivel_oficio`. Si un campo todavía no está disponible, la consulta devuelve `nil`. Los scripts pueden leer una copia completa con `RhomScripts.modules.ficha.datos()`. [Plantilla de datos GMCP de Reinos](../gmcp-reinos.md)

Las consultas `nombre`, `clase`, `oficio`, `sexo` y `raza` devuelven los valores de `Char.Ficha`. `sexo` devuelve el código original de `Ficha.genero`.

Alt+1 lee la vida, Alt+2 la energía y los escudos y Alt+0 la experiencia y los puntos de oficio. Con Mayús, esas mismas combinaciones copian y leen los datos con sus prefijos, anuncian «Copiado» y reproducen el sonido de portapapeles. [Atajos de información del personaje](teclado.md#información-del-personaje)

Si llegan por separado la vida actual y la máxima, la ficha conserva el último valor recibido de cada una durante la sesión. Alt+1 dice «sin datos» en la posición de cada valor pendiente. Para los demás bloques, la ficha refleja el contenido que entrega Mudlet. Tras un reinicio de GMCP, ese contenido puede incluir bloques antiguos junto a los recién recibidos. [Diseño y límites de la captura](../planes/ficha-gmcp.md)

## Organización interna

`init.lua` coordina carga, recarga, construcción previa de ventanas y registros. `arranque.lua` concentra la carga de wxLua/cffi, la comprobación de Windows x64 y la preparación asíncrona del paquete oficial. Ambas bibliotecas se cargan obligatoriamente al arrancar; un fallo impide completar el inicio incluso si no se abre ninguna ventana. Las instancias nativas se conservan entre recargas.

`ui.lua` reúne ventanas, árbol reutilizable, navegación, sonidos de interacción, registro de ventanas preparadas y operaciones de Windows en `ui.nativo`. No carga bibliotecas: utiliza las ya preparadas. Valida los identificadores, propietarios y asociaciones al utilizarlos, porque esas condiciones pueden cambiar después del inicio. El árbol recibe del dominio su nombre accesible y el texto raíz.

`configurador.lua` conserva borrador y acciones de edición; `configuracion.lua`, preferencias y persistencia; `audio.lua`, catálogo y reproducción. `arranque.lua` aplica y vigila preferencias y mantiene el [monitor de señales](arranque.md), incluido Guardar y eventos posteriores a la conexión; `debug.lua` almacena el estado único y presenta mensajes e informes. Las listas y otros controles futuros se incorporarán a UI cuando se implementen; no están disponibles todavía.

## Ventanas construidas al arrancar

La política común es construir las ventanas de todos los módulos activos durante la carga, antes de registrar los atajos y anunciar éxito. Se conservan ocultas en memoria con sus controles y manejadores. La preparación no solicita foco ni reproduce sonidos de apertura. No se construyen todavía ventanas de canales o historial: cuando se implementen adoptarán este contrato.

Abrir el configurador reutiliza la ventana, árbol y botones, crea un borrador de las preferencias confirmadas y escribe únicamente las etiquetas que cambian. Cerrar por Guardar, Cancelar, Escape o X oculta la ventana; se descarta la sesión de edición, no los controles. No se reconstruye el árbol ni se registran de nuevo sus eventos. La posición se calcula en la preparación y se conserva al reabrir. La asociación con Mudlet solo se actualiza al mostrar si ha cambiado la preferencia confirmada de ventanas flotantes; guardar no altera la ventana mientras se está editando.

`ui.preparar()` llama a `preparar()` de los módulos activos y finaliza la preparación de sus ventanas. `ui.nueva()` registra cada ventana; `vista:preparar()` termina su disposición oculta; `vista:mostrar()` y `vista:ocultar()` reutilizan el diálogo. Los dominios conservan la actualización de sus datos y acciones; las colecciones futuras deberán aplicar inserciones, cambios y retiradas por identificador sin reconstruir los controles.

`rl` destruye las ventanas anteriores y construye sus reemplazos con el código nuevo, manteniendo las DLL. Si una ventana está en su diálogo modal, primero se cierra y se difiere la recarga hasta que retorne ese diálogo. Un fallo de construcción bloquea el arranque y limpia los recursos parciales; las APIs ausentes siguen produciendo error.

## Preferencias del paquete oficial

Ctrl+Shift+C abre el configurador. Entrar en «Paquete oficial RLMud_Config» permite modificar sus componentes. Todos permanecen seleccionables para pruebas, incluidos los que pueden coincidir con funciones nuestras. Sus valores iniciales respetan los predeterminados oficiales:

- Mostrar interfaz oficial: activado.
- Mostrar panel de canales: activado.
- Mostrar canales en la consola principal: activado. La copia oficial requiere que su interfaz y panel de canales estén visibles.
- Teclado numérico oficial: activado. Puede coincidir con nuestro movimiento.
- Macros oficiales F1 a F12: desactivado. Activarlas requiere ficha del personaje y puede coincidir con nuestras teclas.
- Sonidos y música MSP oficiales: activado. Su parada puede detener también sonidos de RhomScripts.
- Integración con Discord: activado.
- Descargar mapa automáticamente cuando falta: activado. Es la política para las siguientes comprobaciones del paquete; no inicia ni cancela una descarga al guardar.
- Tamaño de letra del panel: predeterminado del paquete. Cero representa ese ajuste dinámico; también se admiten de 8 a 50 puntos.
- Recibir comunicaciones GMCP: activado. Es independiente de mostrar la interfaz.
- Depuración MSP: desactivada. El modo general compartido se configura en Interfaz y conserva el valor oficial; la depuración MSP necesita que ese modo esté activo.

Derecha entra en el ajuste de una opción. Dentro del ajuste, arriba y abajo aumentan o disminuyen los números; en booleanos, ambas flechas alternan entre Activado y Desactivado; izquierda termina el ajuste y conserva la opción seleccionada. La fuente cambia de uno en uno, saltando entre predeterminado y ocho puntos. Modificar o restablecer cambia el borrador y aplica provisionalmente los volúmenes. Escape descarta el borrador y restaura los volúmenes confirmados sin leer el JSON ni ejecutar acciones oficiales.

El botón Guardar escribe primero el JSON y después aplica las diferencias al paquete: guarda su lote de preferencias, actualiza la GUI una sola vez si procede, ajusta las fuentes existentes, cambia los grupos de teclas y ejecuta las acciones MSP necesarias. No reinicia el perfil. La suscripción de comunicaciones usa un usuario propio y se aplica después de la GUI para conservar la elección aunque la interfaz se oculte. Se mantienen las elecciones individuales aunque otra opción las haga temporalmente inefectivas.

Si falla el guardado JSON, no se aplican acciones oficiales. Si el JSON se guarda pero falla una acción, se anuncia «Preferencias guardadas. Error al aplicar…», se conserva la ventana abierta; Guardar permite reintentarlo. No hay restauración automática de acciones ya realizadas. Escape posterior descarta la edición no guardada y cierra, pero no termina una aplicación parcial: se puede reintentar al guardar o recargar con `rl`.

Macros, Discord y comunicaciones indican su espera de conexión o GMCP cuando corresponde. Al recibir los eventos oficiales se reaplica la última elección guardada, sin tomar las ediciones pendientes del menú. La GUI oculta conserva el tamaño de letra elegido para cuando vuelva a mostrarse. Desactivar Discord impide nuevas acciones oficiales y retira su temporizador de actualización; no borra la presencia global que otros paquetes puedan utilizar.

La instalación y la suscripción local no cambian los consentimientos del personaje en el servidor. `configurarficha` ya no envía las órdenes heredadas que desactivaban GMCP, GUI y MSP; tampoco activa esos permisos automáticamente. La recepción real de información del juego depende de su conexión y consentimientos.

## Configurador y preferencias

Ctrl+Shift+C abre la ventana nativa «RhomScripts. Configuración.». El foco inicial está en Volúmenes y todas las ramas empiezan plegadas. Arriba y abajo recorren los nodos visibles. Enter y derecha despliegan una categoría. Izquierda la pliega. Sobre un valor numérico, Enter y derecha abren el ajuste. Sobre un booleano fuera del ajuste, Enter alterna entre Activado y Desactivado directamente en el borrador. Derecha abre el ajuste.

Mientras se ajusta, arriba y abajo aumentan o disminuyen los números. En booleanos, ambas flechas alternan el valor. Enter guarda y aplica todo el borrador y cierra el configurador si el guardado tiene éxito. Izquierda sale del ajuste y conserva la opción seleccionada. Durante el ajuste, la etiqueta muestra solo el valor. Al salir recupera el nombre de la opción. Cambiar de selección con el ratón o pasar con Tab a un botón termina el ajuste y conserva la edición en el borrador.

Tab recorre Árbol, Guardar y Cancelar; Mayús+Tab realiza el recorrido inverso. El botón Guardar escribe y aplica las preferencias, y cierra cuando tiene éxito. Cancelar, Escape y la X cierran descartando la edición pendiente. Tab permanece dentro del diálogo. La asociación no añade un atajo para alternar con el juego. Las flechas de la ventana las atienden sus controles nativos.

En Interfaz se encuentran Ventanas flotantes y [Modo debug compartido](debug.md). La edición utiliza un borrador: cambiar opciones no modifica la configuración confirmada. Cancelar no lee el JSON, de modo que un error de lectura no impide cerrar. Si ya se había guardado el archivo y falló una aplicación oficial, cancelar descarta únicamente los cambios posteriores; no deshace el archivo ni las acciones oficiales ya ejecutadas.

«Restablecer predeterminados» requiere confirmación dentro del diálogo. Restablece el borrador; hay que pulsar Guardar para conservarlo. Escape también sale desde esa confirmación.

Los volúmenes general, de interfaz, de comunicaciones y de combate tienen valor predeterminado 80, y el de ambiente 70. Se ajustan de 5 en 5 entre 0 y 100. El reproductor por clave aplica el borrador desde el sonido de la propia pulsación y a las reproducciones que se soliciten después. Cero omite la reproducción. Cancelar, Escape, cerrar con la X o recargar descartan los ajustes pendientes y recuperan los últimos volúmenes confirmados.

La configuración utiliza `config.json`, formato 2, en la carpeta del perfil de Mudlet. Los archivos válidos de formato 1 se migran conservando sus preferencias y añadiendo las nuevas con su valor predeterminado. En ambos formatos se retira la antigua copia `oficial_depuracion` sin aplicarla: la autoridad y persistencia del modo debug pertenecen al paquete oficial. Los archivos de formato 2 anteriores al volumen de comunicaciones incorporan ese ajuste conservando los valores existentes. Si falta el archivo, se crea. Si su contenido es incorrecto, se anuncia y se sustituye por valores predeterminados. Un error de lectura impide sobrescribir el archivo hasta una carga correcta.

Guardar escribe primero el JSON y después aplica las preferencias oficiales. Si falla la escritura, el borrador y la ventana permanecen disponibles para reintentar sin aplicar acciones oficiales. Si la escritura termina pero falla la aplicación, se informa de que las preferencias ya están guardadas y se permite reintentar; no hay restauración automática de acciones ya realizadas.

La navegación reproduce Clic 1. Al ajustar un booleano suena Botón 2; al modificar un número suena Botón 1. Al alcanzar el mínimo o máximo numérico sigue sonando Botón 1; Límite suena únicamente al intentar sobrepasarlo. Los booleanos son circulares: cada pulsación de arriba o abajo alterna el valor y reproduce Botón 2, sin aviso de límite. Guardar produce un aviso de aceptación; cancelar produce el cierre del configurador, sin un segundo sonido terminal. El nodo nativo comunica los cambios al lector, sin repetirlos mediante announce ni actualizando otra etiqueta de estado. Al intentar sobrepasar un límite numérico, como el nodo no cambia, announce comunica una sola vez su número. Se lee solo el valor, sin nombre, unidad ni la palabra «límite»; para booleanos, solo Activado o Desactivado. Los controles nativos proporcionan su nombre, estado y foco al lector externo, y los errores de aplicación se comunican también en texto.

## Ventanas nativas

En el configurador, «Interfaz → Ventanas flotantes» permite elegir cómo se crean las ventanas. Su valor predeterminado es Activado (`ventanasflotantes = true`): las nuevas ventanas se asocian a Mudlet y se ocultan con él al minimizarlo. Desactivado crea ventanas independientes. La opción se guarda con Guardar; Cancelar descarta su edición. No cambia ventanas ya abiertas: se aplica a las siguientes aperturas, incluido el propio configurador.

Los archivos antiguos de configuración 1 y 2 incorporan automáticamente la opción activada conservando las preferencias existentes; un valor Desactivado ya guardado se respeta. La asociación se gestiona en el constructor común, utilizado también por `pruebawx` y `pruebacffi`. Los botones de esta última prueba permiten cambiar manualmente solo la relación de su propia ventana.

`pruebacffi` abre una prueba con cinco elementos y botones Vincular, Desvincular y Cerrar. Su asociación inicial depende de «Ventanas flotantes»; Desvincular la convierte en independiente y Vincular la asocia a Mudlet. Escape cierra. Permite comparar ambos comportamientos sin guardar preferencias. Requiere las bibliotecas locales de wxLua y cffi-lua para Windows x64, incluidas junto a los scripts; se cargan cuando se utilizan. No incorpora otro intérprete ni necesita recompilar Mudlet.

Al entrar en un ajuste se reproduce Desplegar y se anuncia «Ajustando valor». Al salir se reproduce Plegar y el nodo recupera su nombre completo, sin repetirlo con announce. Tab o cambiar de selección también terminan el ajuste con Plegar. Guardar o Cancelar cierran con un único sonido terminal. Las instrucciones generales permanecen en la ayuda de la ventana, sin recitarlas en cada ajuste.

El configurador utiliza una ventana nativa independiente de wxLua. Las listas clásicas conservan sus datos, navegación y acciones mediante los atajos existentes; ya no abren el panel lateral Geyser.

Al recargar una sesión que todavía tuviera abierto el antiguo panel, se retiran sus controles y manejadores antes de cargar los módulos actuales.

## Prueba nativa de wxLua en Windows

El comando `pruebawx` abre una demostración independiente con «Elemento 1» a «Elemento 5» en una lista estándar de Windows y botones «Aceptar» y «Cancelar». Ambos botones solo cierran la ventana; no modifican la configuración, no ejecutan órdenes del juego ni guardan la selección. El diálogo utiliza su propio bucle modal para el manejo nativo de Tab y flechas. La llamada al alias permanece dentro del diálogo hasta cerrarlo.

La biblioteca se instala junto a los scripts en `lib/windows-x64/wxlua/wx.dll`. Se carga al abrir una ventana nativa, no durante el arranque normal de RhomScripts. Es una compilación para Windows de 64 bits y el Lua 5.1 de Mudlet; no se distribuye ni sustituye otra `lua51.dll`. Las recargas conservan el módulo nativo ya cargado. La demostración permanece independiente del configurador.

Esta prueba es experimental. La convivencia del bucle modal con Mudlet, la navegación por teclado y el lector externo deben contrastarse con las evidencias de [la prueba de wxLua](../migraciones/prueba-wxlua.md). No implica soporte de varios perfiles usando simultáneamente la DLL. Tras actualizar una DLL cargada puede ser necesario cerrar Mudlet antes de sustituir el archivo.

## Carga del catálogo de sonidos

Al arrancar, `init.lua` carga la configuración persistente y llama a `audio.iniciar()`. Audio toma los volúmenes guardados, delega en `sonidos.lua` la construcción del catálogo y muestra un resumen textual.

El catálogo se construye a partir de `sonidos/` junto a los módulos Lua. Cada entrada contiene el grupo derivado de la carpeta y la ruta completa del WAV. En desarrollo, RhomLoader indica la ubicación de los módulos. Consulta [la organización y las reglas de nombres](sonidos.md#organización).

El resumen informa del estado, las claves disponibles, los archivos comprobados y las incidencias. El estado es `cargado` si hay WAV utilizables y ninguna incidencia, `parcial` si hay WAV utilizables junto con incidencias, `ausente` si falta la carpeta e `invalido` si la ruta no es una carpeta o no contiene WAV utilizables. Las incidencias con los recursos permiten continuar con las funciones que pueden operar sin audio. Si falta una API requerida, el error se propaga.

El resumen queda en `RhomScripts.soporte.sonidos.resumen_catalogo` y las entradas disponibles quedan en `RhomScripts.soporte.sonidos.catalogo.sonidos`.

Para volver a comprobar los archivos manualmente, ejecuta `lua echo(RhomScripts.soporte.sonidos.cargar_catalogo().mensaje .. "\n")`. La función admite como argumento una ruta alternativa a la carpeta que contiene los grupos. Reconstruir el catálogo actualiza el índice, y la coordinación con la caché de Mudlet queda pendiente de la implementación del actualizador.

## Avisos de carga

`init.lua` solicita `ui.carga_ok` al terminar correctamente y `ui.carga_erronea` si falla un módulo o la inicialización, mediante `audio.reproducir(clave)`. El reproductor y el catálogo se preparan al principio de la carga de los módulos activos. Si el propio reproductor no puede cargarse, se propaga el error sin aviso sonoro.

Las incidencias con los recursos conservan su diagnóstico textual. Los errores Lua y de APIs se propagan. Un fallo adicional al reproducir el aviso de error se añade al error original. Los eventos de carga completa se emiten al terminar correctamente la inicialización. Los avisos usan el volumen de interfaz.

## Alcance

### Reproducción básica por clave

Un trigger puede solicitar el sonido al módulo `audio.lua` así:

```lua
local audio = RhomScripts.soporte.audio
local identificador, motivo = audio.reproducir("ui.boton_1", { volumen = 80 })
```

La función reproduce una vez el WAV asociado a la clave. Calcula el volumen efectivo como `solicitado * grupo * general / 10000`. Obtiene el grupo del catálogo. El volumen solicitado y el de un grupo sin ajuste específico valen 100 por defecto. Si el resultado es cero, devuelve `nil` sin llamar a Mudlet. Los demás resultados se redondean al entero más próximo, con un mínimo de 1. Paneo, repeticiones, instancia, simultaneidad, importancia y selección de variantes siguen pendientes.

Devuelve un identificador interno que puede pasarse a `audio.stop(identificador)`. Si el catálogo o la clave no están disponibles, devuelve `nil, motivo` sin reproducir ni emitir avisos repetidos. Un argumento de tipo incorrecto produce error. Una API nativa ausente o un error de reproducción comunicado por ella también produce error.

El identificador interno y la etiqueta de RhomScripts permiten parar sonidos al recargar. No implementan todavía políticas de instancia, grupo ni simultaneidad; las llamadas simultáneas quedan sujetas al comportamiento nativo de Mudlet. Que la API acepte la solicitud no garantiza por sí solo reproducción audible. La gestión de recursos sustituidos y caché permanece pendiente.

## Contenido que se documentará al implementar

- Instalación, requisitos y versión de Mudlet realmente probada.
- Comandos, teclado y configuración accesible.
- Controles avanzados de reproducción.
- Actualizadores propios, canales, conservación de preferencias y recuperación.

Estos apartados son alcance previsto, no funciones nuevas declaradas como disponibles. La documentación de uso se añadirá con evidencia de la implementación correspondiente.
