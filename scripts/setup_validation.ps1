[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$EnvironmentPath = Join-Path $RepoRoot '.tools/venv'
$PythonPath = Join-Path $EnvironmentPath 'Scripts/python.exe'
if (-not (Test-Path -LiteralPath $PythonPath)) {
  & python -m venv $EnvironmentPath
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el entorno Python.' }
}
& $PythonPath -m pip install --disable-pip-version-check -r (Join-Path $PSScriptRoot 'requirements-validation.txt')
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las herramientas de validación.' }
& $PythonPath (Join-Path $PSScriptRoot 'validation.py') --install-luacheck
if ($LASTEXITCODE -ne 0) { throw 'No se pudo preparar Luacheck.' }
& $PythonPath (Join-Path $PSScriptRoot 'validation.py') --install-java
if ($LASTEXITCODE -ne 0) { throw 'No se pudo preparar Java para Muddler.' }
Write-Output 'Herramientas preparadas. Ejecuta: .\scripts\validate.ps1'
