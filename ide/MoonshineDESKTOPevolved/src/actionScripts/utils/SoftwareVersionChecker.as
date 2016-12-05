////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 Prominic.NET, Inc.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
//
// Author: Prominic.NET, Inc. 
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
////////////////////////////////////////////////////////////////////////////////
package actionScripts.utils
{
	import actionScripts.valueObjects.Settings;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.IDataInput;

	public class SoftwareVersionChecker
	{
		[Bindable] public static var JAVA_VERSION: String = "- Not Found -";
		[Bindable] public static var ANT_VERSION: String = "- Not Found -";
		[Bindable] public static var FLEX_SYSTEM_VERSION: String = "- Not Found -";
		[Bindable]public  static var isMacOS  : Boolean;
		
		private var cmdFile: File;
		private var shellInfo: NativeProcessStartupInfo;
		private var nativeProcess: NativeProcess;
		private var checkingQueues: Array; 
		private var currentQueuePosition: int;
		
		
		/**
		 * Checks some required/optional software installation
		 * and their version if available
		 */
		public function SoftwareVersionChecker()
		{
			if (Settings.os == "win")
			{
				cmdFile = new File("c:\\Windows\\System32\\cmd.exe");
				checkingQueues = ["java -version", "ant -version", "mxmlc -version"];
				isMacOS = false;
			}
			else 
			{
				cmdFile = File.documentsDirectory.resolvePath("/bin/bash");
				isMacOS = true;
				checkingQueues = ["java -version"];
			}
			startCheckingProcess();
		}
		
		private function startCheckingProcess():void
		{
			// probable termination
			if (currentQueuePosition >= checkingQueues.length) return;
			
			var processArgs:Vector.<String> = new Vector.<String>;
			shellInfo = new NativeProcessStartupInfo();
			
			if (Settings.os == "win") processArgs.push("/C");
			else processArgs.push("-c");
			processArgs.push(checkingQueues[currentQueuePosition]);
			shellInfo.arguments = processArgs;
			shellInfo.executable = cmdFile;
			
			initShell();
		}
		
		private function initShell():void 
		{
			if (nativeProcess) nativeProcess.exit();
			else startShell();
		}
		
		private function startShell():void 
		{
			nativeProcess = new NativeProcess();
			
			nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, shellData);
			nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, shellError);
			nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, shellExit);
			nativeProcess.start(shellInfo);
		}
		
		private function shellData(e:ProgressEvent):void 
		{
			var output:IDataInput = nativeProcess.standardOutput;
			parseData(output.readUTFBytes(output.bytesAvailable));
		}
		
		private function shellError(e:ProgressEvent):void 
		{
			var output:IDataInput = nativeProcess.standardError;
			parseData(output.readUTFBytes(output.bytesAvailable));
		}
		
		private function shellExit(e:NativeProcessExitEvent):void 
		{
			nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, shellData);
			nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, shellError);
			nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, shellExit);
			nativeProcess.exit();
			nativeProcess = null;
			currentQueuePosition ++;
			startCheckingProcess();
		}
		
		private function parseData(data:String):void
		{
			var match : Array = data.match(/java version/);
			if (match) JAVA_VERSION = (data.split("\n")[0].toString()).split("java version")[1];
			
			match = data.match(/Ant\(TM\) version/);
			if (match) ANT_VERSION = data.split("\n")[0];
			
			// mxmlc check
			if (currentQueuePosition == 2 && data.match("Version")) FLEX_SYSTEM_VERSION = data.split("\n")[0];
		}
	}
}