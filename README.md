crashdumper
===========

A cross-platform automated crash report generator/sender for Haxe/OpenFL apps.

Setup
===========

  1. Install crashdumper (coming soon to haxelib, just github for now).
     
     Command Line:
     ````
     haxelib git crashdumper http://github.com/larsiusprime/crashdumper
     ````
  2. Include crashdumper in your project.xml:  
     
     ````xml
     <haxelib name="crashdumper"/>
     ````
  3. Optionally, set one or both of these haxedefs in your project.xml (for cpp targets)  
     
     ````xml
     <haxedef name="HXCPP_STACK_LINE" />  <!--if you want line numbers-->
	 <haxedef name="HXCPP_STACK_TRACE"/>  <!--if you want stack traces-->
     ````
     On flash target, stack traces will only be generated in a debug player.


If you don't set the haxedefs, you'll still get a crashdump with a system profile, error message and some other useful info, but you won't get line numbers and a backtrace of the method call stack that led up to the error.


Usage
===========

    var unique_id:String = SessionData.generateID("fooApp_"); 
        //generates unique id: "fooApp_YYYY-MM-DD_HH'MM'SS_CRASH"
        
    var crashDumper = new CrashDumper(unique_id); 
        //starts the crashDumper
        
(An example app is provided in the /Example folder)

It will generate something like this:

    SystemData
    {
      OS : Windows 7 SP1
      RAM: 8387064 KB (8 GB)
      CPU: Intel(R) Core(TM)2 Duo CPU     E7400  @ 2.80GHz
      GPU: ATI Radeon HD 4800 Series, driver v. 8.970.100.1100
    }
    --------------------------------------
    filename:	Example
    package:	crashdumper.example
    version:	1.0.0
    session ID:	example_app_2014-06-02_15'38'19
    started:	2014-06-02 15:38:19
    --------------------------------------
    crashed:	2014-06-02 15:38:21
    error:		Null Object Reference
    stack:
    *._Function_1_1 (openfl/display/Stage.hx line 120)
    Main.onClick (Main.hx line 55)
    openfl.events.Listener.dispatchEvent (openfl/events/EventDispatcher.hx line 268)
    openfl.events.EventDispatcher.dispatchEvent (openfl/events/EventDispatcher.hx line 98)
    openfl.display.DisplayObject.__dispatchEvent (openfl/display/DisplayObject.hx line 194)
    openfl.display.DisplayObject.__fireEvent (openfl/display/DisplayObject.hx line 256)
    openfl.display.Stage.__onMouse (openfl/display/Stage.hx line 902)

You may optionally also cache data files (such as a user/player's save game data and/or application config data) at that moment, and the crash report will include verbatim copies of those save files. You can use this to generate a crash report that includes as much data as possible about the user's starting conditions.

Server-Side
============

CrashDumper can be hooked up to a server-side listener that process and/or stores crash dumps. We are happy to receive any such implementations as pull requests, [you can find them all here](https://github.com/larsiusprime/crashdumper/tree/master/servers).

We specifically recommend **[Crashdump Browser](https://github.com/larsiusprime/crashdumper/tree/master/servers/crashdumpbrowser)**.

Paths
============

By default will write to your program's application storage directory (`SystemPath.applicationStorageDirectory`), under `/logs/errors/<SESSION_ID>`.
You can supply your own path, of course.

Performance
============

Using crashdumper probably comes with a small hit to performance, but it should be much less than the difference between debug and release mode. 

`HXCPP_STACK_TRACE` and `HXCPP_STACK_LINE` both come with a small hit to performance, but if you're worried about optimization, `LINE` is the most expensive, `TRACE` is relatively cheap.

We still need to run performance tests to see what the actual overheads are. We would be more than happy to welcome your benchmark results with crashdumper!

System profiles
============

Here's some examples of the output created by CrashDumper for different systems:

Windows:

    SystemData
    {
      OS : Windows 7 SP1
      RAM: 8387064 KB (8 GB)
      CPU: Intel(R) Core(TM)2 Duo CPU     E7400  @ 2.80GHz
      GPU: ATI Radeon HD 4800 Series, driver v. 8.970.100.1100
    }


Linux:

    SystemData
    {
      OS : Ubuntu 14.04 LTS (i686)
      RAM: 4022044 KB (3.84 GB)
      CPU: Intel(R) Core(TM) i3-2310M CPU @ 2.10GHz
      GPU: Intel Corporation 2nd Generation Core Processor Family Integrated Graphics Controller (rev 09)
     Advanced Micro Devices, Inc. [AMD/ATI] Whistler [Radeon HD 6630M/6650M/6750M/7670M/7690M] (rev ff)
    , driver v. 
    }

Mac:

    SystemData
    {
      OS : OS X 10.9.2 (13C1021) iMac iMac12,2
      RAM: 16 GB
      CPU: Intel Core i7 3,40 GHz
      GPU: Gainward GeForce GTX 570 1280 MB 1680 x 1050 @ 60 Hz
    , driver v. unknown
    }

Flash:

    SystemData
    {
      OS: Windows 7 (flash)
      FLASH: StandAlone v. WIN 13,0,0,214
      CPU: x86
    }

TODO
=============

 - More [server-side implementations](https://github.com/larsiusprime/crashdumper/tree/master/servers)
