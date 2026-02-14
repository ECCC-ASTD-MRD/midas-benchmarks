#
# jio/Makefile
#

CC ?= icx
#CC = gcc

default:

clean:
	rm -f *.a *.o

install: lib
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
	$(CC) -c -fpic -o s.jio-prof.o $(OMP) jio-uni-2.c
	ar rcv s.jio-prof.a s.jio-prof.o
