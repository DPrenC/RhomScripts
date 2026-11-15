---
description: "Usar cuando una tarea pida migrar comportamiento desde scripts VIPMud .set a Lua, o comparar logica entre scripts_vipmud/ y rhomscripts."
name: "Migracion VIPMud a Lua"
applyTo: "scripts_vipmud/**/*.set,rhomscripts/**/*.lua,doc/migracion.md,doc/migraciones/**"
---
# Guía de migración desde VIPMud

## Fuentes de verdad

- El código actual de RhomScripts establece qué hace el sistema hoy. Para saber qué módulos están activos, partir de `rhomscripts/init.lua` y seguir sus dependencias.
- Los planes vigentes establecen el comportamiento futuro acordado y el alcance de cada paso. Consultar el [índice de planes](../../doc/planes/README.md) antes de implementar. Una diferencia prevista en un plan se incorpora en el paso que la contempla. Si queda una contradicción que cambia el resultado observable o el alcance acordado, consultarla con el usuario y seguir con el trabajo independiente.
- Los `.set` de `scripts_vipmud/` son documentación histórica. Sirven para diseñar funcionalidades nuevas o recuperar comportamientos concretos que se haya decidido migrar. Registrar la referencia cuando se use, junto con las diferencias deliberadas.

## Límites y responsabilidades de cada módulo

- Migrar en pasos pequeños. Cada paso cambia un comportamiento comprobable de un único módulo funcional. Su alta en `init.lua`, sus recursos y su documentación forman parte del paso. Si necesita un cambio funcional en otro módulo, preparar esa dependencia por separado.
- Reunir responsabilidades concretas y relacionadas. Cada módulo mantiene su estado y expone las operaciones que necesitan sus consumidores. Conservar los alias públicos y las entradas activas que correspondan al alcance. Expresar el comportamiento en Lua compatible con Mudlet. Los alias internos de VIPMud pueden convertirse en funciones Lua con correspondencia documentada.
- `init.lua` carga por orden de dependencias, llama a la función de inicialización de los módulos que la necesiten y coordina la retirada. Cada módulo define qué registra, conserva o limpia. El módulo retira sus recursos propios y el servicio compartido retira los registros que creó en su nombre, también al recargar o tras un fallo parcial. Propagar el error después de la limpieza y documentar qué estado se conserva al recargar o desconectar cuando tenga un efecto observable.

## Proceso de migración

1. Elegir un caso concreto del plan y localizar el módulo responsable y las dependencias. Consultar el código actual y usar las referencias VIPMud que aporten evidencia para el caso.
2. Definir la entrada habitual, el resultado esperado y las diferencias intencionales. Reutilizar una ficha existente. Para un paso sencillo basta con registrar el origen de la decisión o del comportamiento, el resultado esperado y la evidencia en la ficha o en la documentación afectada. Usar la [plantilla de comportamiento](../../doc/migraciones/plantilla.md) cuando haga falta documentar más detalle.
3. Implementar y ejecutar casos focalizados durante el paso. Comprobar los efectos pertinentes desde su entrada habitual, como comandos, estado, foco, orden de lectura y audio. Si cambian la inicialización o los registros, comprobar también doble carga, retirada de recursos y limpieza ante fallo parcial.
4. Ejecutar una suite completa sobre la entrega integrada. Usar `scripts/validate.ps1` o `scripts/validate.ps1 -Mudlet` cuando corresponda integración real. Registrar comandos, resultados y límites según la [guía de validación](../../doc/validacion.md), distinguiendo prueba local, integración con perfil aislado y desconectado y comprobación manual con teclado y lector externo.
5. Registrar por separado la disponibilidad del paso y su evidencia. Una comprobación pendiente debe quedar visible con su alcance. Una decisión sin resolver o una dependencia necesaria que impida cumplir el resultado acordado bloquea la activación del comportamiento afectado. Las dudas menores que puedan resolverse con evidencia se anotan junto a la decisión.

## Organización de los sonidos al migrar

- Revisar los WAV del paso uno a uno. Identificar qué función activa usa cada archivo y asignarlo a un grupo según su función en RhomScripts. Reutilizar un grupo coherente o definir uno nuevo y acordar si le basta el volumen general o si necesita ajuste propio. Comprobar la ruta de destino y la clave resultante antes del traslado para evitar sobrescrituras y colisiones.
- Hacer el traslado a mano o con ayuda de herramientas, a partir de una lista revisada de archivos, usos, grupos y claves de destino. Limitar el traslado a los WAV que necesita el paso. Las carpetas de VIPMud sirven para localizar los archivos de origen. Evitar los traslados masivos y decidir la agrupación por el uso en RhomScripts.
- Si quedan dudas sobre qué WAV se necesitan, cuándo deben sonar o dónde agruparlos, presentar los candidatos y sus usos al usuario. Preguntar y resolver las dudas sucesivas antes de mover los archivos afectados. Mantener esos WAV en `sounds/` mientras se define la organización de destino y continuar con el trabajo independiente.
- Mover cada WAV de `sounds/` a `rhomscripts/sonidos/` en el paso que incorpora su primer uso en una función activa, incluidas las opcionales. Registrar la procedencia, compartir la clave entre consumidores y comprobar que resuelve al archivo correcto. Si desaparece el último uso, conservar el WAV trasladándolo a `sounds/`. Figurar en el catálogo o sonar en una prueba no acredita uso funcional.
- Si el comportamiento acordado necesita paneo, bucles o variantes, comprobar las capacidades vigentes en el [contrato de audio](../../doc/decisiones.md#3-contrato-de-audio). Si falta alguna, preparar la dependencia en un paso propio o registrar qué queda pendiente según el plan.
