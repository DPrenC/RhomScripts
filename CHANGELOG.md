# Historial de RhomScripts

## Sin publicar

### Integración de recursos sonoros, 11 de noviembre de 2026

- Integrados los 61 WAV en `rhomscripts/sonidos/`, con 30 de interfaz y 31 de comunicaciones. Se conservan los nombres originales y el contenido de los archivos. Las claves de abrir y cerrar comunicaciones, el configurador y otros historiales se derivan de esos nombres.
- `sonidos.lua` genera el catálogo en memoria durante el arranque. `audio.lua` reproduce por clave y toma el grupo de volumen del catálogo. Se retiran el catálogo escrito a mano y la estructura del antiguo paquete separado.
- Los sonidos de encendido y apagado de canal usan el grupo de comunicaciones. En el configurador, Clic 1 se comparte para navegación, Botón 1 para ajustes numéricos y Botón 2 para booleanos.
- La procedencia y los permisos de redistribución de los recursos siguen pendientes. Véase [Sonidos de RhomScripts](doc/sonidos.md).

### Panel de canales, 9 de noviembre de 2026

- Nuevo módulo comunicaciones: historiales dinámicos GMCP, ventana nativa reutilizable, selección compartida, lectura automática y a petición y silencio temporal por canal.
- Mayús+F1 abre, Alt+F1 lee el último mensaje, Ctrl+coma/punto cambian categoría y Ctrl+Mayús+S alterna silencio. Tab cambia categorías dentro de la ventana y Escape cierra.
- Retención por canal y total configurable en JSON. Historiales y silencios no persisten entre sesiones ni recargas.
- Responder, Responder en privado y Copiar se presentan deshabilitados; sus acciones quedan diferidas.
- lector.verbalizar recibe prioridad alta y conserva announce estándar.

### Arranque y monitor de sesión, 9 de noviembre de 2026

- Corregido el estado oficial cuando `rlmud_opciones_inicializadas` llega anidado dentro de `rlmud_config_loaded`: ambas señales comprueban el estado local y no dejan «inicializando» tras completar opciones.

- `arranque.lua` reúne las comprobaciones nativas y oficiales, la aplicación de preferencias y su vigilancia durante la sesión; sustituye a `comprobaciones.lua` y `oficial.lua`.
- Registro central de diez componentes con código, explicación, fecha y causa del último cambio. Consultas devuelven copias y los cambios emiten `rhomscripts.estado.cambiado`.
- Nuevo comando `rhomestado`: imprime y anuncia el estado durante la carga, la espera oficial y tras un fallo posterior. El monitor distingue conexión, protocolo GMCP, saludo y datos recibidos; retira confirmaciones al desconectar y separa descarga de extracción MSP.
- Recarga con retirada de observadores, alias y reaplicaciones pendientes; se conservan DLL y preferencias. No se añade barra de estado ni conexión al juego.

### Anuncios de copia, 8 de noviembre de 2026

- Copiar una línea escribe una sola vez en el portapapeles, anuncia su texto, solicita el sonido de copia y anuncia «Copiado».
- Se conserva announce estándar, sin esperas, colas ni interrupciones nuevas.

### Ctrl+Shift+número en español de España, 8 de noviembre de 2026

- keys registra los símbolos que entrega Qt con Ctrl+Shift+1…9, manteniendo los números en las declaraciones del lector, ayuda y listkeys.
- Correspondencia fija únicamente para español de España; no detecta ni adapta distribuciones. Comprueba colisiones sobre los códigos efectivos y conserva veinte registros de teclado.
- Pruebas de los nueve códigos, copia/sonido, ayuda y recarga; las pulsaciones físicas siguen requiriendo comprobación de uso.

### Recuento del lector sin líneas vacías, 8 de noviembre de 2026

- Los índices de lectura y copia omiten líneas vacías o de solo espacios, también al final del búfer. El texto seleccionado conserva sus espacios.
- Recorrido inverso por bloques de hasta 64 líneas, sin caché ni triggers adicionales. Si faltan líneas con contenido, avisa sin modificar el portapapeles.

### Lector integrado, 8 de noviembre de 2026

- Devuelto lector.lua del archivo al arranque activo, sin cargar historial ni su trigger/caché.
- Ctrl+1…9 lee y Ctrl+Shift+1…9 copia mediante pulsaciones, con ayuda, listado y retirada en recarga. Conservados leerlinea N y copiarlinea N.
- Lectura por posición física del búfer; preserva blancos y espacios. Un índice inválido o fuera del búfer anuncia el motivo y no sobrescribe el portapapeles.
- Sonido de copia mediante ui.portapapeles del catálogo actual.

### Ventanas preparadas y reutilizadas, 8 de noviembre de 2026

