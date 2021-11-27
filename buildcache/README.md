To create the github actions key here:

```bash
$ spack gpg init
$ spack gpg create github-actions github-actions@users.noreply.github.com
$ mkdir -p /tmp/test
$ spack buildcache create -d /tmp/test/ zlib@1.2.3%gcc@7.5.0+optimize+pic+shared arch=linux-ubuntu20.04-skylake
$ cp /tmp/test/build_cache/_pgp/4A424030614ADE118389C2FD27BDB3E5F0331921.pub .
```

And then check it

```bash
$ gpg 4A424030614ADE118389C2FD27BDB3E5F0331921.pub 
gpg: WARNING: no command supplied.  Trying to guess what you mean ...
pub   rsa4096 2021-11-25 [SC]
      4A424030614ADE118389C2FD27BDB3E5F0331921
uid           github-actions (GPG created for Spack) <github-actions@users.noreply.github.com>
```
