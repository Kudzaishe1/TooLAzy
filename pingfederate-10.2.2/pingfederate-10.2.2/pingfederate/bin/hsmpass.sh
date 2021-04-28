#!/bin/sh

DIRNAME=`dirname "$0"`
ROOT=$DIRNAME/..
DIRNAME=`(cd "$DIRNAME" && pwd)`

ROOT_LIB="$ROOT/lib"
SERVER_LIB="$ROOT/server/default/lib"

PASSWORD_FILE="$ROOT/server/default/data/hsmpasswd.txt"

# Read an optional running configuration file
if [ "x$RUN_CONF" = "x" ]; then
    RUN_CONF="$DIRNAME/run.conf"
fi
if [ -r "$RUN_CONF" ]; then
    . "$RUN_CONF"
fi

CLASSPATH="$ROOT_LIB/*"
CLASSPATH="$CLASSPATH:$DIRNAME/*"
CLASSPATH="$CLASSPATH:$SERVER_LIB/*"

# Setup the JVM
if [ "x$JAVA" = "x" ]; then
    if [ "x$JAVA_HOME" != "x" ]; then
            JAVA="$JAVA_HOME/bin/java"
    else
            JAVA="java"
        echo "JAVA_HOME is not set.  Unexpected results may occur."
        echo "Set JAVA_HOME to the directory of your local JDK to avoid this message."
    fi
fi

"$JAVA" -classpath "$CLASSPATH" -Dpassword.file="$PASSWORD_FILE" com.pingidentity.console.PasswordChanger HSM "$@"
