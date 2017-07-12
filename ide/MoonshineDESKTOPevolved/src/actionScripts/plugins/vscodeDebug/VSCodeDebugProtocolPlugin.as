////////////////////////////////////////////////////////////////////////////////
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
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
// 
////////////////////////////////////////////////////////////////////////////////
package actionScripts.plugins.vscodeDebug
{
	import actionScripts.events.EditorPluginEvent;
	import actionScripts.locator.IDEModel;
	import actionScripts.plugin.PluginBase;
	import actionScripts.plugin.actionscript.as3project.vo.AS3ProjectVO;
	import actionScripts.plugin.core.compiler.CompilerEventBase;
	import actionScripts.plugins.vscodeDebug.view.VSCodeDebugProtocolView;
	import actionScripts.ui.editor.BasicTextEditor;
	import actionScripts.ui.editor.text.events.DebugLineEvent;
	import actionScripts.ui.menu.MenuPlugin;
	import actionScripts.ui.tabview.CloseTabEvent;
	import actionScripts.utils.findOpenPort;
	import actionScripts.utils.getProjectSDKPath;
	import actionScripts.valueObjects.Settings;

	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.setTimeout;

	import mx.controls.Alert;

	public class VSCodeDebugProtocolPlugin extends PluginBase
	{
		public static const EVENT_SHOW_DEBUG_VIEW:String = "EVENT_SHOW_DEBUG_VIEW";
		private static const MAX_RETRY_COUNT:int = 5;
		private static const TWO_CRLF:String = "\r\n\r\n";
		private static const CONTENT_LENGTH_PREFIX:String = "Content-Length: ";
		private static const MESSAGE_TYPE_REQUEST:String = "request";
		private static const MESSAGE_TYPE_RESPONSE:String = "response";
		private static const MESSAGE_TYPE_EVENT:String = "event";
		private static const COMMAND_INITIALIZE:String = "initialize";
		private static const COMMAND_LAUNCH:String = "launch";
		private static const COMMAND_THREADS:String = "threads";
		private static const COMMAND_SET_BREAKPOINTS:String = "setBreakpoints";
		private static const COMMAND_PAUSE:String = "pause";
		private static const COMMAND_CONTINUE:String = "continue";
		private static const COMMAND_NEXT:String = "next";
		private static const COMMAND_STEP_IN:String = "stepIn";
		private static const COMMAND_STEP_OUT:String = "stepOut";
		private static const COMMAND_DISCONNECT:String = "disconnect";
		private static const COMMAND_STACK_TRACE:String = "stackTrace";
		private static const EVENT_INITIALIZED:String = "initialized";
		private static const EVENT_BREAKPOINT:String = "breakpoint";
		private static const EVENT_OUTPUT:String = "output";
		private static const EVENT_STOPPED:String = "stopped";
		private static const EVENT_TERMINATED:String = "terminated";
		private static const REQUEST_LAUNCH:String = "launch";
		private static const OUTPUT_CATEGORY_STDERR:String = "stderr";
		
		override public function get name():String 			{ return "VSCode Debug Protocol Plugin"; }
		override public function get author():String 		{ return "Moonshine Project Team"; }
		override public function get description():String 	{ return "Debugs ActionScript and MXML projects with the Visual Studio Code Debug Protocol."; }

		private var _cmdFile:File;
		private var _breakpoints:Object = {};
		private var _debugPanel:VSCodeDebugProtocolView;
		private var _nativeProcess:NativeProcess;
		private var _socket:Socket;
		private var _byteArray:ByteArray;
		private var _port:int;
		private var _retryCount:int;
		private var _connected:Boolean = false;
		private var _paused:Boolean = true;
		private var _seq:int = 0;
		private var _messageBuffer:String = "";
		private var _bodyLength:int = -1;
		private var mainThreadID:int = -1;

		public function VSCodeDebugProtocolPlugin()
		{
			_byteArray = new ByteArray();
			if (Settings.os === "win")
			{
				_cmdFile = new File("c:\\Windows\\System32\\cmd.exe");
			}
			else
			{
				_cmdFile = File.documentsDirectory.resolvePath("/usr/bin/java");
			}
		}

		override public function activate():void
		{
			super.activate();

			this._debugPanel = new VSCodeDebugProtocolView();
			
			dispatcher.addEventListener(EVENT_SHOW_DEBUG_VIEW, dispatcher_showDebugViewHandler);
			dispatcher.addEventListener(CompilerEventBase.POSTBUILD, dispatcher_postBuildHandler);
			///dispatcher.addEventListener(CompilerEventBase.PREBUILD, handleCompile);
			dispatcher.addEventListener(EditorPluginEvent.EVENT_EDITOR_OPEN, dispatcher_editorOpenHandler);
			/*dispatcher.addEventListener(MenuPlugin.MENU_SAVE_EVENT, handleEditorSave);
			dispatcher.addEventListener(MenuPlugin.MENU_SAVE_AS_EVENT, handleEditorSave);*/
			dispatcher.addEventListener(CloseTabEvent.EVENT_CLOSE_TAB, dispatcher_closeTabHandler);
			/*
			dispatcher.addEventListener(CompilerEventBase.CONTINUE_EXECUTION,continueExecutionHandler);
			dispatcher.addEventListener(CompilerEventBase.TERMINATE_EXECUTION,terminateExecutionHandler);*/
			dispatcher.addEventListener(MenuPlugin.MENU_QUIT_EVENT, dispatcher_quitHandler);
			dispatcher.addEventListener(DebugLineEvent.SET_DEBUG_LINE, dispatcher_setDebugLineHandler);
		}

		override public function deactivate():void
		{
			super.deactivate();
			
			if(this._debugPanel)
			{
				if(this._debugPanel.parent)
				{
					IDEModel.getInstance().mainView.removePanel(this._debugPanel);
				}
				this._debugPanel = null;
			}

			dispatcher.removeEventListener(EVENT_SHOW_DEBUG_VIEW, dispatcher_showDebugViewHandler);
			dispatcher.removeEventListener(CompilerEventBase.POSTBUILD, dispatcher_postBuildHandler);
			dispatcher.removeEventListener(EditorPluginEvent.EVENT_EDITOR_OPEN, dispatcher_editorOpenHandler);
			dispatcher.removeEventListener(CloseTabEvent.EVENT_CLOSE_TAB, dispatcher_closeTabHandler);
			dispatcher.removeEventListener(MenuPlugin.MENU_QUIT_EVENT, dispatcher_quitHandler);
		}

		private function saveEditorBreakpoints(editor:BasicTextEditor):void
		{
			if(!editor)
			{
				return;
			}
			if(!editor.currentFile)
			{
				return;
			}

			var path:String = editor.currentFile.fileBridge.nativePath;
			if (path == "")
			{
				return;
			}

			this._breakpoints[path] = editor.getEditorComponent().breakpoints;
		}
		
		private function cleanupSocket():void
		{
			if(!_socket)
			{
				return;
			}
			_socket.removeEventListener(Event.CONNECT, socket_connectHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, socketConnect_ioErrorHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
			_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, socketConnect_securityErrorHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, socket_socketDataHandler);
			_socket.removeEventListener(Event.CLOSE, socket_closeHandler);
			_socket = null;
		}
		
		private function connectToProcess():void
		{
			if(!_nativeProcess)
			{
				Alert.show("Could not connect to the SWF debugger. Debugger stopped before connection completed.", "Debug Error", Alert.OK);
				return;
			}
			cleanupSocket();
			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT, socket_connectHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, socketConnect_ioErrorHandler);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socketConnect_securityErrorHandler);
			_socket.connect("localhost", _port);
		}

		private function parseMessageBuffer():void
		{
			if(this._bodyLength !== -1)
			{
				if(this._messageBuffer.length < this._bodyLength)
				{
					//we don't have the full body yet
					return;
				}
				var body:String = this._messageBuffer.substr(0, this._bodyLength);
				this._messageBuffer = this._messageBuffer.substr(this._bodyLength);
				this._bodyLength = -1;
				var message:Object = JSON.parse(body);
				this.parseProtocolMessage(message);
			}
			else if(this._messageBuffer.length > CONTENT_LENGTH_PREFIX.length)
			{
				//start with a new header
				var index:int = this._messageBuffer.indexOf(TWO_CRLF, CONTENT_LENGTH_PREFIX.length);
				if(index === -1)
				{
					//we don't have a full header yet
					return;
				}
				var lengthString:String = this._messageBuffer.substr(CONTENT_LENGTH_PREFIX.length, index - CONTENT_LENGTH_PREFIX.length);
				this._bodyLength = parseInt(lengthString, 10);
				this._messageBuffer = this._messageBuffer.substr(index + TWO_CRLF.length);
			}
			else
			{
				//we don't have a full header yet
				return;
			}
			//keep trying to parse until we hit one of the return statements
			//above
			this.parseMessageBuffer();
		}

		private function sendRequest(command:String, args:Object = null):void
		{
			_seq++;
			var message:Object =
			{
				"type": MESSAGE_TYPE_REQUEST,
				"seq": _seq,
				"command": command
			};
			if(args !== null)
			{
				message.arguments = args;
			}
			sendProtocolMessage(message);
		}

		private function sendProtocolMessage(message:Object):void
		{
			var string:String = JSON.stringify(message);
			_byteArray.clear();
			_byteArray.writeUTFBytes(string);
			var contentLength:String = _byteArray.length.toString();
			_byteArray.clear();
			_socket.writeUTFBytes(CONTENT_LENGTH_PREFIX);
			_socket.writeUTFBytes(contentLength);
			_socket.writeUTFBytes(TWO_CRLF);
			_socket.writeUTFBytes(string);
			_socket.flush();
		}

		private function parseResponse(response:Object):void
		{
			switch(response.command)
			{
				case COMMAND_INITIALIZE:
				{
					if(response.success === true)
					{
						var project:AS3ProjectVO = model.activeProject as AS3ProjectVO;
						this.sendRequest(COMMAND_LAUNCH,
						{
							"program": project.swfOutput.path.fileBridge.nativePath,
							"request": REQUEST_LAUNCH
						});
					}
					else
					{
						trace("initialize command not successful!");
					}
					break;
				}
				case COMMAND_CONTINUE:
				{
					if(response.success === true)
					{
						this._paused = false;
						refreshView();
					}
					else
					{
						trace("continue command not successful!");
					}
					break;
				}
				case COMMAND_THREADS:
				{
					if(response.success === true)
					{
						this._paused = false;
						refreshView();

						var body:Object = response.body;
						if("threads" in body)
						{
							var threads:Array = body.threads as Array;
							mainThreadID = threads[0].id;
						}
					}
					else
					{
						trace("threads command not successful!");
					}
					break;
				}
				case COMMAND_SET_BREAKPOINTS:
				{
					if(response.success === true)
					{
						if(mainThreadID === -1)
						{
							this.sendRequest(COMMAND_THREADS);
						}
					}
					else
					{
						trace("setbreakpoints command not successful!");
					}
					break;
				}
				case COMMAND_STACK_TRACE:
				{
					if(response.success === true)
					{
						var body:Object = response.body;
						if("stackFrames" in body)
						{
							var stackFrames:Array = body.stackFrames as Array;
							var stackFramesCount:int = stackFrames.length;
							for(var i:int = 0; i < stackFramesCount; i++)
							{
								var stackFrame:Object = stackFrames[i];
								trace(stackFrame.name + " " + stackFrame.line);
							}
						}
						refreshView();
					}
					else
					{
						trace("stackTrace command not successful!");
					}
					break;
				}
				case COMMAND_LAUNCH:
				case COMMAND_PAUSE:
				case COMMAND_STEP_IN:
				case COMMAND_STEP_OUT:
				case COMMAND_NEXT:
				{
					if(response.success === false)
					{
						trace(response.command + " command not successful!");
					}
					break;
				}
				default:
				{
					trace("Cannot parse debug response:", JSON.stringify(response));
				}
			}
			
		}

		private function parseEvent(event:Object):void
		{
			switch(event.event)
			{
				case EVENT_INITIALIZED:
				{
					var hasBreakpoints:Boolean = false;
					for(var key:String in _breakpoints)
					{
						hasBreakpoints = true;
						sendSetBreakpointsRequestForPath(key);
					}
					if(!hasBreakpoints)
					{
						this.sendRequest(COMMAND_THREADS);
					}
					break;
				}
				case EVENT_OUTPUT:
				{
					var output:String = null;
					var category:String = "console";
					if("body" in event)
					{
						var body:Object = event.body;
						if("output" in body)
						{
							output = body.output as String;
						}
						if("category" in body)
						{
							category = body.category as String;
						}
					}
					if(output !== null)
					{
						if(category === OUTPUT_CATEGORY_STDERR)
						{
							error(output);
						}
						else
						{
							print(output);
						}
					}
					break;
				}
				case EVENT_BREAKPOINT:
				{
					//we don't currently indicate if a breakpoint is verified or
					//not so, we can ignore this one.
					break;
				}
				case EVENT_STOPPED:
				{
					this.sendRequest(COMMAND_STACK_TRACE,
					{
						threadId: mainThreadID
					});
					_paused = true;
					refreshView();
					break;
				}
				case EVENT_TERMINATED:
				{
					_paused = true;
					refreshView();
					break;
				}
				default:
				{
					trace("Cannot parse debug event:", JSON.stringify(event));
				}
			}
		}

		private function parseProtocolMessage(message:Object):void
		{
			if("type" in message)
			{
				switch(message.type)
				{
					case MESSAGE_TYPE_RESPONSE:
					{
						this.parseResponse(message);
						break;
					}
					case MESSAGE_TYPE_EVENT:
					{
						this.parseEvent(message);
						break;
					}
					default:
					{
						trace("Cannot parse debug message:", JSON.stringify(message));
					}
				}
			}
			else
			{
				trace("Cannot parse debug message:", JSON.stringify(message));
			}
		}
		
		private function showDebugView():void
		{
			IDEModel.getInstance().mainView.addPanel(this._debugPanel);
			_debugPanel.validateNow();
			_debugPanel.playButton.addEventListener(MouseEvent.CLICK, playButton_clickHandler);
			_debugPanel.pauseButton.addEventListener(MouseEvent.CLICK, pauseButton_clickHandler);
			_debugPanel.stepOverButton.addEventListener(MouseEvent.CLICK, stepOutButton_clickHandler);
			_debugPanel.stepIntoButton.addEventListener(MouseEvent.CLICK, stepIntoButton_clickHandler);
			_debugPanel.stepOutButton.addEventListener(MouseEvent.CLICK, stepOutButton_clickHandler);
			_debugPanel.stopButton.addEventListener(MouseEvent.CLICK, stopButton_clickHandler);
		}
		
		private function refreshView():void
		{
			if(!_debugPanel.parent)
			{
				return;
			}
			_debugPanel.playButton.enabled = this._connected && this._paused;
			_debugPanel.pauseButton.enabled = this._connected && !this._paused;
			_debugPanel.stepOverButton.enabled = this._connected && this._paused;
			_debugPanel.stepIntoButton.enabled = this._connected && this._paused;
			_debugPanel.stepOutButton.enabled = this._connected && this._paused;
			_debugPanel.stopButton.enabled = this._connected;
		}
		
		private function sendSetBreakpointsRequestForPath(path:String):void
		{
			if(!(path in _breakpoints))
			{
				return;
			}
			var breakpoints:Array = _breakpoints[path] as Array;
			breakpoints = breakpoints.map(function(item:int, index:int, source:Array):Object
			{
				//the debugger expects breakpoints to start at line 1
				//but moonshine stores breakpoints from line 0
				return { line: item + 1 };
			});
			this.sendRequest(COMMAND_SET_BREAKPOINTS,
			{
				source: { path: path },
				breakpoints: breakpoints
			});
		}
		
		private function dispatcher_showDebugViewHandler(event:Event):void
		{
			showDebugView();
		}

		private function dispatcher_editorOpenHandler(event:EditorPluginEvent):void
		{
			if (event.newFile || !event.file)
			{
				return;
			}

			var path:String = event.file.fileBridge.nativePath;
			var breakpoints:Array = this._breakpoints[path] as Array;
			if(breakpoints)
			{
				//restore the breakpoints
				event.editor.breakpoints = breakpoints;
			}
		}
		
		private function dispatcher_closeTabHandler(event:CloseTabEvent):void
		{
			var editor:BasicTextEditor = event.tab as BasicTextEditor;
			this.saveEditorBreakpoints(editor);
		}
		
		private function dispatcher_setDebugLineHandler(event:DebugLineEvent):void
		{
			var editor:BasicTextEditor = model.activeEditor as BasicTextEditor;
			saveEditorBreakpoints(editor);
			if(_connected)
			{
				var path:String = editor.currentFile.fileBridge.nativePath;
				sendSetBreakpointsRequestForPath(path);
			}
		}
		
		protected function dispatcher_postBuildHandler(event:Event):void
		{
			if(_nativeProcess)
			{
				//if we're already debugging, kill the previous process
				_nativeProcess.exit(true);
			}

			_connected = false;
			refreshView();
			_port = findOpenPort();
			
			var processArgs:Vector.<String> = new <String>[];
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			if (Settings.os == "win")
			{
				processArgs.push("/C");
				processArgs.push("java");
			}
			var project:AS3ProjectVO = model.activeProject as AS3ProjectVO;
			var sdkFile:File = new File(getProjectSDKPath(project, model));
			processArgs.push("-Dflexlib=" + sdkFile.resolvePath("frameworks").nativePath);
			processArgs.push("-Dworkspace=" + project.folderLocation.fileBridge.nativePath);
			processArgs.push("-cp");
			var cp:String = File.applicationDirectory.resolvePath("elements/*").nativePath;
			if (Settings.os == "win")
			{
				cp += ";"
			}
			else
			{
				cp += ":";
			}
			cp += sdkFile.resolvePath("lib/*").nativePath;
			processArgs.push(cp);
			processArgs.push("com.nextgenactionscript.vscode.SWFDebug");
			processArgs.push("--server=" + _port);
			var cwd:File = new File(model.activeProject.folderLocation.resolvePath("bin-debug").fileBridge.nativePath);
			startupInfo.workingDirectory = cwd;
			startupInfo.arguments = processArgs;
			startupInfo.executable = _cmdFile;
			_nativeProcess = new NativeProcess();
			_nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, nativeProcess_standardErrorDataHandler);
			_nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, nativeProcess_exitHandler);
			_nativeProcess.start(startupInfo);

			//connect after a delay because it's not clear when the server has
			//been started by the process
			_retryCount = 0;
			mainThreadID = -1;
			setTimeout(connectToProcess, 100);
		}

		protected function socket_connectHandler(event:Event):void
		{
			_connected = true;
			refreshView();
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, socketConnect_ioErrorHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, socket_socketDataHandler);
			_socket.addEventListener(Event.CLOSE, socket_closeHandler);

			showDebugView();
			clearOutput();
			
			sendRequest(COMMAND_INITIALIZE,
			{
				"clientID": "moonshine",
				"adapterID": "swf"
			});
		}
		
		protected function socketConnect_ioErrorHandler(event:IOErrorEvent):void
		{
			if(_nativeProcess)
			{
				_retryCount++;
				if(_retryCount === MAX_RETRY_COUNT)
				{
					Alert.show("Could not connect to the SWF debugger Retried " + _retryCount + " times.", "Debug Error", Alert.OK);
					cleanupSocket();
					return;
				}
				//try again if the process is still running
				setTimeout(connectToProcess, 100);
				return;
			}
			cleanupSocket();
		}

		protected function socketConnect_securityErrorHandler(event:SecurityErrorEvent):void
		{
			Alert.show("Could not connect to the SWF debugger. Internal error.", "Debug Error", Alert.OK);
			cleanupSocket();
		}

		protected function socket_ioErrorHandler(event:IOErrorEvent):void
		{
			trace("socket io error:", event.toString());
		}

		protected function socket_socketDataHandler(event:ProgressEvent):void
		{
			this._messageBuffer += _socket.readUTFBytes(_socket.bytesAvailable);
			this.parseMessageBuffer();
		}

		protected function socket_closeHandler(event:Event):void
		{
			_connected = false;
			refreshView();
			cleanupSocket();
		}

		protected function nativeProcess_standardErrorDataHandler(event:ProgressEvent):void
		{
			var output:IDataInput = _nativeProcess.standardError;
			var data:String = output.readUTFBytes(output.bytesAvailable);
			trace("[swf-debugger]", data);
		}
		
		protected function nativeProcess_exitHandler(event:NativeProcessExitEvent):void
		{
			_nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, nativeProcess_standardErrorDataHandler);
			_nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, nativeProcess_exitHandler);
			_nativeProcess.exit();
			_nativeProcess = null;
		}
		
		protected function dispatcher_quitHandler(event:Event):void
		{
			if(!_nativeProcess)
			{
				return;
			}
			_nativeProcess.exit(true);
		}
		
		protected function stopButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_DISCONNECT);
		}

		protected function pauseButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_PAUSE);
		}

		protected function playButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_CONTINUE);
		}

		protected function stepOverButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_NEXT);
		}

		protected function stepIntoButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_STEP_IN);
		}

		protected function stepOutButton_clickHandler(event:MouseEvent):void
		{
			this.sendRequest(COMMAND_STEP_OUT);
		}
	}
}
