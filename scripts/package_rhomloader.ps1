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
  return [regex]::new($BasePathPattern).Replace($Content, $Replacement, 1)
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
$OriginalJavaHome = $env:JAVA_HOME
$LocalJavaHome = $null
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
  $JavaRoot = Join-Path $RepoRoot '.tools\java'
  $JavaCandidates = @(Get-ChildItem -LiteralPath $JavaRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\java.exe') })
  if ($JavaCandidates.Count -eq 0) {
    throw 'No hay Java disponible. Ejecuta scripts\setup_validation.ps1.'
  }
  $LocalJavaHome = $JavaCandidates[0].FullName
}
$TemporaryRoot = (Resolve-Path -LiteralPath ([System.IO.Path]::GetTempPath())).Path.TrimEnd('\', '/')
$BuildId = "rhomloader-" + [System.Guid]::NewGuid().ToString("N")
$Workspace = Join-Path $TemporaryRoot $BuildId
$BuildProject = Join-Path $Workspace "RhomLoader"
$PackagePath = Join-Path $BuildPath "rhomloader.mpackage"
$StagedPackage = Join-Path $BuildPath "$BuildId.tmp"
try {
  New-Item -ItemType Directory -Path $BuildProject | Out-Null
  Copy-Item -LiteralPath (Join-Path $RhomLoaderRoot "src") -Destination $BuildProject -Recurse
  Copy-Item -LiteralPath (Join-Path $RhomLoaderRoot "muddler.yml") -Destination $BuildProject
  $BuildSource = Join-Path $BuildProject "src\scripts\rhomloader\code.lua"
  $Source = [System.IO.File]::ReadAllText($BuildSource, [System.Text.Encoding]::UTF8)
  $PackagedSource = Set-BasePathLine -Content $Source -Line $PackageBasePathLine
  [System.IO.File]::WriteAllText($BuildSource, $PackagedSource, [System.Text.Encoding]::UTF8)

  if ($LocalJavaHome) { $env:JAVA_HOME = $LocalJavaHome }
  Set-Location -LiteralPath $BuildProject
  & $MuddlePath

  if ($LASTEXITCODE -ne 0) {
    throw "Muddler termino con codigo de salida $LASTEXITCODE"
  }

  $GeneratedBuild = Join-Path $BuildProject "build"
  $PackageXmlPath = Join-Path $GeneratedBuild "rhomloader.xml"
  $ConfigPath = Join-Path $GeneratedBuild "tmp\config.lua"
  if (-not (Test-Path -LiteralPath $PackageXmlPath -PathType Leaf)) {
    throw "No se encontro el XML generado por Muddler."
  }
  if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "No se encontro config.lua generado por Muddler."
  }
  $PackageXml = [xml] [System.IO.File]::ReadAllText($PackageXmlPath)
  $LoaderScript = $PackageXml.SelectSingleNode("//Script/script")
  if (-not $LoaderScript -or -not $LoaderScript.InnerText.Contains($PackageBasePathLine)) {
    throw "El XML generado no contiene la ruta esperada del cargador."
  }

  # Crear el ZIP en el volumen de destino permite sustituirlo atomicamente.
  New-Item -ItemType Directory -Force -Path $BuildPath | Out-Null
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $Zip = [System.IO.Compression.ZipFile]::Open($StagedPackage, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $ConfigPath, "config.lua") | Out-Null
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $PackageXmlPath, "rhomloader.xml") | Out-Null
  }
  finally {
    $Zip.Dispose()
  }

  try {
    [System.IO.File]::Move($StagedPackage, $PackagePath)
  }
  catch [System.IO.IOException] {
    if (-not [System.IO.File]::Exists($PackagePath)) { throw }
    $PackageItem = Get-Item -LiteralPath $PackagePath -Force
    if ($PackageItem.IsReadOnly) { $PackageItem.IsReadOnly = $false }
    [System.IO.File]::Replace($StagedPackage, $PackagePath, [NullString]::Value)
  }
}
finally {
  if ($null -eq $OriginalJavaHome) {
    Remove-Item -LiteralPath Env:JAVA_HOME -ErrorAction SilentlyContinue
  } else {
    $env:JAVA_HOME = $OriginalJavaHome
  }
  Set-Location -LiteralPath $OriginalLocation

  if (Test-Path -LiteralPath $StagedPackage) {
    Remove-Item -LiteralPath $StagedPackage -Force
  }
  if (Test-Path -LiteralPath $Workspace) {
    $ResolvedWorkspace = (Resolve-Path -LiteralPath $Workspace).Path
    if ((Split-Path -Parent $ResolvedWorkspace) -ne $TemporaryRoot -or
        (Split-Path -Leaf $ResolvedWorkspace) -ne $BuildId) {
      throw "No se pudo verificar la ubicacion del directorio temporal."
    }
    Remove-Item -LiteralPath $ResolvedWorkspace -Recurse -Force
  }
}

$MudletPackagePath = $PackagePath -replace "\\", "/"
$MudletCommand = "lua installPackage(`"$MudletPackagePath`")"

Write-Host ""
Write-Host "RhomLoader empaquetado correctamente."
Write-Host "Paquete generado:"
Write-Host $MudletPackagePath
Write-Host ""
Write-Host "En Mudlet, abre el perfil que quieras usar y pega este comando (no necesitas conectarte al juego):"
Write-Host $MudletCommand
Write-Host ""
Write-Host "Los fuentes del repositorio se han mantenido intactos."
Write-Host "El paquete queda en RhomLoader/build, carpeta ignorada por Git."
