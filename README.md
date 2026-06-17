# MIDAS Benchmarking

Welcome to the MIDAS Data Assimilation Benchmarking System!

You should have obtained this benchmark from https://github.com/ECCC-ASTD-MRD/midas-benchmarks

# Requirements

* CMake (version >= 3.20)
* Fortran and C compiler. These codes have been tested with compilers from GNU and Intel OneAPI (classic and llvm based)
* An MPI implementation such as OpenMPI, MPICH or Intel MPI (with development package)
* OpenMP support
* BLAS, LAPACK or equivalent mathematical/scientific library (ie: Intel MKL), with development package and thread-safe support
* RTTOV version 13.0
  * You can get this library by going to [NWP SAF RTTOV v13 web page](https://nwp-saf.eumetsat.int/site/software/rttov/rttov-v13), create an account and download it.
* HDF5/netCDF
* Python 3
* SQLite with development package (version >= 3.26.0)
* `Libxml2` library

# Build MIDAS

## Compiler specifics

Compiler specific definitions and flags are defined within the
`cmake_rpn` submodule of each code repository. If you need to change
or add any, you can add or modify the rules into `[git source
path]/rpn/cmake_rpn/modules/ec_compiler_presets/default/[architecture]/`

## Build base libraries

After cloning the Git repo, you need to use the following command to get all
the Git submodules:

```bash
mkdir ${MIDAS_BENCHMARKS_DIRECTORY}
cd ${MIDAS_BENCHMARKS_DIRECTORY}
git clone https://github.com/ECCC-ASTD-MRD/midas-benchmarks.git
cd midas-benchmarks
git submodule update --init --recursive
cd ..
```
The following instructions assume that you are installing the libraries and
tools in a directory above the cloned git repo, but you can modify them
according to your chosen installation.

### rmn library

```bash
mkdir build-rpn
cd build-rpn
cmake -DCMAKE_INSTALL_PREFIX=../rpn-install ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks/rpn
make --jobs install
cd ..
```

### RTTOV 13 library

You can get this library by going to [NWP SAF | Numerical Weather Prediction
Satellite Application Facility](https://nwp-saf.eumetsat.int/site/), create
an account and download it.

Follow the instructions and install it in a separate directory, which
we named `rttov-install` in the following instructions.

## MIDAS

To compile MIDAS, follow the steps below.  You have to choose if you
compile with or without Intel MKL mathematical library support (see
variable `MKL_SUPPORT`).

```bash
export MIDAS_COMPILE_EXTLIBS="f90sqlite,udfsqlite,perftools"
export EC_CMAKE_MODULE_PATH="${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks/rpn/rmn/cmake_rpn/modules;${CMAKE_MODULE_PATH}"
export CMAKE_PREFIX_PATH=${MIDAS_BENCHMARKS_DIRECTORY}/rpn-install:${CMAKE_PREFIX_PATH}
export PATH=${MIDAS_BENCHMARKS_DIRECTORY}/rpn-install/bin:${PATH}
## The variable 'rttov_INSTALLDIR' should be set to the RTTOV13 install directory
## Here, we suppose it is install in the same directory as other libraries
export rttov_INSTALLDIR=${MIDAS_BENCHMARKS_DIRECTORY}/rttov-install

mkdir build-midas
cd build-midas
cmake -DMKL_SUPPORT="ON or OFF" -DCMAKE_INSTALL_PREFIX=../midas-install ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks/midas
make --jobs install
cd ..
```

From this project, there will be four programs compiled:
 * `midas.splitobs.Abs`: needed in the preprocessing step
 * `midas-ensPostProcess.Abs`: needed in the preprocessing step
 * `midas-letkf.Abs`: HPC benchmarking program
 * `midas-energyNorm.Abs`: needed in the evaluation step

```bash
splitobs_program=${MIDAS_BENCHMARKS_DIRECTORY}/midas-install/bin/midas.splitobs.Abs
ensPostProcess_program=${MIDAS_BENCHMARKS_DIRECTORY}/midas-install/bin/midas-ensPostProcess.Abs
letkf_program=${MIDAS_BENCHMARKS_DIRECTORY}/midas-install/bin/midas-letkf.Abs
energyNorm_program=${MIDAS_BENCHMARKS_DIRECTORY}/midas-install/bin/midas-energyNorm.Abs
`̀``

# Run MIDAS (LetKF)

From here, we assume the working directory is where the code
`midas-benchmarks` have been downloaded.

## Download database

The variable `${MIDAS_ARCHIVE}` should be set to a directory
where all the files will be downloaded on your system.

Download the data needed to run `midas-letkf.Abs`:
```bash
${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks/download_dbase.sh ${MIDAS_ARCHIVE}
```

There will be an automatic check of `md5sum`s for each downloaded
file.  Since this step can be quite long, you can skip that step by
setting the environment variable `DOWNLOAD_DBASE_CHECK_MD5SUM` to
`no`.

## Testing the execution environment

### Prepare the working directory

We provide a small configuration 8 members at 100km resolution to test
the execution environment.

The variable `${MIDAS_WORK}` should be set to the working directory
where the program will run.  The values `${npex}` and `${npey}` are
the MPI decomposition.  For this small test, some values are
suggested.  And the `${splitobs_program}` is the path to the program
`midas.splitobs.Abs` that has been compiled at the build step.

You can prepare the working directory with
```bash
cd ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks

## For this small test, we suggest this MPI decomposition
npex=3
npey=2

midas/tools/midas_scripts/midas.prepare_workdir -workdir      ${MIDAS_WORK}                 \
                                                -nml          ${PWD}/nml_100km              \
                                                -ensemble     ${MIDAS_ARCHIVE}/ensemble     \
                                                -observations ${MIDAS_ARCHIVE}/observations \
                                                -constants    ${MIDAS_ARCHIVE}/constants    \
                                                -splitobs     ${splitobs_program}           \
                                                -npex ${npex} -npey ${npey}
```

### Prepare the execution environment

Before running to program, make sure to set those variables:

```bash
## load the MPI environment

ulimit -c unlimited
ulimit -s unlimited

export CMCCONST=.
export TMG_ON=YES
export OMP_STACKSIZE=4G ## Or any other value for your system
npex=3
npey=2

cd ${MIDAS_WORK}
```

### Run the program

With `${letkf_program}` as the path to the program `midas-letkf.Abs`
that has been compiled at the build step, launch the program with:

```bash
## It is important to always recreate the 'obs' subdirectory before each execution
rm -rf obs
cp -r obsfiles_split obs

mpirun -n $((npex*npey)) ${letkf_program}
```

Depending on your `mpirun`, you may need to add explicitely the
environment variables to the `mpirun` call such as:
```bash
mpirun -x CMCCONST -x TMG_ON -x OMP_STACKSIZE -n $((npex*npey)) ${letkf_program}
``̀


### Checking the results

This execution should generate this list of files:
 * `2024091818_006_trialmean`
 * `2024091818_006_trialrms`
 * `2024091818_006_trialrms_ascii`
 * `2024091900_000_0000`
 * `2024091900_000_0001`
 * `2024091900_000_0002`
 * `2024091900_000_0003`
 * `2024091900_000_0004`
 * `2024091900_000_0005`
 * `2024091900_000_0006`
 * `2024091900_000_0007`
 * `2024091900_000_0008`
 * `2024091900_000_analmean`
 * `2024091900_000_analrms`
 * `2024091900_000_analrms_ascii`
 * `2024091900_000_inc_0000`
 * `2024091900_000_inc_0001`
 * `2024091900_000_inc_0002`
 * `2024091900_000_inc_0003`
 * `2024091900_000_inc_0004`
 * `2024091900_000_inc_0005`
 * `2024091900_000_inc_0006`
 * `2024091900_000_inc_0007`
 * `2024091900_000_inc_0008`
 * `obs/obs*_*_*`


## Interpolate the ensemble trials from 100km to 10km

To avoid downloading terabytes of data, a set of low resolution, at
100km, ensemble trials have been prepared and should have been
downloading in step [Download database](#download-database).  Then you
need to interpolate them at 10km.  The program `midas-ensPostprocess`
can be used for that in combination with the script `interpEnsTrials`.
You will need a total of around 24TB fo RAM to run this step which
will be equally distributed amongst the 30x20 MPI ranks.

Set `${ensOutput}` and `${workdir}` to path where there is 5TB of free
space and launch the interpolation with:
`̀``bash
cd ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks

ensInput=${MIDAS_ARCHIVE}/ensemble
targetGrid=${MIDAS_ARCHIVE}/constants/targetGrid_10km
gzSfc=${MIDAS_ARCHIVE}/constants/GZ_sfc.fstd
ctlmem=${MIDAS_ARCHIVE}/ensemble_control/*_006_0000
nml=${PWD}/nml_interpEnsTrials
npex=30
npey=20

./interpEnsTrials -pgm      ${ensPostProcess_program}             \
                  -nml      ${nml}      -targetGrid ${targetGrid} \
                  -ctlmem   ${ctlmem}   -gzSfc      ${gzSfc}      \
                  -npex     ${npex}     -npey       ${npey}       \
                  -ensInput ${ensInput} -ensOutput  ${ensOutput}  \
                  -workdir  ${workdir}
```

## Run the benchmark

### Choose the CPU decomposition

This will give you the possible CPU decomposition for the MIDAS LetKF global 10km configuration:

```bash
cd ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks

midas/tools/midas_scripts/midas.mpiTopoFinder --ni 3124 --nj 2084          \
               --min-tasks "minimum total number of MPI tasks to consider" \
               --max-tasks "maximum total number of MPI tasks to consider" \
               --max-diff  "maximum difference of grid points per MPI task allowed (in percentage) between the regular distribution and the last MPI task"
```

### Prepare the working directory

The variable `${MIDAS_WORK}` should be set to the working directory
where the program will run.  The values `${npex}` and `${npey}` are
the MPI decomposition found at the previous step.  And the
`${splitobs_program}` is the path to the program `midas.splitobs.Abs`
that has been compiled at the build step.

```bash
cd ${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks

midas/tools/midas_scripts/midas.prepare_workdir -workdir      ${MIDAS_WORK}                 \
                                                -nml          ${PWD}/nml_10km               \
                                                -ensemble     ${ensOutput}                  \
                                                -observations ${MIDAS_ARCHIVE}/observations \
                                                -constants    ${MIDAS_ARCHIVE}/constants    \
                                                -splitobs     ${splitobs_program}           \
                                                -npex ${npex} -npey ${npey}
```

You need to rerun this preparation each time you change the CPU
decomposition (`${npex}` or `${npey}`).

### Run the program (or submit to queuing system):

Before running to program, make sure to set those variables:

```bash
## load the MPI environment

ulimit -c unlimited
ulimit -s unlimited

export CMCCONST=.
export TMG_ON=YES
export OMP_STACKSIZE=4G ## Or any other value for your system

cd ${MIDAS_WORK}
```

With `${letkf_program}` as the path to the program `midas-letkf.Abs`
that has been compiled at the build step, launch the program with:

```bash
## It is important to always recreate the 'obs' subdirectory before each execution
rm -rf obs
cp -r obsfiles_split obs

mpirun -n $((npex*npey)) ${letkf_program}
```

This configuration has been tested with `npex=48`, `npey=52`,
`OMP_NUM_THREADS=4` and a total of `(48x52)x10 GB` of memory.

# Run verification

Verify the results with the following command providing
`${eneryNorm_program}` as the path to the program
`midas-eneryNorm.Abs`.  It is possible to provide results from several
executions with argument `-states`.  The variable
`${MIDAS_VERIFY_WQRKDIR}` is the path to the working directory the
program can use.

This script will provide a PASS or FAIL rating

```bash
${MIDAS_BENCHMARKS_DIRECTORY}/midas-benchmarks

## load the MPI environment

./verify -pgm ${energyNorm_program} -date 2024091900                   \
         -nml ${PWD}/midas/maestro/suites/midas_system_tests/config/Tests/energyNorm/analmean/nml \
         -reference ${MIDAS_ARCHIVE}/reference/2024091900_000_analmean \
         -states ${MIDAS_WORK}/2024091900_000_analmean                 \
         -workdir ${MIDAS_VERIFY_WQRKDIR}
```

This process is requesting around 155 GB of RAM to run.

## Expected output

```bash
        pass for ${MIDAS_WORK}/2024091900_000_analmean
```
or
```bash
        FAIL for ${MIDAS_WORK}/2024091900_000_analmean
```

# Reference

MIDAS stands for Modular and Integrated Data Assimilation System and is described in this publication:
[Buehner, M., Caron, J.-F., Lapalme, E., Caya, A., Du, P., Rochon, Y., Skachko, S., Bani Shahabadi, M., Heilliette, S., Deshaies-Jacques, M., Chang, W., and Sitwell, M.: The Modular and Integrated Data Assimilation System at Environment and Climate Change Canada (MIDAS v3.9.1), Geosci. Model Dev., 18, 1–18, https://doi.org/10.5194/gmd-18-1-2025, 2025](https://doi.org/10.5194/gmd-18-1-2025).
