# MIDAS Benchmarking

Welcome to the MIDAS Data Assimilation Benchmarking System!

You should have obtained this benchmark from https://github.com/ECCC-ASTD-MRD/midas-src

# Requirements

* Fortran and C compiler. Theses codes have been tested with compilers from GNU and Intel OneAPI (classic and llvm based)
* An MPI implementation such as OpenMPI, MPICH or Intel MPI (with development package)
* OpenMP support
* BLAS, LAPACK or equivalent mathematical/scientific library (ie: MKL), with development package and thread-safe support
* RTTOV version 13 (where to download the library?)
  * You can get this library by going to [NWP SAF | Numerical Weather Prediction Satellite Application Facility](https://nwp-saf.eumetsat.int/site/), create an account and download it.
* SQLite with development package (version >= 3.26.0)
* CMake (version >= 3.20)

# Build and run steps

## Compiler specifics

* Compiler specific definitions and flags are defined within the ```cmake_rpn``` submodule of each code repository. If you need to change or add any,
you can add or modify the rules into `[git source path]/cmake_rpn/modules/ec_compiler_presets/default/[architecture]/`

## Build base library (librmn)

```bash
git clone git@github.com:ECCC-ASTD-MRD/librmn.git
cd librmn
git checkout alpha
git submodule update --init --recursive
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=[rmn install directory] ..
make install
```

## Build MIDAS

```bash
git clone git@github.com:ECCC-ASTD-MRD/midas-src.git
cd gem
git checkout benchmark
./download-dbase.sh .
./download-dbase-benchmarks.sh .
. ./.common_setup [intel|gnu|nvhpc]
mkdir build
cd build
cmake ..
make -j 5
make work
```

## Run MIDAS (LetKF)

```bash
cd ../${MIDAS_WORK}
```

* This will give you the possible CPU decomposition for the MIDAS LetKF configuration:

```
findtopo -npex_low 20 -npex_high 250 -npey_low 20 -npey_high 200 -corespernode 80 -nml $GEM_WORK/configurations/GEM_cfgs_GY_4km/cfg_0000/gem_settings.nml > topo.txt
```

## Run preparation script

```
runprep.sh -dircfg configurations/GEM_cfgs_GY_4km
```

* Run program (or submit to queing system):

The -cpus parameters defines the mpi topology and the openmp number of
threads [X MPI]x[Y MPI]x[OMP threads] (ie: 61x20x8).

This topology is used for 2 simultaneous model run (Yin+Yang), meaning you
will have to use double this number of CPU for the submision/run itself.

In the below example, 9760 cores are needed per sub run, so a total of 19520 cores will be needed.

```
runmod.sh -dircfg configurations/GEM_cfgs_GY_4km -ptopo 61x20x8
```

* If you need a job script so you can submit the job to a queuing system, make sure you define the GOAS_SCRIPT
variable and load the common setup before running the runmod.sh command:

```bash
cd [gem src path]
. ./.common_setup [intel|gnu|nvhpc]
cd $GEM_WORK
runmod.sh -dircfg configurations/GEM_cfgs_GY_4km -ptopo 61x20x8
```

## Run verification

* This script will provide a PASS or FAIL rating

```bash
cd ..
gem_sverif.sh -p $GEM_WORK -f dp2020022915-000-000_006
```

* Expected output

```bash
(INFO) Run configuration found (....)
(INFO) Passed (passed 8/8)
```

# Reference

MIDAS stands for Modular and Integrated Data Assimilation System and is described in this publication:
[Buehner, M., Caron, J.-F., Lapalme, E., Caya, A., Du, P., Rochon, Y., Skachko, S., Bani Shahabadi, M., Heilliette, S., Deshaies-Jacques, M., Chang, W., and Sitwell, M.: The Modular and Integrated Data Assimilation System at Environment and Climate Change Canada (MIDAS v3.9.1), Geosci. Model Dev., 18, 1–18, https://doi.org/10.5194/gmd-18-1-2025, 2025](https://doi.org/10.5194/gmd-18-1-2025).
