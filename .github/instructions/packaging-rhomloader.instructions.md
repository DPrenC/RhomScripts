---
description: "Usar cuando una tarea afecte empaquetado, manifiestos, salida build o estructura de RhomLoader y muddler."
name: "Packaging RhomLoader"
applyTo: ["RhomLoader/**", "muddler/**", "src/**"]
---
# Guia de empaquetado

## Objetivo

Mantener builds reproducibles y estructura estable para distribucion.
RhomLoader debe empaquetarse con una ruta local hacia la carpeta que contiene `init.lua`, pero esa ruta no debe quedar en archivos versionables tras el empaquetado.

## Reglas

- No renombrar artefactos sin necesidad funcional.
- Respetar la estructura de RhomLoader/build y archivos de manifiesto.
- Mantener consistencia entre fuentes en src y salida empaquetada.
- Si se cambia una ruta, actualizar referencias relacionadas.
- Si el usuario pide empaquetar RhomLoader automaticamente, usar el agente `Empaquetador RhomLoader` o ejecutar `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_rhomloader.ps1`.
- Si el usuario pregunta como hacerlo, explicar el flujo automatico y el manual documentados en `Doc/empaquetado-rhomloader.md`.
- Si el usuario pide cargar sus scripts desde Mudlet, explicar que debe instalar RhomLoader desde Mudlet con `lua installPackage("ruta completa del .mpackage")` tras conectarse en el perfil que este usando en Mudlet.
- El comando de instalacion debe darse ya construido con la ruta absoluta real del paquete cuando el empaquetado se haya ejecutado.
- La ruta del comando para Mudlet debe usar `/`, nunca `\`.
- `RhomLoader/src/scripts/rhomloader/code.lua` no debe quedar con rutas personales: al finalizar debe volver a `local BASE_PATH = "PONER_RUTA_AQUI" -- PONER RUTA AQUI`.
- `RhomLoader/build/` y los `.mpackage` son artefactos locales; no deben sincronizarse con el repositorio.

## Verificacion minima

- Confirmar que el manifiesto mantiene metadatos correctos.
- Confirmar que los recursos necesarios siguen presentes en el paquete.
- Documentar cualquier cambio de proceso de build.
- Confirmar que `code.lua` no conserva la ruta local despues del build.
- Confirmar que los artefactos de build no quedan preparados para commit.
