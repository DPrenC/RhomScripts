# Evidencias de la revisión del sistema de agentes

Fecha: 6 de noviembre de 2026.

## Configuración y documentación

Seis roles definidos en doc/agentes/roles.json y doce adaptadores generados para Codex y Copilot. La comprobación local valida sincronización, YAML/TOML, patrones de aplicación y enlaces locales. Esto no demuestra que el selector de cada cliente haya recargado los perfiles: esa comprobación de interfaz continúa pendiente.

Diez páginas oficiales de Mudlet descargadas como HTML y texto, con índice, URLs, fecha, hashes y avisos originales de licencia. Los códigos oficiales de teclado proceden de la release identificada en doc/mudlet/keycodes-source.json. Los manuales históricos se conservan.

## Herramientas preparadas

Python 3.13.15; Lupa 2.6 con Lua 5.1 y LuaJIT 2.1; Luacheck 1.2.0; enlace PCRE2 0.5.3; Eclipse Temurin JRE 17.0.21+9 portátil; Mudlet 5.1.1 instalado por usuario. Dependencias Python fijadas en scripts/requirements-validation.txt; hashes de binarios y procedencia en sus instaladores y metadatos locales.

## Comprobaciones ejecutadas

Comando de validación completa: `scripts/validate.ps1 -Mudlet`.

La sintaxis se compila con ambos runtimes. Luacheck se ejecuta sobre producción y pruebas, sin tolerar avisos nuevos ni históricos. También se valida la sintaxis de herramientas Python y PowerShell, la integridad de los HTML descargados y los códigos oficiales de teclado.

Quince casos observables se ejecutan en Lua 5.1 y otros quince en LuaJIT: lectura y copia con atajos registrados, alias y capturas PCRE, historial, diagnóstico por feedTriggers, navegación y copia de listas, volumen/paneo/mono/bucle/parada, persistencia simulada, teclado numérico, rechazo de teclas y APIs inventadas, fallos ante APIs ausentes, inicialización que aborta sin emitir ready, transición segura desde sesión antigua, carga repetida y eventos de grupo visibles mediante F4/Shift+F4 antes y después de recargar. Se compilan 665 patrones distintos.

Cuatro comprobaciones de empaquetado en copia temporal: ZIP/XML válido con ruta local, restauración del fuente tras éxito, propagación del fallo del build y restauración tras ese fallo. No se sobrescriben los artefactos de build existentes del usuario ni se modifica el índice.

Doce casos en Mudlet 5.1.1 real, sin conexión al juego y con configuración nueva para cada ejecución: carga, persistencia, buffer de texto, capturas mediante feedTriggers, llamada real a announce, audio con paneo y bucle, eventos de grupo visibles antes y después de recargar, recarga, instalación real del paquete RhomLoader y segunda recarga, API ausente y confirmación asíncrona de parada del audio.

Tras recargar se conservan 132 teclas, 55 alias y 610 triggers, sin handlers de simulación añadidos. El portapapeles global no se toca en la integración estándar; la copia real queda como prueba optativa explícita. Solo se cierra el proceso de prueba. `git diff --check` forma parte de la ejecución.

## Correcciones funcionales verificadas

- Eliminadas las defensas que omitían APIs de Mudlet ausentes y los reintentos con firmas alternativas. La inicialización propaga los errores en lugar de presentar éxito.
- Persistencia con firmas oficiales table.save(ruta, tabla) y table.load(ruta, destino); ruta de perfil sin duplicar profiles/nombre.
- Paneo mediante el campo oficial pan de playSoundFile; retirada de setSoundPan.
- Lectura de una línea con extremo final exclusivo en getLines.
- Simulación de triggers mediante feedTriggers, conservando PCRE y capturas del motor.
- Retirada efectiva de teclas, alias y triggers antes de recargar; códigos oficiales y modificador Keypad para teclado numérico.
- Catálogo único de módulos, invalidado una vez antes de cargar: grupos y el módulo público de eventos comparten la misma instancia. La transición desde registradores antiguos exige reabrir el perfil antes de registrar nada.

## cffi-lua y asociación de ventanas, 7 de noviembre de 2026

