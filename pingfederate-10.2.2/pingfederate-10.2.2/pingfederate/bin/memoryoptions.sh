#!/bin/bash
#
# Script to generate optimized memory options for PingFederate
#

set -e

if [ "x$PF_HOME" = "x" ]; then
  dn=`dirname $0`
  PF_HOME=`cd $dn/..; pwd`
fi

runProperties="$PF_HOME/bin/run.properties"
if [ ! -f "$runProperties" ]; then
  echo "$runProperties does not exist"
  exit 1
fi

#Determine runtime mode from run.properties
pfRuntimeMode=$( awk '/^pf.operational.mode/{print $0}' "${runProperties}" |  cut -d= -f2 )

#Get available memory and number of processors (cores w/ hyperthreading)
maybeAvailable=`free | grep free | awk '{ print $6 }'`
if [ "$maybeAvailable" == "available" ]; then
  #If free command presents available, use it
  availableMem=`free | grep "Mem:" | awk '{ print $7 }'`
else
  #Otherwise, use free column
  availableMem=`free | grep "Mem:" | awk '{ print $4 }'`
fi
cpuCount=`nproc --all`


#Heap size should be at most 80% of available memory, in logical steps
#If system has 6 or more CPU cores, max heap is 6GB, otherwise 2GB
if [ $availableMem -lt 819200 ]; then
  #0 - 800 MB
  heap=512
  newSize=256
elif [ $availableMem -lt 983040 ]; then
  #800 - 960 MB
  heap=640
  newSize=320
elif [ $availableMem -lt 1146880 ]; then
  #960 - 1120 MB
  heap=768
  newSize=384
elif [ $availableMem -lt 1310720 ]; then
  #1120 - 1280 MB
  heap=896
  newSize=448
elif [ $availableMem -lt 1638400 ] || [ "$pfRuntimeMode" == "CLUSTERED_CONSOLE" ]; then
  #1280 - 1920 MB
  #Max size for CLUSTERED_CONSOLE and CLUSTERED_CONSOLE_REPLICA mode
  heap=1024
  newSize=512
elif [ $availableMem -lt 1966080 ]; then
  #1600 - 1920 MB
  heap=1280
  newSize=640
elif [ $availableMem -lt 2621440 ]; then
  #1920 - 2560 MB
  heap=1536
  newSize=768
elif [ $availableMem -lt 3276800 ] || [ $cpuCount -lt 4 ]; then
  #2560 - 3200 MB
  #Max size for less than 4 CPUs
  heap=2048
  newSize=1024
elif [ $availableMem -lt 3932160 ]; then
  #3200 - 3840 MB
  heap=2560
  newSize=1280
elif [ $availableMem -lt 4587520 ]; then
  #3840 - 4480 MB
  heap=3072
  newSize=1536
elif [ $availableMem -lt 5242880 ]; then
  #4480 - 5120 MB
  heap=3584
  newSize=1792
elif [ $availableMem -lt 6291456 ] || [ $cpuCount -lt 6 ]; then
  #5120+ MB
  heap=4096
  newSize=2048
elif [ $availableMem -ge 6291456 ] && [ $cpuCount -ge 6 ]; then
  #6144+ MB
  heap=6144
  newSize=3072
fi

#Get current date and time
dt=`date "+%Y-%m-%d_%H-%M-%S-%N"`
Y=${dt:0:4}
M=${dt:5:2}
D=${dt:8:2}
H=${dt:11:2}
MN=${dt:14:2}
S=${dt:17:2}
MIL=${dt:20:3}
backupDateTime="$Y-$M-$D_$H-$MN-$S-$MIL"
generatedTime="$Y/$M/$D $H:$MN:$S:$MIL"

#Output Template
#text position is important
file=`cat << TEMPLATE_END
# Auto-generated JVM memory options for PingFederate
#
# Generated: ${generatedTime}
#
# Each non-commented and non-empty line will be added as a Java option when PingFederate is started.
# Comments can be added to this file by starting a line with the # character.
#

#Minimum heap size
-Xms${heap}m
#Maximum heap size
-Xmx${heap}m
#Minimum size for the Young Gen space
-XX:NewSize=${newSize}m
#Maximum size for the Young Gen space
-XX:MaxNewSize=${newSize}m
#Use the parallel garbage collector
-XX:+UseParallelGC
TEMPLATE_END`


if [ $cpuCount -ge 2 ]; then
#first empty line is important
#text position is important
file+=`cat << TEMPLATE_END

#Use parallel garbage collection for full collections
-XX:-UseParallelOldGC
TEMPLATE_END`
fi

jvmMemoryOpts="$PF_HOME/bin/jvm-memory.options"
if [ -f "$jvmMemoryOpts" ]; then
  #Make a backup before generating a new file
  cp "$jvmMemoryOpts" "$PF_HOME/bin/jvm-memory_${backupDateTime}.options"
fi


echo "$file" > "$jvmMemoryOpts"
echo
echo "Generated new jvm-memory.options."