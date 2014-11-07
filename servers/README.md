Servers
======


These are all the official server-side implementations that can receive CrashDump data from CrashDumper. 
If you would like to add an implementation, we would be happy to receive a pull request!

## crashdumpbrowser
This is the "official" server-side implementation, commissioned by me ([Larsiusprime](http://github.com/larsiusprime)) and written by [Adam Perry](http://github.com/arperry), aka [@hoursgoby](http://www.twitter.com/hoursgoby). It uses PHP and is a full-featured, web-based solution for CrashDumper. It logs your crashdumps, and has some robust UI stuff for viewing, organizing, and processing the results.

## nodejs
This implementation was generously provided by [misterpah](http://github.com/misterpah), originally written as [crashdumper-logger](https://github.com/misterpah/crashdumper-logger). It uses NodeJS and can run on both localhost and a remote server.
