[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$PythonPath = Join-Path $RepoRoot '.tools/venv/Scripts/python.exe'
& $PythonPath (Join-Path $PSScriptRoot 'download_mudlet_docs.py')
if ($LASTEXITCODE -ne 0) { throw 'Descarga incompleta de documentación. Revisa los errores y repite.' }
