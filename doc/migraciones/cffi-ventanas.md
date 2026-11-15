# cffi-lua: prueba de ventanas asociadas a Mudlet

Fecha: 7 de noviembre de 2026, ampliada el 8 de noviembre. Estado: dependencia instalada, ensayo optativo y asociación integrada en el constructor común. Conserva wxLua como biblioteca de controles.

## Uso

La demostración está archivada y su alias no se registra en el arranque actual. Para ejecutarla en un perfil aislado, utilizar el sondeo descrito más abajo con `--interactive`. Abre «RhomScripts. Prueba de asociación.», con cinco elementos y botones Vincular, Desvincular y Cerrar. Escape cierra. Su asociación inicial depende de «Interfaz → Ventanas flotantes», activada por defecto. Vincular y Desvincular permiten comparar la relación sin cambiar preferencias ni enviar órdenes al juego.

Vincular asigna una ventana propietaria de Windows; no incrusta controles en Qt, no acopla el diálogo a un borde, no sincroniza movimientos ni crea un atajo para alternar el foco. No se usa el estilo global siempre encima. El diálogo conserva el bucle wx de la demostración anterior: esta prueba no implementa una nueva política de modalidad para Qt.

## Dependencia instalada

`rhomscripts/lib/windows-x64/cffi/cffi.dll`: cffi-lua 0.2.4, Windows AMD64, compatible con Lua 5.1 de Mudlet. Tamaño: 313344 bytes. SHA-256: `f937d2c52af7b2ca4c85ef9585d98266cd1d3f71af94d55541c1b327e374f8bd`.

Se distribuyen su manifiesto y licencias. libffi se enlaza estáticamente. Las importaciones son únicamente `lua51.dll`, KERNEL32 y bibliotecas UCRT del sistema: no se incorpora otro Lua ni se sustituye el instalado. Desde la reorganización del 8 de noviembre, cffi.dll y wxLua se cargan obligatoriamente en las comprobaciones previas del arranque.

