# GMCP de Reinos de Leyenda en Mudlet

## Alcance de la muestra

Esta plantilla reproduce la estructura y los tipos de los datos observados al ejecutar `lua display(gmcp)` el 16 de noviembre de 2026, con valores sintéticos. También se han sustituido las claves de canales que identificaban al personaje, a sus grupos o a su ubicación.

`gmcp` es la tabla donde Mudlet conserva la información que recibe por este protocolo. El comando muestra una instantánea de la tabla. Durante el juego pueden llegar otros paquetes o campos y el volcado tampoco indica cuándo llegó cada valor. [Manual técnico de Mudlet, sección GMCP](https://wiki.mudlet.org/w/Manual:Technical_Manual#GMCP)

## Datos del personaje

- `gmcp.Char.Ficha` contiene los datos de identidad y perfil, como nombre, raza, clase, especialización, nivel y oficio.
- `gmcp.Char.Stats` contiene atributos numéricos. Se conservan las abreviaturas recibidas, incluidos `con_origen` y `fue_extrema`.
- `gmcp.Char.Status` contiene bloques numéricos `escudo`, `pe`, `pvs`, `xp` y `xp_oficio`. La interfaz del paquete oficial usa `pvs.min` como vida actual y `pvs.max` como vida máxima. La captura aporta la forma de los demás pares `min` y `max`; su significado exacto se podrá documentar conforme se compruebe.
- `gmcp.Char.Status.Estados.set` apareció como `{}`. Con esa muestra queda pendiente identificar la estructura que tiene cuando llega con elementos. El paquete oficial también escucha `gmcp.Char.Status.Estados.add` y `gmcp.Char.Status.Estados.remove`.

La lectura de la barra de vida y los manejadores de estados se comprobaron en el XML de `RLMud_Config`. [Paquete oficial en el manual de RhomScripts](usuario/README.md#arranque-con-el-paquete-oficial-de-reinos)

La descripción textual del personaje incluía su condición religiosa. En esta instantánea no apareció un campo de deidad o religión en `Char`.

`Client`, `Comm`, `Core`, `External` y `Room` aparecen como ramas independientes de `Char`. Se incluyen para documentar la forma del volcado general.

## Plantilla sintética

```lua
{
  Char = {
    Ficha = {
      clase = "clase_ejemplo",
      especializacion = "especializacion_ejemplo",
      genero = 2,
      nivel = 35,
      nivel_oficio = 4,
      nombre = "Personaje",
      nombre_completo = "Personaje de Ejemplo",
      oficio = "oficio_ejemplo",
      raza = "raza_ejemplo"
    },
    Stats = {
      car = 13,
      con = 16,
      con_origen = 14,
      des = 12,
      fue = 18,
      fue_extrema = 42,
      int = 15,
      sab = 11
    },
    Status = {
      Estados = {
        set = {}
      },
      escudo = { max = 60, min = 45 },
      pe = { max = 240, min = 180 },
      pvs = { max = 500, min = 430 },
      xp = { max = 12000, min = 3500 },
      xp_oficio = { max = 150, min = 30 }
    }
  },
  Client = {
    GUI = {
      url = "https://example.invalid/RLMud_Config.zip",
      version = "1700000000"
    }
  },
  Comm = {
    Canales = {
      canal_ejemplo_1 = "canal_ejemplo_1",
      canal_ejemplo_2 = "canal_ejemplo_2",
      chat = "chat",
      consulta = "consulta",
      canal_ejemplo_3 = "canal_ejemplo_3",
      canal_ejemplo_4 = "canal_ejemplo_4",
      novato = "novato",
      rol = "rol"
    }
  },
  Core = {
    Hello = {}
  },
  External = {
    Discord = {
      Info = {
        applicationid = "123456789012345678",
        inviteurl = "https://example.invalid/invitacion"
      },
      Status = {
        details = "example.invalid",
        game = "Reinos de Leyenda",
        largeimagetext = "Texto de ejemplo",
        smallimage = { "icono_ejemplo", "raza_ejemplo" },
        smallimagetext = "Descripción de ejemplo",
        starttime = 1700000000,
        state = "Actividad de ejemplo"
      }
    }
  },
  Room = {
    Actual = "Lugar de ejemplo: Sala de prueba [n]"
  }
}
```

Al incorporar otra observación, registrar la ruta completa y el tipo de cada campo añadido, así como qué actividad hizo aparecer el paquete si se conoce. Usar datos sintéticos también en futuras muestras.
