#!/usr/bin/env bash

if [ $# -eq 1 ]
then
  if [ $1 = "-l" ]
  then
    echo "$0 -l: missing password"
    echo "Try '$0 --help' for more information."
    exit 1
  fi
fi

if [ "$1" = "--help" ]
then
  echo 'Usage:' `basename $0` '[-l PASSWORD] [PASSWORD]'
  echo 'Prompts for a password, obfuscates it, then prints the result.'
  echo 'To avoid prompting, a PASSWORD argument may be specified. However, this is generally less secure.'
  echo 'If PASSWORD contains special characters, it should be enclosed in single quotes.'
  echo
  echo '  -l, Obfuscate using the legacy AES algorithm.'
  exit 1
fi

if [ $# -ge 3 ]
then
  echo "Validation Error: Invalid arguments."
  echo "Try '$0 --help' for more information."
  exit 1
fi

if [ $# -eq 2 ]
then
  if [ $1 != "-l" ]
  then
    echo "Validation Error: Invalid arguments."
    echo "Try '$0 --help' for more information."
    exit 1
  fi
fi

DIRNAME=`dirname "$0"`/..
DIRNAME=`(cd "$DIRNAME" && pwd)`
# Set DIRNAME_ESC - this is DIRNAME but with spaces that are replaced with %20
DIRNAME_ESC=${DIRNAME// /%20}
DEFAULT_DIR="$DIRNAME/server/default"

# Read an optional running configuration file
if [ "x$RUN_CONF" = "x" ]; then
    RUN_CONF="$DIRNAME/bin/run.conf"
fi
if [ -r "$RUN_CONF" ]; then
    . "$RUN_CONF"
fi

CLASSPATH="$CLASSPATH:$DEFAULT_DIR/lib/*"
CLASSPATH="$CLASSPATH:$DEFAULT_DIR/deploy/*"
CLASSPATH="$CLASSPATH:$DEFAULT_DIR/conf/"

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

"$JAVA" -Dlog4j.configurationFile="file:///$DIRNAME_ESC/bin/obfuscate.log4j2.xml" -Dpf.server.default.dir="$DEFAULT_DIR" -cp "$CLASSPATH" com.pingidentity.crypto.PasswordEncoder "$@"

