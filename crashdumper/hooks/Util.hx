package crashdumper.hooks;
import crashdumper.hooks.openfl.HookOpenFL;
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.StringInput;

#if unifill
import unifill.Unifill;
import unifill.CodePoint;
#end

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
	
	public static function lastIsSlash(str:String):Bool
	{
		#if unifill
		//if unifill is detected make sure to do things in a unicode safe manner!
		var ulength = Unifill.uLength(str);
		if (Unifill.uLastIndexOf(str, "/") == ulength -1 || Unifill.uLastIndexOf(str, "\\") == ulength - 1)
		{
			return true;
		}
		#else
		var length = str.length;
		if (str.lastIndexOf("/") == length - 1 || str.lastIndexOf("\\") == length - 1)
		{
			return true;
		}
		#end
		return false;
	}
	
	public static function fixSlashes(str:String):String
	{
		var slash:String = "/";
		
		var otherslash:String = "";
		if (slash == "/")
		{
			otherslash = "\\";
		}
		else if (slash == "\\")
		{
			otherslash = "/";
		}
		
		//enforce operating system slash style
		str = uReplace(str, otherslash, slash);
		
		return str;
	}
	
	public static function fixTrailingSlash(str:String):String
	{
		Sys.println("fixTrailingSlash = " + str);
		#if unifill
		var ulength = Unifill.uLength(str);
		if (Unifill.uLastIndexOf(str,"/") != ulength - 1 && Unifill.uLastIndexOf(str,"\\") != ulength - 1)
		{
			str = uCombine([str, SystemData.slash()]);
		}
		#else
		if (str.lastIndexOf("/") != str.length - 1 && str.lastIndexOf("\\") != str.length - 1)
		{
			//if the path is not blank, and the last character is not a slash
			str = str + SystemData.slash();	//add a trailing slash
		}
		#end
		Sys.println("now = " + str);
		return str;
	}
	
	public static function isFirstChar(str:String, char:String):Bool
	{
		#if unifill
			return Unifill.uIndexOf(str,char) == 0;
		#else
			return str.indexOf(char) == 0;
		#end
		return false;
	}

	public static function uPath(arr:Array<String>):String
	{
		return pathFix(uCombine(arr));
	}
	
	public static function uCombine(arr:Array<String>):String
	{
		var sb = new StringBuf();
		for (str in arr)
		{
			sb.add(Std.string(str));
		}
		return sb.toString();
	}
	
	public static function uReplace(s:String, substr:String, by:String, recursive:Bool=true):String
	{
		#if unifill
		if (Unifill.uIndexOf(s, substr) == -1) return s;
		
		var sb = new StringBuf();
		
		//turn the substr into an array of code points
		var substrArr:Array<CodePoint> = [];
		var iter = Unifill.uIterator(substr);
		while (iter.hasNext())
		{
			substrArr.push(iter.next());
		}
		
		//turn the by str into an array of code points
		var byArr:Array<CodePoint> = [];
		iter = Unifill.uIterator(by);
		while (iter.hasNext())
		{
			byArr.push(iter.next());
		}
		
		var matchI:Int = 0;
		var onMatch = false;
		iter = Unifill.uIterator(s);
		
		while (iter.hasNext())
		{
			//iterate through the main string code point by code point
			var cp:CodePoint = iter.next();
			
			if (matchI < substrArr.length && cp == substrArr[matchI])
			{
				//detected the substr -- advance but don't write to the buffer
				onMatch = true;
				matchI++;
			}
			else
			{
				if (onMatch)
				{
					onMatch = false;
					matchI = 0;
					//write the replacement str to the buffer
					for (i in 0...byArr.length)
					{
						Unifill.uAddChar(sb, byArr[i]);
					}
				}
				//write the character to the buffer
				Unifill.uAddChar(sb, cp);
			}
		}
		if (onMatch && matchI >= substrArr.length)
		{
			for (i in 0...byArr.length)
			{
				Unifill.uAddChar(sb, byArr[i]);
			}
		}
		
		if (recursive)
		{
			return uReplace(sb.toString(), substr, by, true);
		}
		
		//return the final string
		return sb.toString();
		#end
		return StringTools.replace(s, substr, by);
	}
	
	public static function sendReport(request:Http,bytes:Bytes):Void
	{
		var zipString:String = "";
		#if (haxe_ver >= "3.1.3")
			zipString = bytes.getString(0, bytes.length);
		#else
			zipString = bytes.readString(0, bytes.length);
		#end
		
		#if (sys)
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
}