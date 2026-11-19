# Destinos del mapa

En el configurador, abierto con Ctrl+Mayús+C, entra en Interfaz y selecciona «Interfaz del mapa». Es un selector circular entre «Rhomscripts» (por defecto) y «Config oficial». Enter cambia directamente de opción; Derecha entra en el ajuste, Arriba y Abajo recorren las opciones circularmente e Izquierda sale. Cada cambio reproduce `boton_2`. Guarda para aplicar el cambio. Rhomscripts presenta la lista accesible de destinos; Config oficial conserva los enlaces habituales en la terminal. Se respetan las preferencias ya guardadas. Cancelar no aplica los cambios del borrador.

Con la opción activada, `irsala nombre` busca destinos mediante el mapa oficial y abre la lista de RhomScripts. También admite el nombre con salidas, por ejemplo `irsala Plaza [n,s]`. `sigilarsala nombre` busca destinos para viajar sigilando. Los destinos encontrados aparecen únicamente en la ventana; el comando escrito y los avisos del viaje pueden seguir apareciendo en la terminal.

## Consultar y viajar

La ventana «Destinos del mapa» tiene dos pestañas nativas visibles: Resultados y Favoritos. Una búsqueda nueva con coincidencias abre Resultados y selecciona su primer destino. Al reabrir con Ctrl+Mayús+M recuerda la última pestaña utilizada durante la sesión y selecciona su primer elemento.

Usa flechas, Inicio, Fin y las teclas de página para elegir un destino. Tab y Mayús+Tab cambian de pestaña, reproducen el sonido común `pestana` y anuncian únicamente «Resultados» o «Favoritos». El título indica «Destinos del mapa: Resultados» o «Destinos del mapa: Favoritos» según la pestaña activa. Cada entrada contiene nombre, salidas e identificador de sala; también indica si el viaje será sigiloso. Enter, incluido el del teclado numérico, cierra la ventana e inicia el viaje al destino seleccionado. También se admite la activación nativa de la fila: doble clic y, en Windows, Espacio. Cambiar la selección con las flechas no inicia el viaje.

Escape o cerrar la ventana sale sin iniciar un viaje. Ctrl+Mayús+M vuelve a abrir los últimos resultados sin repetir la búsqueda. Este atajo participa en la ayuda de teclado de RhomScripts. Si la opción está desactivada, informa de ello.

Una búsqueda nueva reemplaza Resultados. Si no hay coincidencias se anuncia sin abrir la ventana y se conservan los favoritos. Si otra ventana de RhomScripts está abierta, la apertura automática de una búsqueda con resultados espera a que se cierre. Los resultados se conservan al cerrar la ventana, pero se descartan al recargar los scripts o cerrar el perfil. Para buscar otra vez, cierra con Escape y ejecuta la búsqueda oficial desde Mudlet; la ventana no incorpora un buscador propio.

El viaje sigue utilizando el motor oficial y `stop` lo detiene. Cerrar la lista no detiene un viaje anterior. Si la sala ya no existe o sus datos no coinciden con el mapa cargado, se informa y no se inicia el viaje.

## Favoritos

Favoritos consulta el archivo `destinos_favoritos.json` del perfil de Mudlet, organizado por el nombre del personaje obtenido de `ficha.lua`. Cada personaje ve únicamente sus propios destinos, que sobreviven a las recargas. Al cambiar el nombre o desconectar se actualiza la lista; hasta conocer el nombre no se muestran favoritos y no se permite añadirlos. Al convertir el formato antiguo se vacían sus destinos sin propietario. Un archivo ausente significa que todavía no hay favoritos; un archivo incorrecto produce un error sin reemplazarlo.

Desde Resultados, Derecha accede al botón «Añadir a favoritos» si el destino no está guardado, o «Eliminar de favoritos» si ya lo está. El mismo botón alterna su acción y conserva el foco al añadir o eliminar desde Resultados. En Favoritos también aparece «Eliminar de favoritos». Izquierda devuelve el foco a la lista. Enter, Espacio o un clic sobre el botón ejecutan su acción sin iniciar un viaje. Mientras el foco está en el botón, Arriba y Abajo no cambian de destino. Las acciones se guardan inmediatamente en el JSON del perfil, sin pasar por Guardar en el configurador; el éxito se anuncia después de completar la escritura.

La combinación de sala y modo normal o sigiloso identifica un favorito. Añadir no duplica una combinación existente. La eliminación confirma únicamente «Eliminado de favoritos.», sin añadir el aviso genérico de retirada y vuelta a la lista. Eliminar borra el destino también del JSON, conservando intactas las listas de los demás personajes. Al eliminar se selecciona el siguiente favorito, o el anterior si era el último. Un fallo de escritura se comunica y no publica el cambio en memoria. El formato está documentado en el [contrato de mapa](../contratos-mudlet.md#destinos-del-mapa).

## Presentación

Las listas usan los colores nativos del sistema para conservar la legibilidad y los estados de foco y selección. No se reproduce el amarillo de los enlaces oficiales porque esta presentación no contiene esos enlaces. Todas las acciones y estados se expresan mediante texto y controles nativos.

Desactivar la opción restaura la presentación oficial sin modificar los archivos del paquete ni borrar favoritos. La instalación o reinicialización oficial reaplica la opción elegida. [Diseño y validación](../planes/mapa.md).

Al abrir la lista suena `abrir_mapa`. Al confirmar un destino válido para viajar suena `seleccionar_mapa`; recorrer destinos mantiene `clic_1`. Al salir con Escape o cerrar la ventana se usa `plegar` por ahora.
