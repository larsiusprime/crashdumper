#!/bin/bash
detail=`system_profiler SPHardwareDataType -detailLevel mini`
cpuType=`echo "$detail" | grep -m 1 "Processor Name" | awk -F': ' '{print $2}'`
cpuSpeed=`echo "$detail" | grep -m 1 "Processor Speed" | awk -F': ' '{print $2}'`
echo $cpuType $cpuSpeed
