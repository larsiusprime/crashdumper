package crashdumper.hooks;
import crashdumper.hooks.openfl.HookOpenFL;
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.StringInput;
import haxe.macro.Context;

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
	
	public static function sendReport(request:Http,bytes:Bytes):Void
	{
		var zipString:String = "";
		#if (haxe_ver >= "3.1.3")
			zipString = bytes.getString(0, bytes.length);
		#else
			zipString = bytes.readString(0, bytes.length);
		#end
		
		#if !flash
			var stringInput = new StringInput(zipString);
			request.fileTransfer("report", "report.zip", stringInput, stringInput.length, "application/octet-stream");
			request.request(true);
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

	macro public static function getProjectVersion(path:String) {
        try {
            var p = Context.resolvePath(path);
            var s:String = sys.io.File.getContent(p);
            var r = new EReg('<\\s?app[^>]*?\\sversion="([.\\d]+)"[^>]*?>', "i");
            if (r.match(s)) return macro $v{r.matched(1)};
            else return Context.error('No version found in xml file', Context.currentPos());
        }
        catch(e:Dynamic) {
            return Context.error('Failed to load file $path: $e', Context.currentPos());
        }
    }
}