- Política común: construir ventanas de módulos activos al arrancar, ocultas y sin avisos/foco; conservar controles y callbacks entre aperturas.
- Configurador preparado antes de registrar atajos y ready; cada apertura renueva solo el borrador y los textos distintos. Guardar, Cancelar, Escape y X ocultan sin destruir.
- Registro común de ventanas, posición calculada una vez, asociación actualizada solo cuando cambia la preferencia y foco diferido invalidado por generación.
- Recarga destruye ventanas antiguas y prepara reemplazos. Con diálogo modal abierto, primero oculta y difiere la destrucción hasta el retorno; errores de preparación impiden completar la carga.
- Las ventanas futuras de canales e historial adoptarán esta política cuando se implementen.

### Organización de ventanas y comprobaciones, 8 de noviembre de 2026

- Fusionados `ui/arbol.lua`, `ui/sonidos.lua` y las operaciones de `nativo.lua` en `ui.lua`; árbol con nombre accesible y raíz proporcionados por el dominio.
- Nuevo `comprobaciones.lua`: carga compartida y validación de wxLua/cffi, comprobación/instalación/espera del paquete oficial y cancelación de la preparación.
- wxLua y cffi se cargan obligatoriamente al inicio. Los fallos se propagan y bloquean el arranque; las DLL se conservan entre recargas.
- `oficial.lua` conserva aplicación y vigilancia de preferencias durante la sesión; UI valida ventanas y asociaciones al utilizarlas. No se añaden listas ni otros controles futuros.

### Unificación del configurador, 8 de noviembre de 2026

- Integrado el borrador de edición en `configurador.lua`; eliminado `configurador_modelo.lua`.
- Compartidas las definiciones de opciones y el formato de valores entre sesión y ventana. `nueva_sesion()` permite editar sin abrir controles nativos.
- Conservados Guardar, Cancelar, Restablecer, límites, avisos y propagación de errores.

### Preferencia de ventanas flotantes, 8 de noviembre de 2026

- Añadida «Interfaz → Ventanas flotantes», activada por defecto, con id `ventanasflotantes`.
- El constructor común decide la asociación con Mudlet usando la configuración confirmada; afecta a nuevas ventanas, incluido el configurador y las demostraciones. Las independientes no reciben propietaria wx implícita.
- Los JSON 1/2 antiguos añaden la preferencia sin perder las existentes; false, Guardar, Cancelar y Restablecer conservan sus contratos.

### Puente cffi-lua y ventanas asociadas, 7 de noviembre de 2026

- Incluida cffi-lua 0.2.4 para Lua 5.1/Windows x64, con libffi estática, licencias, manifiesto y compilación reproducible.
- Añadido `pruebacffi`: ventana wxLua vinculada a la instancia de Mudlet, con Vincular, Desvincular y Cerrar. No cambia el configurador.
- Fachada nativa con HWND sin pérdida de precisión, validación de proceso, asociación reversible y rechazo de ciclos y ventanas ajenas.
- Sondeo real `scripts/run_wxlua_probe.py --cffi`, incluida minimización y restauración con la ventana Qt de Mudlet.

### Revisión de eficiencia del configurador, 7 de noviembre de 2026

- Las flechas de ajuste no vuelven a consultar la selección nativa; las definiciones se consultan directamente por identificador.
- Se omiten etiquetas y actualizaciones de estado idénticas. Restablecer no vuelve a escribir valores intactos y el cierre no recalcula el diseño del diálogo.
- Eliminado el anuncio duplicado de errores de escritura.
- Cierre protegido frente a reaperturas y acciones durante Destroy/Yield; los recursos se limpian también si falla la destrucción y el error se propaga.

### Ajuste de valores en el configurador, 7 de noviembre de 2026

- Entrada al ajuste con Desplegar y «Ajustando valor»; salida con Plegar sin anuncio duplicado del nombre. Mensajes del diálogo abreviados.

- Título «RhomScripts. Configuración.». Derecha entra en el ajuste de una opción, arriba/abajo modifican su valor e izquierda vuelve a navegar conservando la selección.
- Tab o cambiar de selección terminan el ajuste. Guardar y Cancelar mantienen el borrador y la persistencia existentes.
- Navegación con Clic 1, booleanos con Interruptor y números con Botón. Límite suena únicamente al intentar sobrepasar un extremo. Durante el ajuste se anuncia y muestra solo el valor; el nombre completo vuelve al salir.
- RhomSounds reindexado: 29 claves cubren los 28 WAV existentes.
- Corrección de doble lectura: los cambios se comunican mediante el nodo nativo, sin anuncio explícito adicional ni actualización duplicada del estado. Si un límite numérico impide cambiar, announce comunica solo el valor.
- Booleanos circulares en ambas direcciones, siempre con Interruptor. Los límites se conservan únicamente en números.

### Demostración experimental de wxLua, 7 de noviembre de 2026

- Añadido `pruebawx`: diálogo nativo independiente con cinco elementos y Aceptar/Cancelar, sin acciones de juego ni persistencia.
- Carga nativa diferida desde `lib/windows-x64/wxlua/wx.dll`, manteniendo el módulo wx entre recargas y retirando la ventana de prueba al recargar.
- El diálogo modal utiliza los controles estándar de wxWidgets en Windows; la compatibilidad y sus límites se registran en la ficha de prueba.

