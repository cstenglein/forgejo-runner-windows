[CmdletBinding()]
param([string]$GoExecutable='go.exe',[Uri]$ProbeUrl)
. "$PSScriptRoot\Common.ps1"
$root=Get-ProjectRoot
$build=Get-WindowsBuild
$savedExecutionPolicy=[Environment]::GetEnvironmentVariable('PSExecutionPolicyPreference','Process')
Push-Location $root
try {
    & $GoExecutable test ./internal/pkg/config
    Assert-NativeSuccess 'Configuration unit tests'
    & $GoExecutable test ./act/container -run '^TestParseEnvFile$'
    Assert-NativeSuccess 'Command-file encoding regression tests'
    & $build.Executable validate --workflow --path "$PSScriptRoot\smoke.yml"
    Assert-NativeSuccess 'Workflow schema validation'
    # Only this test process and its child shells may run generated scripts.
    # No user-level or machine-level execution policy is changed.
    $env:PSExecutionPolicyPreference='Bypass'
    & $build.Executable exec --directory $root --workflows "$PSScriptRoot\smoke.yml" --image=-self-hosted --event workflow_dispatch
    Assert-NativeSuccess 'Native Windows host workflow'
    if ($ProbeUrl) {
        if ($ProbeUrl.Scheme -ne 'https' -or $ProbeUrl.UserInfo) { throw 'ProbeUrl must use HTTPS without credentials' }
        & $GoExecutable run "$PSScriptRoot\dns-probe\main.go" $ProbeUrl.AbsoluteUri
        Assert-NativeSuccess 'Native Windows DNS/HTTPS probe'
    }
} finally {
    Pop-Location
    [Environment]::SetEnvironmentVariable('PSExecutionPolicyPreference',$savedExecutionPolicy,'Process')
}
