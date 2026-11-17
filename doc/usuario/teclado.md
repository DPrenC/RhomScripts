# Registro de teclado

Cada módulo migrado publica una lista `pulsaciones`. `keys.registrar()` recopila estas listas después de cargar los módulos. Las tablas antiguas `key_bindings` se ignoran: sus atajos dejan de registrarse, sin retirar las demás funciones de sus módulos.

```lua
modulo.pulsaciones = {{
  combinacion = {
    tecla = mudlet.key.F12,
    modificadores = { mudlet.keymodifier.Control, mudlet.keymodifier.Shift }
  },
  nombre = "modulo.silenciarVoz",
  funcion = modulo.silenciarVoz,
  descripcion = "Silencia la voz",
  grupo = "lectura"
}}
```

El ejemplo documenta el contrato; no añade una pulsación al sistema. `nombre` identifica de forma estable la función pública; `funcion` contiene la referencia Lua real, no código para evaluar. `grupo` es metadato obligatorio: todavía no existen operaciones para activar o desactivar grupos. No hay personalización ni persistencia de combinaciones.

`combinacion.tecla` es un código oficial de Mudlet. `modificadores` es una lista opcional con cero, uno o dos valores distintos de `mudlet.keymodifier`: Control, Alt, Shift, Meta, Keypad o GroupSwitch. Se admiten una tecla sola, una tecla con un modificador y una tecla con dos modificadores. El orden de los modificadores no cambia la combinación. No se admiten secuencias, varias letras simultáneas ni Escape solo, reservado por Mudlet.

`keys` traduce los números con Ctrl+Mayús o Alt+Mayús a los símbolos del teclado español de España. Con Ctrl+Mayús también traduce la coma a punto y coma y el punto a dos puntos. Los módulos declaran la tecla base y `rhomscripts keys` conserva su etiqueta. `tempKey` recibe el código del símbolo y conserva ambos modificadores. Por ejemplo, Alt+Mayús+0 registra el signo igual. Las colisiones se comprueban con el código efectivo. [Teclado español de Windows](https://learn.microsoft.com/es-es/globalization/keyboards/kbdsp).

Ctrl+Shift+H alterna la ayuda y anuncia su estado mediante `announce(texto)`. En ayuda, cada pulsación registrada anuncia únicamente su descripción y no ejecuta su función. La propia combinación de ayuda siempre alterna el modo para permitir salir. El modo comienza desactivado y se desactiva al retirar o reconstruir los registros. Solo interviene sobre nuestras pulsaciones registradas; no bloquea las teclas de otros paquetes ni los controles de otras ventanas.

`keys.registrar_modulo(nombre_modulo, pulsaciones)` permite añadir un lote explícito cuando ya está cargado el registrador. En el arranque habitual basta con declarar la lista: no se debe registrar dos veces el mismo lote. La recopilación de `keys.registrar()` usa las listas publicadas, por lo que un lote añadido solo mediante llamada no reaparece en una reconstrucción posterior.

Se validan todos los datos y se rechazan nombres y combinaciones duplicados antes de crear registros. Un lote inválido no cambia los registros anteriores. La detección se limita a RhomScripts; no inspecciona atajos de otros paquetes. Si una llamada a Mudlet falla durante la creación se retiran los registros creados en ese lote y se relanza el error. La reconstrucción completa retira previamente la instancia anterior; un fallo de API no restaura esa instancia. Los identificadores de `tempKey` se conservan para retirarlos con `killKey` durante la recarga.

Funciones de control: `keys.ayuda_activa()`, `keys.establecer_ayuda(booleano)` y `keys.alternar_ayuda()`. `rhomscripts keys [modulo]` consulta el inventario efectivo mediante el [diagnóstico centralizado](debug.md): combinación, descripción, nombre, grupo, módulo, código efectivo, modificadores e identificador. Funcionan también con el modo debug desactivado. `keys.consultar()` devuelve copias de los registros y `keys.listar_teclas()` delega la presentación en debug.

APIs oficiales: [tempKey](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#tempKey), [killKey](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#killKey) y [announce](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#announce). tempKey devuelve el identificador y acepta funciones Lua y modificadores sumados; no se documenta una versión mínima en su sección. announce está documentada desde Mudlet 4.17. No se detecta ni sustituye una API ausente.

## Pulsaciones migradas

- Ctrl+Shift+H: activa o desactiva la ayuda de teclado.
- Ctrl+Shift+C: abre el configurador nativo. En ayuda anuncia «Abre el configurador nativo» y no abre la ventana. Declarado en configurador.pulsaciones con nombre configurador.abrir y grupo sistema.

- Ctrl+1 a Ctrl+9: lee la línea reciente de ese índice.
- Ctrl+Shift+1 a Ctrl+Shift+9: copia la línea reciente de ese índice. Las 18 pulsaciones pertenecen a lector, grupo lectura; en ayuda solo anuncian su descripción. Véase [semántica de lectura y copia](lector.md).


## Comunicaciones

Las teclas F1, F2 y F3 corresponden a canales, Room y telepatía, respectivamente. Con Mayús abren su ventana, con Alt leen el último mensaje de la pestaña o lista activa y con Ctrl alternan su silencio. Ctrl+coma/punto cambia de categoría en canales y Ctrl+Mayús+coma/punto en Room. Los atajos desde el juego se registran mediante `keys` y participan en su ayuda. Dentro de cada diálogo, wx atiende los atajos correspondientes. Tab y Mayús+Tab cambian de pestaña cuando el historial las tiene y Escape oculta la ventana. Véase [comunicaciones](comunicaciones.md).

## Información del personaje

Los atajos del grupo `informacion` consultan la ficha GMCP. Con Alt verbalizan en un solo anuncio con interrupción. Con Alt+Mayús copian, anuncian el contenido y «Copiado», y reproducen el sonido de portapapeles. [Consulta de la ficha GMCP](README.md#consulta-de-la-ficha-gmcp)

- **Alt+1** verbaliza la vida con el formato `40\120`.
- **Alt+2** verbaliza primero la energía y luego el escudo, por ejemplo `50\80, 0\0`.
- **Alt+0** verbaliza la experiencia y el oficio, por ejemplo `xp: 40\600, puntos de oficio: 0\20`.
- **Alt+Mayús+1** copia la vida, por ejemplo `pvs: 40\120`.
- **Alt+Mayús+2** copia la energía y los escudos, por ejemplo `energía: 50\80, escudos: 0\0`.
- **Alt+Mayús+0** copia la experiencia y los puntos de oficio, por ejemplo `xp: 40\600, puntos de oficio: 0\20`.

Si falta un valor, la lectura y la copia incluyen «sin datos» en su posición. Por ejemplo, `40\sin datos` indica que se conoce la vida actual y falta la máxima. Los ceros recibidos se conservan. Para la vida, cada valor se conserva durante la sesión aunque el otro llegue en un mensaje separado.
