# Empaquetado y uso de RhomLoader

RhomLoader es un paquete de Mudlet que carga los scripts Lua de `rhomscripts` desde una carpeta externa. El paquete necesita incluir la ruta absoluta local de la carpeta que contiene `init.lua`.

Esa ruta es distinta para cada usuario, por lo que el paquete generado no debe sincronizarse con el repositorio.

## Empaquetado automatico

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
2. Escribe temporalmente esa ruta en `RhomLoader/src/scripts/rhomloader/code.lua`.
3. Ejecuta Muddler para generar el paquete.
4. Devuelve la ruta completa del `.mpackage` y el comando exacto de instalacion para Mudlet.
5. Restaura `code.lua` con el marcador generico `PONER_RUTA_AQUI` para no dejar rutas personales en el repositorio.

## Instalacion en Mudlet

Abre Mudlet, conectate en el perfil que estes usando y pega el comando que te haya devuelto el empaquetador, con esta forma:

```text
lua installPackage("C:/ruta/completa/al/paquete/rhomloader.mpackage")
```

Usa siempre la ruta completa del paquete generado y escribe la ruta con `/`, no con `\`. No copies el ejemplo anterior literalmente si tu ruta es distinta.

Tras instalarlo, RhomLoader intentara cargar `rhomscripts` automaticamente. Para recargar los scripts durante desarrollo, usa el alias:

```text
rl
```

## Empaquetado manual

Si prefieres hacerlo a mano:

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
..\muddler\bin\muddle.bat
```

4. Instala el paquete generado en Mudlet:

```text
lua installPackage("C:/ruta/completa/RhomLoader/build/rhomloader.mpackage")
```

5. Vuelve a dejar `code.lua` con la ruta generica:

```lua
local BASE_PATH = "PONER_RUTA_AQUI" -- PONER RUTA AQUI
```

## Seguridad de rutas locales

`RhomLoader/build/` y los archivos `.mpackage` estan ignorados por Git. No deben subirse al repositorio porque contienen rutas locales de cada usuario.

Si alguna vez Git muestra archivos dentro de `RhomLoader/build/` como preparados para commit, sacalos del indice sin borrarlos del disco:

```powershell
git rm --cached -r RhomLoader/build
```
