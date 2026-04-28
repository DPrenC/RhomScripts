---
description: "Usar cuando una tarea pida migrar comportamiento desde scripts VIPMud .set a Lua, o comparar logica entre Scripts vipmud y rhomscripts."
name: "Migracion VIPMud a Lua"
---
# Guia de migracion desde VIPMud

## Objetivo

Migrar comportamiento funcional desde .set a Lua sin copiar limitaciones historicas innecesarias y utilizando estructuras y sintaxis moderna de lua no disponible en vipmud.

## Decisiones de proyecto

- Mudlet es el unico cliente objetivo.
- No mantener retrocompatibilidad con VIPMud.
- Priorizar modernizacion, legibilidad y simplificacion sobre equivalencia textual.
- Preservar todos los aliases originales como interfaz de usuario.
- No conservar nombres historicos de funciones si una API Lua limpia mejora la claridad.
- Usar modulos grandes por dominio, bien comentados.
- Mantener `init.lua` como punto de entrada y ampliar solo la carga de nuevos modulos.
- Migrar todos los modos: todos se consideran necesarios.
- Normalizar audio si conserva volumenes y paneos aproximados.
- Empaquetar sonidos dentro del package cuando llegue la fase de packaging.
- No hacer commits durante el proceso de migracion.
- Si falta informacion, asumir la opcion mas simple, documentarla y continuar.

## Proceso de migracion

1. Identificar caso de uso exacto en Scripts vipmud.
2. Extraer comportamiento observable (entrada, condiciones, salida).
3. Diseñar version Lua modular y legible.
4. Registrar supuestos cuando falte informacion.

## Reglas de equivalencia

- Priorizar equivalencia funcional sobre equivalencia textual.
- Mantener nombres del dominio cuando ayuden a trazabilidad.
- Evitar portar patrones fragiles del lenguaje antiguo.
- Si hay ambiguedad, elegir la opcion mas simple y documentar la decision.

## Resultado esperado

Toda migracion debe dejar trazable:
- origen funcional
- implementacion Lua final
- diferencias intencionales respecto al original

## Fuera de alcance inicial

- Clases concretas.
- Packaging con RhomLoader o `rhomscripts.iml`.
- Pruebas automatizadas.
