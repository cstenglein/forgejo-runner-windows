[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$')]
    [string]$Version = '13.2.0',
    [string]$GoExecutable = 'go.exe'
)
. "$PSScriptRoot\Common.ps1"
$root = Get-ProjectRoot
$output = Join-Path $root 'dist\windows'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$module = ((Get-Content "$root\go.mod" | Select-String '^module\s+').Line -split '\s+')[1]
$revision = & git.exe -C $root rev-parse HEAD
Assert-NativeSuccess 'Read source revision'
$changes = @(& git.exe -C $root status --porcelain --untracked-files=normal)
Assert-NativeSuccess 'Check source state'
$binaryName = "forgejo-runner-$Version-windows-amd64.exe"
$saved = @{}
foreach ($name in @('CGO_ENABLED','GOOS','GOARCH','GOTOOLCHAIN','GOFLAGS')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
try {
    $env:CGO_ENABLED='0'; $env:GOOS='windows'; $env:GOARCH='amd64'; $env:GOTOOLCHAIN='local'; $env:GOFLAGS=''
    Push-Location $root
    try {
        # Build THIS checkout so local bug fixes are included. Do not use netgo:
        # native Windows DNS is required for NRPT, VPN split DNS and Tailscale.
        & $GoExecutable build -trimpath -ldflags "-s -w -X $module/internal/pkg/ver.version=v$Version" -o "$output\$binaryName" .
        Assert-NativeSuccess 'Build Windows runner'
    } finally { Pop-Location }
    $reportedVersion = & "$output\$binaryName" --version
    Assert-NativeSuccess 'Run compiled binary'
    if ($reportedVersion -notmatch ("v{0}\b" -f [regex]::Escape($Version))) { throw 'Binary reports unexpected version' }
    $goVersion = & $GoExecutable version
    Assert-NativeSuccess 'Read Go version'
    $manifest = [ordered]@{
        Version=$Version; Binary=$binaryName; Platform='windows/amd64'; SourceRevision=[string]$revision
        SourceDirty=($changes.Count -gt 0)
        Go=[string]$goVersion; BuildTags='default (native Windows DNS)'; CGO=$false
        BinarySHA256=(Get-FileHash "$output\$binaryName" -Algorithm SHA256).Hash
    }
    Write-Utf8 "$output\build-manifest.json" ($manifest | ConvertTo-Json)
    Write-Output $reportedVersion
    Write-Output "Build output: $output"
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process') }
}
