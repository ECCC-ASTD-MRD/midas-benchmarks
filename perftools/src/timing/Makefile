#
# timing/Makefile
#
src=$(wildcard *.c)
obj=$(src:.c=.o)
CC ?= icx
#CC = gcc
PREFIX ?= $(INSTALL_DIR)
LIBNAME = libhpcoperf.a


ifeq ($(CC),icx)
	OMP=-qopenmp
else
	OMP=-fopenmp
endif

ifeq ($(shell uname),Darwin)
	INSTALL=ginstall
	LDFLAGS="-L/opt/homebrew/opt/libomp/lib"
	CPPFLAGS="-I/opt/homebrew/opt/libomp/include"
else
	INSTALL=install
endif

default: lib
clean:
	rm -f *.o *.a
install: lib
	$(INSTALL) -m 644 $(LIBNAME) -D $(DESTDIR)$(PREFIX)/lib/$(LIBNAME)
lib: $(LIBNAME)
$(LIBNAME): $(obj)
	ar rv $@ $<
%.o:%.c
	$(CC) -c $(CPPFLAGS) $(OMP) -o $@ $^
vars:
	@echo "src=$(src)"
	@echo "obj=$(obj)"

