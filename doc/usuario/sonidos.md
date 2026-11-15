# Sonidos de RhomScripts

`sonidos.lua` construye en memoria el catálogo de `rhomscripts/sonidos/` durante el arranque. `audio.lua` consulta ese catálogo, aplica los volúmenes y llama a Mudlet para reproducir.

## Organización

- `sonidos/UI/` contiene los 30 WAV de interfaz. El grupo `ui` usa el volumen de interfaz.
- `sonidos/Comunicaciones/` contiene los 31 WAV de comunicaciones. El grupo `comunicaciones` usa el volumen de comunicaciones.

Cada WAV situado directamente en una carpeta de grupo aporta una clave con el formato `grupo.nombre`. Para construirla se elimina la extensión, se convierten los nombres a minúsculas y se sustituye cada secuencia de espacios por un guion bajo. Tras normalizar, cada parte empieza por una letra ASCII, un dígito o un guion bajo. El resto también puede contener guiones. Se admite la extensión WAV con cualquier combinación de mayúsculas y minúsculas. La ruta conserva el nombre real del archivo. Si dos archivos generan la misma clave, el catálogo excluye ambos e informa de la colisión.

Por ejemplo, `sonidos/Comunicaciones/Canal off.wav` genera `comunicaciones.canal_off`. El motor usa el grupo `comunicaciones` para aplicar el volumen. Encender y apagar canales usa `comunicaciones.canal_on` y `comunicaciones.canal_off`. El silencio de los historiales usa `ui.comunicacion_mute` y `ui.comunicacion_unmute`.

El configurador usa `ui.abrir_config`, `ui.cerrar_config` y `ui.clic_1` para abrir, cerrar y navegar. Los ajustes numéricos usan `ui.boton_1` y los booleanos `ui.boton_2`. El panel de comunicaciones usa `ui.abrir_com` y `ui.cerrar_com`. Las claves `ui.abrir_historial` y `ui.cerrar_historial` quedan reservadas para otros historiales.

## Incorporación y procedencia

Al migrar una función que usa un WAV de VIPMud, elige su grupo según el uso en RhomScripts. Si hace falta un grupo nuevo, defínelo antes de trasladar el archivo. Mueve el WAV desde `sounds/` a la carpeta del grupo en `rhomscripts/sonidos/` y recarga RhomScripts. Usa nombres ASCII y comprueba que la clave sea única y resuelva al archivo desde la función que la solicita. Si cambias el nombre de un archivo o grupo y cambia la clave, revisa los consumidores afectados. Si desaparece el último uso de un WAV, muévelo a `sounds/` en la raíz para conservarlo. Véase el [contrato de audio](../decisiones.md#3-contrato-de-audio).

Los WAV actuales se incorporaron a lo largo de la migración y se conservaron al integrar la carpeta antes llamada RhomSounds. Está pendiente documentar el origen, las licencias y las atribuciones de los recursos aportados por el usuario antes de distribuirlos públicamente. Registra esos datos al incorporar recursos y conserva los avisos existentes.

Consulta [Carga del catálogo de sonidos](README.md#carga-del-catálogo-de-sonidos) para el diagnóstico y [el historial de RhomScripts](../CHANGELOG.md) para los cambios de recursos.
