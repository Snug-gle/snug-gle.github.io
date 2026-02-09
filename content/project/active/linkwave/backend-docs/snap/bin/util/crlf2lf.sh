#!/bin/bash

EXEC_PATH=`pwd -P`
SCRIPT_PATH=$( cd "$(dirname "$0")" ; pwd -P )

if [ $# -eq 1 ]; then
  cd $SCRIPT_PATH/../..
  if [ $1 = "print" ]; then
    grep -rIl -m 1 $'\r' config/
#  elif [ $1 = "vim" ]; then
#    echo $1
#    grep -rIl -m 1 $'\r' config/ | xargs -I % vim -c "set ff=unix" -c ":wq" %
#    reset
  elif [ $1 = "sed" ]; then
    echo $1
    grep -rIl -m 1 $'\r' config/ | xargs -I % sed -n -i 's/\r//' %
  elif [ $1 = "perl" ]; then
    echo $1
    grep -rIl -m 1 $'\r' config/ | xargs -I % perl -pi -e 's/\r//' %
  elif [ $1 = "dos2unix" ]; then
    echo $1
    grep -rIl -m 1 $'\r' config/ | xargs -I % dos2unix %
  else
    echo "wrong input, $1"
    echo "print files end with CRLF"
    grep -rIl -m 1 $'\r' config/
  fi
  cd $EXEC_PATH
else
  echo "usage: CRLF2LF.sh [options]"
  echo "    options:"
  echo "        print : find and print files end with CRLF"
#  echo "        vim  : using 'vim -c "set ff=unix" -c ":wq" [file]' command"
  echo "        sed  : using 'sed -i 's/\r//' [file]' command."
  echo "        perl : using 'perl -pi -e 's/\r//' [file]' command"
  echo "        dos2unix : using 'dos2unix [file]' command"
  exit
fi
