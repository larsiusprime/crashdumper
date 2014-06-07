package crashdumper;
#if sys
	import sys.io.Process;
#end

/**
 * A simple data structure that records data about the user's system.
 * 
 * usage: var s = new SystemData();
 * 
 * @author larsiusprime
 */
class SystemData
{
	public var os:String;				//simple constant matching the haxedef -- "windows", "mac", "linux", etc
	public var osRaw:String;			//raw output from command-line OS identifier -- "Microsoft Windows [Version 6.1.7601]"
	public var osName:String;			//common product name of OS -- "Windows 7", "Ubuntu 14.10", "OSX Snow Leopard", "Android KitKat"
	public var osVersion:String;		//version number of OS -- "6.1.7601, 14.10, 10.6, 4.4" (for the above 4 examples)
	public var totalMemory:Int;			//total visible memory, in kilobytes
	public var cpuName:String;			//the name of your cpu, -- "Intel(R) Core(TM)2 Duo CPU     E7400  @ 2.80GHz"
	public var gpuName:String;			//the name of your gpu, -- "ATI Radeon HD 4800 Series"
	public var gpuDriverVersion:String;	//version number of gpu driver, -- "8.970.100.1100"
	
	public function new() 
	{
		#if windows
			os = "windows";
		#elseif mac
			os = "mac";
		#elseif linux
			os = "linux";
		#elseif android
			os = "android";
		#elseif ios
			os = "ios";
		#end
		
		try {
			#if windows
				runProcess("crashdumper/os.bat", [], processOS);
				runProcess("crashdumper/memory.bat", [], processMemory);
				runProcess("crashdumper/cpu.bat", [], processCPU);
				runProcess("crashdumper/gpu.bat", [], processGPU);
			#elseif linux
				// must set file to executable first
				runProcess("chmod", [ "a+x","crashdumper/os.sh"], dummy);
				runProcess("chmod", [ "a+x","crashdumper/memory.sh"], dummy);
				runProcess("chmod", [ "a+x","crashdumper/cpu.sh"], dummy);
				runProcess("chmod", [ "a+x","crashdumper/gpu.sh"], dummy);
				
				runProcess("crashdumper/os.sh", [], processOS);
				runProcess("crashdumper/memory.sh", [], processMemory);
				runProcess("crashdumper/cpu.sh", [], processCPU);
				runProcess("crashdumper/gpu.sh", [], processGPU);
			#elseif mac
				//do mac stuff
			#end
		}
		catch (msg:Dynamic)
		{
			trace("error creating SystemData : " + msg);
		}
	}
	
	private function dummy(line:String):Void
	{
	// this is because runprocess() must accept function
	}
	
	public function summary():String
	{
		return "SystemData" + endl() + 
		"{" + endl() + 
		"  OS : " + osName + endl() + 
		"  RAM: " + totalMemory + " KB (" + toGBStr(totalMemory) + " GB)" + endl() +
		"  CPU: " + cpuName + endl() +
		"  GPU: " + gpuName + ", driver v. " + gpuDriverVersion + endl() +
		"}";
	}
	
	public function toString():String
	{
		return "SystemData" + "\n"+ 
		"{" + endl() + 
		"  os: " + os + "\n" + 
		"  osRaw: " + osRaw + "\n" +
		"  osName: " + osName + "\n" + 
		"  osVersion: " + osVersion + "\n" + 
		"  totalMemory: " + totalMemory + "\n" +
		"  cpuName: " + cpuName + "\n" +
		"  gpuName: " + gpuName + "\n" +
		"  gpuDriverVersion: " + gpuDriverVersion + "\n" +
		"}";
	}
	
	private function toMB(kilobytes:Int):Float
	{
		return kilobytes / (1024);
	}
	
	private function toGB(kilobytes:Int):Float
	{
		return kilobytes / (1024 * 1024);
	}
	
	private function toGBStr(kilobytes:Int):String
	{
		var gb:Float = toGB(kilobytes);
		gb = Math.round(gb * 100) / 100;
		return Std.string(gb);
	}
	
