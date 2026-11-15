# Plan de migración de RhomScripts

Esta hoja de ruta recoge el alcance y el estado de la migración a Lua para Mudlet. El código actual establece el comportamiento vigente y los planes vigentes establecen el resultado futuro acordado. Los `.set` de VIPMud son referencias históricas para diseñar funcionalidades o recuperar comportamientos concretos.

## Decisiones confirmadas

- Cliente objetivo: última versión estable disponible de Mudlet; comprobar y registrar la versión real.
- No se mantiene retrocompatibilidad con VIPMud.
- Prioridad: modernizacion y simplificacion por encima de equivalencia textual.
- Alcance: migrar la funcionalidad necesaria de todos los `.set`.
- `start.set` y `VipMud.set`: migrar solo utilidades funcionales necesarias, como
  lectura/copia de ultimas lineas; ignorar configuracion propia del cliente antiguo.
- Cada paso migra un comportamiento acotado de un único módulo. Un módulo reúne responsabilidades relacionadas, declara sus dependencias y mantiene su propio estado. Los cambios funcionales que necesite en otro módulo se preparan en pasos propios.
- `init.lua` carga los módulos en el orden de sus dependencias y llama a la función de inicialización de los que la necesiten. Cada módulo se ocupa de sus registros y recursos, incluida su retirada al recargar o tras un fallo parcial.
- Aliases: preservar la interfaz usada por el jugador; transformar los aliases internos usados como funciones en funciones Lua, con correspondencia trazable.
- Comandos: migrar completamente el comportamiento; no hay comandos excluidos por
  considerarse peligrosos.
