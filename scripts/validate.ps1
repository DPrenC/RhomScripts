[CmdletBinding()]
param([switch]$SkipGit, [switch]$Mudlet, [string]$MudletExe)
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$PythonPath = Join-Path $RepoRoot '.tools/venv/Scripts/python.exe'
$Arguments = @((Join-Path $PSScriptRoot 'validation.py'))
if ($SkipGit) { $Arguments += '--skip-git' }
if ($Mudlet) {
  $Arguments += '--mudlet'
  if ($MudletExe) { $Arguments += @('--mudlet-exe', $MudletExe) }
}
& $PythonPath @Arguments
if ($LASTEXITCODE -ne 0) { throw 'La validación ha fallado. Revisa el resultado indicado arriba.' }