Ampliación del 8 de noviembre: opción «Interfaz → Ventanas flotantes», predeterminada true, asociación común al construir, migración conservadora y false respetado. Quince casos del configurador superados en `.tools/wxlua-probe/runs/1590373345eb4ef79199056524caaf62/result.txt`; seis de wx en `5936026c99d64e8aa1fc941fa5ff6549` y ocho de cffi en `bf9a958d9ecc42c7bf9d4793c38e9202`. General: nueve controles locales y 54 casos reales, `.tools/mudlet-integration/runs/254d45fa7f514078aec89531134c69d7/result.txt`. Mudlet 5.1.1 y wxWidgets 3.2.8. Se verifica además foco diferido tras mostrar y cleanup del constructor fallido, sin simular teclas físicas ni lector.

Dependencia cffi-lua 0.2.4 instalada para Lua 5.1/Windows AMD64, con fuentes fijadas, hashes, licencias y libffi estática. SHA-256 de la DLL: `f937d2c52af7b2ca4c85ef9585d98266cd1d3f71af94d55541c1b327e374f8bd`.

Siete casos reales superados, Mudlet 5.1.1/wxWidgets 3.2.8, 18 pulsos Qt: `.tools/wxlua-probe/runs/a27c5f0f7a48421887cf8729df6b44f6/result.txt`. Se observaron HWND wx/Qt válidos, asociación/restauración, rechazo de ventanas ajenas y ciclos, botones, recarga, ocultación de la asociada al minimizar la Qt propia y reaparición al restaurar. No se modificaron ventanas de otros procesos ni perfiles personales.

Nueve controles locales y 51 casos de integración general superados: `.tools/mudlet-integration/runs/60c6f6e0a3b541b89662a0f388df258a/result.txt`. `pruebacffi` permite comprobación manual; no cambia el configurador. [Contratos y límites de cffi](migraciones/cffi-ventanas.md).

Repetición final tras proteger los botones durante el cierre: siete casos cffi superados y 21 pulsos Qt, `.tools/wxlua-probe/runs/fe42da690f9b445292609d28e630bef8/result.txt`. Los nueve controles locales también se repitieron sin fallos.

## Límites pendientes

No se ha auditado la equivalencia completa de los 72 originales VIPMud. Los estados de dominios se mantienen como implementados hasta disponer de evidencia propia. La lateralidad y calidad audible, el comportamiento percibido con el lector de pantalla externo y las pulsaciones físicas no se certifican por estos ensayos automáticos. Por decisión del usuario, no se usa SAPI ni se desarrolla compatibilidad con SAPI; se conserva announce estándar y las políticas de cola e interrupción por mensaje se diseñarán después.

Resultados regenerables detallados: doc/validacion-local.json y la ejecución indicada en .tools/mudlet-integration/latest.json, excluidos de Git. Cada prueba real tiene perfil, resultado, log y paquete independientes. El informe describe comprobaciones concretas y no declara todas las funcionalidades del proyecto validadas.

## Configurador nativo, comprobado el 7 de noviembre de 2026

Última revisión de eficiencia: diez casos de ventana nativa, 67 pulsos Qt, Mudlet 5.1.1/wxWidgets 3.2.8, `.tools/wxlua-probe/runs/77918c9ee11948d39ce92dab1c9e6cec/result.txt`. Comprobados trabajo redundante evitado, error de escritura con un solo anuncio, reentrada bloqueada desde destrucción nativa, limpieza tras fallo y reapertura posterior. Nueve controles locales y 51 casos generales reales superados: `.tools/mudlet-integration/runs/11c6b9d13cba402fb396e0643ce94068/result.txt`. No equivale a una medición de latencia percibida ni de lectura con el lector externo.

Última revisión: Desplegar al entrar en ajustes, Plegar al salir y anuncio «Ajustando valor.», con mensajes del diálogo abreviados. Nueve controles locales y siete casos nativos superados en Mudlet 5.1.1/wxWidgets 3.2.8, 54 pulsos Qt: `.tools/wxlua-probe/runs/fbb95eeb3fa64a04bce560a57148b394/result.txt`. Audio y llamadas de anuncio comprobados; percepción del lector externo pendiente de comprobación de uso.

Última corrección: retirada la doble ruta nodo/announce durante cambios; solo el nodo se actualiza. En límites numéricos sin cambio, announce comunica una vez el valor. Booleanos circulares con Interruptor en cada pulsación, sin Límite. Nueve controles locales y siete casos nativos superados en Mudlet 5.1.1/wxWidgets 3.2.8, 51 pulsos Qt: `.tools/wxlua-probe/runs/d0300c3ee3274a419bb7970646a4c13a/result.txt`. No se certifica automáticamente la lectura percibida con el lector externo.

