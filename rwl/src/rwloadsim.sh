#!/bin/sh

# RWP*Load Simulator
#
# Copyright (c) 2020 Oracle Corportaion
# Licensed under the Universal Permissive License v 1.0
# as shown at https://oss.oracle.com/licenses/upl/

# Look for an appropriate libclntsh.so and call the right
# executable
#
# History
#
# bengsig 01-may-2019 - Creation

if test -z "$LD_LIBRARY_PATH"
then
  echo 'RWL-187: error: LD_LIBRARY_PATH environment is not set' 1>&2
  exit 1
fi

rwloadsim=''


for dir in `echo $LD_LIBRARY_PATH | sed 's/:/ /g'`
do
  if test -r "$dir"/libclntsh.so.20.1 
  then
    rwloadsim=rwloadsim20
  else
    if test -r "$dir"/libclntsh.so.19.1 
    then
      rwloadsim=rwloadsim19
    else
      if test -r "$dir"/libclntsh.so.18.1
      then
	rwloadsim=rwloadsim18
      else
	if test -r "$dir"/libclntsh.so.12.1
	then
	  rwloadsim=rwloadsim12
	else
	  if test -r "$dir"/libclntsh.so.11.1
	  then
	    rwloadsim=rwloadsim11
	  fi
	fi
      fi
    fi
  fi
  if test ! -z "$rwloadsim"
  then
    break
  fi
done

if test -z "$rwloadsim" 
then
  echo 'RWL-188: error: LD_LIBRARY_PATH does not contain Oracle client library' 1>&2
  exit 1
fi

# Do our own search such that the full path is used
# in the exec command line
for dir in `echo $PATH | sed 's/:/ /g'`
do
  if test -x "$dir"/$rwloadsim
  then
    exec "$dir"/$rwloadsim "$@"
  fi
done

echo "RWL-243: error: Cannot find $rwloadsim executable in PATH" 1>&2
exit 1
