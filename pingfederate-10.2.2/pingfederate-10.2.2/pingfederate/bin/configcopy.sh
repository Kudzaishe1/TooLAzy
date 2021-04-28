#!/usr/bin/env bash

DIRNAME=`dirname "$0"`/..
DIRNAME=`(cd "$DIRNAME" && pwd)`
# Set DIRNAME_ESC - this is DIRNAME but with spaces that are replaced with %20
DIRNAME_ESC=${DIRNAME// /%20}

if [ "x$1" = "x" ]; then
    echo USAGE:
    echo "       configcopy -Dconfigcopy.conf.file=<properties_file1>:<properties_file2>:..."
    echo
    echo "Refer to the README.txt file in the bin/configcopy_templates"
    echo "directory for a list of all commands and summary information. See the"
    echo "template files themselves for parameters associated with each"
    echo "command (or with use cases), as well as lists of Override Properties"
    echo "(configuration settings that can be modified in transit), where"
    echo "applicable."
    
else

    # Read an optional running configuration file
    if [ "x$RUN_CONF" = "x" ]; then
          RUN_CONF="$DIRNAME/bin/run.conf"
      fi
      if [ -r "$RUN_CONF" ]; then
         . "$RUN_CONF"
    fi

    CURRENTDIR=`pwd`

    cd "$DIRNAME"

    PF_LIB=lib
    SERVER_LIB=server/default/lib
    SERVER_DEPLOY=server/default/deploy
    PF_BIN=bin

    CLASSPATH=$DIRNAME/server/default/conf

    for jar in `ls $PF_LIB/*.jar 2>/dev/null`
    do
        CLASSPATH=$CLASSPATH:$DIRNAME/$jar
    done

    for jar in `ls $SERVER_LIB/*.jar 2>/dev/null`
    do
        CLASSPATH=$CLASSPATH:$DIRNAME/$jar
    done

    for jar in `ls $SERVER_DEPLOY/*.jar 2>/dev/null`
    do
        CLASSPATH=$CLASSPATH:$DIRNAME/$jar
    done

    for jar in `ls $PF_BIN/*.jar 2>/dev/null`
    do
        CLASSPATH=$CLASSPATH:$DIRNAME/$jar
    done

    if [ ! -d log ] ; then
        mkdir log
    fi

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

    cd "$CURRENTDIR"

    $JAVA \
        -cp "$CLASSPATH" \
        "$@" \
        -Dpf.home="$DIRNAME" \
        -Dpf.server.default.dir="$DIRNAME/server/default" \
        -Dlog4j.configurationFile="file:///$DIRNAME_ESC/bin/configcopy.log4j2.xml" \
        -Dorg.apache.axis.components.net.SecureSocketFactory=org.sourceid.common.soap.soap11.JSSESocketFactory \
        com.pingidentity.console.ConfigCopy
fi

echo ""
echo "WARNING: This tool has been deprecated."
echo ""