- Modos: todos los modos existentes son necesarios.
- Cada WAV se revisa y se mueve desde `sounds/` al grupo de `rhomscripts/sonidos/` que corresponde a su función en el paso que lo pone en uso. Si el uso o la agrupación están por definir, se consulta al usuario antes de trasladarlo. Los WAV que quedan sin uso se mueven a `sounds/` en la raíz. Véanse la [guía de organización de los sonidos](../.github/instructions/migracion-vipmud.instructions.md#organización-de-los-sonidos-al-migrar) y el [contrato de audio](decisiones.md#3-contrato-de-audio).
- Datos personales: no hay datos que excluir; todos los `.set` pueden analizarse.
- Git: no hacer commits durante el proceso.
- Fuera del cierre actual: clases concretas, ambientacion, oficios y empaquetado
  mediante `rhomscripts.iml`, `RhomLoader` y ajustes de packaging.

El procedimiento está en la [guía de migración](../.github/instructions/migracion-vipmud.instructions.md). Usar la [ficha de comportamiento](migraciones/plantilla.md) para delimitar cada paso y el [índice de planes](planes/README.md) para consultar su estado y el siguiente paso.

## Primer hito funcional

El diseño inicial del primer entregable contemplaba tres piezas de infraestructura. Para conocer las capacidades vigentes de audio, consultar el [contrato de audio](decisiones.md#3-contrato-de-audio).

1. Modulo de sonidos funcional.
   - Resolver rutas de sonidos empaquetados.
   - Reproducir efectos simples.
   - Reproducir loops.
   - Aplicar volumenes y paneos aproximados.
   - Permitir parada de sonidos activos.

2. Sistema de listas navegables.
   - Guardar informacion por listas de dominio: chats, eventos, tiendas y otros usos.
   - Permitir insertar nuevas entradas.
   - Navegar con teclas arriba/abajo.
   - Leer en voz alta la entrada seleccionada.
   - Exponer una API comun para que otros modulos reutilicen el sistema.

3. Lectura y copia de ultimas lineas.
   - `Ctrl+1`, `Ctrl+2`, etc.: leer ultimas frases.
   - `Ctrl+Shift+1`, `Ctrl+Shift+2`, etc.: copiar ultimas frases.
   - Adaptar la funcionalidad desde `start.set` y `VipMud.set` sin portar
     configuracion obsoleta del cliente antiguo.

## Fases de migracion

### Fase 0: inventario funcional

Objetivo: convertir los `.set` en un mapa de comportamiento, no en una traduccion
linea a linea.

Tareas:

- Clasificar cada `.set` por dominio.
- Detectar aliases, triggers, variables, funciones, timers, macros y sonidos.
- Separar funcionalidad necesaria de configuracion obsoleta de VIPMud.
- Registrar supuestos importantes.

Salida esperada:

- Tabla resumida por dominio.
- Estado de cada grupo: pendiente, en curso, migrado, diferido o fuera de alcance.

### Fase 1: infraestructura base

Objetivo: preparar APIs Lua limpias para evitar arrastrar patrones fragiles de VIPMud.

Modulos previstos:

- `sonidos.lua`: construcción y consulta del catálogo de sonidos a partir de las carpetas.
- `audio.lua`: volúmenes y reproducción por clave.
- `lector.lua`: lectura accesible y salida para lector de pantalla.
- `historial.lua`: ultimas lineas, lectura por indice y copia al portapapeles.
- `listas.lua`: listas navegables reutilizables.
- Cada módulo es propietario del estado de su dominio. Expone operaciones concretas a sus consumidores y define qué conserva al recargar o desconectar.
- `comandos.lua`: envio de comandos a Mudlet y helpers comunes.

### Fase 2: superficie de uso general

Objetivo: portar los comandos usados de forma transversal.

Dominios:

- Configuracion funcional del personaje.
- Aliases generales.
- Modos.
- Comunicaciones.
- Reportes y portapapeles.
- Nicks.
- Corrector.
- Estados y stats.

### Fase 3: grupos, combate, habilidades y mundo no ambiental

Objetivo: migrar comportamiento reactivo y sonoro no ambiental, validando cada cambio según su riesgo y APIs afectadas.

Dominios:

- Sucesos.
- Efectos.
- Bloqueos.
- Items.
- NPCs.
- Grupos.
- Emociones.
- Estados.
- Combate.
- Magia general.
- Habilidades y hechizos de otros.
- Monturas.
- Oceano y embarcaciones.

### Fase 4: movimiento avanzado, oceano y embarcaciones

Objetivo: migrar comportamiento de alta interaccion.

Dominios:

- Movimiento de otros.
- Teclas de movimiento.
- Oceano y embarcaciones.

### Fase 5: clases concretas

Estado: diferido por decision del usuario.

Siguiente bloque real tras cerrar la base no ambiental. Incluye
`ScripsRL/Clases/` y cualquier integracion transversal que dependa de clases.

### Fase 6: prueba real intensiva en Mudlet

Estado: disponible cuando sea necesario; ya no depende de completar clases.

Objetivo: comprobar en Mudlet real, con perfil aislado y desconectado, las colisiones de triggers y teclas, los tiempos, la lectura, los sonidos y los falsos positivos. Registrar por separado cualquier comprobación que requiera una sesión de juego autorizada o uso manual con teclado y lector externo.

### Fase 7: ambientacion y oficios

Estado: diferido por decision del usuario.

Objetivo: migrar lo ambiental y los oficios al final, cuando la base y las clases
esten testadas.

Dominios:

- `Ambientacion.set`.
- `ScripsRL/Ambientacion/`.
- Oficios comunes.
- Crear.
- Herrero.
- Jornalero.
- Marinero.
- Minero.

### Fase 8: empaquetado

Estado: diferido por decision del usuario.

Quedan fuera del alcance inicial los cambios de `RhomLoader`, `rhomscripts.iml` y
packaging final. Se retomara cuando exista una rama funcional lista para probar.

## Inventario histórico por dominio

cffi-lua: dependencia Windows x64 y [asociación wx/Qt](migraciones/cffi-ventanas.md) integrada en el constructor común. «Interfaz → Ventanas flotantes», activada por defecto, decide la asociación de nuevas ventanas, incluido el configurador. `pruebacffi` permite comparar la relación manualmente, sin recompilar Mudlet.

Biblioteca nativa de ventanas wxLua: ciclo de vida, árbol y perfil sonoro implementados y conectados al configurador, con borrador, Guardar y Cancelar. Las variantes de listas, comunicaciones e historiales siguen pendientes; requisitos y decisiones en [biblioteca de ventanas](migraciones/biblioteca-ventanas.md). La demostración mínima de wxLua sigue separada de esta biblioteca.

Panel Geyser compartido retirado: las listas conservan navegación y acciones sin abrir panel lateral. El configurador migra a la ventana nativa descrita en [biblioteca de ventanas](migraciones/biblioteca-ventanas.md). El [informe del panel anterior](migraciones/interfaz-visual.md) se conserva como evidencia histórica, sin representar funcionalidad disponible.

La tabla conserva el inventario de la primera migración. «Implementado» registra que hubo una implementación en esa etapa. Para saber qué se carga, consultar [`init.lua`](../rhomscripts/init.lua) y el [inventario de módulos archivados](migraciones/modulos-archivados.md). En las fichas vigentes, registrar por separado disponibilidad y validación. Véanse la [guía de validación](validacion.md) y las [evidencias](evidencias-validacion.md).

| Dominio | Origen principal | Estado | Notas |
| --- | --- | --- | --- |
| Infraestructura de sonidos | `Funciones.set`, varios dominios, `sounds/` | Parcial | Catálogo dinámico de `rhomscripts/sonidos/`, reproducción por clave y volúmenes. Selección de variantes, bucles y paneo pendientes en la interfaz por clave. |
| Listas navegables | `Listas.set` | Implementado | API `listas.lua` creada; tienda/baul/mochila/embarcaciones migrados |
| Ultimas lineas y copia | `start.set`, `VipMud.set` | Implementado | `lector.lua` activo implementa Ctrl+1..9 y Ctrl+Shift+1..9 sin historial; véase [ficha revisada](migraciones/lector.md) |
| Aliases generales | `Alias_Macros.set` | Implementado | `general.lua` creado con aliases y macros generales |
| Configuracion funcional | `Configuracion.set`, `Alias_Macros.set` | Implementado | Defaults funcionales migrados a `config.lua`; prompts y configuracion de ficha migrados |
| Modos | `Modos.set` | Implementado | `modes.lua` ampliado con Shift+F11, alias historico `ModoE` y sonidos de modo |
| Comunicaciones | `Comunicaciones.set` | Implementado | `comunicaciones.lua` creado con telepatia, room, canales e historiales sobre listas |
| Corrector | `Corrector.set` | Implementado | `corrector.lua` creado con normalizacion de signos, players y salidas |
| Nicks | `Nicks.set` | Implementado | `nicks.lua` creado con nick X, objetivo, triggers y teclas principales |
| Grupos | `Grupos.set` | Implementado | `grupos.lua` creado con miembros, lider, eventos y Ctrl+Shift+G |
| Combate | `Combate.set`, `Bloqueos.set`, `Estados.set` | Implementado | `combate.lua` creado con kills, heridas, bloqueos, estados y teclas principales |
| Habilidades y magia | `HHFunciones.set`, `Habilidades_otros.set`, `Hechizos_otros.set`, `Magia.set` | Implementado | `habilidades.lua` creado con API comun de preparacion e impacto |
| Movimiento | `Movimiento_*.set` | Implementado | `movimiento.lua` cubre teclas, numpad, direcciones, retorno, presentes y movimiento de terceros |
| Ambientacion | `Ambientacion*.set`, subcarpeta `Ambientacion/` | Diferido | Pospuesto hasta que el resto funcione correctamente |
| Eventos | `Eventos.set` | Implementado | `eventos.lua` creado con historial y teclas F4/Shift+F4 |
| Generales | `Generales.set` | Implementado | `generales.lua` creado con conexiones, XP, tiradas y eventos generales |
| Stats | `Stats.set` | Implementado | `stats.lua` creado con prompt, vida/energia/fe, salidas, pieles/imagenes, aliados/enemigos/Jgd y alertas configurables |
| Sucesos y efectos | `Sucesos.set`, `Efectos.set`, `Items.set` | Implementado | `sucesos.lua` cubre sucesos/efectos/items transversales; ampliado con economia, misiones, busquedas, estatus y objetos frecuentes |
| NPCs | `NPCs.set` | Implementado | `npcs.lua` creado con jefes y criaturas especiales no ambientales |
| Emociones | `Emociones.set` | Implementado | `emociones.lua` creado con reglas table-driven y filtro de sujeto |
| Monturas | `Monturas.set` | Implementado | `monturas.lua` creado con flags de montado/galopando y sonidos principales |
| Items | `Items.set` | Implementado | Cubierto por `sucesos.lua` para objetos transversales; objetos de clase/oficio quedan con su dominio |
| Oceano y embarcaciones | `Oceano.set`, `Embarcaciones.set` | Implementado | `oceano.lua` cubre puerto, embarque, navegacion, puente/timon, clima maritimo, disparos, hundimientos y listas de embarcaciones |
| Oficios | `Oficios/*.set` | Diferido | Ultima fase junto a ambientacion |
| Clases concretas | `Clases/*.set` | Diferido | Siguiente fase de migracion |
| Packaging | `RhomLoader/`, `rhomscripts.iml` | Diferido | Fuera de alcance inicial |

## Siguientes pasos inmediatos

1. Consultar el [índice de planes](planes/README.md) y seleccionar un comportamiento acotado con sus dependencias disponibles. Si falta una dependencia, darle su propio paso.
2. Aplicar el [proceso y los criterios de cierre de la guía](../.github/instructions/migracion-vipmud.instructions.md#proceso-de-migración). Registrar el resultado y el siguiente paso en la ficha correspondiente.
3. Mantener clases, ambientación y oficios en las fases diferidas indicadas en la hoja de ruta.

## Supuestos registrados

- `VipMud.set` solo contiene configuracion del cliente antiguo y no aporta
  funcionalidad portable en esta fase.
- `audio.lua` llama directamente a `playSoundFile` y `stopSounds`. Una API ausente produce error. La interfaz por rutas de la primera migración, incluidos sus patrones `*N` y sus comandos de prueba, se retiró del módulo activo.
- Las listas navegan con flechas arriba/abajo sobre la lista activa. Si esto
  interfiere con historial de comandos en Mudlet, se ajustara a un modo de foco en
  la fase de prueba.
- Validación reproducible con Lua 5.1, LuaJIT, Luacheck, PCRE2, casos observables, comprobación de recarga y empaquetado. Véase doc/validacion.md.
- La validación real en Mudlet se realiza cuando sea necesaria; véanse las evidencias registradas. No equivale a auditar todos los dominios.
- `Ambientacion.set` y `ScripsRL/Ambientacion/` quedan diferidos a una fase muy
  posterior junto con oficios.
- `Oficios/*.set` queda diferido para la fase final. Las referencias históricas a sonidos de marinero se revisarán al migrar las funciones que los usen.
- En la auditoria fina posterior a Fase 3 se revisaron referencias sonoras de los
  modulos migrados; las rutas Lua actuales resuelven contra archivos reales del
  paquete local o contra variantes existentes.
- En el cierre de oceano y embarcaciones se migraron los aliases historicos
  `FuncOceanoControl` y `FuncMovBarco` como superficie compatible de diagnostico,
  y se dejo estado Lua para puente/timon, embarque, navegacion y hundimientos.

## Alcance temporal del arranque, 8 de noviembre de 2026

Están conectados configuracion, configurador, lector y keys. Audio, integración oficial, ventana nativa y registro de comandos son soporte necesario. El lector revisado consulta el búfer directamente y registra sus 18 pulsaciones y los comandos leerlinea/copiarlinea; historial permanece archivado. Los módulos propios pendientes están archivados en `rhomscripts old`, fuera de la ruta de carga. Se reincorporarán individualmente tras su revisión. Las evidencias anteriores sobre dominios desconectados son históricas, no certifican el alcance activo. Configuración y modos antiguos dejan de inicializarse; config.json es la única persistencia de preferencias del arranque.


## Panel de canales activo, 9 de noviembre de 2026

Comunicaciones se reincorpora como módulo nuevo conectado desde init.lua, junto a configuración, configurador, lector y keys. Utiliza los eventos GMCP oficiales, selección compartida entre ventana y atajos, historiales temporales acotados y silencio por canal. La implementación archivada permanece intacta. Los botones Responder, Responder en privado y Copiar se presentan deshabilitados por decisión del usuario. Contratos en [panel de canales](migraciones/panel-canales.md), uso en [manual de comunicaciones](usuario/comunicaciones.md) y evidencia en [validación](validacion.md). Los estados anteriores de comunicaciones se conservan como historia y no describen este módulo nuevo.