	private function runProcess(commandStr:String, commandArgs:Array<String>, processFunc:String->Void):Void
	{
		#if sys
			var p:Process = null;
			try
			{
				p = new Process(commandStr, commandArgs);
			}
			catch (msg:String)
			{
				p = null;
			}
			if (p != null)
			{
				p.exitCode();
				var str:String = p.stdout.readAll().toString();
				p.close();
				processFunc(str);
			}
		#end
	}
	
	private function processOS(line:String):Void 
	{
		#if windows
			line = stripEndLines(line);
			osRaw = line;
			line = line.toLowerCase();
			line = stripWhiteSpace(line);
			line = stripWord(line, "microsoft");
			line = stripWord(line, "windows");
			if (line.indexOf("version") != -1)
			{
				line = stripWord(line, "version");
				line = stripWord(line, "[");
				line = stripWord(line, "]");
				osVersion = line;
			}
			switch(line)
			{
				case "3.10.103":	osName = "Windows 3.1";
				case "4.00.950":	osName = "Windows 95";
				case "4.00.1111":	osName = "Windows 95 OSR2";
				case "4.00.1381":	osName = "Windows NT 4.0";
				case "4.10.1998":	osName = "Windows 98";
				case "4.10.2222":	osName = "Windows 98 SE";
				case "4.90.3000":	osName = "Windows ME";
				case "5.00.2195":	osName = "Windows 2000";
				case "5.1.2600":	osName = "Windows XP";
				case "6.0.6000":	osName = "Windows Vista";
				case "6.0.6002":	osName = "Windows Vista SP2";
				case "6.1.7600":	osName = "Windows 7";
				case "6.1.7601":	osName = "Windows 7 SP1";
				case "6.2.9200":	osName = "Windows 8";
				case "6.3.9600":	osName = "Windows 8.1";
				default:			osName = "Windows (unknown version)";
			}
		#elseif linux
			var temp = line.split("\n");
			if (temp != null && temp.length >= 2)
			{
				osName = temp[0] + " (" + temp[1] + ")";
			}
		#elseif mac
			//do mac stuff
		#end
	}
	
	private function processMemory(line:String):Void
	{
		#if windows
			line = stripWhiteSpace(line);
			if (line.indexOf("TotalVisibleMemorySize=") != -1)
			{
				line = stripWord(line,"TotalVisibleMemorySize=");
				totalMemory = Std.parseInt(line);
			}
		#elseif linux
			totalMemory = Std.parseInt(line);
		#elseif mac
			//do mac stuff
		#end
	}
	
	private function processCPU(line:String):Void
	{
		#if windows
			line = stripEndLines(line);
			if (line.indexOf("Name=") != -1) {
				cpuName = stripWord(line, "Name=");
			}
		#elseif linux
			cpuName = stripWord(line,"\n");
		#elseif mac
			//do mac stuff
		#end
	}
	
	private function processGPU(line:String):Void
	{
		#if windows
			var arr:Array<String> = line.split(",");
			if (arr != null && arr.length == 2) {
				for (str in arr) {
					str = stripEndLines(str);
					if (str.indexOf("Name=") != -1)
					{
						gpuName = stripWord(str, "Name=");
					}
					else if (str.indexOf("DriverVersion=") != -1)
					{
						gpuDriverVersion = stripWord(str, "DriverVersion=");
					}
				}
			}
		#elseif linux
			gpuName = line;
			gpuDriverVersion = "unknown";
		#elseif mac
			//do mac stuff
		#end
	}
	
	public static function endl():String
	{
		#if windows
			return "\r\n";
		#end
		return "\n";
	}
	
	public static function slash():String
	{
		#if windows
			return "\\";
		#end
		return "/";
	}
	
	public static function replaceWord(line:String, word:String, replace:String):String
	{
		if (word == replace)
		{
			return line;
		}
		while (line.indexOf(word) != -1)
		{
			line = StringTools.replace(line, word, replace);
		}
		return line;
	}
	
	public static function stripWord(line:String, word:String):String
	{
		while (line.indexOf(word) != -1)
		{
			line = StringTools.replace(line, word, "");
		}
		return line;
	}
	
	public static function stripEndLines(str:String):String
	{
		str = stripWord(str, "\n");
		str = stripWord(str, "\r");
		return str;
	}
	
	public static function stripWhiteSpace(str:String):String
	{
		str = stripWord(str, " ");
		str = stripWord(str, "\t");
		return str;
	}
}
