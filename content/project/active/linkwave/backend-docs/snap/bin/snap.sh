#!/bin/bash

APP_NAME=snap
JAVA=/usr/bin/java

EXEC_PATH=`pwd -P`
SCRIPT_PATH=$( cd "$(dirname "$0")" ; pwd -P )
cd $SCRIPT_PATH/..

export $(grep -v '^#' bin/.env | xargs -0)

if [ $# -eq 1 ]; then
  echo $1
elif [ $1 = "encrypt" ] && [ $# -ge 2 ]; then
  echo $1 $2
else
  echo "usage: snap.sh start/stop/encrypt"
  echo "       start   : START LG U+ Snap Agent."
  echo "       stop    : STOP LG U+ Snap Agent."
  echo "       encrypt [plain text] ([key seed]) : Encrypt input text."
  exit
fi

p_count=$(ps -ef | grep "app.name=$APP_NAME" | grep -v 'grep ' | grep -v 'tail ' | wc -l)
if [ $1 = "start" ]; then
  if [ $p_count -eq 0 ]; then
    JVM_OPTION=$(cat bin/jvm_option | xargs)
    nohup $JAVA -Dapp.name=$APP_NAME $JVM_OPTION -jar lib/snap-$APP_VERSION.jar 2> log/$APP_NAME.err 1> log/$APP_NAME.out & echo $! > log/$APP_NAME.pid
    ps -ef | grep "app.name=$APP_NAME" | grep -v 'grep ' | grep -v 'tail '
  else
    echo "$APP_NAME is already running"
  fi
elif [ $1 = "stop" ]; then
  if [ $p_count -eq 1 ]; then
    kill $(ps -ef | grep "app.name=$APP_NAME" | grep -v 'grep ' | grep -v 'tail ' | awk '{print $2}')
  else
    echo "$APP_NAME is not running"
  fi
elif [ $1 = "encrypt" ]; then
  $JAVA -jar lib/snap-$APP_VERSION.jar utility encrypt $2 $3
fi

unset $(grep -v '^#' bin/.env | awk -F = '{print $1}' | xargs)

cd $EXEC_PATH
