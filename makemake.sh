#!/bin/bash

# Copyright (c) 2021 Oracle Corportaion
# Licensed under the Universal Permissive License v 1.0
# as shown at https://oss.oracle.com/licenses/upl/

# RWP*Load Simulator - generate the top level Makefile
# and the Makefile in src

# History
#
# bengsig  28-jun-2022 - Generate project
# bengsig  01-jun-2022 - Add cleano target in src/Makefile
# bengsig  18-mar-2022 - Add ctags in flex .l files
# bengsig  29-mar-2021 - Stop using .yi include files for parser
# bengsig  18-feb-2020 - watermark
# bengsig  17-feb-2020 - Add rwlerror utility
# bengsig  23-dec-2020 - Solaris
# bengsig  14-dec-2020 - rwlman is now in bin; no rwlman.sh
# bengsig  02-dec-2020 - Directory structure change
# bengsig  18-nov-2020 - Use INT in stead of SIGINT for portability and exit
# bengsig  08-sep-2020 - Use printf in stead of echo for Solaris portability
# bengsig  03-sep-2020 - Don't allow 11 as primary
# bengsig  01-sep-2020 - Add a "clean" entry to top Makefile, improved tags
# bengsig  28-aug-2020 - Fix use of GCC flags for debug etc
# bengsig  15-aug-2020 - Creation
 
clean=`mktemp`
trap "rm -f $clean; exit" EXIT INT

fail=2
if test -f Makefile
then
  echo Makefile already exists, please remove or rename 1>&2
  exit $fail
fi

if test -f src/Makefile
then
  echo src/Makefile already exists, please remove or rename 1>&2
  exit $fail
fi

printf "Please enter your primary development release [12/18/19/21]: "
read primary

case $primary in
  12|18|19|21)
    ;;
  *)
    echo Development release must be one of 12, 18, 19, 21
    exit $fail
    ;;
esac

printf "Please enter either ORACLE_HOME or top of instant client for release $primary: "
read phome

fail=1

if test -f $phome/sdk/include/oci.h 
then
  echo $phome identified as Instant Client
  oracle_lib=$phome
  oracle_include=$phome/sdk/include
  fail=0
fi

if test -f $phome/rdbms/public/oci.h
then
  if test x$oracle_lib = x
  then
    echo $phome identified as ordinary ORACLE_HOME
  else
    echo Overwriting Instant Client and using $phome as ordinary ORACLE_HOME
  fi
  oracle_lib=$phome/lib
  oracle_include=$phome/rdbms/public
  fail=0
fi

if test $fail -gt 0
then
  echo Cannot find oci.h as expected in $phome 1>&2
  exit $fail
fi

# Check bison version
case `bison --version | sed -r -n '/^bison.*([1-9]+)\.[0-9]+\.[0-9]+.*$/s//\1/ p'` in
  0|1|2) 
    echo 'bison must be at least version 3.0.4' 1>&2
    exit 1
    ;;
  3) BISONFLAGS=
    ;;
  4|5) BISONFLAGS=
       echo rwloadsim compile was never tested with
       bison --version
    ;;
esac
    


cat > Makefile <<END
# This Makefile is generated by makemake.sh, 
# your changes will be overwritten
#
# Make just the release that is our main building release
# and also increase the patch level by 1
#
only: 
	(cd src; ./rwlpatch.sh; make MAJOR_VERSION=$primary ORACLE_LIB=$oracle_lib ORACLE_INCLUDE=$oracle_include)

# Make all the other releases, documentation, etc
all: only docs/ERRORLIST.md
END

cat >> $clean <<END

clean:
	(cd src; make MAJOR_VERSION=$primary ORACLE_LIB=$oracle_lib ORACLE_INCLUDE=$oracle_include clean)
END

cat > src/Makefile <<END
#
# There are these three fundamental variables
# that are being overwritten when compiling
# for anything but the default version
MAJOR_VERSION=$primary
ORACLE_LIB=$oracle_lib
ORACLE_INCLUDE=$oracle_include
#
# If you need to change this file, please change makemake.sh
# accordingly
#
END
cat >> src/Makefile <<'END'

