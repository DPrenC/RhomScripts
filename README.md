# RhomScripts

Proyecto de migracion y modernizacion de scripts para Reinos de Leyenda.

[Documentación del proyecto](doc/README.md) · [Planes de implementación](doc/planes/README.md) · [Historial de cambios](doc/CHANGELOG.md)

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
- Accesibilidad: lector de pantalla externo; sin uso ni compatibilidad con SAPI. Anuncios estándar por ahora.
- Idioma de desarrollo y documentacion: espanol

## Estructura del repositorio

El repositorio Git abarca todo el proyecto y se abre desde la carpeta raíz de RhomScripts. Las rutas de esta guía y de las instrucciones para desarrolladores parten de esa raíz.

- `rhomscripts/`: carpeta de despliegue para los usuarios. Contiene los módulos Lua, las bibliotecas de ejecución, las licencias y los recursos integrados.
- `rhomscripts/sonidos/`: archivos de audio de RhomScripts, organizados por grupo. `sonidos.lua` genera el catálogo al arrancar y `audio.lua` reproduce por clave.
- `RhomLoader/src/`: fuentes del cargador; `RhomLoader/muddler.yml`: manifiesto
- `muddler/`: herramienta de empaquetado
- `scripts/`: herramientas y pruebas de desarrollo.
- `doc/`: manuales de usuario, planes, historial de cambios, contratos, validación y fuentes de referencia.
- `scripts_vipmud/`: scripts originales en formato `.set` como referencia funcional
- `doc/doc_vipmud.txt`: referencia del lenguaje/command set de VIPMud
- `sounds/`: colección de origen para la migración desde VIPMud.
- `rhomscripts old/`: módulos archivados para su revisión durante la migración.

## Diseño de distribución

Los usuarios descargarán la carpeta `rhomscripts/` como parte de la distribución. El actualizador previsto mantendrá al día sus archivos. El resto del árbol se usa para el desarrollo. RhomLoader es el cargador local de desarrollo.

Al arrancar, RhomScripts construye el catálogo a partir de las carpetas de sonidos y muestra un resumen textual. La reproducción por clave aplica los volúmenes de la solicitud, del grupo y general. El empaquetado público, las políticas avanzadas de reproducción y el actualizador siguen pendientes.

Consultar las [decisiones de arquitectura y distribución](doc/decisiones.md), la [presentación de RhomScripts](doc/usuario/presentacion.md) y la [guía de sonidos](doc/usuario/sonidos.md).

## Recursos binarios de sonido
Deben utilizarse de la misma manera que en los scripts originales, reproduciéndose en los mismos casos a través de las funciones de mudlet para reproducción de sonidos.


## Flujo de trabajo recomendado

1. Analizar comportamiento original en `scripts_vipmud/`.
2. Traducir intencion funcional a modulos Lua en `rhomscripts/`.
3. Mantener contratos modulares simples (cada modulo expone funciones y datos claros).
4. Validar compatibilidad operativa en Mudlet.
5. Usar `RhomLoader/muddler.yml` para el cargador local de desarrollo. El empaquetado público de RhomScripts sigue pendiente.

## Convenciones del proyecto

- Priorizar claridad frente a trucos de sintaxis.
- Nombrado y comentarios en espanol tecnico.
- Evitar dependencias externas innecesarias.
- No introducir logica especulativa: implementar solo requisitos confirmados.
- Preservar la arquitectura modular.

## Colaborar en RhomScripts

Abre la raíz del repositorio y prepara las herramientas con `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup_validation.ps1`. Antes de editar, revisa los cambios que ya existan y acuerda quién se ocupa de cada archivo compartido. En la entrega indica qué cambió, cómo se comprobó y el siguiente paso si queda trabajo.

Durante la edición elige comprobaciones focalizadas. El responsable de integrar ejecuta o asigna `.\scripts\validate.ps1` sobre el resultado integrado y añade `-Mudlet` cuando corresponda. Consulta la [guía de validación](doc/validacion.md) para preparar Mudlet y compartir la evidencia.

La [guía de colaboración](doc/contexto-multiagente.md#coordinación) describe el reparto y los traspasos entre desarrolladores y agentes. El [contrato de IA](AGENTS.md) enlaza las instrucciones por tarea. Los seis perfiles de proyecto se generan desde [roles.json](doc/agentes/roles.json) con `python scripts/sync_agents.py`.

## Validación y documentación

[Guía de validación](doc/validacion.md), [documentación oficial descargada](doc/mudlet/README.md), [contratos de APIs](doc/contratos-mudlet.md) y [plan de migración](doc/migracion.md).

Las funciones de Mudlet se llaman directamente y las ausentes deben lanzar error. Las pruebas reales se realizan cuando sean necesarias, en un perfil aislado y desconectado.
