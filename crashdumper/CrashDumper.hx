package crashdumper;
import crashdumper.hooks.Util;
import crashdumper.hooks.IHookPlatform;
import haxe.CallStack;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.StringInput;
import haxe.Utf8;
import haxe.zip.Entry;
import haxe.zip.Tools;
import haxe.zip.Writer;
import haxe.Http;
import openfl.events.Event;

#if flash
	import flash.display.Stage;
#end

#if sys
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileOutput;
#end

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
	public static var active:Bool=true;	//whether we're actively crashdumping or not
	
	public var closeOnCrash:Bool;
	public var postCrashMethod:CrashDumper->Void;
	public var customDataMethod:CrashDumper->Void;
	public var collectSystemData:Bool;
	
	public var session:SessionData;
	public var system:SystemData;
	
	public var path(default, set):String;
	public var url(default, set):String;
	
	public static var endl:String = "\n";
	public static var sl:String = "/";
	
	
	public var pathLogErrors(default, null):String;
	public var uniqueErrorLogPath(default, null):String;
	
	/**
	 * Creates a new CrashDumper that will listen for uncaught error events and properly handle the crash
	 * @param	sessionId			a unique string identifier for this session
	 * @param	path				where you want crash dumps to be saved (defaults to same directory as executable)
	 * @param	url					url you want to send the crash dump to. If empty or null, no connection is made.
	 * @param	customDataMethod_	method to call BEFORE a crash dump is created, so you can modify the crashDump object before it outputs
	 * @param	closeOnCrash_		whether or not to close after a crash dump is created
	 * @param	collectSystemData_	whether or not to gather system data (causes some cmd windows to pop open on first launch, which sometimes annoys users, so disable it if you like)
	 * @param	postCrashMethod_	method to call AFTER a crash dump is created if closeOnCrash is false
	 * @param	stage_				(flash target only) the root Stage object
	 */
	
	public function new(sessionId_:String, ?path_:String, ?url_:String="http://localhost:8080/result", ?closeOnCrash_:Bool = true, ?collectSystemData_:Bool = false, ?customDataMethod_:CrashDumper->Void, ?postCrashMethod_:CrashDumper->Void, ?stage_:Dynamic) 
	{
		hook = Util.platform();
		
		closeOnCrash = closeOnCrash_;
		collectSystemData = collectSystemData_;
		postCrashMethod = postCrashMethod_;
		customDataMethod = customDataMethod_;
		
		endl = SystemData.endl();
		sl = SystemData.slash();
		
		path = path_;
		
		var data = { fileName:hook.fileName, packageName:hook.packageName, version:hook.version };
		#if flash
			data.fileName = stage_.loaderInfo.url;
		#end
		
		session = new SessionData(sessionId_, data);
		
		hook.setErrorEvent(onErrorEvent);
		
		#if cpp
			#if !HXCPP_STACK_LINE
				SHOW_LINES = false;
			#end
			#if !HXCPP_STACK_TRACE
				SHOW_STACK = false;
			#end
			untyped __global__.__hxcpp_set_critical_error_handler(onCriticalErrorEvent);
		#end
		
		//set url to "http://localhost:8080/result" for local connections
		url = url_;
	}
	
	/**********PRIVATE************/
	
	private var hook:IHookPlatform;
	
	private var theError:Dynamic;
	private var SHOW_LINES:Bool = true;
	private var SHOW_STACK:Bool = true;
	
	private var CACHED_STACK_TRACE:String = "";
	
	private static var request:haxe.Http;
	
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
		str = hook.getFolderPath(str);
		path = str;
		return path;
	}

	/***THE BIG ERROR FUNCTION***/
	
	private function onCriticalErrorEvent(message:String):Void
	{
		if(!CrashDumper.active) return;
		throw message;
	}
	private function onErrorEvent(e:Dynamic):Void
	{
		if(!CrashDumper.active) return;
		CACHED_STACK_TRACE = getStackTrace();
		
		#if !flash
			doErrorStuff(e);		//easy to separately override
		#else
			doErrorStuffByHTTP(e);	//minimal flash error report
		#end
		
		//cancel the event. We control exiting from here on out.
		if(#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(e, openfl.events.Event)) 
		{
			e.stopImmediatePropagation();
		}
		
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
	
	
	private function doErrorStuff(e:Dynamic, writeToFile:Bool = true, sendToServer:Bool = true, traceToLog:Bool = true):Void
	{
		if(!CrashDumper.active) return;
		theError = e;
		
		var pathLog:String = "log/";				//  path/to/log/
		pathLogErrors = pathLog + "errors/";		//  path/to/log/errors/
		
		//Prepend pathLog with a slash character if the user path does not end with a slash character
		if (path.length >= 0 && path.charAt(path.length - 1) != "/" && path.charAt(path.length - 1) != "\\")
		{
			pathLog = Util.slash() + pathLog;
		}
		
		var errorMessage:String = errorMessageStr();
		
		if (customDataMethod != null)
		{
			customDataMethod(this);			//allow the user to add custom data to the CrashDumper before it outputs
		}
		
		var logdir:String = session.id + "_CRASH/"; //directory name for this crash
		
		if (traceToLog)
		{
			trace("CRASH session.id = " + session.id);
			trace("MESSAGE = " + errorMessage);
		}
		
		var path2Log = Util.uPath([path, pathLog]);
		var path2LogErrors = Util.uPath([path, pathLogErrors]);
		var path2LogErrorsDir = Util.uPath([path, pathLogErrors, logdir]);
		
		#if sys
			if (writeToFile)
			{
				if (!FileSystem.exists(path2Log))
				{
					FileSystem.createDirectory(path2Log);
				}
				if (!FileSystem.exists(path2LogErrors))
				{
					FileSystem.createDirectory(path2LogErrors);
				}
				
				var counter:Int = 0;
				var failsafe:Int = 999;
				while (FileSystem.exists(path2LogErrorsDir) && failsafe > 0)
				{
					//if the session ID is not unique for some reason, append numbers until it is
					logdir = session.id + "_CRASH_" + counter + "/";
					counter++;
					failsafe--;
				}
				
				FileSystem.createDirectory(path2LogErrorsDir);
				
				if (FileSystem.exists(path2LogErrorsDir))
				{
					uniqueErrorLogPath = path2LogErrorsDir;
					//write out the error message
					
					var outPath = Util.uPath([path2LogErrors, logdir, "_error.txt"]);
					
					var f:FileOutput = File.write(outPath);
					f.writeString(errorMessage);
					f.close();
					
					var sanityCheck:String = File.getContent(outPath);
					
					//write out all our associated game session files
					for (filename in session.files.keys())
					{
						var filecontent:String = session.files.get(filename);
						if (filecontent != "" && filecontent != null)
						{
							var fileOut = Util.uPath([pathLogErrors, logdir, filename]);
							logFile(fileOut, filecontent);
						}
					}
				}
			}
		#end
		
		if (sendToServer)
		{
			var entries:List<Entry> = new List();
			
			var entry = strToZipEntry(errorMessage, "_error");
			if (entry != null)
			{
				entries.add(entry);	
			}
			
			for (filename in session.files.keys())
			{
				var filecontent:String = session.files.get(filename);
				if (filecontent != "" && filecontent != null)
				{
					entry = strToZipEntry(filecontent, filename);
					if(entry != null)
					{
						entries.add(entry);
					}
				}
			}
			
			var bytesOutput = new BytesOutput();
			var writer = new Writer(bytesOutput);
			writer.write(entries);
			var zipfileBytes:Bytes = bytesOutput.getBytes();
			
			Util.sendReport(request, zipfileBytes);
		}
	}
	
	private function doErrorStuffByHTTP(e:Dynamic):Void
	{	
		theError = e;
		var errorMessage:String = errorMessageStr();
		request.setParameter("result",errorMessage);
		request.request(true);
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
	
	private function strToZipEntry(str, fileName):Entry
	{
		var bytes:Bytes = hook.getZipBytes(str);
		var entry:Entry = null;
		
		if (bytes != null)
		{
			entry = 
			{
				fileName : fileName,
				fileSize : bytes.length,
				fileTime : Date.now(),
				compressed : false,
				dataSize : 0,
				data : bytes,
				crc32 : Crc32.make(bytes)
			}
		}
		
		return entry;
	}
	
	/*****THESE FUNCTIONS ARE SEPARATED OUT BELOW SO THAT THEY ARE EASY TO OVERRIDE IN SUBCLASSES*****/
	
	/**
	 * Returns the error message that will be output
	 * @return
	 */
	
	public function errorMessageStr():String
	{
		if (system == null && collectSystemData)
		{
			try
			{
				system = new SystemData();
			}
			catch (msg:String)
			{
				trace("error during crashdump : " + msg);
			}
		}
		
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
			filename = getSafeFilename(path, filename);
			var f = File.write(filename);
			f.writeString(content);
			f.close();
		}
	#end
	
	private function getSafeFilename(path:String, filename:String):String
	{
		var lastIsSlash = false;

		
		filename = lastIsSlash ? Util.uCombine([path, filename]) : Util.uCombine([path, "/", filename]);
		
		return filename;
	}
	
	/**
	 * Outputs basic information about the user's system
	 * @return
	 */
	
	private function systemStr():String {
		
		if(!collectSystemData) return "";
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
		#if flash
		stack.reverse();
		#end
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
			#if (haxe_ver >= "3.1.0")
			case LocalFunction(n):
			#else
			case Lambda(n):
			#end
				str += ("local function #");
				str += (n);
		}
		return str;
	}
}
