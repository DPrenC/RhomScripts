---
description: "Usar cuando una tarea cree, mueva, renombre o vincule archivos de audio en sounds, o cuando se modifique audio.lua y logica relacionada con efectos de sonido."
name: "Audio Assets Guidelines"
applyTo: ["sounds/**", "rhomscripts/audio.lua", "src/**"]
---
# Guia de assets de audio

## Objetivo

Gestionar recursos binarios de sonido como parte funcional del proyecto.

## Reglas

- Tratar archivos de sonido como artefactos validos, no como ruido del repositorio.
- Evitar renombrados o movimientos masivos sin requerimiento funcional.
- Si se agrega un sonido, dejar clara su categoria y destino funcional.
- Mantener consistencia de rutas entre `sounds/` y el codigo que los utiliza.

## Validacion minima

- Verificar que la ruta referenciada por el codigo existe.
- Verificar que no se rompe la organizacion por categorias en `sounds/RL/`.
- Informar impacto de tamano o volumen de assets solo cuando sea relevante para build o distribucion.