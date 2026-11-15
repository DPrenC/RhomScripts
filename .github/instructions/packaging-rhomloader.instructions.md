---
description: "Usar cuando una tarea afecte empaquetado, manifiestos, salida build o estructura de RhomLoader y muddler."
name: "Packaging RhomLoader"
applyTo: "RhomLoader/**,muddler/**,scripts/package_rhomloader.ps1"
---
# Guia de empaquetado

## Objetivo

Mantener builds reproducibles y estructura estable para distribucion.
RhomLoader debe empaquetarse con una ruta local hacia la carpeta que contiene `init.lua`, pero esa ruta no debe quedar en archivos versionables tras el empaquetado.

## Reglas

- Aplicar AGENTS.md: las APIs inexistentes deben lanzar error, también en RhomLoader.
- Distinguir cargador de desarrollo (scripts externos en disco) de distribución final con scripts y sonidos.
- No modificar el índice de Git como reparación automática; resolver artefactos versionados como tarea explícita.
- El paquete local contiene rutas personales por diseño: no publicarlo.


- No renombrar artefactos sin necesidad funcional.
- Respetar la estructura de RhomLoader/build y archivos de manifiesto.
- Mantener consistencia entre fuentes en RhomLoader/src/ y salida empaquetada.
- Si se cambia una ruta, actualizar referencias relacionadas.
- Si el usuario pide empaquetar RhomLoader automaticamente, usar el agente `Empaquetador RhomLoader` o ejecutar `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_rhomloader.ps1`.
- Si el usuario pregunta como hacerlo, explicar el flujo automatico y el manual documentados en `doc/empaquetado-rhomloader.md`.
- Para cargar scripts, abrir el perfil de Mudlet e instalar RhomLoader con `lua installPackage("ruta completa del .mpackage")`. No es necesario conectar al juego; usar un perfil aislado para pruebas.
- Si el usuario solicita un paquete local, entregar el comando construido al destinatario local. En evidencias compartidas usar rutas relativas y datos sintéticos.
- La ruta del comando para Mudlet debe usar `/`, nunca `\`.
- Insertar la ruta de desarrollo únicamente en la copia temporal del fuente. Comprobar la salida antes de sustituir el paquete local y coordinar quién usa la ruta de salida compartida.
- `RhomLoader/build/` y los `.mpackage` son artefactos locales; no deben sincronizarse con el repositorio.

## Verificacion minima

- Confirmar que el manifiesto mantiene metadatos correctos.
- Confirmar que los recursos necesarios siguen presentes en el paquete.
- Documentar cualquier cambio de proceso de build.
- Confirmar que los fuentes del repositorio se conservan y que un fallo mantiene el paquete anterior.
- Confirmar que los artefactos de build no quedan preparados para commit.
