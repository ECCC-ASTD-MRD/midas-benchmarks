#
# timing/Makefile
#

CC ?= icx
#CC = gcc

default:

clean:
	rm -f *.o *.a

install: 
	if [ "$(INSTALL_DIR)" = "" ]; then echo "error: INSTALL_DIR not set"; exit 1; fi
	mkdir -p $(INSTALL_DIR)/lib
	cp *.a $(INSTALL_DIR)/lib

lib:
# with icc/icx or with gcc
	@if [ "$(CC)" = "icx" ]; then OMP=-qopenmp $(MAKE) compile; \
	else if [ "$(CC)" = "gcc" ]; then OMP=-fopenmp $(MAKE) compile; \
	else if [[ "$(CC)" = *clang ]]; then OMP=-fopenmp $(MAKE) compile; \
	fi ; fi ; fi ;

compile:
	$(CC) -O2 -c $(OMP) hpco_fort_hpm.c weak*.c rebind.c reporter.c history_trace.c ; \
	ar rv libhpcoperf.a hpco_fort_hpm.o weak*.o rebind.o reporter.o history_trace.o; \