Corrección más reciente: Límite solo al intentar superar extremos, con lectura y etiqueta reducidas al valor durante el ajuste. Nueve controles locales y siete casos nativos superados; 52 pulsos Qt en Mudlet 5.1.1/wxWidgets 3.2.8. Evidencia `.tools/wxlua-probe/runs/423c1fe9b5f04642a9c66e21257e5ecd/result.txt`. Se verifican anuncios exactos únicos y sonidos; lectura percibida con lector externo y pulsaciones físicas continúan siendo manuales. Los párrafos siguientes describen revisiones previas.

Revisión de flechas y sonidos: siete casos de ventana nativa superados, 51 pulsos Qt, ejecución `.tools/wxlua-probe/runs/5b97471a6c6345dca33c2522706a1442/result.txt`. Se comprueban entrada/salida del ajuste, arriba/abajo sin cambiar de fila durante el ajuste, retorno a navegación, salida por selección/foco y secuencias exactas de Botón/Interruptor/Límite. Título: «RhomScripts. Configuración.». Catálogo: 29 claves cubren 28 WAV; navegación del configurador con Clic 1. El ensayo invoca el controlador del hook sin simular eventos físicos.

Integración general posterior: nueve controles locales y 51 casos reales en Mudlet 5.1.1, `.tools/mudlet-integration/runs/bfe74ccf75ae4440bc05286b86888778/result.txt`. La lectura percibida y las pulsaciones físicas siguen siendo comprobaciones manuales.

Integración general final: nueve controles locales, 63 casos en cada runtime y 51 casos en Mudlet 5.1.1; ejecución `.tools/mudlet-integration/runs/f00b78de0df34fdaae48e6707ab28d7c/result.txt`. El ensayo nativo posterior al ajuste de texto pasó sus seis casos y 45 pulsos Qt en `.tools/wxlua-probe/runs/77c5301834c848ef8102cad09c3f54a8/result.txt`. Un intento anterior registró selección inicial inesperada; se conserva como fallo, sin causa atribuida ni simulación de entrada física. Véase [validación detallada](validacion.md).

El panel Geyser y el alias `rhompanel` se han retirado. El configurador utiliza ahora un diálogo wxLua con TreeCtrl y botones Guardar y Cancelar. La edición mantiene un borrador: cancelar descarta lo no guardado sin leer el archivo; guardar valida y escribe JSON antes de aplicar las preferencias oficiales.

Comando específico: `.\.tools\venv\Scripts\python.exe scripts/run_wxlua_probe.py --configurador`. Resultado: seis casos superados en Mudlet 5.1.1, última estable consultada por el ejecutor, Lua 5.1 y wxWidgets 3.2.8. Se observaron 40 pulsos de temporizador Qt durante las aperturas modales. Evidencia: `.tools/wxlua-probe/runs/92c0bba5a817429c97a9cf866e88f811/result.txt` y su archivo `.progress`.

Los casos comprueban identidad y selección del árbol real, foco inicial y recorrido circular Árbol/Guardar/Cancelar en ambos sentidos, representación de fuente predeterminada, confirmación No/Sí para restablecer, cancelación sin I/O, escritura anterior a la aplicación, fallo de escritura con diálogo abierto, aplicación fallida con preferencias ya guardadas y reintento, y cierre por X tras recargar Lua conservando la DLL. Guardar, Cancelar y error de escritura solicitan un solo sonido por acción; se delega a la reproducción real. Los botones se activan mediante wxCommandEvent real; la selección y el foco se verifican en los controles nativos.

La aplicación oficial se instrumenta únicamente en este ensayo de interfaz para comprobar el orden JSON/aplicación; sus efectos pertenecen a la integración general. El fallo de aplicación se provoca llamando a `guardar` dentro de pcall con el diálogo real abierto: se comprueban el error relanzado, el estado y el reintento, sin afirmar haber observado la presentación nativa de errores de wxLua en un callback de botón.

El ciclo de foco se invoca mediante la operación de la ventana; esto no demuestra que las teclas físicas Tab, Mayús+Tab o las flechas lleguen al manejador. El binding wxKeyEvent instalado no expone un setter del código de tecla y no se inventan eventos de teclado. Las pulsaciones físicas, Escape y la lectura percibida con lector externo requieren comprobación manual de este configurador. La prueba manual previa del usuario correspondía a la demostración wxLua de cinco elementos. No se conecta al juego ni se lee o modifica el portapapeles.
