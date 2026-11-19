# Planes de implementación

Cada entrada enlaza con el plan o ficha que contiene el alcance, los criterios de aceptación y el siguiente paso. Para abrir un plan, usar la [plantilla](plantilla.md) o enlazar una ficha existente. Para el alcance general, consultar la [hoja de ruta de migración](../migracion.md). El [flujo de mantenimiento](../contexto-multiagente.md#mantenimiento-de-la-documentación) describe quién actualiza cada documento.

## En curso

Sin etapas de implementación activas.

## Bloqueados

Registrar aquí los planes iniciados que requieren una decisión, un dato o una dependencia. Indicar qué permite retomarlos.

## Pendientes y diferidos

- **Distribución y actualizador.** Siguiente paso previsto: concretar el contrato del manifiesto, el alojamiento y la activación de versiones. [Diseño de actualizaciones](../decisiones.md#4-actualizaciones-previstas)
- **Clasificación de emisores de Room.** Siguiente paso previsto: comprobar qué dato identifica de forma fiable a Jugadores y PNJs en cada línea capturada. [Captura y clasificación](../migraciones/historiales-room-telepatia.md#captura-y-clasificación)
- **Respuestas del historial de canales.** Responder y responder en privado requieren verificar el comando de envío y la identificación del autor. Copiar está disponible mediante los [componentes comunes](componentes-interfaz.md). [Contrato pendiente de respuestas](../migraciones/panel-canales.md#4-acciones)
- **Descubrimiento de perfiles en los clientes.** Comprobar los adaptadores regenerados en una nueva sesión de Codex y en la interfaz de VS Code con Copilot disponible. [Ficha de colaboración y herramientas](colaboracion-y-herramientas.md).

## Entregas cerradas

- **Componentes comunes de interfaz.** Listas, pestañas nativas visibles, acciones contextuales, clic y pulsación comunes y demás sonidos por dominio, detalle de mensajes, copia y gestión de favoritos; validación local y 150 casos en Mudlet 5.1.1 desconectado. [Entrega y límites](componentes-interfaz.md#entrega-y-validación).

- **Enter en destinos del mapa.** Activación nativa y aceptación estándar del diálogo corregidas; verificado el motor oficial y los envíos capturados con Return normal y numérico en Mudlet 5.1.1 desconectado. [Corrección y evidencia](mapa.md#revisión-de-enter).

- **Primera fase de destinos del mapa.** Lista activable en Interfaz, Resultados efímeros y consulta de Favoritos en JSON; validación local y en Mudlet 5.1.1 desconectado. [Plan y evidencia](mapa.md#entrega-y-límites).

- **Debug centralizado y arranque limpio.** Modo compartido, familia única `rhomscripts`, consulta de versión e historial de 500 mensajes implementados y validados con Mudlet 5.1.1 desconectado. [Plan y evidencia](debug.md).

- **Primera fase de ficha GMCP del personaje.** Captura y consulta de `Char` con validación en Mudlet desconectado. [Plan de ficha GMCP](ficha-gmcp.md)
- **Colaboración, perfiles y herramientas de desarrollo.** Cambios aplicados, con la suite local y Mudlet real verificados. [Ficha de colaboración y herramientas](colaboracion-y-herramientas.md).
- **Primera fase de Room y telepatía.** Implementada y probada con perfil desconectado. La clasificación de emisores queda en la etapa posterior indicada arriba. [Ficha](../migraciones/historiales-room-telepatia.md) y [evidencia](../validacion.md#historiales-de-room-y-telepatía-12-de-noviembre-de-2026).

Las funcionalidades incorporadas y sus correcciones se consultan en el [historial de cambios](../CHANGELOG.md).
