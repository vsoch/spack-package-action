# Spack Package Action

Can we build and release a spack package alongside a repository, either in binary or container form? 
Let's find out! This repository serves three different actions:

 - [*install spack*](#install-spack): hey, just need spack for your own purposes? We got you covered!
 - [*release binaries*](#package-binary-release): build and (optionally) release spack binaries to GitHub packages
 - [*spack containers*](#package-container-build): build and (optionally) deploy a container with spack packages to GitHub packages


For examples of all three, see the [GitHub workflows](.github/workflows) or keep reading. If you'd like to
see a different or custom example or request additional functionality or changes, please don't hesitate
to [open an issue](https://github.com/vsoch/spack-package-action/issues).

## Install Spack

This simple action will allow you to install spack.

```yaml
jobs:
  install-spack:
    runs-on: ubuntu-latest
    name: Install Spack
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Install Spack
        uses: vsoch/spack-package-action/install
```

You can optionally set a spack root to install to (defaults to /opt/spack) or ask for full depth (by default we clone with `--depth 1` to increase the speed of the install, but if you need the git history you can add `full_clone: true`

```yaml
jobs:
  install-spack:
    runs-on: ubuntu-latest
    name: Install Spack
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Install Spack
        uses: vsoch/spack-package-action/install
        with:
          root: /home/spack
          full_clone: true
```

This action is provided in [install](install).

## Package Binary Build

This action will allow for:

 - build of local package.py, a core package.py, or a package.py from another spack repos repository.
 - choice of spack version or branch to use
 - customization of compiler, target arch, and other flags
 - release to GitHub packages as a binary artifact

Given the above, we could have repos that build and provide their own package binaries,
and then an addition to spack to allow installing from here. This means that a single repository
could package an existing spack package, or provide a new package. 
An example workflow might look like:

```yaml
jobs:
  build-binaries:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    name: Build Package Binaries
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Build Spack Package
        uses: vsoch/spack-package-action@main
        with:
          package: zlib
          deploy: true
          token: ${{ secrets.GITHUB_TOKEN }}
          deploy: ${{ github.event_name != 'pull_request' }}
```

This action is provided in [package](package), and an example package is shown 
[here](https://github.com/vsoch/spack-package-action/pkgs/container/spack-package-action%2Fzlib).

To then get the binary, you can [install oras](https://oras.land/cli/) and do:

```bash
$ oras pull ghcr.io/vsoch/spack-package-action/zlib:46878b236da7283b9b71086044d4e3884e04defa
```
The package "spack-package.tar.gz" will then be in the present working directory, which has the contents
of a build cache with one package.

## Package Container Build

If you instead want to provide a container for your package, you can do that too!
We will either allow for a spack package name, or a spack.yaml to use directly
for a custom build. This approach will be in [container](container). We will also add some basic
spack metadata tags

And you could have a workflow that does both, actually! See the [.github/workflows](.github/workflows) for full examples.
  
For the latter two, the recommended approach will be to build on changes to the codebase (given a codebase here) and release on
merge into a main branch _or_ a release, depending on your preference.

🚧️ **under development** 🚧️

Documentation and examples coming soon!

## Questions for Discussion

1. Should we add an ability to install a spack binary from GitHub packages (akin to an on the fly build cache?)
2. What should the namespace of the package be in GitHub packages? Since it's technically one package in a build cache, we could name based on the build hash, but arguably there could be more than one.
3. Should we preserve the entire thing .tar.gz-ed or just the .spack archive?
4. Should we have a way to keep a persistent gpg key to sign packages?
5. What about [spack container labels](https://github.com/spack/label-schema)? How should we include here or extent?
