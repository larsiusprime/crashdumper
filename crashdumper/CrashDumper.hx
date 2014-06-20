package crashdumper;
import flash.display.Stage;
import haxe.CallStack;
import openfl.Lib;
import haxe.Http;
#if (windows || mac || linux)
	import openfl.events.UncaughtErrorEvent;
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileOutput;
#elseif flash
	import flash.events.UncaughtErrorEvent;
	import flash.system.Security;
#end

/**
 * TODO:
	 * Optionally zip up crash reports
	 * 
 */

/**
 * Listens for uncaught error events and then generates a comprehensive crash report.
 * Works best on native (windows/mac/linux) targets.
 *
 * optional: set one or both of these in your project.xml:
 *   <haxedef name="HXCPP_STACK_LINE" />  <!--if you want line numbers-->
 *   <haxedef name="HXCPP_STACK_TRACE"/>  <!--if you want stack traces-->
 * 
 * usage 1: var c = new CrashDumper("unique_str_id",true);
 * -->on crash: dumps a report & closes the app.
 * 
 * usage 2: var c = new CrashDumper("unique_str_id",false,myCrashMethod);
 * -->on crash: dumps a report & calls myCrashMethod
 * 
 * All you need to do is instantiate it, preferably at the beginning of your app, and you only need one.
 *  
 * NOTE: crashdumper automatically sets these (required) haxedefs via it's include.xml:
 *   <haxedef name="safeMode"/>
 *   <haxedef name="HXCPP_CHECK_POINTER"/>
 * 
 * "safeMode" causes UncaughtErrorEvents to properly fire even in release mode, and 
 *  CHECK_POINTER forces null pointer crashes to fire errors in release mode.
 * 
 * @author larsiusprime
 */
class CrashDumper
{
	public var closeOnCrash:Bool;
	public var postCrashMethod:CrashDumper->Void;
	public var customDataMethod:CrashDumper->Void;
	
	public var session:SessionData;
	public var system:SystemData;
	
	public var path(default, set):String;
	public var url(default, set):String;
	
	public static inline var PATH_APPDATA:String = "%APPDATA%";		//your app's applicationStorageDirectory
	public static inline var PATH_DOC:String = "%DOCUMENTS%";		//the user's Documents directory
	
	public static var endl:String = "\n";
	public static var sl:String = "/";
	
	private var theError:Dynamic;
	
	public var uniqueErrorLogPath(default, null):String;
	
	private var SHOW_LINES:Bool = true;
	private var SHOW_STACK:Bool = true;
	
	private var CACHED_STACK_TRACE:String = "";
	
	private static var request:haxe.Http;
	
	/**
	 * Creates a new CrashDumper that will listen for uncaught error events and properly handle the crash
	 * @param	sessionId			a unique string identifier for this session
	 * @param	path				where you want crash dumps to be saved (defaults to same directory as executable)
	 * @param	url					url you want to send the crash dump to. If empty or null, no connection is made.
	 * @param	customDataMethod_	method to call BEFORE a crash dump is created, so you can modify the crashDump object before it outputs
	 * @param	closeOnCrash_		whether or not to close after a crash dump is created
	 * @param	postCrashMethod_	method to call AFTER a crash dump is created if closeOnCrash is false
	 */
	
