# RhomScripts para GitHub Copilot

Leer y aplicar AGENTS.md en la raíz: contrato común para Codex y Copilot, rutas reales, política de Mudlet y validación. Consultar las guías enlazadas según la tarea.

Abrir como espacio de trabajo la raíz del repositorio RhomScripts. `rhomscripts/` es la carpeta de despliegue. Las instrucciones de colaboración se mantienen en la raíz y sus carpetas de desarrollo.

Para retomar una implementación, consultar [los planes](../doc/planes/README.md). Para documentar una entrega, aplicar el [flujo común](../doc/contexto-multiagente.md#mantenimiento-de-la-documentación) de AGENTS.md.

Las llamadas a APIs de Mudlet son directas: una función inexistente debe lanzar error. No añadir comprobaciones de existencia, alternativas ni capturas que oculten el fallo.

Los perfiles de .github/agents/ y .codex/agents/ se generan desde doc/agentes/roles.json mediante scripts/sync_agents.py. No modificar una sola copia generada. Operativa: doc/contexto-multiagente.md.
