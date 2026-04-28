[CmdletBinding()]
param(
  [string]$ScriptsPath
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$RhomLoaderRoot = Join-Path $RepoRoot "RhomLoader"
$LoaderCodePath = Join-Path $RhomLoaderRoot "src\scripts\rhomloader\code.lua"
$MuddlePath = Join-Path $RepoRoot "muddler\bin\muddle.bat"
$BuildPath = Join-Path $RhomLoaderRoot "build"
$BasePathPattern = '(?m)^local\s+BASE_PATH\s*=\s*".*?"\s*--.*$'
$GenericBasePathLine = 'local BASE_PATH = "PONER_RUTA_AQUI" -- PONER RUTA AQUI'

function Convert-ToLuaPath {
  param([string]$Path)

  $Resolved = (Resolve-Path -LiteralPath $Path).Path
  $LuaPath = $Resolved -replace "\\", "/"

  if (-not $LuaPath.EndsWith("/")) {
    $LuaPath = "$LuaPath/"
  }

  return $LuaPath
}

function Set-BasePathLine {
  param(
    [string]$Content,
    [string]$Line
  )

  if (-not [regex]::IsMatch($Content, $BasePathPattern)) {
    throw "No se encontro la linea local BASE_PATH en $LoaderCodePath"
  }

  $Replacement = $Line.Replace('$', '$$')
  return [regex]::Replace($Content, $BasePathPattern, $Replacement, 1)
}

function Resolve-ScriptsDirectory {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    $DefaultPath = Join-Path $RepoRoot "rhomscripts"
    if (Test-Path -LiteralPath (Join-Path $DefaultPath "init.lua")) {
      return (Resolve-Path -LiteralPath $DefaultPath).Path
    }

    $Candidates = @(Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Filter "init.lua" |
      Where-Object {
        $_.FullName -notlike (Join-Path $RepoRoot ".git\*") -and
        $_.FullName -notlike (Join-Path $RepoRoot "RhomLoader\*") -and
        $_.FullName -notlike (Join-Path $RepoRoot "scripts_vipmud\*")
      })

    if ($Candidates.Count -eq 1) {
      return $Candidates[0].DirectoryName
    }

    if ($Candidates.Count -gt 1) {
      $List = ($Candidates | ForEach-Object { "  - $($_.FullName)" }) -join [Environment]::NewLine
      throw "Hay varios init.lua posibles. Ejecuta el script con -ScriptsPath apuntando a la carpeta correcta:$([Environment]::NewLine)$List"
    }

    throw "No se encontro rhomscripts\init.lua. Ejecuta el script con -ScriptsPath apuntando a la carpeta que contiene init.lua."
  }

  $ResolvedPath = (Resolve-Path -LiteralPath $Path).Path
  if (Test-Path -LiteralPath $ResolvedPath -PathType Leaf) {
    if ((Split-Path -Leaf $ResolvedPath) -ne "init.lua") {
      throw "Si pasas un archivo, debe ser init.lua: $ResolvedPath"
    }

    return (Split-Path -Parent $ResolvedPath)
  }

  if (-not (Test-Path -LiteralPath (Join-Path $ResolvedPath "init.lua"))) {
    throw "La carpeta indicada no contiene init.lua: $ResolvedPath"
  }

  return $ResolvedPath
}

if (-not (Test-Path -LiteralPath $LoaderCodePath)) {
  throw "No existe el script de RhomLoader: $LoaderCodePath"
}

if (-not (Test-Path -LiteralPath $MuddlePath)) {
  throw "No existe Muddler en: $MuddlePath"
}

$ScriptsDirectory = Resolve-ScriptsDirectory -Path $ScriptsPath
$LuaScriptsPath = Convert-ToLuaPath -Path $ScriptsDirectory
$PackageBasePathLine = "local BASE_PATH = `"$LuaScriptsPath`" -- RUTA LOCAL PARA EMPAQUETADO"
$OriginalLocation = (Get-Location).Path
try {
  $Source = [System.IO.File]::ReadAllText($LoaderCodePath, [System.Text.Encoding]::UTF8)
  $PackagedSource = Set-BasePathLine -Content $Source -Line $PackageBasePathLine
  [System.IO.File]::WriteAllText($LoaderCodePath, $PackagedSource, [System.Text.Encoding]::UTF8)

  Set-Location -LiteralPath $RhomLoaderRoot
  & $MuddlePath

  if ($LASTEXITCODE -ne 0) {
    throw "Muddler termino con codigo de salida $LASTEXITCODE"
  }
}
finally {
  Set-Location -LiteralPath $OriginalLocation

  if (Test-Path -LiteralPath $LoaderCodePath) {
    $CurrentSource = [System.IO.File]::ReadAllText($LoaderCodePath, [System.Text.Encoding]::UTF8)
    $CleanSource = Set-BasePathLine -Content $CurrentSource -Line $GenericBasePathLine
    [System.IO.File]::WriteAllText($LoaderCodePath, $CleanSource, [System.Text.Encoding]::UTF8)
  }
}

$Package = Get-ChildItem -LiteralPath $BuildPath -Filter "*.mpackage" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Package) {
  throw "El build termino, pero no se encontro ningun .mpackage en $BuildPath"
}

$PackagePath = Join-Path $BuildPath "rhomloader.mpackage"
$PackageXmlPath = Join-Path $BuildPath "rhomloader.xml"
$ConfigPath = Join-Path $BuildPath "tmp\config.lua"
$TmpPackageXmlPath = Join-Path $BuildPath "tmp\rhomloader.xml"
$TemporaryPackagePath = Join-Path ([System.IO.Path]::GetTempPath()) ("rhomloader.repacked.{0}.zip" -f ([System.Guid]::NewGuid().ToString("N")))

if (-not (Test-Path -LiteralPath $PackageXmlPath)) {
  throw "No se encontro el XML correcto del paquete: $PackageXmlPath"
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
  throw "No se encontro config.lua para el paquete: $ConfigPath"
}

Copy-Item -LiteralPath $PackageXmlPath -Destination $TmpPackageXmlPath -Force

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Zip = [System.IO.Compression.ZipFile]::Open($TemporaryPackagePath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $ConfigPath, "config.lua") | Out-Null
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $PackageXmlPath, "rhomloader.xml") | Out-Null
}
finally {
  $Zip.Dispose()
}

if (Test-Path -LiteralPath $PackagePath) {
  $PackageItem = Get-Item -LiteralPath $PackagePath -Force
  $PackageItem.Attributes = $PackageItem.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
}

[System.IO.File]::Copy($TemporaryPackagePath, $PackagePath, $true)
Remove-Item -LiteralPath $TemporaryPackagePath -Force -ErrorAction SilentlyContinue

$MudletPackagePath = $PackagePath -replace "\\", "/"
$MudletCommand = "lua installPackage(`"$MudletPackagePath`")"

Write-Host ""
Write-Host "RhomLoader empaquetado correctamente."
Write-Host "Paquete generado:"
Write-Host $MudletPackagePath
Write-Host ""
Write-Host "En Mudlet, conectate en el perfil que estes usando y pega este comando:"
Write-Host $MudletCommand
Write-Host ""
Write-Host "La ruta local se ha retirado de RhomLoader/src/scripts/rhomloader/code.lua."
Write-Host "El paquete queda en RhomLoader/build, carpeta ignorada por Git."
