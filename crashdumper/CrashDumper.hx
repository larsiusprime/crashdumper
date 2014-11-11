package crashdumper;
import flash.display.Stage;
import haxe.CallStack;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.StringInput;
import haxe.Utf8;
import haxe.zip.Entry;
import haxe.zip.Tools;
import haxe.zip.Writer;
import openfl.system.Capabilities;
import openfl.utils.ByteArray;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import haxe.Http;
#if sys
	import openfl.utils.SystemPath;
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileOutput;
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
	
	public static var endl:String = "\n";
	public static var sl:String = "/";
	
	private var theError:Dynamic;
	
	public var pathLogErrors(default, null):String;
	public var uniqueErrorLogPath(default, null):String;
	
	public static inline var PATH_APPDATA:String = "%APPDATA%";			//The ApplicationStorageDirectory. Highly recommended.
	public static inline var PATH_DOCUMENTS:String = "%DOCUMENTS%";		//The Documents directory.
	public static inline var PATH_USERPROFILE:String = "%USERPROFILE%";	//The User's profile folder
	public static inline var PATH_DESKTOP:String = "%DESKTOP%";			//The User's desktop
	public static inline var PATH_APP:String = "%APP%";					//The Application's own directory
	
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
		#if cpp
			untyped __global__.__hxcpp_set_critical_error_handler(onCriticalErrorEvent);
		#end
		//set url to "http://localhost:8080/result" for local connections
		url = url_;
	}
	
	private static function onData(msg:String)
	{
		trace("onData(" + msg + ")");
		// trigger when HTTP return results
	}

	private static function onError(msg:String)
	{
		trace("onError(" + msg + ")");
		// trigger when HTTP error
	}

	private static function onStatus(val:Int)
	{
		trace("onStatus(" + val + ")");
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
	
	/**
	 * Set the path to save crashdumper log files to.
	 * NOTE: on mac/win/linux, this is an absolute path. On mobile, this is ALWAYS prepended by the applicationStorageDirectory.
	 * @param	str
	 * @return
	 */
	
	public function set_path(str:String):String
	{
		#if (windows || mac || linux || mobile)
			#if (mobile)
				if (str.charAt(0) != "/" && str.charAt(0) != "\\")
				{
					str = "/" + str;
				}
				str = SystemPath.applicationStorageDirectory + str;
			#else
				switch(str)
				{
					case null, "": str = SystemPath.applicationStorageDirectory;
					case PATH_APPDATA: str = SystemPath.applicationStorageDirectory;
					case PATH_DOCUMENTS: str = SystemPath.documentsDirectory;
					case PATH_DESKTOP: str = SystemPath.desktopDirectory;
					case PATH_USERPROFILE: str = SystemPath.userDirectory;
					case PATH_APP: str = SystemPath.applicationDirectory;
				}
			#end
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
		
		#if (windows || mac || linux || mobile)
			doErrorStuff(e);		//easy to separately override
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
	
	private function doErrorStuff(e:Dynamic,writeToFile:Bool=true,sendToServer:Bool=true):Void
	{
		theError = e;
		
		var pathLog:String = "log/";				//  path/to/log/
		pathLogErrors = pathLog + "errors/";		//  path/to/log/errors/
		
		//Prepend pathLog with a slash character if the user path does not end with a slash character
		if (path.length >= 0 && path.charAt(path.length - 1) != "/" && path.charAt(path.length - 1) != "\\")
		{
			pathLog = getSlash() + pathLog;
		}
		
		pathLog = fixSlashes(pathLog);
		pathLogErrors = fixSlashes(pathLogErrors);
		
		var errorMessage:String = errorMessageStr();
		
		if (customDataMethod != null)
		{
			customDataMethod(this);			//allow the user to add custom data to the CrashDumper before it outputs
		}
		
		var logdir:String = session.id + "_CRASH/"; //directory name for this crash
		
		#if sys
			if (writeToFile)
			{
				if (!FileSystem.exists(path + pathLog))
				{
					FileSystem.createDirectory(path + pathLog);
				}
				if (!FileSystem.exists(path + pathLogErrors))
				{
					FileSystem.createDirectory(path + pathLogErrors);
				}
				
				var counter:Int = 0;
				var failsafe:Int = 999;
				while (FileSystem.exists(path + pathLogErrors + logdir) && failsafe > 0)
				{
					//if the session ID is not unique for some reason, append numbers until it is
					logdir = session.id + "_CRASH_" + counter + "/";
					counter++;
					failsafe--;
				}
				
				FileSystem.createDirectory(path + pathLogErrors + logdir);
				
				if (FileSystem.exists(path + pathLogErrors + logdir))
				{
					uniqueErrorLogPath = path + pathLogErrors + logdir;
					//write out the error message
					var f:FileOutput = File.write(path + pathLogErrors + logdir + "_error.txt");
					f.writeString(errorMessage);
					f.close();
					
					var sanityCheck:String = File.getContent(path + pathLogErrors + logdir + "_error.txt");
					
					//write out all our associated game session files
					for (filename in session.files.keys())
					{
						var filecontent:String = session.files.get(filename);
						if (filecontent != "" && filecontent != null)
						{
							logFile(pathLogErrors + logdir + filename, filecontent);
						}
					}
				}
			}
		
			if (sendToServer)
			{
				var entries:List<Entry> = new List();
				
				entries.add(strToZipEntry(errorMessage, "_error"));
				
				for (filename in session.files.keys())
				{
					var filecontent:String = session.files.get(filename);
					if (filecontent != "" && filecontent != null)
					{
						entries.add(strToZipEntry(filecontent, filename));
					}
				}
				
				var bytesOutput = new BytesOutput();
				var writer = new Writer(bytesOutput);
				writer.write(entries);
				var zipfileBytes:Bytes = bytesOutput.getBytes();
				
				var zipString:String = zipfileBytes.getString(0, zipfileBytes.length);
				
				var stringInput = new StringInput(zipString);
				request.fileTransfer("report", "report.zip", stringInput, stringInput.length, "application/octet-stream");
				request.request(true);
			}
		#end
	}
	
	private function strToZipEntry(str, fileName):Entry
	{
		#if !html5
		#if flash
			var fbytes:ByteArray = new ByteArray();
			fbytes.writeUTFBytes(str);
			var bytes:Bytes = cast fbytes;
		#else
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(str);
		#end
		var entry:Entry = {
			fileName : fileName,
			fileSize : bytes.length,
			fileTime : Date.now(),
			compressed : false,
			dataSize : 0,
			data : bytes,
			crc32 : Crc32.make(bytes)
		}
		#else
		var entry = null;
		#end
		return entry;
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
			var f = File.write(path + filename);
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
	
	private inline function getSlash():String {
		#if windows
			return "\\";
		#elseif flash
			if (Capabilities.os.toLowerCase().indexOf("win") != -1)
			{
				return "\\";
			}
			else
			{
				return "/";
			}
		#else
			return "/";
		#end
	}
	
	private function fixSlashes(str:String):String{
		var slash:String = getSlash();
		
		var otherslash:String = "";
		if (slash == "/") {
			otherslash = "\\";
		}else if(slash == "\\"){
			otherslash = "/";
		}
		
		//enforce operating system slash style
		while (str.indexOf(otherslash) != -1) {
			str = StringTools.replace(str, otherslash, slash);
		}
		return str;
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
