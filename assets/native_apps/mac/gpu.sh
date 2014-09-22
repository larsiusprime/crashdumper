#!/bin/bash
detail=`system_profiler SPDisplaysDataType`
chipset=`echo "$detail" | grep -m 1 "Chipset Model" | awk -F': ' '{print $2}'`
memory=`echo "$detail" | grep -m 1 "VRAM" | awk -F': ' '{print $2}'`
resolution=`echo "$detail" | grep -m 1 "Resolution" | awk -F': ' '{print $2}'`
echo $chipset $memory $resolution
