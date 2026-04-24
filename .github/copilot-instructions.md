# Instrucciones Globales de RhomScripts

## Contexto del proyecto

RhomScripts es una migracion de scripts de VIPMud (archivos .set) a Lua para Mudlet, centrada en Reinos de Leyenda.

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
