# RhomScripts

Proyecto de migracion y modernizacion de scripts para Reinos de Leyenda.

- Version: 1.0
- Autor: Rhomdur
- Stack principal: Lua para Mudlet

## Objetivo

RhomScripts reescribe desde cero un conjunto de scripts historicos en formato `.set` (VIPMud) hacia Lua moderno para Mudlet.

El objetivo no es copiar estructuras antiguas, sino conservar la logica funcional y mejorar:

- mantenibilidad
- modularidad
- legibilidad
- robustez ante errores
- accesibilidad con lector de pantalla

## Alcance funcional

- Cliente objetivo: Mudlet
- Juego objetivo: Reinos de Leyenda
- Enfoque de accesibilidad: uso con lectores de pantalla, sin depender de SAPI
- Idioma de desarrollo y documentacion: espanol

## Estructura del repositorio

- `rhomscripts/`: base modular en Lua (configuracion, alias, triggers, modos, audio, depuracion, etc.)
- `src/`: estructura de proyecto para empaquetado/carga
- `RhomLoader/`: salida de build y manifiesto del paquete
- `muddler/`: herramienta de empaquetado
- `Scripts vipmud/`: scripts originales en formato `.set` como referencia funcional
- `Doc/documentacion original.txt`: referencia del lenguaje/command set de VIPMud
- `sounds/`: recursos de audio organizados por categoria

## Recursos binarios de sonido

Los archivos binarios de `sounds/` forman parte legitima del proyecto.

- Se incorporan progresivamente segun se implementan nuevas funcionalidades.
- No deben tratarse como cambios anomalos por defecto.
- Cualquier nueva funcionalidad que dispare audio debe documentar la ruta del recurso asociado.

## Flujo de trabajo recomendado

1. Analizar comportamiento original en `Scripts vipmud/`.
2. Traducir intencion funcional a modulos Lua en `rhomscripts/`.
3. Mantener contratos modulares simples (cada modulo expone funciones y datos claros).
4. Validar compatibilidad operativa en Mudlet.
5. Empaquetar mediante la configuracion de `RhomLoader/muddler.yml`.

## Convenciones del proyecto

- Priorizar claridad frente a trucos de sintaxis.
- Nombrado y comentarios en espanol tecnico.
- Evitar dependencias externas innecesarias.
- No introducir logica especulativa: implementar solo requisitos confirmados.
- Preservar la arquitectura modular.

## Trabajo con agentes de IA (GitHub Copilot)

El repositorio incluye configuracion para trabajo multiagente en `.github/`:

- `copilot-instructions.md`: reglas globales del proyecto
- `instructions/*.instructions.md`: reglas por tipo de tarea
- `agents/*.agent.md`: agentes especializados

Documento de referencia de operativa multiagente:

- `Doc/contexto-multiagente.md`