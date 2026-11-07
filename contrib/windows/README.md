# Windows build tools

These scripts build the source in the current checkout, including local fixes.
They do not download and replace the runner source with an upstream archive.

Requirements: Windows x64, Git, Go matching `go.mod`, and Windows PowerShell or
PowerShell 7. Docker is not needed for the Windows smoke test.

```powershell
./contrib/windows/Build.ps1 -Version 13.2.1-windows.1
./contrib/windows/Test.ps1
./contrib/windows/Package.ps1
```

Builds are written to `dist/windows/`. Release packages containing the binary,
manifest, source archive, license and `SHA256SUMS` are written to
`dist/release/<version>/`. Both directories are ignored by Git.

An alternate Go executable can be supplied to `Build.ps1` and `Test.ps1` using
`-GoExecutable 'C:\path\to\go.exe'`.

Optional DNS test against your own server:

```powershell
./contrib/windows/Test.ps1 -ProbeUrl 'https://forgejo.example.com/api/v1/version'
```

No credentials are needed for this test. Do not put credentials in the URL.

## Native Windows DNS

The Linux-oriented upstream Makefile builds with `netgo`. On Windows this can
bypass the Windows resolver and its NRPT rules, breaking VPN/split DNS names.
The PowerShell build deliberately uses default build tags and `CGO_ENABLED=0`.
The native Windows resolver works without a C compiler.

## Tests and scope

`Test.ps1` runs the configuration and command-file encoding unit tests and a local two-step Windows host
workflow, checking environment variables and step outputs. The optional HTTPS
probe uses Go's normal Windows resolver. This is not the full Linux/Docker/LXC
upstream test suite and is not official upstream Windows certification. The smoke
workflow uses Windows PowerShell 5 and exercises its UTF-8 BOM output behavior.

`Package.ps1` archives the exact commit recorded in the build manifest. Commit
your source changes before producing a release; uncommitted changes are not
part of that source archive. GitHub Actions always builds a committed checkout.

## Authentication

Building and testing require no Forgejo or GitHub credentials. Release publishing
in GitHub Actions uses the automatically generated `GITHUB_TOKEN`, limited to
`contents: write` in the tag-only release job. No personal access token or
repository secret is required.
