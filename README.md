=MIDAS benchmark=

This project contains the scripts to launch the several experiments
needed to evaluate the acceptable spread of the LETKF results in the
context of the MIDAS benchmark project.

This is documented in https://gitlab.science.gc.ca/atmospheric-data-assimilation/midas/-/issues/980

## MIDAS compilation

To compile MIDAS, one must do the commands:
```bash
mkdir -pv midas/compiledir/build
cd midas/compiledir/build
source ../../src/config.dot.sh
cmake ../..
make -j
make install
```

The programs will be installed under `midas/compiledir/midas_abs`.

### Note on the MIDAS code

This particular project is using a special version of MIDAS which
removes the dependency on SQLite files.  It is the branch
`for-benchmark`.

## Launching the program

To launch the program, you can use the `launcher` script to submit an
execution of `midas-letkf.Abs` on the supercomputer.  In that file,
`launcher`, edit the variables `midas_version` and `label` to identify
the version and the label of the results.

You will surely need to adapt the script to your context.

## Verify the program

You can use the program `midas-energyNorm.Abs` to check the result of
the execution.  The compilation of that program included.  To launch
the program, adapt the script `verify` to your needs.

## Check the timings of the execution

To compare the timing of the execution, one can use
`midas/tools/timingTool/midas.timingTool`:
```bash
midas/tools/timingTool/midas.timingTool ${listing}
```

You can compare two listings with the command:
```bash
midas/tools/timingTool/midas.timingTool ${listing} --reference ${reference_listing} --diff
```
