@echo off
wmic PATH Win32_VideoController get name /Value
echo ,
wmic PATH Win32_VideoController get driverversion /Value