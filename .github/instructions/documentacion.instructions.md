---
description: "Búsqueda y mantenimiento de documentación oficial y contratos de APIs."
applyTo: "doc/**,scripts/download_mudlet_docs.py,scripts/update_docs.ps1"
---
# Documentación verificable

- Consultar el [índice de documentación](../../doc/README.md) y aplicar el [flujo de mantenimiento](../../doc/contexto-multiagente.md#mantenimiento-de-la-documentación) para planes, manuales, historial y evidencias.
- Aplicar AGENTS.md. Buscar primero en doc/mudlet/ y doc/doc_vipmud.txt; consultar fuentes oficiales online si falta una API o hay dudas de vigencia.
- Registrar URL, sección, firma, retorno, versión mínima documentada y fecha. Distinguir hechos de inferencias.
- Conservar HTML original, extracción de texto, atribución y SHA-256. Actualizar con scripts/update_docs.ps1; mantener los manuales históricos intactos.
- Comprobar la última versión estable en releases oficiales y anotar la versión realmente probada.
- No inventar funciones ni añadir stubs para suplir falta de evidencia. Localizar la API correcta o plantear la limitación al usuario.
- Registrar decisiones y dudas; una descarga o análisis estático no demuestra funcionamiento real.
