[CmdletBinding()]
param()
$HasFailures = $false
foreach ($ScriptFile in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File) {
  $ParseTokens = $null
  $ParseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile.FullName, [ref]$ParseTokens, [ref]$ParseErrors) | Out-Null
  foreach ($ParseError in $ParseErrors) {
    Write-Output "$($ScriptFile.Name):$($ParseError.Extent.StartLineNumber): $($ParseError.Message)"
    $HasFailures = $true
  }
}
if ($HasFailures) { exit 1 }
Write-Output 'Sintaxis PowerShell correcta.'
