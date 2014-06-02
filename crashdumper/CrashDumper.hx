package crashdumper;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

/**
 * TODO:
	 * Optionally zip up crash reports
	 * 
 */

/**
 * Listens for uncaught error events and then generates a comprehensive crash report.
 * Works best on native (windows/mac/linux) targets.
 * 
 * usage 1: var c = new CrashDumper("unique_str_id",true);
 * -->on crash: dumps a report & closes the app.
 * 
 * usage 2: var c = new CrashDumper("unique_str_id",false,myCrashMethod);
 * -->on crash: dumps a report & calls myCrashMethod
 * 
 * All you need to do is instantiate it, preferably at the beginning of your app, and you only need one.
 * 
 * @author larsiusprime
 */
class CrashDumper
{
	public var closeOnCrash:Bool;
	public var crashMethod:CrashDumper->Void;
	
	public var session:SessionData;
	public var system:SystemData;
	
	public var path(default,set):String;
	
	public static inline var PATH_APPDATA:String = "%APPDATA%";		//your app's applicationStorageDirectory
	public static inline var PATH_DOC:String = "%DOCUMENTS%";		//the user's Documents directory
	
	private static var endl:String = "\n";
	private static var sl:String = "/";
	
	/**
	 * Creates a new CrashDumper that will listen for uncaught error events and properly handle the crash
	 * @param	sessionId		a unique string identifier for this session
	 * @param	path			where you want crash dumps to be saved (defaults to same directory as executable)
	 * @param	closeOnCrash_	whether or not to close after a crash dump is created
	 * @param	crashMethod_	method to call after a crash dump is created if closeOnCrash is false
	 */
	
	public function new(sessionId_:String,?path_:String,closeOnCrash_:Bool=true,?crashMethod_:CrashDumper->Void) 
	{
		closeOnCrash = closeOnCrash_;
		crashMethod = crashMethod_;
		
		path = path_;
		
		session = new SessionData(sessionId_);
		system = new SystemData();
		
		endl = SystemData.endl();
		sl = SystemData.slash();
		
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorEvent); 
	}
	
	public function set_path(str:String):String
	{
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
		path = str;
		return path;
	}
	
	/**
	 * Outputs basic information about the app session, including app name, version, session ID, and session start time
	 * @return
	 */
	
	private function sessionStr():String {
		return "--------------------------------------" + endl + 
		"filename:\t" + session.fileName + endl + 
		"package:\t" + session.packageName + endl + 
		"version:\t" + session.version + endl + 
		"session ID:\t" + session.id + endl + 
		"started:\t" + session.startTime.toString();
	}
	
	/**
	 * Outputs information about the crash itself, including error message, crash time, and stack trace
	 * @param	errorData	the .error parameter from the object passed in to onErrorEvent
	 * @return
	 */
	
	private function crashStr(errorData:Dynamic):String {
		return "--------------------------------------" + endl + 
		"crashed:\t" + Date.now().toString() + endl + 
		"error:\t\t" + errorData + endl + 
		"stack:" + endl + getStackTrace() + endl;
	}
	
	private function getStackTrace():String
	{
		var stack:Array<StackItem> = CallStack.exceptionStack();
		var stackTrace:String = "";
		stack.reverse();
		var item:StackItem;
		for (item in stack)
		{
			stackTrace += printStackItem(item) + endl;
		}
		return stackTrace;
	}
	
	private function onErrorEvent(e:Dynamic):Void
	{
		var pathLog:String = path + "log" + sl;						//  path/to/log/
		var pathLogErrors:String = pathLog + sl + "errors" + sl;	//  path/to/log/errors/
		
		var errorMessage:String = 
			system.summary() + endl + 		//we separate the output into three blocks so it's easy to override them with your own customized output
			sessionStr() + endl + 
			crashStr(e.error) + endl;
		
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
						f = File.write(pathLogErrors + logdir + sl + filename);
						f.writeString(filecontent);
						f.close();
					}
				}
			}
		#end
		
		if (closeOnCrash)
		{
			#if sys
				Sys.exit(1);
			#end
		}
		else
		{
			if (crashMethod != null)
			{
				crashMethod(this);
			}
		}
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
				str += " line ";
				str += line;
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