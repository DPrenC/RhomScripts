# Sonidos de RhomScripts

`sonidos.lua` construye en memoria el catálogo de `rhomscripts/sonidos/` durante el arranque. `audio.lua` consulta ese catálogo, aplica los volúmenes y llama a Mudlet para reproducir.

## Organización

- `sonidos/UI/` contiene los 31 WAV de interfaz. El grupo `ui` usa el volumen de interfaz.
- `sonidos/Comunicaciones/` contiene los 31 WAV de comunicaciones. El grupo `comunicaciones` usa el volumen de comunicaciones.

Cada WAV situado directamente en una carpeta de grupo aporta una clave con el formato `grupo.nombre`. Para construirla se elimina la extensión, se convierten los nombres a minúsculas y se sustituye cada secuencia de espacios por un guion bajo. Tras normalizar, cada parte empieza por una letra ASCII, un dígito o un guion bajo. El resto también puede contener guiones. Se admite la extensión WAV con cualquier combinación de mayúsculas y minúsculas. La ruta conserva el nombre real del archivo. Si dos archivos generan la misma clave, el catálogo excluye ambos e informa de la colisión.

Por ejemplo, `sonidos/Comunicaciones/Canal off.wav` genera `comunicaciones.canal_off`. El motor usa el grupo `comunicaciones` para aplicar el volumen. Encender y apagar canales usa `comunicaciones.canal_on` y `comunicaciones.canal_off`. El silencio de los historiales usa `ui.comunicacion_mute` y `ui.comunicacion_unmute`.

Los componentes comunes usan `ui.clic_1` para recorrer listas y árboles, y `ui.boton_1` para pulsar botones. El movimiento entre botones es silencioso. El configurador conserva `ui.abrir_config` y `ui.cerrar_config` para abrir y cerrar. Los reguladores de volumen usan `ui.clic_2`; los demás ajustes numéricos usan `ui.boton_1` y los booleanos `ui.boton_2`. El selector «Interfaz del mapa» también reproduce `ui.boton_2` al cambiar. El panel de comunicaciones usa `ui.abrir_com` y `ui.cerrar_com`. Las claves `ui.abrir_historial` y `ui.cerrar_historial` quedan reservadas para otros historiales.

## Incorporación y procedencia

Al migrar una función que usa un WAV de VIPMud, elige su grupo según el uso en RhomScripts. Si hace falta un grupo nuevo, defínelo antes de trasladar el archivo. Mueve el WAV desde `sounds/` a la carpeta del grupo en `rhomscripts/sonidos/` y recarga RhomScripts. Usa nombres ASCII y comprueba que la clave sea única y resuelva al archivo desde la función que la solicita. Si cambias el nombre de un archivo o grupo y cambia la clave, revisa los consumidores afectados. Si desaparece el último uso de un WAV, muévelo a `sounds/` en la raíz para conservarlo. Véase el [contrato de audio](../decisiones.md#3-contrato-de-audio).

Los WAV actuales se incorporaron a lo largo de la migración y se conservaron al integrar la carpeta antes llamada RhomSounds. Está pendiente documentar el origen, las licencias y las atribuciones de los recursos aportados por el usuario antes de distribuirlos públicamente. Registra esos datos al incorporar recursos y conserva los avisos existentes.

Consulta [Carga del catálogo de sonidos](README.md#carga-del-catálogo-de-sonidos) para el diagnóstico y [el historial de RhomScripts](../CHANGELOG.md) para los cambios de recursos.

El mapa usa `ui.abrir_mapa` para abrir, `ui.seleccionar_mapa` para confirmar un destino válido y, provisionalmente, `ui.plegar` para salir. Recorrer sus destinos conserva el clic común de listas.

Las pestañas usan `ui.pestana` por defecto, reproducido por el componente común al cambiar mediante teclado o ratón. Comunicaciones sobrescribe esa clave con `ui.seleccion_canal` para canales y Room; sus atajos de categoría usan la misma función compartida, una sola vez. El archivo es `UI/Pestana.wav`: se normalizó el nombre aportado «Pestaña.wav» a ASCII conservando su contenido. Preparar, refrescar y seleccionar de nuevo la misma pestaña no reproducen este sonido.
