package crashdumper.hooks;
import haxe.io.Bytes;

/**
 * This lets you abstract away specific implementations (like OpenFL) so you can use crashdumper with various different systems
 * @author larsiusprime
 */

interface IHookPlatform
{
	public var fileName(default, null):String;
	public var packageName(default, null):String;
	public var version(default, null):String;
	
	public function getZipBytes(str:String):Bytes;
	public function getFolderPath(str:String):String;
	public function setErrorEvent(onErrorEvent:Dynamic->Void):Void;
}