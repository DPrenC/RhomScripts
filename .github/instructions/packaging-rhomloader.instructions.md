---
description: "Usar cuando una tarea afecte empaquetado, manifiestos, salida build o estructura de RhomLoader y muddler."
name: "Packaging RhomLoader"
applyTo: ["RhomLoader/**", "muddler/**", "src/**"]
---
# Guia de empaquetado

## Objetivo

Mantener builds reproducibles y estructura estable para distribucion.

## Reglas

- No renombrar artefactos sin necesidad funcional.
- Respetar la estructura de RhomLoader/build y archivos de manifiesto.
- Mantener consistencia entre fuentes en src y salida empaquetada.
- Si se cambia una ruta, actualizar referencias relacionadas.

## Verificacion minima

- Confirmar que el manifiesto mantiene metadatos correctos.
- Confirmar que los recursos necesarios siguen presentes en el paquete.
- Documentar cualquier cambio de proceso de build.