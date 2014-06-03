crashdumper
===========

A cross-platform automated crash report generator/sender for Haxe/OpenFL apps.

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

Paths
============

By default will write to your program's own directory, under /logs/errors/\<SESSION_ID\>
You can supply your own path, of course.

Cross-Platform
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



TODO
=============

 - SystemData processing for Mac & Linux (pull requests welcome!)
 - Ability to zip up crash reports
 - Ability to email crash reports to the developer or send to a web server
 - Ability to store custom data (such as HaxeFlixel replays) for super advanced crash reporting.