# List of all object files, rwlpatch.o is generic for 
# all versions, the rest are compiled for each client
# version seperately in separate directories
RWLSHROBJECTS = rwlpatch.o \
  obj$(MAJOR_VERSION)/rwlparser.tab.o \
  obj$(MAJOR_VERSION)/rwldiprs.tab.o \
  obj$(MAJOR_VERSION)/lex.rwlz.o \
  obj$(MAJOR_VERSION)/lex.rwla.o \
  obj$(MAJOR_VERSION)/lex.rwly.o \
  obj$(MAJOR_VERSION)/rwlerror.o \
  obj$(MAJOR_VERSION)/rwlvariable.o \
  obj$(MAJOR_VERSION)/rwlexprcomp.o \
  obj$(MAJOR_VERSION)/rwlexpreval.o \
  obj$(MAJOR_VERSION)/rwlcodeadd.o \
  obj$(MAJOR_VERSION)/rwlcoderun.o \
  obj$(MAJOR_VERSION)/rwlrast.o \
  obj$(MAJOR_VERSION)/rwldynsql.o \
  obj$(MAJOR_VERSION)/rwlsql.o \
  obj$(MAJOR_VERSION)/rwlmisc.o 

RWLOBJECTS = $(RWLSHROBJECTS) obj$(MAJOR_VERSION)/rwlmain.o
RWLGENOBJECTS = $(RWLSHROBJECTS) obj$(MAJOR_VERSION)/rwlgenexec.o


# List of generated files
GENFILES=rwlparser.tab.c lex.rwly.c rwlparser.tab.h rwldiprs.tab.c rwldiprs.tab.h lex.rwlz.c lex.rwla.c

# List of all source files that are input for ctags
RWLTAGSOURCES = rwl.h \
  rwlerror.h \
  rwlcodeadd.c \
  rwlcoderun.c \
  rwlerror.c \
  rwlexprcomp.c \
  rwlexpreval.c \
  rwllexer.l \
  rwlmain.c \
  rwlrast.c \
  rwldynsql.c \
  rwlsql.c \
  rwlvariable.c \
  rwlmisc.c \
  rwlparser.y \
  rwldiprs.y \
  rwldilex.l \
  rwlarglex.l \
  rwlport.h

# List all sources
RWLSOURCES = $(RWLTAGSOURCES) \
  rwltypedefs.h rwlmainerror.c

# Change this if you want debugging
GCC_O=-O3 
# GCC_O=-O0 -g

# We set all variables and don't use any of those
# already existing in make
GCC=gcc
# Used by all
GCCFLAGSALL=-m64

OCI_LIBS=-L$(ORACLE_LIB) -lclntsh

# Different flags are needed for pure and generated C files
MYGCCFLAGSC = $(GCCALLFLAGS) $(GCC_O) -W -Wall -Wextra -Wconversion
MYGCCFLAGSY = $(GCCALLFLAGS) $(GCC_O) -W -Wall -Wextra 
MYGCCFLAGSL = $(GCCALLFLAGS) $(GCC_O) -W -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare

GCCFLAGSC = $(MYGCCFLAGSC) -D RWL_GCCFLAGS='$(MYGCCFLAGSC)'
GCCFLAGSY = $(MYGCCFLAGSY) -D RWL_GCCFLAGS='$(MYGCCFLAGSY)'
GCCFLAGSL = $(MYGCCFLAGSL) -D RWL_GCCFLAGS='$(MYGCCFLAGSL)'

FLEX=flex

BISON=bison
END
echo BISONFLAGS=$BISONFLAGS >> src/Makefile
cat >> src/Makefile <<'END'

only: ../bin/rwloadsim$(MAJOR_VERSION) ../bin/rwloadsim ../bin/rwlerror ../lib/rwlgenmain$(MAJOR_VERSION).o

