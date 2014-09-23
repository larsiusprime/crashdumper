#!/bin/bash
detail=`system_profiler SPHardwareDataType -detailLevel mini`
modelName=`echo "$detail" | grep -m 1 "Model Name" | awk -F': ' '{print $2}'`
modelIdentifier=`echo "$detail" | grep -m 1 "Model Identifier" | awk -F': ' '{print $2}'`
detail=`system_profiler SPSoftwareDataType -detailLevel mini`
osVersion=`echo "$detail" | grep -m 1 "System Version" | awk -F': ' '{print $2}'`
echo $osVersion $modelName $modelIdentifier
