$ErrorActionPreference = 'Stop'

function Assert-NativeSuccess([string]$Operation) {
    if ($LASTEXITCODE -ne 0) { throw "$Operation failed (exit $LASTEXITCODE)" }
}

function Write-Utf8([string]$Path,[string]$Text) {
    [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))
}

function Get-ProjectRoot { return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')) }

function Get-WindowsBuild {
    $root = Get-ProjectRoot
    $manifest = Get-Content "$root\dist\windows\build-manifest.json" -Raw | ConvertFrom-Json
    $exe = Join-Path $root ("dist\windows\" + $manifest.Binary)
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $manifest.BinarySHA256) { throw 'Binary checksum mismatch' }
    return [pscustomobject]@{Manifest=$manifest;Executable=$exe}
}
