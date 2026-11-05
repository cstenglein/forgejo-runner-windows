[CmdletBinding()]
param()
. "$PSScriptRoot\Common.ps1"
$root=Get-ProjectRoot
$build=Get-WindowsBuild
if ($build.Manifest.SourceDirty) { throw 'Commit source changes and rebuild before packaging a release' }
$output=Join-Path $root ("dist\release\" + $build.Manifest.Version)
New-Item -ItemType Directory -Path $output -Force | Out-Null
Copy-Item -LiteralPath $build.Executable -Destination (Join-Path $output $build.Manifest.Binary) -Force
Copy-Item -LiteralPath "$root\dist\windows\build-manifest.json" -Destination "$output\build-manifest.json" -Force
$sourceName="forgejo-runner-$($build.Manifest.Version)-source.tar.gz"
# Only committed source is packaged. No local settings, logs or credentials.
& git.exe -C $root archive --format=tar.gz "--prefix=forgejo-runner-$($build.Manifest.Version)/" -o "$output\$sourceName" $build.Manifest.SourceRevision
Assert-NativeSuccess 'Package corresponding source'
Copy-Item -LiteralPath "$root\LICENSE" -Destination "$output\LICENSE.txt" -Force
$files=@($build.Manifest.Binary,'build-manifest.json',$sourceName,'LICENSE.txt')
$checksums=foreach($name in $files){"$((Get-FileHash -LiteralPath (Join-Path $output $name) -Algorithm SHA256).Hash.ToLowerInvariant())  $name"}
Write-Utf8 "$output\SHA256SUMS" (($checksums -join "`n")+"`n")
Write-Output "Release files: $output"
