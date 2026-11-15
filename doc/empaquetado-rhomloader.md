# Empaquetado y uso de RhomLoader

RhomLoader es un paquete de Mudlet que carga los scripts Lua de `rhomscripts` desde una carpeta externa. El paquete necesita incluir la ruta absoluta local de la carpeta que contiene `init.lua`.

Esa ruta es distinta para cada usuario, por lo que el paquete generado no debe sincronizarse con el repositorio.

## Empaquetado automatico

Preparar las herramientas con `scripts/setup_validation.ps1`. El empaquetador utiliza Java del entorno o la instalación portátil de `.tools/java`, sin cambiar permanentemente JAVA_HOME ni PATH. Este paquete es un cargador de desarrollo; los scripts Lua y sonidos continúan en disco y no constituyen una distribución final autocontenida.

Desde la raiz del repositorio:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_rhomloader.ps1
```

Por defecto el script usa `rhomscripts\init.lua`. Si quieres indicar otra carpeta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_rhomloader.ps1 -ScriptsPath "C:\ruta\a\rhomscripts"
```

Tambien puedes pasar directamente el archivo `init.lua`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\package_rhomloader.ps1 -ScriptsPath "C:\ruta\a\rhomscripts\init.lua"
```

El script hace lo siguiente:

1. Localiza la carpeta que contiene `init.lua`.
2. Copia los fuentes y el manifiesto a un directorio temporal propio de la ejecución e inserta la ruta en esa copia.
3. Ejecuta Muddler y comprueba el XML generado.
4. Escribe y cierra el ZIP antes de sustituir `RhomLoader/build/rhomloader.mpackage`. Dos ejecuciones pueden preparar sus paquetes en paralelo. La última sustitución correcta determina el paquete disponible en esa ruta.
5. Elimina los temporales y devuelve la ruta completa del paquete y el comando de instalación. Los fuentes del repositorio se conservan incluso si Muddler falla.

## Instalacion en Mudlet

Abre el perfil de Mudlet que quieras usar y pega el comando que te haya devuelto el empaquetador. No es necesario conectar al juego. Para pruebas, usa un perfil aislado. El comando tiene esta forma:

```text
lua installPackage("C:/ruta/completa/al/paquete/rhomloader.mpackage")
```

Usa siempre la ruta completa del paquete generado y escribe la ruta con `/`, no con `\`. No copies el ejemplo anterior literalmente si tu ruta es distinta.

Si el perfil tenía cargada la versión antigua sin identificadores de registros, esta actualización requiere cerrarlo y reabrirlo una vez. init.lua lo indica mediante un error antes de registrar nada. Después, las recargas con rl retiran los registros anteriores correctamente.

Tras instalarlo, RhomLoader intentara cargar `rhomscripts` automaticamente. Para recargar los scripts durante desarrollo, usa el alias:

```text
rl
```

## Empaquetado manual

Si prefieres hacerlo a mano, copia primero `RhomLoader` a un directorio local fuera del repositorio y realiza los pasos sobre esa copia:

1. Abre `RhomLoader/src/scripts/rhomloader/code.lua`.
2. Cambia esta linea:

```lua
local BASE_PATH = "PONER_RUTA_AQUI" -- PONER RUTA AQUI
```

por la ruta absoluta de la carpeta que contiene `init.lua`, usando barras `/` y terminando en `/`:

```lua
local BASE_PATH = "C:/ruta/a/rhomscripts/" -- RUTA LOCAL PARA EMPAQUETADO
```

3. Ejecuta Muddler desde `RhomLoader`:

```powershell
cd .\RhomLoader
& "C:\ruta\al\repositorio\muddler\bin\muddle.bat"
```

4. Instala el paquete generado en Mudlet:

```text
lua installPackage("C:/ruta/completa/RhomLoader/build/rhomloader.mpackage")
```

5. Retira la copia temporal cuando termines de usar el paquete.

## Seguridad de rutas locales

`RhomLoader/build/` y los archivos `.mpackage` estan ignorados por Git. No deben subirse al repositorio porque contienen rutas locales de cada usuario.

Si Git ya seguía artefactos antes de añadir la regla de exclusión, seguirán apareciendo. Resolver su retirada del índice como tarea explícita. Las pruebas de `scripts/validate.ps1` verifican la integridad de los fuentes, la salida concurrente y la conservación del paquete anterior tras un fallo. Al compartir evidencia, usar rutas relativas y datos sintéticos en lugar de copiar el comando de instalación o los registros brutos.
