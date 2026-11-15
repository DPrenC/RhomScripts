# RhomScripts: contrato común para agentes

RhomScripts migra VIPMud a Lua para Mudlet y Reinos de Leyenda. Conservar el comportamiento observable, mejorar la arquitectura y garantizar el acceso mediante lector de pantalla.

## Repositorio y distribución

- Trabajar desde la raíz de RhomScripts, donde está Git y desde donde se resuelven las rutas de estas instrucciones.
- `rhomscripts/` es la carpeta de despliegue para los usuarios. El actualizador previsto mantendrá al día los archivos distribuidos de esa carpeta.
- Mantener la documentación del proyecto en [doc/](doc/README.md), con el manual de uso en `doc/usuario/`. Las instrucciones de IA permanecen en sus rutas de descubrimiento. Conservar las licencias junto a los archivos redistribuidos.

## Planes y cambios funcionales

- Al iniciar o retomar una implementación, consultar el [índice de planes](doc/planes/README.md). Para trabajos con varias etapas o que continúan en otra sesión, enlazar una ficha con alcance, criterios de aceptación y siguiente paso. Reutilizar una ficha de migración cuando ya contenga el diseño.
- En cada entrega, actualizar la ficha si cambian el estado, los pasos o los bloqueos. Registrar cualquier cambio observable en [Sin publicar](doc/CHANGELOG.md#sin-publicar) y actualizar la guía de uso afectada. Enlazar la evidencia de validación y sus límites desde la ficha o la entrada correspondiente.
- Aplicar el [flujo de colaboración](doc/contexto-multiagente.md#coordinación) para repartir archivos, intercambiar evidencias e integrar la entrega.

## Reglas

- Implementar el alcance solicitado, conservar cambios del usuario y evitar refactorizaciones ajenas.
- Usar español claro. Comunicar resultados en texto, sin depender de colores o alineación.
- Accesibilidad mediante lector de pantalla externo. No usar SAPI ni implementar compatibilidad con SAPI. Por ahora conservar announce(texto) estándar, sin políticas diferenciadas de cola o interrupción; se definirán por tipo de mensaje en otra tarea.
- Objetivo: última versión estable disponible de Mudlet. Comprobar releases oficiales y registrar la versión realmente probada; no fijar para siempre un número antiguo.
- Llamar directamente a las funciones de Mudlet. Si una función no existe, debe lanzarse error. No comprobar existencia con type, if, pcall ni mecanismos equivalentes para omitir, sustituir o continuar. Si se captura para añadir contexto o limpiar recursos, relanzar. Las comprobaciones de datos y estado del dominio sí están permitidas.
- Verificar nombre, firma, retorno y versión de las APIs en documentación oficial antes de utilizarlas. No inventar APIs ni stubs para conseguir pruebas positivas.
- No hacer commits, publicar, conectar al juego ni modificar el índice de Git salvo petición explícita. Generar paquetes locales cuando forme parte de la tarea.
- Mantener en el proyecto solo instrucciones, perfiles y evidencias de RhomScripts. Excluir configuraciones y skills personales, conversaciones, rutas privadas, credenciales y registros de sesión de la documentación y de los archivos destinados a Git. Usar rutas relativas y datos sintéticos en las evidencias compartidas.

## Fuentes

- rhomscripts/: módulos Lua; init.lua es la entrada.
- scripts_vipmud/: referencia histórica para diseñar funciones o recuperar comportamientos. El código de RhomScripts describe el comportamiento vigente y los planes vigentes definen el resultado futuro. doc/doc_vipmud.txt documenta el lenguaje original.
- rhomscripts/sonidos/: recursos de audio usados por funciones activas de RhomScripts.
- sounds/: sonidos de VIPMud pendientes de incorporar y WAV retirados del despliegue. Véase el [contrato de audio](doc/decisiones.md#3-contrato-de-audio).
- RhomLoader/src/: cargador de desarrollo; scripts/package_rhomloader.ps1: empaquetado local.
- doc/mudlet/README.md: documentación oficial descargada; manifest.json: procedencia y hashes.
- doc/migracion.md: alcance y estado. Los estados históricos no demuestran validación actual.

## Lecturas por tarea

- Lua y pruebas Lua: .github/instructions/lua-mudlet.instructions.md.
- Migración: .github/instructions/migracion-vipmud.instructions.md y doc/migracion.md.
- Empaquetado: .github/instructions/packaging-rhomloader.instructions.md y doc/empaquetado-rhomloader.md.
- Búsqueda documental: .github/instructions/documentacion.instructions.md.
- Agentes: doc/contexto-multiagente.md.
- Herramientas y pruebas: doc/validacion.md.

Las instrucciones del usuario prevalecen. Las guías especializan estas reglas; no pueden autorizar ocultar una API inexistente ni ampliar el alcance funcional. Preguntar cuando una ambigüedad cambie comportamiento sin evidencia suficiente y continuar trabajo independiente.

## Validación y entrega

Resolver directamente los cambios sencillos. Cuando la tarea y el entorno permitan delegar, emplear los roles especializados con un alcance y unos archivos concretos. El responsable de integrar asigna la validación final del resultado combinado.

Preparación: scripts/setup_validation.ps1. Validación: scripts/validate.ps1. Manuales: scripts/update_docs.ps1.

Comprobar casos focalizados durante la edición y aplicar el [flujo de validación](doc/validacion.md) al integrar. Usar Mudlet real cuando lo exijan APIs, recarga, triggers, teclado o audio, con un perfil aislado y desconectado. Distinguir simulación, integración y comprobación manual.

Entregar cambios, comportamiento afectado, comandos y resultados de validación, versiones y límites pendientes. Una API ausente que no produce error es una regresión.
