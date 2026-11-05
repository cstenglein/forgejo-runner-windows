# Forgejo Runner for Windows

Community Windows x64 builds and an editable source fork of Forgejo Runner,
starting from upstream **v13.2.0**. This repository contains the full upstream
source and history. The Windows build compiles this checkout, so fixes made
here are included in the executable.

**[Download Windows releases](https://github.com/cstenglein/forgejo-runner-windows/releases)**

This is not an official Forgejo Windows release. Upstream officially supports
and tests Linux. Windows builds here are tested with the native host executor.

## Use a Windows release

1. Download `forgejo-runner-<version>-windows-amd64.exe` and `SHA256SUMS`.
2. Check the executable's SHA-256 checksum using `Get-FileHash -Algorithm SHA256`.
3. Run it with `--version`, then configure your runner following the
   [Forgejo administrator guide](https://forgejo.org/docs/latest/admin/actions/).

Each release includes its exact source revision, a matching source archive and
the GPL license. Executables are currently **unsigned**. Windows Smart App
Control or an organization application-control policy may block unsigned builds.

## Build and change the runner

Install Windows x64, Git and the Go toolchain specified by `go.mod`.

```powershell
git clone https://github.com/cstenglein/forgejo-runner-windows.git
cd forgejo-runner-windows

# Edit the actual Go source in this checkout, then build and test it.
./contrib/windows/Build.ps1 -Version 13.2.0-windows.1
./contrib/windows/Test.ps1
```

Build outputs are in `dist/windows/`. Commit your fixes, rebuild, and run
`./contrib/windows/Package.ps1` to produce a release package with matching source.
See [Windows build tools](contrib/windows/README.md) for details and the optional
DNS probe.

The Windows build intentionally omits the Linux-oriented `netgo` build tag.
This preserves native Windows DNS resolution, including NRPT and VPN split DNS.
The fork also accepts UTF-8 BOMs in environment/output/state command files,
as produced by Windows PowerShell 5's `Out-File -Encoding utf8`.

## GitHub builds and releases

- Pushes to `main`, pull requests and manual workflow runs build and test the
  current source and upload downloadable workflow artifacts.
- Pushing a release tag such as `v13.2.0-windows.1` builds that exact commit and
  publishes the executable, matching source, manifest, license and checksums as
  a GitHub release.
- Use a new `windows.N` suffix when publishing local fixes for the same upstream
  release. Do not move an existing release tag.

```powershell
git tag v13.2.0-windows.1
git push origin main
git push origin v13.2.0-windows.1
```

No Forgejo instance address, runner token, personal GitHub token, signing key or
repository secret is needed to build. GitHub Actions uses its automatic
`GITHUB_TOKEN`; only the tag-only release job has `contents: write` permission.

Local deployment configuration belongs outside this public repository. `.local/`,
runtime data and root-level credential files are ignored by Git.

## Follow upstream

```powershell
git remote add upstream https://code.forgejo.org/forgejo/runner.git
git fetch upstream --tags
# Merge a reviewed upstream release into a branch, resolve changes, and rerun tests.
```

The current upstream base is tag `v13.2.0`, commit
`df6b843fb929bb04b933b09c6bf208774d42480b`. Keep the Windows build path when
merging later upstream changes. For Windows-specific issues and fixes, use this
repository's issues and pull requests; report general upstream issues to Forgejo.

The code retains upstream licenses and attribution. Forgejo Runner and the
Windows additions are distributed under GPL-3.0-or-later; see [LICENSE](LICENSE).
Original project documentation follows below and is also preserved in
[README.upstream.md](README.upstream.md).

---

## Upstream Forgejo Runner

A daemon that connects to a Forgejo instance and runs jobs for continuous integration. The [installation and usage instructions](https://forgejo.org/docs/next/admin/actions/) are part of the Forgejo documentation. Forgejo Runner can also run workflows locally and act as a cache.

Forgejo Runner is distributed under the terms of the [GPL version 3.0](LICENSE) or any later version.

## Issues

* [Feature requests](https://code.forgejo.org/forgejo/forgejo-actions-feature-requests)
* [Runner-specific issues](https://code.forgejo.org/forgejo/runner/issues)
* [Forgejo Actions issues](https://codeberg.org/forgejo/forgejo/issues?q=&type=all&labels=96148&state=open)

It is totally okay to report issues in the "wrong" place; identifying the right place is hard. In the worst case, we will ask you to open it somewhere else because issues cannot be transferred between instances.

### Reporting Security Vulnerabilities

Please report security-related issues to [security@forgejo.org](mailto:security@forgejo.org) using [encryption](https://keyoxide.org/security@forgejo.org).

## Contributing

See the [contribution guide](CONTRIBUTING.md).

## Architectures & OS

The Forgejo runner is supported and tested on `amd64` and `arm64` ([binaries](https://code.forgejo.org/forgejo/runner/releases) and [containers](https://code.forgejo.org/forgejo/-/packages/container/runner/versions)) on Operating Systems based on the Linux kernel.

Work may be in progress for other architectures and you can browse the corresponding issues to figure out how they make progress. If you are interested in helping them move forward, open an issue. The most challenging part is to setup and maintain a native runner long term. Once it is supported by Forgejo, the runner is expected to be available 24/7 which can be challenging. Otherwise debugging any architecture specific problem won't be possible.

- [linux-s390x](https://code.forgejo.org/forgejo/runner/issues?labels=969)
- [linux-powerpc64le](https://code.forgejo.org/forgejo/runner/issues?labels=968)
- [linux-riscv64](https://code.forgejo.org/forgejo/runner/issues?labels=970)
- [Windows](https://code.forgejo.org/forgejo/runner/issues?labels=365)

## Development

The Forgejo runner is a dependency of the [setup-forgejo action](https://code.forgejo.org/actions/setup-forgejo). See [the full dependency graph](https://code.forgejo.org/actions/cascading-pr/#forgejo-dependencies) for a global view.

### Building

- Install [Go](https://go.dev/doc/install) and `make(1)`
- `make build`

### Linting

- `make lint-check`
- `make lint` # will fix some lint errors

### Testing

There are three kinds of tests for Forgejo Runner:

* Unit tests
* Integration tests
* [End-to-end tests](https://code.forgejo.org/forgejo/end-to-end/) that involve a running Forgejo instance

Unit and integration tests are included in this repository, whereas [end-to-end tests](https://code.forgejo.org/forgejo/end-to-end/) are maintained separately.

Tests can either be run using predefined GNU Make targets or `go test`. 

#### Running Tests

To run all unit tests with GNU Make, run:

```shell
$ make test
```

Or with `go test`, run:

```shell
$ go test -short ./...
```

To run all integration tests with GNU Make, run:

```shell
$ make integration-test
```

Or with `go test`, run:

```shell
$ go test ./...
```

#### Toggling Tests by Feature

Forgejo Runner integrates with various technologies like [Docker](https://docker.com/) and [LXC](https://linuxcontainers.org/). They are not available on all platforms that Forgejo Runner can run on. The related tests take a long time to execute, too. It is possible to enable or disable the tests with the help of the test argument `-features`. **All feature-related tests are enabled by default**.

`-features` takes a list of comma-separated feature names. For example, to run all tests including those related to `docker` and `lxc`, invoke:

```shell
$ go test ./... -args -features "docker,lxc"
```

If all feature-related tests should be skipped, run:

```shell
$ go test ./... -args -features "-"
```

If `-features` is not present, all feature-related tests will be enabled.

List of all feature toggles:

| Key      | Purpose                                                                                   |
|----------|-------------------------------------------------------------------------------------------|
| `docker` | Toggles tests that require [Docker](https://docker.com/) or [Podman](https://podman.io/). |
| `lxc`    | Toggles tests that require [LXC](https://linuxcontainers.org/).                           |

#### Running End-to-End Tests

For running end-to-end tests during development, please see the instructions in the respective [repository where the end-to-end tests are maintained](https://code.forgejo.org/forgejo/end-to-end/).

During CI, the end-to-end tests can be triggered for a particular pull request by attaching the label [`run-end-to-end-tests`](https://code.forgejo.org/forgejo/runner/pulls?labels=1032).
