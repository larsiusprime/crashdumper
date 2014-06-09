#!/bin/bash
#HSPATH= dirname "$0"
#DIR= dirname "${BASH_SOURCE[0]}"
#DIR = pwd -P
#echo $DIR
if [ "$(uname -m)" == "x86_64" ]
then
	echo "detecting linux-64 bit"
	cd "./runtime/linux-64/"
	sed -i 's/\x75\x64\x65\x76\x2E\x73\x6F\x2E\x30/\x75\x64\x65\x76\x2E\x73\x6F\x2E\x31/g' nw
	cd "../../"	
	LD_LIBRARY_PATH="./runtime/linux-64/library:${LD_LIBRARY_PATH}" ./runtime/linux-64/nw ./bin $@
else
	echo "detecting linux-32 bit"
	cd "./runtime/linux-32/"
	sed -i 's/\x75\x64\x65\x76\x2E\x73\x6F\x2E\x30/\x75\x64\x65\x76\x2E\x73\x6F\x2E\x31/g' nw
	cd "../../"	
	LD_LIBRARY_PATH="./runtime/linux-32/library:${LD_LIBRARY_PATH}" $HSPATH./runtime/linux-32/nw $HSPATH./bin $@
fi
