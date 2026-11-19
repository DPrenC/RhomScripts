# Navegación común de ventanas

Las ventanas reutilizan controles nativos preparados al arrancar. Cerrar con Escape o X los oculta; recargar los retira. Los componentes comunes reproducen `ui.clic_1` al recorrer los elementos de listas y árboles, y `ui.boton_1` al pulsar un botón con ratón o teclado. Pasar de la lista a los botones, moverse entre ellos y volver a la lista no reproduce sonido. El cambio de pestaña usa `ui.pestana` por defecto. Cada módulo puede sobrescribir esa clave sin duplicar la navegación: comunicaciones conserva `ui.seleccion_canal`. Los demás sonidos los decide cada sistema, incluidos los avisos de límite y los efectos propios de las acciones. La opción Ventanas flotantes del configurador se aplica también al mapa y a los historiales.

## Árboles

Arriba y Abajo recorren los nodos. Izquierda pliega y Derecha despliega, conservando el comportamiento de ajuste del configurador. Tab y Mayús+Tab recorren el árbol y sus botones. Los botones generales pertenecen a este tipo de ventana.

## Listas y acciones del elemento

Un clic selecciona un elemento; Enter o doble clic ejecutan su acción. Elegir un elemento con las flechas no lo activa. En el mapa, la acción es viajar; en un historial, abrir el detalle del mensaje.

Derecha pasa de la lista al primer botón disponible del elemento seleccionado y avanza entre sus botones. Izquierda retrocede hasta volver a la lista. En un extremo se mantiene el foco y se reproduce el aviso de límite del sistema. Arriba y Abajo no cambian de elemento mientras el foco está en un botón.

Un clic, Enter o Espacio sobre un botón ejecutan su acción sobre el elemento asociado. No ejecutan la acción de la fila. Los controles se reutilizan al cambiar de elemento: el nombre accesible y la acción corresponden a la selección actual. Las acciones indisponibles no se ejecutan.

## Pestañas y actualizaciones

Las pestañas son visibles y se pueden seleccionar con el ratón. Tab cambia a la siguiente y Mayús+Tab a la anterior desde la lista o sus acciones. Estas ventanas no tienen botones generales ni una navegación adicional con Ctrl+Tab.

Al cerrar y reabrir durante la sesión se recuerda la pestaña y se selecciona su primer elemento. Una búsqueda oficial nueva del mapa abre Resultados con el primer destino, mientras que una búsqueda sin coincidencias no abre la ventana. Para volver a buscar se sale con Escape y se utiliza la interfaz oficial de Mudlet.

Las llegadas de datos conservan el elemento seleccionado por su identificador, aunque cambie su posición. También conservan el foco en su acción. Si se retira ese elemento, se selecciona el siguiente disponible o el anterior y se devuelve el foco desde los botones a la lista, con aviso textual. Una actualización no equivale a navegación ni activa elementos.

## Detalle de mensajes

El detalle muestra una copia del texto completo en un control de solo lectura. Las nuevas llegadas y los descartes del historial no modifican el texto abierto. Escape o X cierra el detalle y vuelve al historial. La acción Copiar del historial copia el mensaje seleccionado mediante el lector común.

Consulta los comportamientos específicos en [comunicaciones](comunicaciones.md) y [destinos del mapa](mapa.md). El estado y la evidencia se registran en el [plan de componentes](../planes/componentes-interfaz.md).
