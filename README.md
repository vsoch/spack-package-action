# Spack Package Action

Can we build and release a spack package alongside a repository, either in binary or container form? 
Let's find out! This repository serves three different actions:

 - [*install spack*](#install-spack): hey, just need spack for your own purposes? We got you covered!
 - [*release binaries*](#package-binary-build): build and (optionally) release spack binaries to GitHub packages
 - [*spack containers*](#package-container-build): build and (optionally) deploy a container with spack packages to GitHub packages

For examples of all three, see the [GitHub workflows](.github/workflows) or keep reading. If you'd like to
see a different or custom example or request additional functionality or changes, please don't hesitate
to [open an issue](https://github.com/vsoch/spack-package-action/issues). I haven't tested all possible
use cases for the action, so please do open an issue if you hit a bug and I'll help asap!

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
        uses: vsoch/spack-package-action/install@main
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
        uses: vsoch/spack-package-action/install@main
        with:
          root: /home/spack
          full_clone: true
```

This action is provided in [install](install).

### Variables

| name | description | default | example | required |
|------|-------------|---------|---------|----------|
| repos | comma separated list of additional repos to clone and add | unset | https://github.com/rbogle/spack-repo | false
| branch | The branch of spack to use | develop | feature-branch | false | 
| release | A spack release to use (if defined, overrides branch) | unset | 0.17.0 | false |
| root |  root to install spack to | /opt/spack | /home/spack | false |
| full_clone |  Instead of cloning with --depth 1, clone the entire git history (branch only) | false | true | false |

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
        uses: vsoch/spack-package-action/package@main
        with:
          package: zlib
          deploy: true
          token: ${{ secrets.GITHUB_TOKEN }}
          deploy: ${{ github.event_name != 'pull_request' }}
```

This action is provided in [package](package), and an example package is shown 
[here](https://github.com/vsoch/spack-package-action/pkgs/container/spack-package-action%2Fzlib).

### Oras Pull

To then get the binary, you can [install oras](https://oras.land/cli/) and do:

```bash
$ oras pull ghcr.io/vsoch/spack-package-action/21.11/build_cache/linux-ubuntu20.04-x86_64_v4-gcc-10.3.0-zlib-1.2.11-2bkp3o6gfeilpf4o7d2h7xcujnupytlt.spack:07f0a453
Downloaded b287cffe632d linux-ubuntu20.04-x86_64_v4-gcc-10.3.0-zlib-1.2.11-2bkp3o6gfeilpf4o7d2h7xcujnupytlt.spack
Pulled ghcr.io/vsoch/spack-package-action/21.11/build_cache/linux-ubuntu20.04-x86_64_v4-gcc-10.3.0-zlib-1.2.11-2bkp3o6gfeilpf4o7d2h7xcujnupytlt.spack:07f0a453
Digest: sha256:296655195f73756b60218b342ab9850d6931a85fc66955283763f8f11a5f81ee
```
What did we pull?

```bash
linux-ubuntu20.04-x86_64_v4-gcc-10.3.0-zlib-1.2.11-2bkp3o6gfeilpf4o7d2h7xcujnupytlt.spack 
```

In summary, the oras package, after pull will then produce the .spack artifact in the present working directory.
See [questions](#questions-for-discussion) for some things to talk about!
For example, we could easily add this to spack proper as a *much* easier to use build cache than say, needing
to pay all the monies for AWS and get lost in the interface of bouncy doom.

### Variables

| name | description | default | example | required |
|------|-------------|---------|---------|----------|
| package | the name of a package to install | unset | zlib | false |
| package_path | the path to a package.py to add instead | unset | spack/package.py | false |
| repos | comma separated list of additional repos to clone and add | unset | https://github.com/rbogle/spack-repo | false
| branch | The branch of spack to use | develop | feature-branch | false | 
| release | A spack release to use (if defined, overrides branch) | unset | 0.17.0 | false |
| token | A GitHub token required if releasing artifacts to the same repository | unset | `${{ secrets.GITHUB_TOKEN }}` | false |
| flags | Extra flags (compiler, target, variants, etc) to add to the install command | unset | +debug | false |
| tag | Tag to use for package | latest | v10.0.0 | false |
| deploy | Deploy (release) package to GitHub repository (token is required) | false | true | true |

The interesting thing about building on actions is that you get a different builder each time, so your
spack build hashes (that identify the package) are going to vary. This could be a good thing to provide lots
of different supported packages, or bad if you want consistently the same one. Likely you can pin this by setting a target
in the `flags` for the package.

## Package Container Build

If you instead want to provide a container for your package, you can do that too!
We will either allow for a spack package name, or a spack.yaml to use directly
for a custom build. This approach will be in [container](container). We will also add some basic
spack metadata tags as defined by the [spack/label-schema](https://github.com/spack/label-schema) include
the package (or packages) and compilers.

```bash
jobs:
  build-container:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    name: Build Package Container
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Build Spack Container
        uses: vsoch/spack-package-action/container@main
        with:
          package: zlib
          token: ${{ secrets.GITHUB_TOKEN }}
          deploy: ${{ github.event_name != 'pull_request' }}
```

And you don't need to choose just one of the above - you could have a workflow that does both, actually! 
See the [.github/workflows](.github/workflows) for full examples.

### Variables

| name | description | default | example | required |
|------|-------------|---------|---------|----------|
| package | the name of a package to install | unset | zlib | false |
| spack_yaml | Instead of a package name, install from a spack.yaml instead | unset | spack.yaml | false |
| branch | The branch of spack to use | develop | feature-branch | false | 
| release | A spack release to use (if defined, overrides branch) | unset | 0.17.0 | false |
| token | A GitHub token required if releasing artifacts to the same repository | unset | `${{ secrets.GITHUB_TOKEN }}` | false |
| tag | Tag to use for package | latest | v10.0.0 | false |
| deploy | Deploy (release) package to GitHub repository (token is required) | false | true | true |

You can specify a `spack_yaml` OR a `package` but not both, and the same for `release` and `branch`. 

## Build Cache Website

After you deploy to spack packages, you can create a web interface (that will also serve metadata to spack)
along with an easy UI to explore packages. This action is modular but *does* require using the packages action
previously for variables set in the environment, and there are inputs that you can also customize for other variables.
Your workflow might look like this:

```yaml
```


### Variables



## Common

For the package builds (binary or container) the recommended approach will be to build on changes to the codebase (given a codebase here) and release on
merge into a main branch _or_ a release, depending on your preference.


## Questions for Discussion

1. Should we add an ability to install a spack binary from GitHub packages (akin to an on the fly build cache?)
2. What should the namespace of the package be in GitHub packages? Since it's technically one package in a build cache, we could name based on the build hash, but arguably there could be more than one.
3. Should we preserve the entire thing .tar.gz-ed or just the .spack archive?
4. Should we have a way to keep a persistent gpg key to sign packages?
5. What about [spack container labels](https://github.com/spack/label-schema)? How should we include here or extent?
6. Should we add these labels to spack containerize instead (I think so)
