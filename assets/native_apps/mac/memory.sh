#!/bin/bash
detail=`system_profiler SPHardwareDataType -detailLevel mini`
memory=`echo "$detail" | grep -m 1 "Memory" | awk -F': ' '{print $2}'`
echo $memory
