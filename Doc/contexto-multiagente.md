# Contexto de trabajo multiagente para RhomScripts

Este documento describe como colaborar con multiples agentes de IA en GitHub Copilot para este repositorio.

## Objetivo

Asegurar que todos los agentes compartan el mismo contexto tecnico y de calidad.

## Archivos de contexto

- `.github/copilot-instructions.md`: reglas globales de proyecto.
- `.github/instructions/*.instructions.md`: guias especializadas por tipo de trabajo.
- `.github/agents/*.agent.md`: agentes especializados para analisis, implementacion y revision.

## Estrategia recomendada

1. Analisis inicial
   - Usar el agente Analista RhomScripts para mapear impacto.
2. Implementacion
   - Usar Implementador Lua Mudlet para cambios de codigo.
3. Revision
   - Usar Revisor de Riesgos antes de integrar.

## Criterios de calidad

- Cambios pequenos y trazables.
- Equivalencia funcional en migraciones desde VIPMud.
- No introducir logica no pedida.
- Mantener consistencia modular y accesibilidad.
- Tratar assets binarios de `sounds/` como contenido funcional valido.

## Flujo corto sugerido por tarea

1. Definir requerimiento exacto.
2. Ejecutar analisis de impacto.
3. Implementar cambio minimo.
4. Revisar riesgos y pruebas.
5. Integrar.

## Nota

Si una tarea afecta reglas del repositorio, actualizar primero instrucciones en `.github/` para que todos los agentes trabajen con el mismo contrato.