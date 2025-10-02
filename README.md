# MIDAS Benchmarking

Welcome to the MIDAS Data Assimilation Benchmarking System!

You should have obtained this benchmark from https://github.com/ECCC-ASTD-MRD/midas-benchmarks

# Requirements

* Fortran and C compiler. Theses codes have been tested with compilers from GNU and Intel OneAPI (classic and llvm based)
* An MPI implementation such as OpenMPI, MPICH or Intel MPI (with development package)
* OpenMP support
* BLAS, LAPACK or equivalent mathematical/scientific library (ie: MKL), with development package and thread-safe support
* RTTOV version 13
  * You can get this library by going to [NWP SAF | Numerical Weather Prediction Satellite Application Facility](https://nwp-saf.eumetsat.int/site/), create an account and download it.
* SQLite with development package (version >= 3.26.0)
* CMake (version >= 3.20)
* Python 3

# Build MIDAS

## Compiler specifics

Compiler specific definitions and flags are defined within the
```cmake_rpn``` submodule of each code repository. If you need to
change or add any, you can add or modify the rules into `[git source
path]/cmake_rpn/modules/ec_compiler_presets/default/[architecture]/`

## Build base libraries

### LibRMN

Ces commandes doivent être revues!

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

### rpn_comm

Insérer les commandes pour compiler!

### VGrid

Insérer les commandes pour compiler!

### `burp-tools`

Insérer les commandes pour compiler!

### RPN-SI `random`

Insérer les commandes pour compiler!

### hpcoperf

Insérer les commandes pour compiler!

### `cclargs`

Les scripts `midas.prepare_workdir` et `verify` utilisent de
`cclargs`.  Est-ce compliqué d'ajouter cet outil dans le package?

Je peux aussi convertir la logique de `cclargs` à du `bash` standard.

## MIDAS

Ces commandes doivent être revues!

```bash
## load the compiling environment

mkdir midas/build
cd midas/build

cmake ..

make -j
```

From this project, there will be three programs compiled:
 * `midas.splitobs.Abs`: needed in the preprocessing step
 * `midas-letkf.Abs`: HPC benchmarking program
 * `midas-energyNorm.Abs`: needed in the evaluation step

# Run MIDAS (LetKF)

## Download database

The variable `${MIDAS_ARCHIVE}` should be set to a directory
where all the files will be downloaded on your system.

Download the data needed to run `midas-letkf.Abs`:
```bash
./download_dbase.sh ${MIDAS_ARCHIVE}
```

There will be an automatic check of `md5sum`s for each downloaded
file.  Since this step can be quite long, you can skip that step by
setting the environment variable `DOWNLOAD_DBASE_CHECK_MD5SUM` to
`no`.

## Choice of CPU decomposition

This will give you the possible CPU decomposition for the MIDAS LetKF global 10km configuration:

```bash
midas/tools/midas_scripts/midas.mpiTopoFinder --ni 3124 --nj 2084          \
               --min-tasks "minimum total number of MPI tasks to consider" \
               --max-tasks "maximum total number of MPI tasks to consider" \
               --max-diff  "maximum difference of grid points per MPI task allowed (in percentage) between the regular distribution and the last MPI task"
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
## load the MPI environment

ulimit -c unlimited

export CMCCONST=.
export TMG_ON=YES
export OMP_STACKSIZE=4G ## Or any other value for your system

cd ${MIDAS_WORK}
```

With `${letkf_program}` as the path to the program `midas-letkf.Abs`
that has been compiled at the build step, launch the program with:

```bash
cat > ptopo_nml <<EOF
 &ptopo
  npex=${npex}
  npey=${npey}
/
EOF

mpirun -n $((npex*npey)) ${letkf_program}
```

# Run verification

Verify the results with the following command providing
`${eneryNorm_program}` as the path to the program
`midas-eneryNorm.Abs`.  It is possible to provide results from several
executions with argument `-states`.  The variable
`${MIDAS_VERIFY_WQRKDIR}` is the path to the working directory the
program can use.

This script will provide a PASS or FAIL rating

```bash
## load the MPI environment

./verify -pgm ${eneryNorm_program} -date 2024091900                    \
         -nml ${PWD}/midas/maestro/suites/midas_system_tests/config/Tests/energyNorm/analmean/nml \
         -reference ${MIDAS_ARCHIVE}/reference/2024091900_000_analmean \
         -states ${MIDAS_WORK}/2024091900_000_analmean                 \
         -workdir ${MIDAS_VERIFY_WQRKDIR}
```

This process is requesting around 160 GB of RAM to run.

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
