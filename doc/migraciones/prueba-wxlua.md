# Prueba mínima de wxLua en Mudlet

## Alcance autorizado

Prueba local en Windows de una ventana con una lista de cinco elementos, «Elemento 1» a «Elemento 5», y botones «Aceptar» y «Cancelar». Los botones solo cierran la ventana. No se conecta con el configurador, las listas del juego, guardado, comandos ni voz propia. La autorización incluye instalar las DLL necesarias en RhomScripts; no incluye modificar o recompilar Mudlet.

## Objetivo y procedencia

Consulta documental: 7 de noviembre de 2026. La API oficial de releases sigue identificando [Mudlet 5.1.1](https://github.com/Mudlet/Mudlet/releases/tag/Mudlet-5.1.1) como última versión estable. Esto fija el objetivo; la ejecución y versión observadas deben registrarse por separado.

El proyecto mantenido es [pkulchenko/wxlua](https://github.com/pkulchenko/wxlua). Última etiqueta encontrada en su API de tags: `v3.2.0.2`, commit `5501947ebe1134d6b11ff6efac3df10e35b47364`. El HEAD consultado fue `d80dddbd78a1f93ea5f40e163f6d246da28a65ed`. No hay releases de binarios publicadas en su página GitHub de releases.

Se inspeccionó el árbol oficial de [ZeroBraneStudio](https://github.com/pkulchenko/ZeroBraneStudio), del mismo mantenedor. Contiene `bin/clibs/wx.dll`; no se encontró `bin/clibs64` en el árbol consultado. Su presencia no certifica arquitectura de 64 bits ni compatibilidad con Mudlet; no debe copiarse como si ya estuviera validada. Las compilaciones, descargas concretas y hashes elegidos por el constructor deben quedar en el manifiesto de distribución. Esta revisión documental no descargó ni ejecutó DLL.

## Carga del módulo

`package.loadlib(rutaAbsoluta, "luaopen_wx")` carga la biblioteca y obtiene la función de entrada compatible con Lua. La biblioteca debe estar compilada para la arquitectura y ABI de Lua de Mudlet. La mera coincidencia del nombre `wx.dll` no demuestra compatibilidad. [Manual Lua 5.1](https://www.lua.org/manual/5.1/manual.html#pdf-package.loadlib).

En [luamodule.cpp](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/modules/luamodule/luamodule.cpp), `luaopen_wx(lua_State *L)` llama a `wxEntryStart`, ejecuta `CallOnInit`, abre los bindings sobre el estado Lua recibido y devuelve una tabla, que es también el global `wx`. En éxito devuelve un resultado Lua; algunas rutas de error internas retornan cero resultados y escriben diagnóstico. El cargador de RhomScripts debe exigir que el resultado tenga el contrato esperado y propagar los errores, no sustituirlo por una implementación vacía.

El fuente conserva `s_wxlState` como estado estático del módulo. La carga debe hacerse una vez por estado de prueba y conservar `package.loaded.wx`; una recarga de los scripts de demostración no debe llamar otra vez a `luaopen_wx` ni intentar descargar manualmente la DLL. La coexistencia de varios perfiles, que tienen estados Lua distintos, no queda validada por esta prueba de un solo perfil.

## Contratos de ventana y controles

Firmas verificadas en los [bindings oficiales de diálogos](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_dialogs.i), [controles](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_controls.i), [ventanas](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_windows.i) y [organizadores](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_sizer.i). Estos archivos no documentan una mínima individual de wxLua para cada constructor; las firmas existen en el HEAD citado.

- `wx.wxDialog(parent, id, title, pos=wx.wxDefaultPosition, size=wx.wxDefaultSize, style=wx.wxDEFAULT_DIALOG_STYLE, name="wxDialog")` devuelve el objeto de diálogo. `wx.NULL` crea una ventana superior sin padre wx.
- `wx.wxListBox(parent, id, pos=wx.wxDefaultPosition, size=wx.wxDefaultSize, choices, style=0, validator=wx.wxDefaultValidator, name="wxListBox")` devuelve una lista; `choices` admite la secuencia de cadenas que se traduce a `wxArrayString`. `wx.wxLB_SINGLE` solicita selección única.
- `lista:SetSelection(indice, select=true)` cambia la selección, con índice desde cero. No devuelve valor. `lista:SetFocus()` asigna el foco y no devuelve valor. El orden de Tab y la entrega física de flechas deben comprobarse en la ejecución real.
- `wx.wxButton(parent, id, label, pos=wx.wxDefaultPosition, size=wx.wxDefaultSize, style=0, validator=wx.wxDefaultValidator, name="wxButton")` devuelve el botón. `boton:SetDefault()` no devuelve valor. Los identificadores `wx.wxID_OK` y `wx.wxID_CANCEL` permiten el cierre estándar del diálogo.
- `wx.wxBoxSizer(orient)` crea el organizador. `sizer:Add(windowOrSizer, proportion=0, flag=0, border=0)` devuelve `wxSizerItem`. `dialogo:SetSizerAndFit(sizer, deleteOld=true)` no devuelve valor.
- `dialogo:ShowModal()` devuelve un entero de resultado al terminar. `dialogo:EndModal(codigo)` fija el retorno y oculta el diálogo; no devuelve valor. `dialogo:Destroy()` devuelve un booleano e inicia la retirada del objeto.
- Los eventos `wx.wxEVT_COMMAND_BUTTON_CLICKED` y `wx.wxEVT_CLOSE_WINDOW`, conectados mediante `objeto:Connect(...)`, aparecen en el [ejemplo oficial de diálogo](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/samples/dialog.wx.lua).

## Bucle de eventos y convivencia con Qt

El nombre del accessor es `wx.wxGetApp()`, no `wx.GetApp()`. Los [bindings de aplicación](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/bindings/wxwidgets/wxcore_appframe.i) exponen, para wxWidgets desde 3.0: `app:MainLoop() -> int`, `app:Yield(onlyIfNeeded=false) -> bool`, `app:ProcessPendingEvents() -> void`, y `app:ExitMainLoop() -> void`.

El [manual wxLua](https://github.com/pkulchenko/wxlua/blob/d80dddbd78a1f93ea5f40e163f6d246da28a65ed/wxLua/docs/wxlua.md), sección «How to Run the Samples», advierte que `MainLoop()` retiene el control de Lua hasta cerrar las ventanas. No debe adoptarse como si fuera una función que retorna inmediatamente a Mudlet.

Como opción no modal, `Show(true)` junto a llamadas acotadas a `app:Yield(true)` puede procesar eventos. En [wxWidgets 3.2.6 appbase.cpp](https://github.com/wxWidgets/wxWidgets/blob/v3.2.6/src/common/appbase.cpp), `Yield` usa el bucle activo y, si no existe, crea un bucle temporal. Debe impedirse reentrada al bombear desde temporizadores Lua. Esto no demuestra que el Tab del sistema de diálogo reciba todos los mensajes si Qt los filtra antes; hace falta prueba física.

Como opción modal, [wxDialog::ShowModal](https://github.com/wxWidgets/wxWidgets/blob/v3.2.6/src/msw/dialog.cpp) crea su bucle modal, muestra el diálogo, ejecuta `RunLoop()` y devuelve el resultado al cerrarse. `EndModal` conserva el código y oculta la ventana. Este bucle puede despachar mensajes de otras ventanas de Windows, pero no se debe inferir sin prueba que todos los temporizadores, sockets y eventos de Qt continúen funcionando. La prueba debe programar una señal periódica de Mudlet y comprobar que progresa mientras la ventana está abierta. La llamada Lua queda dentro de `ShowModal` hasta el cierre.

## Criterios de la prueba

La carga debe producir una tabla wx real y abrir controles reales, sin stubs. La lista debe presentar exactamente cinco cadenas y recibir el foco inicial; Arriba/Abajo deben cambiar la selección. Tab debe llegar a Aceptar y Cancelar. Ambos botones y el cierre de ventana deben permitir salir y después abrir de nuevo la demostración. Una prueba de lectura periódica debe distinguir bloqueo de Lua de progreso real del procesamiento de Qt mientras el diálogo esté abierto.

La carga y los métodos invocados no bastan para certificar interacción física o accesibilidad con el lector externo. Registrar separadamente arquitectura PE, dependencias, hashes, versión de wxLua/wxWidgets, versión real de Mudlet, carga, eventos, observación del árbol accesible, pulsaciones físicas, cierre y límites pendientes. Esta ficha aporta los contratos documentales; los resultados de ejecución corresponden al coordinador.

## Implementación y biblioteca instalada

`rhomscripts/prueba_wxlua.lua` añade el alias `pruebawx`, con carga diferida de la biblioteca. Usa `wxDialog:ShowModal()` y los identificadores estándar `wxID_OK` y `wxID_CANCEL`; ambos botones solo terminan el diálogo. Conserva el módulo en `package.loaded.wx`, destruye el diálogo al regresar y ejecuta `wxGetApp():Yield(true)` para procesar la destrucción diferida. `init.lua` registra el nuevo módulo y solicita cerrar su ventana antes de sustituirlo durante una recarga. No se ha cambiado el panel anterior ni se han conectado compras, configuración o persistencia a esta prueba.

La DLL está en `rhomscripts/lib/windows-x64/wxlua/wx.dll`: PE AMD64, 14.465.024 bytes, SHA-256 `da7cb982a7ad80a2b8d81b13c843f568b52668f8bcd11590f1301b7ba2767449`. Exporta `luaopen_wx`. Importa `lua51.dll` y bibliotecas Win32/UCRT del sistema; no requiere otra DLL Lua ni runtimes adicionales de LLVM/MinGW. No se ha modificado la instalación de Mudlet. Licencias y procedencia completa, incluidos hashes de las fuentes y herramientas, acompañan a la biblioteca en `licenses/` y `manifest.json`.

Compilación: wxLua commit `d80dddbd78a1f93ea5f40e163f6d246da28a65ed`, bindings core/base, wxWidgets 3.2.8 estático, Unicode y `wxUSE_ACCESSIBILITY=ON`, LLVM-MinGW 20261104 UCRT x64. Se generó la biblioteca de importación desde las exportaciones de la `lua51.dll` real de Mudlet y se usaron cabeceras Lua 5.1.5. No se empaqueta ni reemplaza el intérprete. La reproducción se realiza con `.\.tools\venv\Scripts\python.exe scripts/setup_wxlua.py`; admite `--lua-dll` explícito y, en su ausencia, consulta la última versión estable oficial de Mudlet.

## Resultados, 7 de noviembre de 2026

`scripts/validate.ps1` pasó sus nueve controles locales tras añadir el módulo y los ejecutores: compilación Lua 5.1/LuaJIT, Luacheck sin avisos, casos de comportamiento y PCRE2, documentación, política de APIs, empaquetado aislado y diff. La DLL no se simula en esos casos: la integración nativa se comprueba aparte.

La ejecución general `scripts/validate.ps1 -Mudlet` también pasó con 77 casos por runtime local y 65 casos en Mudlet real; evidencia `.tools/mudlet-integration/runs/523e2e2ae71b426ba2c1872533ba195a/result.txt`. Registra 132 teclas, 57 alias y 610 triggers tras recargar; la nueva demostración no carga wx en el arranque.

`scripts/run_wxlua_probe.py --timeout 45` terminó con `STATUS OK` en Mudlet 5.1.1, última estable consultada por el ejecutor, Lua 5.1 y wxWidgets 3.2.8. Evidencia local: `.tools/wxlua-probe/runs/e4652d46892440a7b2399d6299cb1ded/result.txt` y su diario `.progress`. Verificó cinco textos exactos, selección inicial, foco nativo en «Elementos», cambio de selección mediante API, cierres por Aceptar, Cancelar y X, reapertura y recarga Lua conservando el módulo nativo. Las ventanas dejaron de encontrarse tras Destroy/Yield. El heartbeat de temporizadores reales de Mudlet avanzó 31 veces, también dentro de cada ShowModal; esto demuestra progreso de esos temporizadores, no equivalencia completa de todos los subsistemas conectados al juego.

Para identificar el foco, `wxWindow.FindFocus()` devuelve un wrapper de tipo wxWindow que puede ser un userdata Lua diferente al wrapper wxListBox del mismo control. La prueba compara sus identificadores nativos mediante `GetId()`, no identidad de userdata.

La ejecución interactiva `.tools/wxlua-probe/runs/01c6010519d24a6f820a5a7563681cf1/result.txt` también terminó con `STATUS OK`, resultado Aceptar (5100) y 361 pulsos Qt. El usuario comprobó manualmente esta ventana y comunicó que funciona correctamente. Su comprobación no especifica un desglose por tecla o por lector/versiones; no se presenta como una matriz exhaustiva de accesibilidad.

El árbol accesible de Windows expuso un diálogo, una lista «Elementos» con los cinco elementos y botones «Aceptar» y «Cancelar». La captura gráfica del agente falló con `FrameArrived timed out`; su intento de envío de Tab falló con `foreground window did not report a process id`. Por tanto las pulsaciones de escritorio no se atribuyen a la automatización: se distingue la observación del árbol, los callbacks de prueba y la comprobación manual del usuario. No se consultó ni modificó el portapapeles y todos los perfiles de ensayo fueron aislados y sin servidor.

Esta entrega solo acredita el prototipo solicitado. No valida uso simultáneo desde varios perfiles, ventanas no modales, controles embebidos dentro de Geyser, instalador público ni interacción con datos del servidor. No se han añadido políticas de voz ni SAPI.
