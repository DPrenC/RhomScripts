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

Por ahora `keys` aplica una correspondencia fija para Ctrl+Shift+1…9 en el teclado español de España. Los módulos siguen declarando los dígitos y `listkeys` conserva esas etiquetas, pero `tempKey` recibe los códigos de los símbolos que entrega Qt: 1 → `!` (33), 2 → comillas dobles (34), 3 → `·` (183), 4 → `$` (36), 5 → `%` (37), 6 → `&` (38), 7 → `/` (47), 8 → `(` (40), 9 → `)` (41). Se conservan ambos modificadores. Las colisiones se comprueban sobre ese código efectivo: declarar también Ctrl+Shift+Exclam colisiona con Ctrl+Shift+1. Ctrl+número, letras y otras combinaciones no cambian. No se detecta la distribución ni se adapta a otras distribuciones, incluido español latinoamericano; tampoco se añaden registros alternativos.

Ctrl+Shift+H alterna la ayuda y anuncia su estado mediante `announce(texto)`. En ayuda, cada pulsación registrada anuncia únicamente su descripción y no ejecuta su función. La propia combinación de ayuda siempre alterna el modo para permitir salir. El modo comienza desactivado y se desactiva al retirar o reconstruir los registros. Solo interviene sobre nuestras pulsaciones registradas; no bloquea las teclas de otros paquetes ni los controles de otras ventanas.

`keys.registrar_modulo(nombre_modulo, pulsaciones)` permite añadir un lote explícito cuando ya está cargado el registrador. En el arranque habitual basta con declarar la lista: no se debe registrar dos veces el mismo lote. La recopilación de `keys.registrar()` usa las listas publicadas, por lo que un lote añadido solo mediante llamada no reaparece en una reconstrucción posterior.

Se validan todos los datos y se rechazan nombres y combinaciones duplicados antes de crear registros. Un lote inválido no cambia los registros anteriores. La detección se limita a RhomScripts; no inspecciona atajos de otros paquetes. Si una llamada a Mudlet falla durante la creación se retiran los registros creados en ese lote y se relanza el error. La reconstrucción completa retira previamente la instancia anterior; un fallo de API no restaura esa instancia. Los identificadores de `tempKey` se conservan para retirarlos con `killKey` durante la recarga.

Funciones de control: `keys.ayuda_activa()`, `keys.establecer_ayuda(booleano)` y `keys.alternar_ayuda()`. `listkeys` enumera combinación, descripción, nombre, grupo y módulo en texto, sin depender de la información de debug.

APIs oficiales: [tempKey](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#tempKey), [killKey](https://wiki.mudlet.org/w/Manual:Mudlet_Object_Functions#killKey) y [announce](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#announce). tempKey devuelve el identificador y acepta funciones Lua y modificadores sumados; no se documenta una versión mínima en su sección. announce está documentada desde Mudlet 4.17. No se detecta ni sustituye una API ausente.

## Pulsaciones migradas

- Ctrl+Shift+H: activa o desactiva la ayuda de teclado.
- Ctrl+Shift+C: abre el configurador nativo. En ayuda anuncia «Abre el configurador nativo» y no abre la ventana. Declarado en configurador.pulsaciones con nombre configurador.abrir y grupo sistema.

- Ctrl+1 a Ctrl+9: lee la línea reciente de ese índice.
- Ctrl+Shift+1 a Ctrl+Shift+9: copia la línea reciente de ese índice. Las 18 pulsaciones pertenecen a lector, grupo lectura; en ayuda solo anuncian su descripción. Véase [semántica de lectura y copia](lector.md).


## Comunicaciones

El módulo comunicaciones publica Mayús+F1 (abrir historial), Alt+F1 (leer último mensaje de la categoría seleccionada), Ctrl+coma/punto (categoría anterior/siguiente) y Ctrl+Mayús+S (silencio del canal; conjunto desde Todos). Los atajos exteriores se registran mediante keys y participan en su ayuda. Dentro del diálogo, la política local de wx atiende sus teclas; Tab y Mayús+Tab cambian de categoría y Escape oculta. Las acciones de los tres botones siguen diferidas. Véase [comunicaciones](comunicaciones.md).
