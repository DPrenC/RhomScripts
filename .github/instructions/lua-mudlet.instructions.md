---
description: "Implementación, revisión y pruebas de Lua para Mudlet."
applyTo: "rhomscripts/**/*.lua,RhomLoader/src/**/*.lua,scripts/**/*.lua"
---
# Lua para Mudlet

- Aplicar AGENTS.md. Compatibilidad Lua 5.1/LuaJIT; no usar sintaxis exclusiva de Lua 5.4.
- Mantener módulos por dominio y funciones de responsabilidad concreta. Conservar contratos públicos y evitar globals nuevas salvo integración documentada.
- Verificar firma, retornos y versión de cada API en doc/mudlet/ o fuentes oficiales en línea. Encargar esa búsqueda al documentalista cuando se delegue.
- No proteger llamadas contra funciones inexistentes: ni comprobaciones previas, ni alternativas, ni errores silenciados. Propagar el fallo. Incluye cargador y persistencia table.load/table.save.
- No confundir patrones Lua con PCRE. Simular triggers con PCRE2 en pruebas locales y feedTriggers en Mudlet.
- Conservar identificadores de tempKey, tempAlias, tempRegexTrigger y handlers; retirarlos con la API documentada antes de recargar. Vaciar estadísticas de debug no elimina registros.
- Probar doble carga, colisiones y dependencias al cambiar registros o inicialización.
- Mantener lectura, copia, orden de anuncios y navegación. Audio y texto accesible son comportamiento funcional.
- Lector de pantalla externo, sin SAPI ni compatibilidad con SAPI. Conservar announce(texto) estándar; no introducir aún selección de colas o interrupciones por tipo de mensaje.
- Ejecutar casos focalizados durante la edición y aplicar el flujo de validación final de doc/contexto-multiagente.md. Evitar dobles genéricos que acepten cualquier función o tecla.

## Política común de ventanas

- Construir las ventanas y todos sus controles de los módulos activos durante el arranque, antes de registrar atajos y emitir ready. Mantenerlas ocultas en memoria; la preparación no debe pedir foco ni anunciar/reproducir avisos de apertura.
- Mostrar/ocultar reutiliza los mismos objetos y manejadores. Actualizar únicamente los datos cambiados; en listas futuras conservar identificadores y aplicar inserciones, modificaciones y retiradas sin reconstruir el control. Evitar temporizadores periódicos solo por mantener una ventana oculta.
- Separar sesión de uso y controles persistentes: el configurador crea un borrador nuevo al mostrar y lo descarta al ocultar. Guardar, Cancelar, Escape y X no destruyen los controles.
- Destruir ventanas al recargar o limpiar un fallo, conservando las DLL. Si ShowModal sigue en ejecución, ocultar y diferir la recarga hasta que retorne; invalidar callbacks de foco atrasados por apertura. Usar el registro y ciclo de vida común de ui.lua para las ventanas futuras.
