# Colaboración, perfiles y herramientas de desarrollo

Estado: Implementación cerrada. Comprobación de los perfiles en los clientes pendiente.

Última actualización: 2026-11-15.

## Objetivo y alcance

Definir el reparto y los traspasos entre desarrolladores y agentes, comprobar los perfiles compartidos y simplificar la validación y el empaquetado local. La guía de migración corresponde a una revisión posterior. Las configuraciones y evidencias personales quedan fuera del proyecto.

## Criterios de aceptación

- El contrato común remite al reparto por archivo, al traspaso y a los criterios de evidencia compartida.
- El generador produce los perfiles de proyecto para Codex y Copilot y detecta un perfil generado que haya quedado sobrante.
- RhomLoader acepta dos construcciones concurrentes y conserva los fuentes y el último paquete correcto cuando falla la construcción.
- La validación distingue los diffs de Git, registra un informe por ejecución y reutiliza el paquete comprobado para la integración nativa.

## Entrega y validación

Consultar la [guía de colaboración](../contexto-multiagente.md), las [comprobaciones locales](../validacion.md#comprobaciones-locales) y el [empaquetado de desarrollo](../empaquetado-rhomloader.md#empaquetado-automatico).

- `python scripts/sync_agents.py --check` confirmó los seis roles y 12 adaptadores en el árbol de trabajo y en una copia temporal con archivos seleccionados del proyecto. La regresión sintética detectó un rol retirado y protegió los perfiles manuales.
- `scripts/validate.ps1 -Mudlet` superó 10 controles locales, con 111 casos en Lua 5.1 y otros 111 en LuaJIT. Incluyó dos empaquetados concurrentes, la preservación del paquete anterior tras un fallo y las dos comprobaciones de Git. La integración pasó 97 casos en Mudlet 5.1.1 con un perfil aislado y desconectado. Se probó la instalación de RhomLoader y la recarga. La comprobación estándar conservó el portapapeles.
- Se revisaron las rutas destinadas a la entrega y los archivos de perfiles generados. Los paquetes y los informes brutos se guardaron en directorios locales ignorados.

Siguiente paso de comprobación: abrir una sesión nueva de Codex y revisar el descubrimiento tras la regeneración. En VS Code 1.146.0, comprobar el selector y las herramientas en una sesión con Copilot disponible. Las verificaciones de los archivos y formatos se hicieron en una copia seleccionada, ya que la reorganización aún contiene archivos sin seguimiento.
