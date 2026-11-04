param([string]$ToolDirectory = '')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
function Invoke-Check([string]$Name, [string[]]$ToolArguments) {
    $toolPath = if ($ToolDirectory) { Join-Path $ToolDirectory ($Name + '.exe') } else { $Name }
    & $toolPath @ToolArguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit code $LASTEXITCODE" }
}
Invoke-Check 'luau' @('tests/domain.spec.luau')
Invoke-Check 'luau' @('tests/persistence.spec.luau')
Invoke-Check 'luau' @('tests/latency.spec.luau')
Invoke-Check 'luau' @('tests/presentation.spec.luau')
Invoke-Check 'luau-analyze' @('src/shared', 'src/server/Persistence.luau', 'tests/domain.spec.luau', 'tests/persistence.spec.luau', 'tests/latency.spec.luau', 'tests/presentation.spec.luau')
Invoke-Check 'stylua' @('--check', 'src', 'tests')
Get-ChildItem src,tests -Recurse -Filter '*.luau' | ForEach-Object {
    Invoke-Check 'luau-compile' @('--null', $_.FullName)
}
New-Item -ItemType Directory -Path build -Force | Out-Null
Invoke-Check 'rojo' @('build', 'default.project.json', '-o', 'build/StreamerLife.rbxlx')
Invoke-Check 'rojo' @('build', 'tests/studio.project.json', '-o', 'build/StreamerLife-QA.rbxlx')
Invoke-Check 'rojo' @('build', 'tests/m4.project.json', '-o', 'build/StreamerLife-M4.rbxlx')
Invoke-Check 'rojo' @('build', 'tests/latency.project.json', '-o', 'build/StreamerLife-Latency.rbxlx')
Invoke-Check 'rojo' @('build', 'tests/manual.project.json', '-o', 'build/StreamerLife-Manual.rbxlx')

Invoke-Check 'rojo' @('build', 'tests/visual.project.json', '-o', 'build/Visual-After.rbxlx')
