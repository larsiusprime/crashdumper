package crashdumper.hooks;
import crashdumper.hooks.openfl.HookOpenFL;

/**
 * ...
 * @author larsiusprime
 */
class Hook
{
	public function new() 
	{
		throw "You can't and shouldn't instantiate this!";
	}
	
	public static function platform():IHookPlatform
	{
		#if openfl
			return new HookOpenFL();
		#end
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