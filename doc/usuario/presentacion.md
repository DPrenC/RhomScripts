# RhomScripts

RhomScripts es un proyecto independiente de scripts Lua para jugar a [Reinos de Leyenda](https://www.reinosdeleyenda.es/) con Mudlet y un lector de pantalla externo. Nace de la migración de los scripts de VIPMud de Rhomdur. Su objetivo es recuperar sus funciones de forma gradual y aprovechar los datos y servicios que el juego ya ofrece a través de sus scripts oficiales.

## Estado del proyecto

RhomScripts está en desarrollo temprano. La arquitectura general ya está organizada en módulos y el arranque reúne una primera base utilizable: configuración, lector de consola, historial de canales, atajos de teclado y avisos sonoros. La migración del resto de funciones de VIPMud y la preparación de una versión instalable siguen en curso.

El entorno objetivo es la [última versión estable de Mudlet](https://github.com/Mudlet/Mudlet/releases/latest) en Windows de 64 bits. Se han realizado pruebas de integración con Mudlet 5.1.1 en perfiles aislados y desconectados. Quedan por comprobar el uso conectado al juego y la experiencia con un lector de pantalla externo. Las ventanas usan controles nativos y los avisos de voz se envían mediante `announce`, la función estándar de Mudlet.

## Qué puedes hacer

- **Configurar RhomScripts y el paquete oficial.** Ctrl+Mayús+C abre el configurador. Permite ajustar los volúmenes, la retención del historial, el comportamiento de las ventanas y las preferencias de los scripts oficiales. Guardar aplica los cambios y conserva las preferencias en el perfil de Mudlet. [Uso del configurador](README.md#configurador-y-preferencias).
- **Leer y copiar líneas de la consola.** Ctrl+1 a Ctrl+9 lee desde la última línea con contenido. Ctrl+Mayús+1 a Ctrl+Mayús+9 copia la línea correspondiente con el teclado español de España. También puedes usar `leerlinea N` y `copiarlinea N`. [Guía del lector de líneas](lector.md).
- **Consultar las comunicaciones.** Mayús+F1 abre el historial de canales, Mayús+F2 el de Room y Mayús+F3 el de telepatía. Con Alt y la misma tecla de función se lee el último mensaje. Con Ctrl se alterna la lectura automática. Los historiales se borran al desconectar o recargar RhomScripts. [Guía de los historiales de comunicaciones](comunicaciones.md).
- **Elegir destinos del mapa.** Activa la lista de destinos en Interfaz para presentar `irsala` y `sigilarsala` en una ventana nativa. Enter inicia el viaje y Ctrl+Mayús+M recupera la ventana. [Guía de destinos](mapa.md).
- **Consultar los atajos y el estado.** Ctrl+Mayús+H alterna la ayuda de teclado. Mientras está activa, los atajos de RhomScripts anuncian su función. `rhomscripts keys` los enumera y `rhomscripts estado` muestra y anuncia el estado de la carga, el paquete oficial, la conexión y los datos del juego. [Atajos de RhomScripts](teclado.md#pulsaciones-migradas) y [monitor de estado](arranque.md#consulta).

## Integración con los scripts oficiales

RhomScripts está diseñado para funcionar junto con `RLMud_Config`, el paquete oficial de Reinos de Leyenda para Mudlet. Al arrancar, reutiliza el paquete instalado en el perfil. Si falta, lo descarga de la fuente oficial y lo instala. Espera a que termine su inicialización local y aplica las preferencias guardadas. Esta preparación puede completarse con el perfil desconectado del juego.

El paquete oficial sigue gestionando servicios como el mapa, su interfaz y el sonido MSP. RhomScripts usa los eventos GMCP de Reinos de Leyenda para construir su propio historial accesible, que puede usarse con el panel oficial oculto. Recibir los mensajes del juego requiere conexión y la habilitación de GMCP y de las comunicaciones.

## Cómo se organiza

- **Arranque e integración.** `init.lua` coordina la carga y la recarga. `arranque.lua` prepara las bibliotecas nativas wxLua y cffi, integra el paquete oficial y centraliza el estado de la sesión.
- **Funciones y preferencias.** `configuracion.lua` guarda las preferencias en `config.json` dentro del perfil. `configurador.lua`, `lector.lua`, `comunicaciones.lua` y `mapa.lua` implementan las funciones de uso diario. `keys.lua` y `aliases.lua` registran sus atajos y comandos.
- **Interfaz y audio.** `ui.lua` comparte la infraestructura de las ventanas nativas, que se preparan al arrancar y se reutilizan. `sonidos.lua` cataloga los WAV de interfaz y comunicaciones desde `sonidos/`. `audio.lua` reproduce por clave y aplica los volúmenes de cada grupo y el general. [Guía de sonidos](sonidos.md).

Consulta el [historial de cambios de RhomScripts](../CHANGELOG.md) para conocer el avance de la migración.
