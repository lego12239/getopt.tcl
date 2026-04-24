test:
	cd tests && ./tests.tcl

dist:
	SRCDIR=`basename $(PWD)`; \
	  git-ls-files | sed -re "s/^/$$SRCDIR\//" | \
	    (cd ..; tar -cT- | xz > $${SRCDIR}-3.0.1.txz)

