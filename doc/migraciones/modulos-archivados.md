# Módulos desconectados pendientes de revisión

Esta carpeta conserva 25 de los 26 módulos Lua retirados del arranque activo el 8 de noviembre de 2026. No forma parte de package.path en el arranque de RhomScripts. No copiar módulos de vuelta sin revisar sus dependencias, contratos, pulsaciones y pruebas.

Incluye los dominios de juego, historiales, listas, modos, configuración antigua (config.lua), depuración, registrador de triggers y demostraciones wxLua/cffi. La suite anterior de dominios se conserva en tests/behavior.lua como referencia histórica; no se ejecuta en la validación activa ni demuestra comportamiento actual.

La carpeta `rhomscripts/` conserva configuración JSON, configurador, lector y teclado, además de audio, integración oficial, registro de comandos y adaptadores nativos necesarios. Los recursos sonoros activos se integran en `rhomscripts/sonidos/`.

config.lua todavía es requerido por modes, monturas, movimiento, oceano y stats archivados. Se conserva con ellos hasta revisar esos dominios. El arranque oficial no lo carga ni utiliza rl_config.lua. No se ha borrado ningún archivo de preferencias del perfil del usuario.

Las pruebas optativas de demostración scripts/tests/wxlua_probe.lua y cffi_probe.lua añaden explícitamente esta carpeta a su propia ruta de pruebas. Eso permite conservar sus ensayos independientes sin reactivar los aliases de demostración en init.lua. La validación normal no incluye el código archivado en su comprobación estática de producción.

El lector se revisó y devolvió a `rhomscripts/lector.lua`: consulta directamente el búfer nativo, sin reactivar historial ni su caché o trigger. Sus pulsaciones usan el contrato actual de keys. Véase [lector](../usuario/lector.md).
