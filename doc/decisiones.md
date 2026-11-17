# Decisiones de arquitectura y distribución

Actualizado el 15 de noviembre de 2026.

## 1. Distribución

RhomScripts reúne código y recursos de sonido. Los usuarios descargarán los archivos de `rhomscripts/`. El formato de instalación previsto es `rhomscripts.mpackage`. RhomLoader conserva su función de cargador local de desarrollo. El empaquetado público y el actualizador siguen pendientes.

El paquete público incluirá los módulos, los recursos seleccionados, las licencias y los metadatos necesarios. Los manuales de uso se mantendrán en [doc/usuario](usuario/README.md). La colección histórica de sonidos, los scripts VIPMud, las pruebas, las herramientas de desarrollo y las rutas personales quedan fuera del artefacto. La procedencia y los permisos de redistribución de los recursos deben verificarse antes de publicarlos.

## 2. Organización del repositorio

Git abarca el árbol desde la raíz de RhomScripts.

- `rhomscripts/` es la carpeta de despliegue y contiene los módulos Lua, sus dependencias y las licencias.
- `rhomscripts/sonidos/` contiene los recursos sonoros integrados, organizados por grupo.
- `RhomLoader/` contiene el cargador local y su configuración de empaquetado.
- `doc/` reúne los manuales de uso, los planes, el historial de cambios, los contratos de APIs, las evidencias y las copias de fuentes oficiales.
- `scripts/` contiene herramientas de validación y empaquetado.
- `sounds/` conserva los sonidos del proyecto original pendientes de incorporar y los WAV retirados del despliegue. `scripts_vipmud/` conserva los scripts de origen.

## 3. Contrato de audio

`rhomscripts/sonidos/` contiene únicamente WAV usados por funciones activas. El paso que incorpora el primer uso activo de un WAV de `sounds/` lo mueve a `rhomscripts/sonidos/` y registra su procedencia. Una función opcional disponible en el producto cuenta como uso activo. Varios módulos pueden compartir la misma clave. Cuando desaparece su último uso, el WAV se conserva trasladándolo de `rhomscripts/sonidos/` a `sounds/` en la raíz. El catálogo y las pruebas permiten comprobar los recursos, pero por sí solos no justifican conservarlos en el despliegue.

Organizar los WAV según su función en RhomScripts. Asignar cada archivo a un grupo existente que le corresponda o definir un grupo nuevo. Revisar los archivos individualmente antes de su traslado manual o asistido. Consultar al usuario si falta definir qué sonidos se necesitan o cómo agruparlos. Los archivos afectados permanecen en `sounds/` hasta resolver esas dudas.

Al arrancar, `sonidos.lua` construye en memoria un catálogo a partir de `rhomscripts/sonidos/`. La carpeta determina el grupo y, junto con el nombre del WAV, la clave. Por ejemplo, `Comunicaciones/Canal off.wav` genera `comunicaciones.canal_off`. Cada clave conserva la ruta exacta del archivo. Una colisión se comunica y deja la clave indisponible.

`audio.reproducir(clave, opciones)` resuelve la entrada, calcula `volumen_solicitado * volumen_grupo * volumen_general / 10000` y llama a Mudlet. Un volumen efectivo de cero omite la solicitud. Las llamadas usan claves estables y el volumen de grupo se toma de la entrada. Los recursos ausentes se diagnostican en texto; la ausencia de una API nativa produce un error. Las funciones de parada y las etiquetas del motor permiten retirar reproducciones al recargar.

Los grupos que carecen de un ajuste propio aplican un factor de grupo del 100 % y siguen sujetos al volumen general. Al definir un grupo nuevo, indicar en la ficha de migración si ese comportamiento basta o si el plan necesita un ajuste específico.

El paneo, la repetición, las secuencias, las políticas de simultaneidad y la selección de variantes quedan pendientes. Una futura agrupación de variantes deberá declararse de forma que se pueda distinguir de archivos numerados que representan claves separadas. La prioridad del lector de pantalla se decide por tipo de mensaje. Las consultas de ficha por teclado solicitan interrupción y los demás anuncios usan el procesamiento predeterminado de Mudlet. [Atajos de información](usuario/teclado.md#información-del-personaje)

## 4. Actualizaciones previstas

El paquete completo servirá para instalar RhomScripts. Para actualizar los archivos distribuidos desde `rhomscripts/` se prevé un manifiesto generado a partir de una revisión concreta del repositorio. El manifiesto identificaría esa revisión y las rutas, tamaños y huellas SHA-256 de los archivos distribuidos. El actualizador compararía el manifiesto publicado con el instalado y descargaría por HTTPS los archivos añadidos o modificados. Retiraría únicamente los archivos que pertenecían a la versión instalada y desaparecieron de la nueva.

GitHub Actions podría generar y publicar el manifiesto cuando cambien los sonidos en la rama elegida para publicarlos. Las descargas corresponderían al commit indicado en el manifiesto. GitHub Releases podría ofrecer paquetes completos para instalaciones nuevas. El alojamiento del manifiesto, los canales, la autenticación y las reglas para reinstalar un paquete completo siguen pendientes.

Antes de activar una actualización, se comprobarían el origen, la compatibilidad y la integridad de los archivos. La versión instalada se registraría una vez aplicado el cambio completo. En audio, esto incluye reconstruir el catálogo y gestionar las copias de caché afectadas. El proceso debe preservar los archivos ajenos al inventario y permitir seguir usando la instalación anterior si falla.

El diseño prevé comprobar las novedades en segundo plano, ofrecer la opción de desactivar la instalación automática, evitar actualizaciones simultáneas y comunicar disponibilidad, progreso y fallos de forma accesible.

El mismo mecanismo puede servir para módulos Lua. Una actualización de código prepararía una versión completa, con su `init.lua` y dependencias coherentes, y la activaría al reiniciar el perfil. Un cargador estable elegiría la versión y conservaría la anterior para recuperación. El contrato de ese cargador y su interacción con los registros, la configuración persistente y las bibliotecas nativas quedan pendientes.

## 5. Referencias

- [Documentación de RhomScripts](usuario/README.md) y [guía de sonidos](usuario/sonidos.md).
- [Plan de migración](migracion.md) y [cargador de desarrollo](empaquetado-rhomloader.md).
- [Manual oficial de paquetes de Mudlet](https://wiki.mudlet.org/w/Manual:Package_Manager).
- [API de reproducción de Mudlet](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#playSoundFile).
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
