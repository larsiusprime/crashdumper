package crashdumper.hooks.openfl;
import crashdumper.hooks.IHookPlatform;
import haxe.io.Bytes;

#if openfl
	import openfl.utils.SystemPath;
#end

#if (openfl >= "2.0.0")
	import openfl.Lib;
	import openfl.utils.ByteArray;
	import openfl.events.UncaughtErrorEvent;
#else
	import nme.Lib;
	import nme.utils.ByteArray;
	import flash.events.UncaughtErrorEvent;
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
	
	public function new() 
	{
		#if openfl
			#if !flash
				#if lime_legacy
					fileName = Lib.file;
					packageName = Lib.packageName;
					version = Lib.version;
				#else
					fileName = Lib.current.stage.application.config.file;
					packageName = Lib.current.stage.application.config.packageName;
					version = Lib.current.stage.application.config.version;
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
				if (str.charAt(0) != "/" && str.charAt(0) != "\\")
				{
					str = "/" + str;
				}
				str = SystemPath.applicationStorageDirectory + str;
			#else
				#if lime_legacy
					switch(str)
					{
						case null, "": str = SystemPath.applicationStorageDirectory;
						case PATH_APPDATA: str = SystemPath.applicationStorageDirectory;
						case PATH_DOCUMENTS: str = SystemPath.documentsDirectory;
						case PATH_DESKTOP: str = SystemPath.desktopDirectory;
						case PATH_USERPROFILE: str = SystemPath.userDirectory;
						case PATH_APP: str = SystemPath.applicationDirectory;
					}
				#else
					str = "";
				#end
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
		return str;
	}
	
	public function setErrorEvent(onErrorEvent:Dynamic->Void)
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onErrorEvent);
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