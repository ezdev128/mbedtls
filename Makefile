
DESTDIR=/usr/local
PREFIX=mbedtls_

.PHONY: all no_test programs lib tests install uninstall clean test check covtest lcov apidoc apidoc_clean

all: lib programs tests

no_test: programs

programs:
ifndef SKIP_PROGRAMS
	$(MAKE) -C programs
endif

lib:
	$(MAKE) -C library static
	$(MAKE) -C library shared

tests: lib
ifndef SKIP_TESTS
	$(MAKE) -C tests
endif

ifndef WINDOWS
install: no_test
	mkdir -p $(DESTDIR)/include/mbedtls
	cp -r include/mbedtls $(DESTDIR)/include
	
	mkdir -p $(DESTDIR)/lib
	cp -a library/*.a $(DESTDIR)/lib
	cp -a library/*.so $(DESTDIR)/lib
	cp -a library/*.so.* $(DESTDIR)/lib
	
ifndef SKIP_PROGRAMS
	mkdir -p $(DESTDIR)/bin
	for p in programs/*/* ; do              \
	    if [ -x $$p ] && [ ! -d $$p ] ;     \
	    then                                \
	        f=$(PREFIX)`basename $$p` ;     \
	        cp $$p $(DESTDIR)/bin/$$f ;     \
	    fi                                  \
	done
endif

uninstall:
	rm -rf $(DESTDIR)/include/mbedtls
	rm -f $(DESTDIR)/lib/libmbedtls.*
	rm -f $(DESTDIR)/lib/libmbedx509.*
	rm -f $(DESTDIR)/lib/libmbedcrypto.*
	
ifndef SKIP_PROGRAMS
	for p in programs/*/* ; do              \
	    if [ -x $$p ] && [ ! -d $$p ] ;     \
	    then                                \
	        f=$(PREFIX)`basename $$p` ;     \
	        rm -f $(DESTDIR)/bin/$$f ;      \
	    fi                                  \
	done
endif
endif

clean:
	$(MAKE) -C library clean
	$(MAKE) -C programs clean
	$(MAKE) -C tests clean
ifndef WINDOWS
	find . \( -name \*.gcno -o -name \*.gcda -o -name *.info \) -exec rm {} +
endif

check: lib
	$(MAKE) -C tests check

test: check

ifndef WINDOWS
# note: for coverage testing, build with:
# make CFLAGS='--coverage -g3 -O0'
covtest:
	$(MAKE) check
	programs/test/selftest
	tests/compat.sh
	tests/ssl-opt.sh

lcov:
	rm -rf Coverage
	lcov --capture --initial --directory library -o files.info
	lcov --capture --directory library -o tests.info
	lcov --add-tracefile files.info --add-tracefile tests.info -o all.info
	lcov --remove all.info -o final.info '*.h'
	gendesc tests/Descriptions.txt -o descriptions
	genhtml --title "mbed TLS" --description-file descriptions --keep-descriptions --legend --no-branch-coverage -o Coverage final.info
	rm -f files.info tests.info all.info final.info descriptions

apidoc:
	mkdir -p apidoc
	doxygen doxygen/mbedtls.doxyfile

apidoc_clean:
	rm -rf apidoc
endif
