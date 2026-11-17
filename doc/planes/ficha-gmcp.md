# Ficha del personaje por GMCP

Estado de la primera fase: Cerrada.

Última actualización: 2026-11-17.

## Objetivo y alcance

Retener en memoria los datos de `gmcp.Char` que expone Mudlet, incluidos los paquetes desconocidos y sus campos anidados. La [plantilla anonimizada](../gmcp-reinos.md) sirve de referencia para `Ficha`, `Stats`, `Status` y sus tipos.

## Contrato

Mudlet actualiza su tabla y emite el evento padre `gmcp.Char` con la ruta del paquete en el segundo argumento. El módulo copia los datos de esa ruta en una tabla privada. Cada paquete puede reemplazar su propio subárbol y los demás conservan sus datos. El módulo no modifica la tabla global de Mudlet. [Implementación del evento padre en Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/TLuaInterpreter.cpp#L4383-L4408)

`RhomScripts.modules.ficha.obtener(ruta)` acepta rutas relativas a `gmcp.Char` y también los nombres `nombre`, `clase`, `oficio`, `sexo`, `raza`, `vida_actual` y `vida_maxima`. Los datos de identidad proceden de `Ficha`, usando `genero` para `sexo` y conservando el código recibido. Las dos consultas de vida leen `Status.pvs.min` y `Status.pvs.max`. Un campo ausente devuelve `nil`. Tanto `obtener` para un campo compuesto como `datos()` devuelven copias independientes. La API carece de persistencia en disco.

Para leer una lista o una tabla con claves que contienen puntos, se consulta la tabla que la contiene y se accede con índices Lua. En `Status.Estados` se guardan los mensajes tal como aparecen en GMCP. La reconstrucción de los estados activos a partir de `set`, `add` y `remove` queda para una etapa posterior.

Al cargar por primera vez en una conexión ya abierta, el módulo espera paquetes nuevos. Al recargar, traspasa la copia ya observada y elimina los manejadores anteriores. La conexión nueva, la desconexión, `gmcp.Core.Goodbye` y `sysProtocolDisabled` para GMCP vacían el estado privado.

Mudlet combina `Char.Status` de forma superficial. Un mensaje que incluya `pvs` reemplaza el bloque entero en Mudlet. La ficha conserva `min` y `max` de la sesión si llegan por separado. Cuando Mudlet conserva la misma subtabla `pvs` en un mensaje sobre otros bloques, la ficha mantiene su copia previa. Al vaciar la sesión toma nota de la subtabla de Mudlet para poder ignorarla si aparece arrastrada en el siguiente mensaje parcial. Los demás bloques reflejan la vista que entrega Mudlet y todavía pueden incluir valores de la sesión anterior. [Combinación de subtablas en Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/blob/Mudlet-5.1.1/src/mudlet-lua/lua/LuaGlobal.lua)

## Criterios de aceptación

- Cada paquete observado queda disponible por su ruta y mantiene sus tipos, incluidos cero, falso y tablas vacías.
- Las consultas devuelven copias y las actualizaciones de un subárbol preservan las ramas independientes.
- Las transiciones de sesión vacían la copia. La recarga renueva los manejadores y conserva la copia de la sesión.
- La captura funciona con paquetes sintéticos procesados por Mudlet en un perfil aislado.

## Siguiente paso

Ampliar la muestra con datos observados cuando los cálculos o la presentación requieran campos nuevos. Queda por observar un `Estados.set` con elementos.

## Atajos de información

`ficha.pulsaciones` registra Alt+1 para `Status.pvs`, Alt+2 para `Status.pe` y `Status.escudo`, y Alt+0 para `Status.xp` y `Status.xp_oficio`. Cada pulsación anuncia los pares en una llamada directa a `announce(texto, "importantmostrecent")`. Al componer el anuncio, cada posición sin valor numérico se lee como «sin datos» y la copia privada conserva sus valores originales. El modo está documentado para Windows. [Formato de los anuncios](../usuario/teclado.md#información-del-personaje) y [API announce de Mudlet](https://wiki.mudlet.org/w/Manual:Miscellaneous_Functions#announce).

[Validación de los atajos](../validacion.md#atajos-de-información-17-de-noviembre-de-2026), [regresión de las actualizaciones parciales de vida](../validacion.md#lectura-de-vida-17-de-noviembre-de-2026) y [pruebas del aviso de valores ausentes](../validacion.md#aviso-de-valores-ausentes-17-de-noviembre-de-2026).

Los atajos con Alt+Mayús preparan los mismos pares con prefijos y delegan la copia, la verbalización y el sonido en `lector.copiar(texto)`. Comparten el formato de los valores ausentes, «sin datos». [Contrato de copia](../contratos-mudlet.md#copia-de-texto-al-portapapeles) y [validación de la copia y las consultas de identidad](../validacion.md#identidad-y-copia-de-la-ficha-17-de-noviembre-de-2026).

## Entrega y validación

La captura y las consultas se integraron en el arranque de RhomScripts. Las pruebas locales y la integración con paquetes sintéticos en Mudlet 5.1.1 pasaron. La recepción durante una partida queda pendiente. [Guía de consulta](../usuario/README.md#consulta-de-la-ficha-gmcp), [historial](../CHANGELOG.md#ficha-gmcp-del-personaje-16-de-noviembre-de-2026) y [resultados de validación](../validacion.md#ficha-gmcp-16-de-noviembre-de-2026).
