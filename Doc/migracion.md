# Plan de migracion RhomScripts

Este documento fija el contrato de trabajo para migrar la funcionalidad necesaria de
los scripts VIPMud (`scripts_vipmud/**/*.set`) a Lua moderno para Mudlet.

## Decisiones confirmadas

- Cliente objetivo: Mudlet actual.
- No se mantiene retrocompatibilidad con VIPMud.
- Prioridad: modernizacion y simplificacion por encima de equivalencia textual.
- Alcance: migrar la funcionalidad necesaria de todos los `.set`.
- `start.set` y `VipMud.set`: migrar solo utilidades funcionales necesarias, como
  lectura/copia de ultimas lineas; ignorar configuracion propia del cliente antiguo.
- Estructura Lua: modulos grandes por dominio, bien comentados.
- `init.lua`: se mantiene como entrada principal y conserva su funcionamiento actual;
  solo debe ampliarse para cargar nuevos modulos.
- Aliases: preservar todos los aliases originales como superficie de uso, aunque la
  implementacion interna use nombres Lua nuevos y limpios.
- Comandos: migrar completamente el comportamiento; no hay comandos excluidos por
  considerarse peligrosos.
- Modos: todos los modos existentes son necesarios.
- Sonidos: deben empaquetarse dentro del package; el sistema de audio puede
  normalizarse si conserva paneos y volumenes aproximados.
- Datos personales: no hay datos que excluir; todos los `.set` pueden analizarse.
- Pruebas: no ejecutar validacion funcional en Mudlet real todavia. Si se permite
  validacion local, usar `luac`, `luacheck` y el arnes de carga con stubs de
  Mudlet.
- Git: no hacer commits durante el proceso.
- Fuera del cierre actual: clases concretas, ambientacion, oficios y empaquetado
  mediante `rhomscripts.iml`, `RhomLoader` y ajustes de packaging.
- Si falta informacion, asumir la opcion mas simple, documentar el supuesto y seguir.

## Primer hito funcional

El primer entregable testable debe centrarse en tres piezas de infraestructura:

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

- `audio.lua`: reproduccion de sonidos, loops, volumenes, paneo y resolucion de rutas.
- `lector.lua`: lectura accesible y salida para lector de pantalla.
- `historial.lua`: ultimas lineas, lectura por indice y copia al portapapeles.
- `listas.lua`: listas navegables reutilizables.
- `estado.lua`: estado central de modos, flags y variables compartidas.
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

Objetivo: migrar comportamiento reactivo y sonoro no ambiental, dejando la
validacion funcional de Fase 2 para mas adelante.

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

Estado: diferido hasta completar clases.

Objetivo: probar el paquete en Mudlet real con sesiones de juego, revisar
colisiones de triggers/teclas, tiempos, lecturas, sonidos y falsos positivos.

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

## Estado por dominio

| Dominio | Origen principal | Estado | Notas |
| --- | --- | --- | --- |
| Infraestructura de sonidos | `Funciones.set`, varios dominios, `sounds/` | Cerrado para pruebas | API `audio.lua` creada; variantes `*N.wav`, loops `music`/`StopMusic` y rutas auditadas localmente; pendiente validar paneo en Mudlet real |
| Listas navegables | `Listas.set` | Cerrado para pruebas | API `listas.lua` creada; tienda/baul/mochila/embarcaciones migrados |
| Ultimas lineas y copia | `start.set`, `VipMud.set` | Cerrado para pruebas | `historial.lua` y `lector.lua` implementan Ctrl+1..9 y Ctrl+Shift+1..9 |
| Aliases generales | `Alias_Macros.set` | Cerrado para pruebas | `general.lua` creado con aliases y macros generales |
| Configuracion funcional | `Configuracion.set`, `Alias_Macros.set` | Cerrado para pruebas | Defaults funcionales migrados a `config.lua`; prompts y configuracion de ficha migrados |
| Modos | `Modos.set` | Cerrado para pruebas | `modes.lua` ampliado con Shift+F11, alias historico `ModoE` y sonidos de modo |
| Comunicaciones | `Comunicaciones.set` | Cerrado para pruebas | `comunicaciones.lua` creado con telepatia, room, canales e historiales sobre listas |
| Corrector | `Corrector.set` | Cerrado para pruebas | `corrector.lua` creado con normalizacion de signos, players y salidas |
| Nicks | `Nicks.set` | Cerrado para pruebas | `nicks.lua` creado con nick X, objetivo, triggers y teclas principales |
| Grupos | `Grupos.set` | Cerrado para pruebas | `grupos.lua` creado con miembros, lider, eventos y Ctrl+Shift+G |
| Combate | `Combate.set`, `Bloqueos.set`, `Estados.set` | Cerrado para pruebas | `combate.lua` creado con kills, heridas, bloqueos, estados y teclas principales |
| Habilidades y magia | `HHFunciones.set`, `Habilidades_otros.set`, `Hechizos_otros.set`, `Magia.set` | Cerrado para pruebas | `habilidades.lua` creado con API comun de preparacion e impacto |
| Movimiento | `Movimiento_*.set` | Cerrado para pruebas | `movimiento.lua` cubre teclas, numpad, direcciones, retorno, presentes y movimiento de terceros |
| Ambientacion | `Ambientacion*.set`, subcarpeta `Ambientacion/` | Diferido | Pospuesto hasta que el resto funcione correctamente |
| Eventos | `Eventos.set` | Cerrado para pruebas | `eventos.lua` creado con historial y teclas F4/Shift+F4 |
| Generales | `Generales.set` | Cerrado para pruebas | `generales.lua` creado con conexiones, XP, tiradas y eventos generales |
| Stats | `Stats.set` | Cerrado para pruebas | `stats.lua` creado con prompt, vida/energia/fe, salidas, pieles/imagenes, aliados/enemigos/Jgd y alertas configurables |
| Sucesos y efectos | `Sucesos.set`, `Efectos.set`, `Items.set` | Cerrado para pruebas | `sucesos.lua` cubre sucesos/efectos/items transversales; ampliado con economia, misiones, busquedas, estatus y objetos frecuentes |
| NPCs | `NPCs.set` | Cerrado para pruebas | `npcs.lua` creado con jefes y criaturas especiales no ambientales |
| Emociones | `Emociones.set` | Cerrado para pruebas | `emociones.lua` creado con reglas table-driven y filtro de sujeto |
| Monturas | `Monturas.set` | Cerrado para pruebas | `monturas.lua` creado con flags de montado/galopando y sonidos principales |
| Items | `Items.set` | Cerrado para pruebas | Cubierto por `sucesos.lua` para objetos transversales; objetos de clase/oficio quedan con su dominio |
| Oceano y embarcaciones | `Oceano.set`, `Embarcaciones.set` | Cerrado para pruebas | `oceano.lua` cubre puerto, embarque, navegacion, puente/timon, clima maritimo, disparos, hundimientos y listas de embarcaciones |
| Oficios | `Oficios/*.set` | Diferido | Ultima fase junto a ambientacion |
| Clases concretas | `Clases/*.set` | Diferido | Siguiente fase de migracion |
| Packaging | `RhomLoader/`, `rhomscripts.iml` | Diferido | Fuera de alcance inicial |

