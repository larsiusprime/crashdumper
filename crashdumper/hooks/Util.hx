package crashdumper.hooks;
import crashdumper.hooks.openfl.HookOpenFL;
import haxe.io.Path;

/**
 * ...
 * @author larsiusprime
 */
class Util
{
	public function new() 
	{
		throw "You can't and shouldn't instantiate this!";
	}
	
	/**
	 * 
	 * @return
	 */
	
	public static function platform():IHookPlatform
	{
		#if openfl
			return new HookOpenFL();
		#end
	}
	
	public static function pathFix(str:String):String
	{
		str = fixSlashes(str);
		#if (haxe_ver < "3.1.0")
			return Path.removeTrailingSlashes(str);
		#end
		return str;
	}
	
	public static function fixSlashes(str:String):String
	{
		var slash:String = slash();
		
		var otherslash:String = "";
		if (slash == "/") {
			otherslash = "\\";
		}else if(slash == "\\"){
			otherslash = "/";
		}
		
		//enforce operating system slash style
		while (str.indexOf(otherslash) != -1)
		{
			str = StringTools.replace(str, otherslash, slash);
		}
		
		return str;
	}
	
	public static function slash():String
	{
		#if windows
			return "\\";
		#elseif flash
			//On flash target this API path will always be available:
			if (flash.system.Capabilities.os.toLowerCase().indexOf("win") != -1)
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
}