ctags: $(RWLSOURCES)
	rm -f tags cscope.out
	ctags --c-kinds=-t $(RWLTAGSOURCES) 
	sh lextag.sh rwllexer.l
	sh lextag.sh rwldilex.l
	sh lextag.sh rwlarglex.l
	cscope -b -c $(RWLSOURCES) 
	chmod ugo-w tags cscope.out # prevent inadvertent updates

# The full parser:
obj$(MAJOR_VERSION)/rwlparser.tab.o: rwlparser.tab.c
	$(GCC) -c $(GCCFLAGSY) -I$(ORACLE_INCLUDE) rwlparser.tab.c -o obj$(MAJOR_VERSION)/rwlparser.tab.o

rwlparser.tab.h rwlparser.tab.c: rwlparser.y rwl.h rwlerror.h
	$(BISON) $(BISONFLAGS) -v -d rwlparser.y

# The parser for $if $then directive 
obj$(MAJOR_VERSION)/rwldiprs.tab.o: rwldiprs.tab.c
	$(GCC) -c $(GCCFLAGSY) -I$(ORACLE_INCLUDE) rwldiprs.tab.c -o obj$(MAJOR_VERSION)/rwldiprs.tab.o

rwldiprs.tab.h rwldiprs.tab.c: rwldiprs.y rwl.h rwlerror.h
	$(BISON) $(BISONFLAGS) -v -d rwldiprs.y

# The ordinary lexer
obj$(MAJOR_VERSION)/lex.rwly.o: lex.rwly.c 
	$(GCC) -c $(GCCFLAGSL) -I$(ORACLE_INCLUDE) lex.rwly.c -o obj$(MAJOR_VERSION)/lex.rwly.o

lex.rwly.c: rwllexer.l rwl.h rwlerror.h rwlparser.tab.h
	$(FLEX) --prefix=rwly rwllexer.l

# The lexer for $if $then directive
obj$(MAJOR_VERSION)/lex.rwlz.o: lex.rwlz.c 
	$(GCC) -c $(GCCFLAGSL) -I$(ORACLE_INCLUDE) lex.rwlz.c -o obj$(MAJOR_VERSION)/lex.rwlz.o

lex.rwlz.c: rwldilex.l rwl.h rwlerror.h rwldiprs.tab.h
	$(FLEX) --prefix=rwlz rwldilex.l

# The lexer for scanning first file for option directives
obj$(MAJOR_VERSION)/lex.rwla.o: lex.rwla.c 
	$(GCC) -c $(GCCFLAGSL) -I$(ORACLE_INCLUDE) lex.rwla.c -o obj$(MAJOR_VERSION)/lex.rwla.o

lex.rwla.c: rwlarglex.l rwl.h rwlerror.h rwldiprs.tab.h
	$(FLEX) --prefix=rwla rwlarglex.l

# The almost full object for generation
../lib/rwlgenmain$(MAJOR_VERSION).o: obj$(MAJOR_VERSION)/rwlgenexec.o ../bin/rwloadsim$(MAJOR_VERSION)
	ld -r -o ../lib/rwlgenmain$(MAJOR_VERSION).o $(RWLGENOBJECTS) rwlwatermark.o

# All the normal object files
obj$(MAJOR_VERSION)/rwlgenexec.o: rwlmain.c 
	$(GCC) -DRWL_GEN_EXEC -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlgenexec.o rwlmain.c
