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

You can optionall set a spack root to install to (defaults to /opt/spack)

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

## Package Container Build

**under development**

If you instead want to provide a container for your package, you can do that too!
We will either allow for a spack package name, or a spack.yaml to use directly
for a custom build. This approach will be in [container](container). You could have a workflow
that does both, actually!
  
For the latter two, the recommended approach will be to build on changes to the codebase (given a codebase here) and release on
merge into a main branch _or_ a release, depending on your preference.

🚧️ **under development** 🚧️

Documentation and examples coming soon!