	#if flash
	public function new(sessionId_:String, ?stage_:Stage, ?path_:String, ?url_:String="http://localhost:8080/result", closeOnCrash_:Bool = true, ?customDataMethod_:CrashDumper->Void, ?postCrashMethod_:CrashDumper->Void)
	#else
	public function new(sessionId_:String, ?path_:String, ?url_:String="http://localhost:8080/result", closeOnCrash_:Bool = true, ?customDataMethod_:CrashDumper->Void, ?postCrashMethod_:CrashDumper->Void) 
	#end
	{
		closeOnCrash = closeOnCrash_;
		postCrashMethod = postCrashMethod_;
		customDataMethod = customDataMethod_;
		
		path = path_;
		
		#if flash
		session = new SessionData(sessionId_, stage_);
		#else
		session = new SessionData(sessionId_);
		#end
		system = new SystemData();
		
		endl = SystemData.endl();
		sl = SystemData.slash();
		
		#if cpp
			#if !HXCPP_STACK_LINE
				SHOW_LINES = false;
			#end
			#if !HXCPP_STACK_TRACE
				SHOW_STACK = false;
			#end
		#end
		
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorEvent); 
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalErrorEvent);
		//set url to "http://localhost:8080/result" for local connections
		url = url_;
	}
	
	private static function onData(msg:String) {
		// trigger when HTTP return results
	}

	private static function onError(msg:String) {
		// trigger when HTTP error
	}

	private static function onStatus(val:Int) {
		// trigger when HTTP return status (200,501,403,etc)
	}	
	
	public function set_url(str:String):String
	{
		url = str;
		if (url != "" && url != null)
		{
			if (request == null)
			{
				request = new haxe.Http(url);
				request.onData   = onData;
				request.onError  = onError;
				request.onStatus = onStatus;
			}
			request.url = str;
		}
		return url;
	}
	
	public function set_path(str:String):String
	{
		#if (windows || mac || linux)
			switch(str)
			{
				case null: str = "";
				case "%APPDATA%": str = flash.filesystem.File.applicationStorageDirectory.nativePath;
				case "%DOCUMENTS%": str = flash.filesystem.File.documentsDirectory.nativePath;
			}
			if (str != "")
			{
				if (str.lastIndexOf("/") != str.length - 1 && str.lastIndexOf("\\") != str.length - 1)
				{
					//if the path is not blank, and the last character is not a slash
					str = str + SystemData.slash();	//add a trailing slash
				}
			}
		#end
		path = str;
		return path;
		
	}
	
	/***THE BIG ERROR FUNCTION***/
	private function onCriticalErrorEvent(message:String):Void {throw message;}
	private function onErrorEvent(e:Dynamic):Void
	{
		CACHED_STACK_TRACE = getStackTrace();
		
		#if (windows || mac || linux)
			doErrorStuff(e);			//easy to separately override
		#end
		
		#if flash
			doErrorStuffByHTTP(e);
		#end
		
		e.__isCancelled = true;		//cancel the event. We control exiting from here on out.
		
		if (closeOnCrash)
		{
			#if sys
				Sys.exit(1);
			#end
		}
		else
		{
			if (postCrashMethod != null)
			{
				postCrashMethod(this);
			}
		}
	}
	
	
	private function doErrorStuffByHTTP(e:Dynamic):Void
	{	
		theError = e;
		var errorMessage:String = errorMessageStr();
		request.setParameter("result",errorMessage);
		request.request(true);
	}
	
	private function doErrorStuff(e:Dynamic):Void
	{
		theError = e;
		
		var pathLog:String = path + "log" + sl;						//  path/to/log/
		var pathLogErrors:String = pathLog + "errors" + sl;			//  path/to/log/errors/
		
		var errorMessage:String = errorMessageStr();
		
		if (request != null)
		{
			request.setParameter("result",errorMessage);
			request.request(true);
		}
		
		if (customDataMethod != null)
		{
			customDataMethod(this);			//allow the user to add custom data to the CrashDumper before it outputs
		}
		
		
		
		#if sys
			if (!FileSystem.exists(pathLog))
			{
				FileSystem.createDirectory(pathLog);
			}
			if (!FileSystem.exists(pathLogErrors))
			{
				FileSystem.createDirectory(pathLogErrors);
			}
			
			var logdir:String = session.id + "_CRASH";							//directory name for this crash
			
			var counter:Int = 0;
			var failsafe:Int = 999;
			while (FileSystem.exists(pathLogErrors + logdir) && failsafe > 0)
			{
				//if the session ID is not unique for some reason, append numbers until it is
				logdir = session.id + "_CRASH_" + counter;
				counter++;
				failsafe--;
			}
			
			FileSystem.createDirectory(pathLogErrors + logdir);
			
			if (FileSystem.exists(pathLogErrors + logdir))
			{
				uniqueErrorLogPath = pathLogErrors + logdir;
				//write out the error message
				var f:FileOutput = File.write(pathLogErrors + logdir + sl + "_error.txt");
				f.writeString(errorMessage);
				f.close();
				
				//write out all our associated game session files
				for (filename in session.files.keys())
				{
					var filecontent:String = session.files.get(filename);
					if (filecontent != "" && filecontent != null)
					{
						logFile(pathLogErrors + logdir + sl + filename, filecontent);
					}
				}
			}
		#end
	}
	
	/**
	 * Concats 2 strings with an endl between them if str1 != ""
	 * @param	filename
	 * @param	content
	 */
	
	private function endlConcat(str1:String, str2:String):String
	{
		if (str1 != "")
		{
			return str1 + endl + str2;
		}
		return str1 + str2;
	}
	
	
	/*****THESE FUNCTIONS ARE SEPARATED OUT BELOW SO THAT THEY ARE EASY TO OVERRIDE IN SUBCLASSES*****/
	
	/**
	 * Returns the error message that will be output
	 * @return
	 */
	
	public function errorMessageStr():String
	{
		var str:String = "";
		str = systemStr();
		str = endlConcat(str, sessionStr());		//we separate the output into three blocks so it's easy to override them with your own customized output
		#if flash
			str = endlConcat(str, crashStr(theError));
		#else
			str = endlConcat(str, crashStr(theError.error));
		#end
		return str;
	}
	
	#if sys
		private function logFile(filename:String, content:String):Void
		{
			var f = File.write(filename);
			f.writeString(content);
			f.close();
		}
	#end
	
	
	/**
	 * Outputs basic information about the user's system
	 * @return
	 */
	
	private function systemStr():String {
		return system.summary();
	}
	
	/**
	 * Outputs basic information about the app session, including app name, version, session ID, and session start time
	 * @return
	 */
	
	private function sessionStr():String {
		return "--------------------------------------" + endl + 
		"filename:\t" + session.fileName + endl + 
		#if !flash
			"package:\t" + session.packageName + endl + 
			"version:\t" + session.version + endl + 
		#end
		"sess. ID:\t" + session.id + endl + 
		"started:\t" + session.startTime.toString();
	}
	
	/**
	 * Outputs information about the crash itself, including error message, crash time, and stack trace
	 * @param	errorData	the .error parameter from the object passed in to onErrorEvent
	 * @return
	 */
	
	private function crashStr(errorData:Dynamic):String {
		var str:String = "--------------------------------------" + endl + 
		"crashed:\t" + Date.now().toString() + endl + 
		"duration:\t" + getTimeStr((Date.now().getTime()-session.startTime.getTime())) + endl + 
		"error:\t\t" + errorData + endl;
		if (SHOW_STACK)
		{
			#if sys
				str += "stack:" + endl + CACHED_STACK_TRACE + endl;
			#elseif flash
				str += "stack:" + endl + errorData.error.getStackTrace() + endl;
			#end
		}
		return str;
	}
	
	private function getTimeStr(ms:Float):String
	{
		var seconds:Int = 0;
		var minutes:Int = 0;
		var hours:Int = 0;
		
		var seconds:Int = Std.int(ms / 1000);
		if (seconds > 60) {
			minutes = Std.int(seconds / 60);
			seconds = seconds % 60;
			if (minutes > 60) {
				  hours = Std.int(minutes / 60);
				minutes = minutes % 60;
			}
		}
		return padDigit(hours, 2) + ":" + padDigit(minutes, 2) + ":" + padDigit(seconds, 2);
	}
	
	private function padDigit(i:Int, digits:Int):String
	{
		var str:String = Std.string(i);
		while (str.length < digits)
		{
			str = "0" + str;
		}
		return str;
	}
	
	private function getStackTrace():String
	{
		var stackTrace:String = "";
		var stack:Array<StackItem> = CallStack.exceptionStack();
		stack.reverse();
		var item:StackItem;
		for (item in stack)
		{
			stackTrace += printStackItem(item) + endl;
		}
		return stackTrace;
	}
	
	private function printStackItem(itm:StackItem):String
	{
		var str:String = "";
		switch( itm ) {
			case CFunction:
				str = "a C function";
			case Module(m):
				str = "module " + m;
			case FilePos(itm,file,line):
				if( itm != null ) {
					str = printStackItem(itm) + " (";
				}
				str += file;
				if (SHOW_LINES)
				{
					str += " line ";
					str += line;
				}
				if (itm != null) str += ")";
			case Method(cname,meth):
				str += (cname);
				str += (".");
				str += (meth);
			case LocalFunction(n):
				str += ("local function #");
				str += (n);
		}
		return str;
	}
}
