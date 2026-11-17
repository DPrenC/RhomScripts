# Debug y consultas de diagnóstico

## Un modo compartido

«Modo debug» se encuentra en Interfaz, junto a Ventanas flotantes, dentro del configurador abierto con Ctrl+Mayús+C. Es el mismo modo que utilizan los scripts oficiales: activar o desactivar la opción oficial cambia inmediatamente el filtro de mensajes de RhomScripts. No hay una segunda preferencia de debug en `config.json`.

Modificar el configurador cambia su borrador. Guardar escribe las preferencias propias y después aplica el modo compartido al paquete oficial; Cancelar descarta la edición pendiente. Un cambio oficial realizado mientras el configurador está abierto se respeta si el usuario no ha editado expresamente ese campo. Restablecer predeterminados propone desactivar debug y requiere Guardar para aplicarlo.

La persistencia del modo corresponde al paquete oficial. Mientras sus opciones no estén disponibles, RhomScripts considera debug desactivado. La depuración MSP permanece en la rama del paquete oficial como filtro específico: requiere también el modo general.

## Mensajes automáticos

Con debug desactivado, una carga normal emite dos hitos propios: «RhomScripts · Cargando…» y «RhomScripts · Carga correcta.». El nombre usa color y formato, pero toda la información está expresada en palabras y se anuncia al lector. No hay animaciones ni porcentajes de progreso.

Con debug activado se añaden los detalles de preparación, estados, módulos y catálogo, identificados por su origen. Los mensajes se registran también mientras debug está desactivado. Activarlo no reproduce automáticamente los mensajes anteriores.

Los errores reales siguen avisándose y se propagan aunque debug esté desactivado. Un catálogo incompleto o inaccesible produce una advertencia y «Carga con avisos»; los detalles se consultan mediante los comandos de diagnóstico. Estar desconectado o esperar datos GMCP no significa que la carga local haya fallado.

Las lecturas, copias, ayuda de teclado, datos del personaje y confirmaciones del configurador son interacción funcional: siguen disponibles con debug desactivado. Los mensajes propios del paquete oficial conservan su mecanismo de presentación y su filtro de depuración; RhomScripts comparte ese filtro sin interceptar la salida general de Mudlet.

## Comandos

Las consultas explícitas funcionan con debug activado o desactivado. `rhomscripts` muestra la ayuda y el modo compartido actual.

- `rhomscripts estado [filtro]`: estados de carga, paquete, preferencias, conexión, GMCP y servicios, incluidos avisos. Sin filtro muestra y anuncia el resumen.
- `rhomscripts modulos [modulo]`: módulos funcionales y de soporte, resultado de carga, dependencias y error, si existe. Incluye cantidades calculadas del registro.
- `rhomscripts keys [modulo]`: teclas registradas, descripción, grupo, combinación declarada, código efectivo, modificadores e identificador.
- `rhomscripts alias [modulo]`: aliases registrados, uso, descripción, patrón PCRE, acción e identificador.
- `rhomscripts triggers [modulo]`: triggers registrados, propósito, patrón PCRE, acción e identificador.
- `rhomscripts sonidos [grupo]`: catálogo de sonidos, archivos relativos, disponibilidad e incidencias.
- `rhomscripts mensajes [modulo]`: últimos mensajes de esta carga, en orden cronológico, con origen e instante.
- `rhomscripts version`: muestra y anuncia la versión de la distribución y su fecha: `1.0, 17/11/2026`. El dato se mantiene en `debug.lua` y también se utiliza en el evento de carga correcta.

Los corchetes indican un argumento opcional y no se escriben. El filtro debe coincidir con el nombre del módulo; en sonidos también puede ser el grupo del catálogo y en estado puede ser el componente. Por ejemplo: `rhomscripts keys lector`, `rhomscripts triggers comunicaciones`, `rhomscripts sonidos ui` y `rhomscripts estado gmcp`.

La única familia de consultas es `rhomscripts`; se han retirado `rhomdebug`, `estado`, `rhomestado` y todos los accesos `list…`. Los listados se agrupan mediante encabezados de módulo y campos textuales por recurso, sin columnas alineadas.

## Estado e historial

El estado actual permanece en memoria y se puede consultar aunque sus cambios no se hayan mostrado automáticamente. Cada entrada conserva código, detalle, instante y causa. Las consultas programáticas devuelven copias. Repetir un estado idéntico no genera otra transición.

El historial conserva como máximo 500 mensajes en memoria, sin archivo de registro. Cuando se alcanza el límite se sustituye el mensaje más antiguo. Recargar los scripts vacía el historial y reconstruye el estado actual; no conserva mensajes de la carga anterior. Los comandos se preparan antes de la espera oficial para permitir consultar una espera o un fallo posterior.

Las listas muestran recursos gestionados por RhomScripts y el estado de su integración oficial; no enumeran todos los registros internos del paquete oficial. Un archivo de sonido disponible está catalogado y es accesible: esto no confirma que esté decodificado ni reproduciéndose. Los grupos del catálogo no equivalen a un único módulo consumidor.

La entrada «pendiente» de un módulo no alcanzado durante una carga fallida no significa que ese módulo haya fallado por sí mismo. Consulte el error del módulo o dependencia que detuvo la secuencia.

El [plan de implementación](../planes/debug.md) conserva el contrato técnico. Los resultados y límites de las pruebas se registran en [validación del debug centralizado](../validacion.md#debug-centralizado).