obj$(MAJOR_VERSION)/rwlmain.o: rwlmain.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlmain.o rwlmain.c
obj$(MAJOR_VERSION)/rwlcoderun.o: rwlcoderun.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlcoderun.o rwlcoderun.c
obj$(MAJOR_VERSION)/rwlerror.o: rwlerror.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlerror.o rwlerror.c
obj$(MAJOR_VERSION)/rwlexprcomp.o: rwlexprcomp.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlexprcomp.o rwlexprcomp.c
obj$(MAJOR_VERSION)/rwlexpreval.o: rwlexpreval.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlexpreval.o rwlexpreval.c
obj$(MAJOR_VERSION)/rwlrast.o: rwlrast.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlrast.o rwlrast.c
obj$(MAJOR_VERSION)/rwldynsql.o: rwldynsql.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwldynsql.o rwldynsql.c
obj$(MAJOR_VERSION)/rwlsql.o: rwlsql.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlsql.o rwlsql.c
obj$(MAJOR_VERSION)/rwlvariable.o: rwlvariable.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlvariable.o rwlvariable.c
obj$(MAJOR_VERSION)/rwlmisc.o: rwlmisc.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlmisc.o rwlmisc.c
obj$(MAJOR_VERSION)/rwlcodeadd.o: rwlcodeadd.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o obj$(MAJOR_VERSION)/rwlcodeadd.o rwlcodeadd.c
rwlpatch.o: rwlpatch.c 
	$(GCC) -c $(GCCFLAGSC) -I$(ORACLE_INCLUDE) -o rwlpatch.o rwlpatch.c

../bin/rwlerror: rwlmainerror.c rwl.h rwlerror.h
	$(GCC) $(GCCFLAGSC) -I $(ORACLE_INCLUDE) -o ../bin/rwlerror rwlmainerror.c

../bin/rwloadsim$(MAJOR_VERSION): $(RWLOBJECTS) 
	sh rwlwatermark.sh
	$(GCC) -c -o rwlwatermark.o rwlwatermark.c
	env LD_LIBRARY_PATH=$(ORACLE_LIB) $(GCC) $(GCC_O) -o ../bin/rwloadsim$(MAJOR_VERSION) $(RWLOBJECTS) rwlwatermark.o $(OCI_LIBS) -lm -lrt


clean:
	rm -f $(RWLOBJECTS) $(RWLGENOBJECTS) $(GENFILES) ../bin/rwloadsim$(MAJOR_VERSION) ../bin/rwlerror

cleano:
	rm -f $(RWLOBJECTS) 

$(RWLOBJECTS): rwl.h rwlerror.h

.SUFFIXES:	.i
.c.i:
	$(GCC) -E -I$(ORACLE_INCLUDE) -D RWL_GCCFLAGS='-I -E' $< > $*.i

sources: $(RWLSOURCES)
	@echo $(RWLSOURCES)

END


secondary=nothing
until test -z "$secondary"
do
  
  printf "Please enter a secondary development release, return for none/no more : "
  read secondary

  if test x$secondary = x$primary
  then
    echo Secondary is the same as the primary
  else

    case $secondary in
      11|12|18|19|21)

	printf "Please enter either ORACLE_HOME or top of instant client for release $secondary: "
	read shome

	fail=3
	if test -f $shome/sdk/include/oci.h 
	then
	  echo $shome identified as Instant Client
	  oracle_lib=$shome
	  oracle_include=$shome/sdk/include
	  fail=0
	fi

	if test -f $shome/rdbms/public/oci.h
	then
	  echo $shome identified as ordinary ORACLE_HOME
	  oracle_lib=$shome/lib
	  oracle_include=$shome/rdbms/public
	  fail=0
	fi

	if test $fail -gt 0
	then
	  echo Cannot find oci.h as expected in $shome 
	else
	  printf "\t(cd src; make MAJOR_VERSION=$secondary ORACLE_LIB=$oracle_lib ORACLE_INCLUDE=$oracle_include)\n" >> Makefile
	  printf "\t(cd src; make MAJOR_VERSION=$secondary ORACLE_LIB=$oracle_lib ORACLE_INCLUDE=$oracle_include clean)\n" >> $clean
	fi
	;;

      ?*)
	echo Secondary release must be one of 11, 12, 18, 19, 21
	;;
    esac
  fi
done

cat $clean >> Makefile

cat >> Makefile <<'END'

docs/ERRORLIST.md: src/rwlerror.h
	sh errorlist.sh | sed 's%\\%\&#134;%g' > docs/ERRORLIST.md

# Run the test shell script
test: only
	(cd test; sh test.sh -e)

# Prepare the tgz file for shipping
ship: all 
	sh makeship.sh

END

echo Makefiles have been created, you can type make now
