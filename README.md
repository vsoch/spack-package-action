# Spack Package Action

Can we build and release a spack package alongside a repository, either in binary or container form? 
Let's find out!

## Package Binary Build

The goals of this action will be to:

 - build of local package.py, a core package.py, or a package.py from another spack repos repository.
 - choice of spack version or branch to use
 - customization of compiler, target arch, and other flags
 - release to GitHub packages as a binary artifact

Given the above, we could have repos that build and provide their own package binaries,
and then an addition to spack to allow installing from here. This means that a single repository
could package an existing spack package, or provide a new package.  This action will be provided in [package](package).

## Package Container Build

If you instead want to provide a container for your package, you can do that too!
We will either allow for a spack package name, or a spack.yaml to use directly
for a custom build. This approach will be in [container](container). You could have a workflow
that does both, actually!
 
 
For both, the recommended approach will be to build on changes to the codebase (given a codebase here) and release on
merge into a main branch _or_ a release, depending on your preference.

🚧️ **under development** 🚧️

Documentation and examples coming soon!
