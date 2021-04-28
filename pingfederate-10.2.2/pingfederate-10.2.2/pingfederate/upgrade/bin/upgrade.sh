#!/usr/bin/env bash

DIRNAME=`dirname $0`/..
DIRNAME=`(cd $DIRNAME && pwd)`
# Set DIRNAME_ESC - this is DIRNAME but with spaces that are replaced with %20
DIRNAME_ESC=${DIRNAME// /%20}
PROGNAME=`basename $0`
GREP="grep"

# Use the maximum available, or set MAX_FD != -1 to use that
MAX_FD="maximum"

#
# Helper to complain.
#
warn() {
    echo "${PROGNAME}: $*"
}

#
# Helper to fail.
#
die() {
    warn $*
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false;
darwin=false;
case "`uname`" in
    CYGWIN*)
        cygwin=true
        ;;

    Darwin*)
        darwin=true
        ;;
esac

# For Cygwin, ensure paths are in UNIX format before anything is touched
if $cygwin ; then
    [ -n "$JBOSS_HOME" ] &&
        JBOSS_HOME=`cygpath --unix "$JBOSS_HOME"`
    [ -n "$JAVA_HOME" ] &&
        JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
    [ -n "$JAVAC_JAR" ] &&
        JAVAC_JAR=`cygpath --unix "$JAVAC_JAR"`
fi

# Setup the JVM
if [ "x$JAVA" = "x" ]; then
    if [ "x$JAVA_HOME" != "x" ]; 
    then
	    JAVA="$JAVA_HOME/bin/java"
            echo
    else
	    JAVA="java"
        warn "JAVA_HOME is not set.  Please set the JAVA_HOME environment variable to a JDK directory path."
	exit 1
    fi
fi

# check java version
JAVA_VERSION_STRING=`"$JAVA" -version 2>&1 | head -1 | cut -d '"' -f2`
javaSupportedVersion=0
javaIsJava8=0

case "$JAVA_VERSION_STRING" in
    1.8*)            # Java 8
        javaSupportedVersion=1
        javaIsJava8=1
        ;;
    1.*)             # Earlier than Java 8 not supported
        ;;
    9|9.*|10|10.*)   # Pre-LTS Java 9 and 10 not supported
        ;;
    *)               # Java 11 or later
        javaSupportedVersion=1
        ;;
esac

if [[ $javaSupportedVersion == 0 ]]; then
        echo ""
        echo "!! WARNING !!"
        echo "Java version ${JAVA_VERSION_STRING} is not supported for running PingFederate. Please install Java 8 or 11."
        echo ""
fi

CLASSPATH="$DIRNAME/lib/*"

"$JAVA" -Xms128m -Xmx128m -cp "$CLASSPATH" -Dupgrade.home.dir="$DIRNAME" -Dlog.dir="$DIRNAME/log" -Dlog4j.configurationFile="file:///$DIRNAME_ESC/bin/log4j2.xml" com.pingidentity.pingfederate.migration.UpgradeUtility "$@"
