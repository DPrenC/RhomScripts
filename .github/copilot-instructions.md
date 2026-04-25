# Instrucciones Globales de RhomScripts

## Contexto del proyecto

RhomScripts es una migracion de scripts de VIPMud (archivos .set) a Lua para Mudlet, centrada en el mud Reinos de Leyenda.

Objetivo principal:
- conservar comportamiento funcional
- mejorar arquitectura y legibilidad
- facilitar mantenimiento
- priorizar accesibilidad con lector de pantalla

## Reglas generales de implementacion

- Implementar solo lo solicitado en la tarea.
- Evitar logica adicional no pedida o inferida sin evidencia.
- Mantener el estilo modular del repositorio.
- Mantener nombres y comentarios en espanol tecnico y claro.
- Antes de cambiar comportamiento, revisar referencia en Scripts vipmud y documentacion original.

## Convenciones tecnicas

- Lenguaje principal: Lua.
- Evitar dependencias nuevas salvo justificacion clara.
- Evitar refactors amplios cuando el cambio pedido es puntual.
- No romper APIs internas existentes entre modulos.

## Assets binarios

- Los binarios en `sounds/` son artefactos esperados del proyecto.

## Validacion

En cada cambio, indicar:
- archivos tocados
- impacto funcional
- riesgos o supuestos
- pruebas realizadas o no realizadas

## Contexto multiagente

Cuando se use trabajo con multiples agentes:
- usar agentes especializados en .github/agents
- respetar instrucciones especificas en .github/instructions
- si hay conflicto, priorizar la instruccion mas especifica para el archivo/tarea

## Carpetas y documentos importantes:

- 'doc/doc_vipmud.txt': Documentación original sobre el lenguaje de los scripts originales en vipmud
- 'doc/manual*^.*' documentación de referencia sobre funciones disponibles en mudlet.
- 'scripts_vipmud/' Scripts originales a migrar a lenguaje lua.
- 'souncs/' Sonidos a integrar en los scripts lua según la implementación original en los scripts vipmud

# Información sobre el código original.
El código original en los archivos .set se construyó de la siguiente manera:
- El código está dividido en módulos con extension .set.
- Cada módulo contiene funcionalidades sobre aspectos concretos.
- El código original es muy limitado y se estructura en alias, triggers y keys.
- Los triggers se disparan al recibir texto desde el mud.
- Los alias se utilizan en muchas ocasiones como funciones, ya que al llamarse ejecutan el código que contienen y el lenguaje original vipmud carece de mecanismos para construir funciones.
- Las keys configuran una pulsación de teclas que ejecuta el código que contienen.
- Todas estas funcionalidades deben adaptarse a código lua moderno, conservando su funcionamiento original.
- Los alias utilizados como funciones deben transformarse en funciones reales.
- Los triggers deben dispararse de la misma manera.
- Los sonidos configurados en los archivos .set originales deben reutilizarse de la misma manera en el código nuevo.
- Los nombres de los módulos y su estructura deben respetarse y reutilizarse lo máximo posible.
- las funciones públicas del lenguaje vipmud empiezan por el símbolo #, están todas listadas en 'Doc/doc_original.txt'
- Las funciones propias de los scripts, que realmente son lo que en vipmud se consideran alias, empiezan por Func o f, Por ejemplo FuncComprobarSujeto o FEventos.
- Los manuales con las funciones publicas de mudlet están en /doc.
Deberás buscar ahí las funciones a utilizar en la migración para la comunicación de los scripts con el programa mudlet sobre el que se van a ejecutar.
