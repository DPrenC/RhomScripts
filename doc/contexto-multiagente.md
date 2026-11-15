# Agentes de RhomScripts para Codex y GitHub Copilot

AGENTS.md es el contrato común. Las guías de .github/instructions especializan tareas. Los seis roles se definen una vez en [roles.json](agentes/roles.json); scripts/sync_agents.py genera perfiles de Copilot en .github/agents y perfiles nativos de Codex en .codex/agents. Heredan modelo y permisos del entorno; no se fijan modelos ni se modifican preferencias personales.

Abrir Codex o VS Code en la raíz del repositorio RhomScripts para usar las instrucciones y perfiles del proyecto. `rhomscripts/` contiene los archivos destinados al despliegue.

## Responsabilidades

- Analista: identifica comportamiento VIPMud, contratos y riesgos; no edita.
- Documentalista: verifica APIs en Doc y fuentes oficiales online; solo modifica documentación.
- Implementador: cambia código y completa trazabilidad y pruebas.
- Validador: edita pruebas y evidencias; verifica efectos, accesibilidad y recarga.
- Revisor: revisión independiente sin modificaciones funcionales.
- Empaquetador: cargador local, integridad del paquete y conservación de fuentes.

Las restricciones de edición de roles también son instrucciones cuando una herramienta de ejecución tiene capacidad de escritura; no constituyen un sandbox independiente. La disponibilidad de herramientas y descubrimiento de perfiles debe verificarse en cada cliente, sin darla por demostrada por validar YAML/TOML.

## Coordinación

Quien coordina, sea un desarrollador o el agente principal, mantiene alcance, dudas, criterios de aceptación y resultado integrado. Decide qué trabajo se puede hacer en paralelo según el encargo y las capacidades del entorno.

Para un cambio pequeño, implementar y validar directamente. Para un dominio nuevo, producir primero una ficha con [la plantilla](migraciones/plantilla.md), obtener evidencia documental si falta, implementar y solicitar validación y revisión independientes cuando su complejidad lo justifique. Respetar los límites de delegación del entorno y del usuario.

Antes de editar, revisar el estado del árbol y las asignaciones vigentes. Cada archivo o recurso compartido tiene un responsable a la vez, tanto si lo usa una persona como si lo usa un agente. Esto incluye init.lua, configuración, registros compartidos, historial y salida local de empaquetado. El revisor puede trabajar en paralelo en lectura y comunica los hallazgos al responsable de corregirlos.

En un traspaso, indicar objetivo, responsable y archivos asignados, cambios previos que deben preservarse, criterio de aceptación, comprobaciones con resultado y límites, y siguiente paso o bloqueo. Adjuntar la referencia VIPMud y el contrato cuando correspondan. Para un cambio pequeño basta con el mensaje de entrega. Para trabajo por etapas, actualizar la ficha existente.

Durante la edición se ejecutan comprobaciones focalizadas. Quien integra ejecuta o asigna una sola suite completa sobre el resultado integrado. Si un hallazgo cambia ese resultado, se repiten las comprobaciones afectadas. Aplicar la [guía de validación](validacion.md) para elegir los casos de Mudlet real.

## Criterios de aceptación

- Implementado: comportamiento y diferencias documentados; no implica pruebas superadas.
- Validado localmente: casos pertinentes pasan con herramientas y versiones registradas.
- Validado en Mudlet: integración pertinente observada en versión real identificada.
- Pendiente o diferido: trabajo sin completar, con motivo concreto.

No convertir estados históricos a validado sin evidencia. Las pruebas en Mudlet real se realizan cuando sean necesarias, en perfil aislado y desconectado. Una API inexistente debe lanzar error.

## Mantenimiento de la documentación

1. **Al empezar.** Consultar los [planes de implementación](planes/README.md) y la [hoja de ruta de migración](migracion.md). Reutilizar una ficha relacionada. Crear una con la [plantilla de plan](planes/plantilla.md) si el cambio se divide en etapas, tiene dependencias relevantes o necesita un traspaso. Para un cambio pequeño bastan la documentación afectada y, si modifica algo observable, el historial.
2. **Durante el trabajo.** Mantener en el plan el alcance, los criterios de aceptación, la etapa actual y el siguiente paso verificable. Anotar los bloqueos y qué falta para resolverlos. El analista y el revisor entregan hallazgos al coordinador. El implementador documenta el cambio efectuado, el validador aporta pruebas y límites, el documentalista mantiene las fuentes y contratos, y el empaquetador aporta la evidencia de construcción cuando corresponda.
3. **En cada entrega.** Actualizar la [guía de uso](usuario/README.md) si cambian comandos, atajos, configuración o comportamiento. Añadir al comienzo de [Sin publicar](CHANGELOG.md#sin-publicar) una entrada fechada para cada funcionalidad o corrección observable. Describir el efecto para el usuario y enlazar el manual o la evidencia pertinente. Actualizar contratos y decisiones cuando cambie su contenido.
4. **Al cerrar o traspasar.** El coordinador comprueba los enlaces, los resultados y las limitaciones, integra los cambios en los archivos compartidos y actualiza el índice. Si queda trabajo, registrar el siguiente paso; si se completó el alcance, conservar la ficha en su ruta y enlazar su entrega. Indicar el tipo de prueba y la versión observada en [validación](validacion.md).

La ficha conserva el diseño y su estado. El índice apunta a la ficha. El manual describe el uso actual y el historial registra el cambio entregado. Guardar el detalle técnico y los resultados en sus documentos correspondientes y enlazarlos desde los demás.

## Mantenimiento y comprobación

Editar roles.json y ejecutar `python scripts/sync_agents.py`. Comprobar con `python scripts/sync_agents.py --check` o scripts/validate.ps1, que también valida sintaxis YAML/TOML, guías, destinos de enlaces locales y rutas. Si se retira o cambia de nombre un rol, eliminar los perfiles generados que señale el comprobador.

Comprobar el descubrimiento desde una copia limpia. En Codex, abrir una sesión nueva con el proyecto de confianza y comprobar los roles disponibles para delegar. En Visual Studio Code, seleccionar el modo Copilot y revisar que el editor de personalizaciones y el selector muestran los perfiles. Los adaptadores declaran `target: github-copilot`. Comprobar que el documentalista puede consultar una página oficial y que el analista tiene herramientas de lectura y búsqueda. Registrar el cliente y qué se observó. [Subagentes de Codex](https://learn.chatgpt.com/docs/agent-configuration/subagents) y [formato de agentes de VS Code](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference).

## Archivos y evidencias compartidas

Revisar por ruta los archivos destinados a Git. Compartir AGENTS.md, las instrucciones de proyecto, el catálogo de roles y sus adaptadores generados. Los perfiles, configuraciones y skills personales se mantienen fuera del repositorio. También se excluyen conversaciones, credenciales, rutas privadas y registros de sesión.

Registrar en la ficha o en el informe compartido el comando, la versión, el resultado y los límites, con rutas relativas y datos sintéticos. Los paquetes locales de RhomLoader y los informes brutos se quedan en directorios ignorados. Antes de compartir evidencia copiada de una ejecución, revisar que no incluya datos privados.

La accesibilidad usa lector de pantalla externo, sin SAPI ni compatibilidad con SAPI. El comportamiento estándar de announce se mantiene; las políticas diferenciadas de cola e interrupción se definirán por mensaje en otra tarea.
