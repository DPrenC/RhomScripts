---
description: "Usar cuando se cree, edite o revise codigo Lua para Mudlet en rhomscripts o src. Incluye pautas de modularidad, seguridad y compatibilidad con APIs de Mudlet."
name: "Lua Mudlet Guidelines"
applyTo: ["rhomscripts/**/*.lua", "src/**/*.lua"]
---
# Guia Lua para Mudlet

## Objetivo

Producir cambios Lua pequenos, claros y compatibles con Mudlet.

## Reglas

- Mantener funciones pequenas y con responsabilidad unica.
- Preferir tablas modulo con retorno explicito al final del archivo.
- Usar comprobaciones defensivas para APIs de Mudlet (por ejemplo, verificar que una funcion existe antes de llamarla).
- Mantener mensajes de error claros y accionables.
- No introducir globals nuevas salvo necesidad real de integracion.

## Compatibilidad y estabilidad

- Evitar romper contratos de modulos ya consumidos por init.lua.
- Si una funcion de Mudlet no esta disponible, degradar con fallo controlado.
- No eliminar eventos ni aliases sin revisar impacto cruzado.

## Estilo

- Comentarios breves solo en bloques no obvios.
- Mantener nombres coherentes con el dominio de Reinos de Leyenda.