### Retirada del panel lateral, 7 de noviembre de 2026

- Eliminados el panel Geyser compartido y su alias; las listas conservan su funcionamiento sin abrir una vista lateral.
- La recarga retira también los controles y manejadores del panel de una sesión anterior.

### Preferencias del paquete oficial, 7 de noviembre de 2026

- Añadido el submenú «Paquete oficial RLMud_Config», con todos los componentes seleccionables y los valores predeterminados oficiales.
- JSON de formato 2 con booleanos y fuente predeterminada o 8–50 puntos; migración desde formato 1 conservando volúmenes.
- Guardar escribe primero el JSON y aplica después opciones y acciones oficiales; Escape no las aplica. Un fallo conserva el menú abierto y permite reintentar.
- Aplicación al arrancar y tras eventos oficiales, sin usar las ediciones aún no guardadas. Una sola reconstrucción de GUI para interfaz/canales y fuente sobre consolas existentes.
- Suscripción Comm independiente de la GUI; macros y Discord pendientes sin conexión. Retiradas de configurarficha las tres órdenes heredadas que desactivaban GMCP, GUI y MSP en el servidor.

### Dependencia oficial al arrancar, 7 de noviembre de 2026

- Comprobación de RLMud_Config antes de cargar módulos; descarga e instalación desde su fuente oficial solo cuando falta.
- Espera por eventos de la inicialización local, compatible con trabajo sin conexión al juego, y mensajes breves accesibles. Los fallos y el tiempo de espera impiden anunciar carga correcta.
- Retirada de manejadores y temporizadores al recargar; RhomLoader admite la carga pendiente sin anunciar éxito anticipado.
- No se alteran los componentes ni preferencias oficiales ni se añade consumo GMCP.

### Sonidos del configurador, 6 de noviembre de 2026

- Conectados apertura, navegación, submenús, ajustes, límites, confirmaciones, guardado y cancelación con las claves UI de RhomSounds mediante `audio.reproducir`.
- Se mantienen los anuncios y las reglas de guardado. No se modifican `modes.lua`, los controles de volumen ni el audio antiguo.

### Configuración y menú accesible, 6 de noviembre de 2026

- Cambio posterior: Escape descarta ajustes pendientes, recarga los valores del JSON y cierra. «Guardar cambios» se activa con Enter y cierra el menú si el guardado tiene éxito. Las recargas tampoco guardan ajustes pendientes.

- Añadidos `configuracion.lua` y `configurador.lua`, persistencia JSON por perfil y construcción del menú desde las opciones declaradas.
- Volúmenes general, interfaz y combate al 80; ambiente al 70. Ajustes de 0 a 100 en pasos de 5, guardado al salir y restauración con confirmación.
- Ctrl+Shift+C abre el configurador y deja de copiar en las listas clásicas. Navegación con lectura de valores y anuncio de submenús; contexto de teclado retirado al cerrar.
- Regeneración del JSON defectuoso sin copias, errores de lectura y guardado anunciados, recuperación de temporal tras sustitución interrumpida y conservación de cambios pendientes si falla el guardado.
- `modes.lua` y la configuración antigua se conservan. La conexión con audio por claves queda para otra tarea.

### Avisos de carga, 6 de noviembre de 2026

- `init.lua` solicita carga correcta o errónea mediante `audio.reproducir`, con grupo UI. Se prepara audio antes de los demás módulos para avisar de fallos tempranos y se conservan los errores originales.
- La ausencia o invalidez del paquete RhomSounds no cuenta como fallo de RhomScripts. Las políticas de grupo continúan pendientes en el reproductor.

### Reproducción básica por clave, 6 de noviembre de 2026

- Añadida `audio.reproducir(clave, opciones)`: utiliza el primer archivo disponible del catálogo y la API real de Mudlet.
- Recibe volumen, paneo, repeticiones, grupo, instancia, simultaneidad e importancia, sin aplicarlos todavía. Devuelve identificador interno o motivo de indisponibilidad.
- Conservadas las funciones anteriores por ruta. Volúmenes relativos, selección de variantes y políticas de reproducción siguen pendientes.

### Cargador de catálogo, 6 de noviembre de 2026

- Añadida carga de RhomSounds desde el perfil o carpeta hermana de desarrollo, con prioridad para el paquete instalado.
- Verificación de formato y archivos; conservación de variantes accesibles y diagnóstico de recursos ausentes, rutas inválidas y catálogos incompatibles.
- Resumen textual al iniciar y estado consultable desde `audio.lua`. Sin cambios en la reproducción existente ni implementación de actualizadores.

### 6 de noviembre de 2026

- Documentado el objetivo del paquete exclusivamente Lua, acompañado de documentación y metadatos, sin recursos de audio.
- Diseñados el contrato con RhomSounds y los actualizadores propios. Pendientes de implementación.
- Creada la base de documentación pública. Esta entrada no reconstruye el historial previo ni constituye un lanzamiento.
