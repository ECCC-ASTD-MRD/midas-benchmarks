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

# Build MIDAS

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

## Build

```bash
git clone git@github.com:ECCC-ASTD-MRD/midas-src.git midas
cd midas
git checkout benchmark

## instructions to download the data

## instructions to load the compiling environment
. ./.common_setup [intel|gnu|nvhpc]

mkdir build
cd build
cmake ..
make -j 5
make work
```

# Run MIDAS (LetKF)

## Download database

The variable `${MIDAS_ARCHIVE}` should be set to a directory
where all the files will be downloaded on your system.

Download the data needed to run `midas-letkf`:
```bash
./download_dbase.sh ${MIDAS_ARCHIVE}
```

## Choice of CPU decomposition

This will give you the possible CPU decomposition for the MIDAS LetKF global 10km configuration:

```bash
midas/tools/midas_scripts/midas.mpiTopoFinder --ni 3124 --nj 2084          \
               --min-tasks "minimum total number of MPI tasks to consider" \
               --max-tasks "maximum total number of MPI tasks to consider"
```

## Prepare working directory

The variable `${MIDAS_WORK}` should be set to the working directory
where the program will run.  The values `${npex}` and `${npey}` are
the MPI decomposition found at the previous step.  And the
`${splitobs_program}` is the path to the program `midas.splitobs.Abs`
that has been compiled at the build step.

```bash
midas/tools/midas_scripts/midas.prepare_workdir -workdir ${MIDAS_WORK}                      \
                                                -ensemble ${MIDAS_ARCHIVE}/ensemble         \
                                                -observations ${MIDAS_ARCHIVE}/observations \
                                                -constants ${MIDAS_ARCHIVE}/constants       \
                                                -npex ${npex} -npey ${npey}                 \
                                                -splitobs ${splitobs_program}
```

You need to rerun this preparation each time you change the CPU
decomposition (`${npex}` or `${npey}`).

## Run program (or submit to queuing system):

Before running to program, make sure to set those variables:

```bash
ulimit -c unlimited

export CMCCONST=.
export TMG_ON=YES
export OMP_STACKSIZE=4G ## Or any other value for your system

${MIDAS_WORK}

mpirun -n $((npex*npey)) ${letkf_program}
```

# Run verification

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