Fuentes fijadas: cffi-lua commit `1d6d54b4068eefc6dc4c4455175b6d0e530fa72a`, correspondiente a v0.2.4; libffi Meson commit `41fc1ec58b987922d66bdc7a7531d3a1b34b3983`, snapshot 3.4.4 del fork utilizado por el wrap upstream. Los archivos descargados se comprueban por SHA-256 antes de extraer. [Proyecto cffi-lua](https://github.com/q66/cffi-lua/tree/v0.2.4), [compilación oficial](https://github.com/q66/cffi-lua/blob/v0.2.4/README.md).

## Reproducción de la compilación

Preparar el entorno de validación y las herramientas de wxLua existentes mediante `scripts/setup_validation.ps1` y `scripts/setup_wxlua.py`. Después ejecutar `.\.tools\venv\Scripts\python.exe scripts/setup_cffi.py`. El script admite `--lua-dll` para una DLL real explícita y, por defecto, consulta la última release estable de Mudlet. No modifica el cliente, el PATH del sistema ni el índice Git.

Utiliza LLVM-MinGW 20261104 UCRT x64, Meson 1.12.1, Ninja 1.13.2 y pefile 2024.8.26. Las cabeceras son Lua 5.1.5, incluido `lua.hpp` distribuido en `etc/`; la biblioteca de importación se genera desde la DLL Lua real. Se compilan los fuentes oficiales sin parches de funcionalidad. Fuentes, herramientas y logs quedan en `.tools/cffi-build` y `.tools/wxlua-build`; solo la biblioteca, licencias y procedencia se instalan junto a los scripts. Dos compilaciones de esta revisión produjeron el mismo SHA-256.

## Encaje de los módulos

`arranque.lua` carga cffi-lua y declara las funciones Win32 utilizadas durante el arranque. Las operaciones sobre ventanas residen en `ui.nativo`, dentro de `ui.lua`. Conserva `package.loaded.cffi` y el runtime `package.loaded.rhom_nativo_runtime` entre recargas para no repetir declaraciones. La fachada Lua puede recargarse. No se llama a funciones desconocidas ni se sustituyen por alternativas silenciosas.

`ui.lua` aplica la preferencia confirmada `ventanasflotantes` al construir ventanas. Con true identifica Mudlet y asocia el diálogo; con false crea una ventana independiente. `wxDIALOG_NO_PARENT` impide que wx asigne una propietaria implícita cuando no se quiere asociación. Si la asociación falla tras crear el diálogo, lo destruye y relanza el error. `prueba_cffi.lua` y `prueba_wxlua.lua` utilizan este mismo constructor; los botones Vincular/Desvincular solo modifican la ventana de prueba actual. Los sondeos cargan las demostraciones archivadas explícitamente; `init.lua` conserva la limpieza de sesiones anteriores, sin registrar esos aliases.

La opción vive en el JSON de RhomScripts, no en el paquete oficial. Se edita como booleano circular en el borrador; Guardar confirma y Cancelar descarta. Afecta a aperturas posteriores, sin cambiar la ventana que está editando la opción. Los JSON 1/2 anteriores sin el campo nuevo se amplían con true sin perder preferencias. Un false existente se conserva. El formato permanece en versión 2 y la validación de los demás campos sigue siendo estricta.

Operaciones disponibles en la fachada: `cargar()` devuelve ffi/User32/Kernel32; `handle(ventanaWx)` valida y devuelve su HWND; `ventanas()` enumera los HWND de este proceso; `mudlet()` identifica su ventana Qt; `propietario(ventanaWx)` consulta GW_OWNER; `asociar(ventanaWx, hwnd)` asigna propietario y devuelve el anterior. `nil` o `ffi.nullptr` desasocian. Una asociación idéntica se trata como operación sin cambios.

Se rechazan ventanas ajenas al proceso, controles hijos como ventanas superiores, autoasociación y ciclos. La identificación de Mudlet utiliza la raíz propietaria de la ventana activa de este hilo; si no es una raíz Qt propia, busca una única raíz Qt visible y sin propietario entre las ventanas del proceso. No selecciona por título ni actúa sobre otra instancia de Mudlet. El filtro de clase Qt es un criterio de identificación local, no una API estable prometida por Qt; si resulta ambiguo, la operación falla y pide activar Mudlet.

## Contratos verificados

El override wxLua de `wxWindow:GetHandle()` llama a `lua_pushlightuserdata`, y cffi admite su conversión directa a un tipo puntero. Los HWND se mantienen como cdata, sin transportarlos mediante números Lua. [Override wxLua](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_override.hpp), [semántica cffi](https://github.com/q66/cffi-lua/blob/v0.2.4/docs/semantics.md).

`cffi.cdef`, `load`, `cast`, `new`, `sizeof`, `tonumber`, `nullptr` y callbacks con `free()` están documentados por el proyecto. Las declaraciones se registran una sola vez. [API cffi 0.2.4](https://github.com/q66/cffi-lua/blob/v0.2.4/docs/api.md).

`SetWindowLongPtrW(HWND,int,LONG_PTR)` cambia GWLP_HWNDPARENT (-8), que es el propietario de una ventana superior. No es `SetParent` ni convierte el diálogo en control hijo. `GetWindow(hwnd,4)` consulta GW_OWNER. Se resuelven los símbolos y convierten los argumentos antes de limpiar LastError; un retorno cero se considera fallo únicamente si el error del hilo es distinto de cero. Después se comprueba el propietario efectivo. [SetWindowLongPtrW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw), [GetWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getwindow).

Durante la prueba, asignar NULL cuando el propietario ya era NULL produjo error 1400 también en una comprobación independiente de Win32 con una ventana oculta propia. La fachada evita escrituras redundantes por estado; no ignora errores al cambiar realmente el propietario.

`EnumWindows` enumera ventanas superiores y se filtran por PID; el callback captura errores para liberar sus recursos y después relanzarlos. `GetActiveWindow` pertenece al hilo llamante; `GetAncestor(...,GA_ROOTOWNER)` recorre propietario y padre. `GetWindowThreadProcessId`, `GetCurrentProcessId` e `IsWindow` validan pertenencia y existencia. [EnumWindows](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumwindows), [GetActiveWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getactivewindow), [GetAncestor](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getancestor).

## Validación y límites

Ejecutar `.\.tools\venv\Scripts\python.exe scripts/run_wxlua_probe.py --cffi`. Para comprobación manual aislada: añadir `--interactive --timeout 240`. El ejecutor comprueba el PE AMD64, SHA frente al manifiesto, última versión estable de Mudlet y coincidencia del PID Lua con el proceso que ha creado. Solo termina ese proceso al finalizar.

La asociación real wx/Qt y las operaciones observadas se registran en [validación](../validacion.md). Pulsaciones físicas, lectura percibida, política de Alt+Tab, sincronización de posición y coexistencia de varios perfiles permanecen separadas de lo demostrado por el sondeo. No se conecta al juego ni se toca el portapapeles o un perfil personal.

El sondeo pasó siete casos en Mudlet 5.1.1, Lua 5.1 y wxWidgets 3.2.8, con 18 pulsos Qt: `.tools/wxlua-probe/runs/a27c5f0f7a48421887cf8729df6b44f6/result.txt`. Observó botones de asociación, minimización de la ventana Qt propia que oculta la asociada y restauración que la vuelve a mostrar. La integración general también pasó 51 casos reales: `.tools/mudlet-integration/runs/60c6f6e0a3b541b89662a0f388df258a/result.txt`.
