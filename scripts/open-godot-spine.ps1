$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $repoRoot "tools/godot-spine-4.1.3/godot-4.1-4.1.3-stable.exe"
$projectDir = Join-Path $repoRoot "game"

if (-not (Test-Path -LiteralPath $godotExe -PathType Leaf)) {
    throw "Spine-enabled Godot editor not found: $godotExe"
}

& $godotExe --path $projectDir