## Criterios de hecho por modulo

Un modulo se considera migrado cuando:

- Sus aliases publicos originales estan disponibles si aplican.
- Sus triggers principales estan representados en Lua si aplican.
- El comportamiento observable esta documentado a nivel de dominio.
- Las rutas de sonidos usadas existen o quedan marcadas como supuesto.
- No introduce dependencias externas innecesarias.
- No rompe la carga desde `init.lua`.
- Los supuestos importantes quedan anotados en este documento o en comentarios
  breves del modulo.

## Politica de supuestos

Cuando el comportamiento original sea ambiguo:

- Elegir la interpretacion mas simple.
- Priorizar accesibilidad y legibilidad.
- No bloquear la migracion por dudas menores.
- Documentar el supuesto en el bloque del dominio afectado.

## Siguientes pasos inmediatos

1. Migrar clases concretas en una fase posterior.
2. Ejecutar prueba real intensiva en Mudlet cuando las clases esten migradas.
3. Migrar ambientacion y oficios al final.
4. Ejecutar validacion local tras cada bloque: `luac -p`, `luacheck`,
   `luajit scripts/validate_mudlet_load.lua` y `git diff --check`.

## Supuestos registrados

- `VipMud.set` solo contiene configuracion del cliente antiguo y no aporta
  funcionalidad portable en esta fase.
- `audio.lua` usa `playSoundFile()` y `stopSounds()` como API moderna; el paneo se
  intenta aplicar mediante `setSoundPan()` solo si la instalacion de Mudlet lo
  expone. Si Mudlet no lo expone, se conserva volumen/loop/ruta y el paneo queda
  como aproximacion pendiente de prueba real.
- `audio.lua` expande patrones heredados `*N.wav`/`*N.mp3` a una variante
  aleatoria existente cuando el archivo esta disponible en `sounds/`.
- Las listas navegan con flechas arriba/abajo sobre la lista activa. Si esto
  interfiere con historial de comandos en Mudlet, se ajustara a un modo de foco en
  la fase de prueba.
- Hay validacion local disponible mediante Lua 5.4, LuaJIT y LuaRocks/luacheck.
  El arnes `scripts/validate_mudlet_load.lua` carga `init.lua` con stubs de
  Mudlet y detecta errores de carga y atajos duplicados.
- La validacion funcional real en Mudlet queda pospuesta hasta completar clases.
- `Ambientacion.set` y `ScripsRL/Ambientacion/` quedan diferidos a una fase muy
  posterior junto con oficios.
- `Oficios/*.set` queda diferido para la fase final. Las referencias actuales a
  sonidos de marinero se mantienen porque ya estan empaquetadas, pero la logica
  propia de oficio no se migra todavia.
- En la auditoria fina posterior a Fase 3 se revisaron referencias sonoras de los
  modulos migrados; las rutas Lua actuales resuelven contra archivos reales del
  paquete local o contra variantes existentes.
- En el cierre de oceano y embarcaciones se migraron los aliases historicos
  `FuncOceanoControl` y `FuncMovBarco` como superficie compatible de diagnostico,
  y se dejo estado Lua para puente/timon, embarque, navegacion y hundimientos.
