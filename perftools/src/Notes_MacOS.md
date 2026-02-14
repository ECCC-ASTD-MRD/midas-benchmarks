Although `clang --help` shows `-fopenmp` in the options we get this error:
```
clang: error: unsupported option '-fopenmp'
```
This [stack overflow question](https://stackoverflow.com/a/60043467) explains
that this is because the `clang` shipped with MacOS does not have openmp support
or rather the underlying llvm does not have it.

The linked answer suggests
```
brew install llvm libomp
```
After this, we need to use the compiler that comes with it:
```
export CC=/opt/homebrew/Cellar/llvm/21.1.8_1/bin/clang
```
and of course check the version.
