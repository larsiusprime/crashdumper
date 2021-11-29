package crashdumper.hooks.openfl;
import crashdumper.hooks.IHookPlatform;
import haxe.io.Bytes;

#if !lime_legacy
	import lime.app.Application;
	import lime.system.System;
#end

#if (openfl >= "2.0.0")
	import openfl.Lib;
	import openfl.utils.ByteArray;
	import openfl.events.UncaughtErrorEvent;
	import crashdumper.hooks.Util;
#else
	import nme.Lib;
	import nme.utils.ByteArray;
	import flash.events.UncaughtErrorEvent;
#end

#if openfl_legacy
	import openfl.utils.SystemPath;
#else
	import lime.app.Application;
	typedef SystemPath = lime.system.System;
#end

/**
 * ...
 * @author larsiusprime
 */
class HookOpenFL implements IHookPlatform
{
	public var fileName(default, null):String="";
	public var packageName(default, null):String="";
	public var version(default, null):String="";
	
	public static inline var PATH_APPDATA:String = "%APPDATA%";			//The ApplicationStorageDirectory. Highly recommended.
	public static inline var PATH_DOCUMENTS:String = "%DOCUMENTS%";		//The Documents directory.
	public static inline var PATH_USERPROFILE:String = "%USERPROFILE%";	//The User's profile folder
	public static inline var PATH_DESKTOP:String = "%DESKTOP%";			//The User's desktop
	public static inline var PATH_APP:String = "%APP%";					//The Application's own directory
	
	private var errorEvent:Dynamic->Void;
	
	public function new() 
	{
		#if openfl
			#if !flash
				#if lime_legacy
					fileName = Lib.file;
					packageName = Lib.packageName;
					version = Lib.version;
				#elseif (lime < "7.0.0")
					fileName = Application.current.config.file;
					packageName = Application.current.config.packageName;
					version = Application.current.config.version;
				#else
					fileName = Application.current.meta.get("file");
					packageName = Application.current.meta.get("packageName");
					version = Util.getProjectVersion("Project.xml");
				#end
			#end
		#else
			throw "OpenFL Library was not detected, using HookOpenFL is therefore impossible!";
		#end
	}
	
	public function getFolderPath(str:String):String
	{
		#if (windows || mac || linux || mobile)
			#if (mobile)
				if (!Util.isFirstChar(str, "/") && !Util.isFirstChar("\\"))
				{
					str = Util.uCombine("/" + str);
				}
				str = Util.uCombine([SystemPath.applicationStorageDirectory,str]);
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
				str = Util.fixTrailingSlash(str);
			}
		#end
		return str;
	}
	
	public function setErrorEvent(onErrorEvent:Dynamic->Void)
	{
		errorEvent = onErrorEvent;
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorEvent);
	}
	
	public function disable()
	{
		if (errorEvent != null)
		{
			trace("DISABLE ERROR EVENT");
			Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, errorEvent);
		}
	}
	
	public function getZipBytes(str):Bytes
	{
		#if !html5
			#if flash
				var fbytes:ByteArray = new ByteArray();
				fbytes.writeUTFBytes(str);
				var bytes:Bytes = cast fbytes;
				return bytes;
			#else
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(str);
				return bytes;
			#end
		#end
		return null;
	}
}
