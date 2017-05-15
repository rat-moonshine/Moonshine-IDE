package actionScripts.utils
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.net.XMLSocket;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	
	import mx.events.CollectionEvent;
	
	import actionScripts.events.CompletionItemsEvent;
	import actionScripts.events.DiagnosticsEvent;
	import actionScripts.events.FileChangeEvent;
	import actionScripts.events.GlobalEventDispatcher;
	import actionScripts.events.GotoDefinitionEvent;
	import actionScripts.events.HoverEvent;
	import actionScripts.events.ReferencesEvent;
	import actionScripts.events.SignatureHelpEvent;
	import actionScripts.events.SymbolsEvent;
	import actionScripts.events.TypeAheadEvent;
	import actionScripts.locator.IDEModel;
	import actionScripts.plugin.actionscript.as3project.vo.AS3ProjectVO;
	import actionScripts.plugin.console.ConsoleOutputter;
	import actionScripts.plugin.help.HelpPlugin;
	import actionScripts.ui.editor.BasicTextEditor;
	import actionScripts.ui.menu.MenuPlugin;
	import actionScripts.valueObjects.Command;
	import actionScripts.valueObjects.CompletionItem;
	import actionScripts.valueObjects.Diagnostic;
	import actionScripts.valueObjects.Location;
	import actionScripts.valueObjects.ParameterInformation;
	import actionScripts.valueObjects.Position;
	import actionScripts.valueObjects.ProjectReferenceVO;
	import actionScripts.valueObjects.Range;
	import actionScripts.valueObjects.Settings;
	import actionScripts.valueObjects.SignatureHelp;
	import actionScripts.valueObjects.SignatureInformation;
	import actionScripts.valueObjects.SymbolInformation;
	
	import no.doomsday.console.ConsoleUtil;

	public class TypeAheadProcess
	{
		private static const MARKDOWN_NEXTGENAS_START:String = "```nextgenas\n";
		private static const MARKDOWN_MXML_START:String = "```mxml\n";
		private static const MARKDOWN_CODE_END:String = "\n```";
		private static const FLEXJS_NAME_PREFIX:String = "Apache Flex (FlexJS) ";
		
		private var cmdFile: File;
		private var shellInfo: NativeProcessStartupInfo;
		private var nativeProcess: NativeProcess;
		private var checkingQueues: Array; 
		private var xmlSocket :XMLSocket;
		private var flag:Boolean = false;
		private var model:IDEModel = IDEModel.getInstance();
		//private var setFlexJSSDKPopup:SetFlexJSSDKMessagePopup;
		private var javaPath:String;
		private var dispatcher:GlobalEventDispatcher = GlobalEventDispatcher.getInstance();
		private var requestID:int = 0;
		private var gotoDefinitionLookup:Dictionary = new Dictionary();
		private var findReferencesLookup:Dictionary = new Dictionary();
		
		public function TypeAheadProcess(path:String)
		{
			if (Settings.os == "win")
			{
				cmdFile = new File("c:\\Windows\\System32\\cmd.exe");
			}
			else 
			{
				cmdFile = File.documentsDirectory.resolvePath("/usr/bin/java");
			}
			this.javaPath = path;
			model.userSavedSDKs.addEventListener(CollectionEvent.COLLECTION_CHANGE,collectionChangedHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_DIDOPEN, didOpenCall);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_DIDCHANGE, didChangeCall);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_TYPEAHEAD, completionHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_SIGNATURE_HELP, signatureHelpHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_HOVER, hoverHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_GOTO_DEFINITION, gotoDefinitionHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_WORKSPACE_SYMBOLS, workspaceSymbolsHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_DOCUMENT_SYMBOLS, documentSymbolsHandler);
			GlobalEventDispatcher.getInstance().addEventListener(TypeAheadEvent.EVENT_FIND_REFERENCES, findReferencesHandler);
			GlobalEventDispatcher.getInstance().addEventListener(MenuPlugin.MENU_QUIT_EVENT, shutdownHandler);
			//connectToJava();
			startNativeProcess();
		}

		private function getNextRequestID():int
		{
			requestID++;
			return requestID;
		}

		private function startNativeProcess():void
		{
			var processArgs:Vector.<String> = new Vector.<String>;
			shellInfo = new NativeProcessStartupInfo();
			var jarFile:File = File.applicationDirectory.resolvePath("elements/codecompletion.jar");
			if (Settings.os == "win")
			{
				processArgs.push("/C");
				processArgs.push("java");
				processArgs.push("-jar");
				processArgs.push(jarFile.nativePath);
			}
			else
			{
				processArgs.push("-jar");
				processArgs.push(jarFile.nativePath);
			}
			var javafile:File = new File(this.javaPath);
			shellInfo.workingDirectory =javafile;
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
			var data:String = output.readUTFBytes(output.bytesAvailable);
			ConsoleUtil.print("shellError " + data + ".");
			ConsoleOutputter.formatOutput(HtmlFormatter.sprintfa(data, null), 'weak');
			var match:Array;
			//A new filter added here which will detect command for FDB exit
			match = data.match(/.*\ onConnected */);
			if(match)
			{
				trace(data);
				parseData(output.readUTFBytes(output.bytesAvailable));
			}
			else
			{
				trace(data);
				//Alert.show("jar connection "+data);
			}
			
		}
		
		private function shellExit(e:NativeProcessExitEvent):void 
		{
			if(xmlSocket)shutdownHandler(null);
			nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, shellData);
			nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, shellError);
			nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, shellExit);
			nativeProcess.exit();
			nativeProcess = null;
		}
		
		private function parseData(data:String):void
		{
			//Alert.show(data+" Parse Data " + flag);
			if(!flag)connectToJava();
		}
		
		protected function connectToJava():void
		{
			// TODO Auto-generated method stub
			//Alert.show("connect to java "+xmlSocket);
			if(!xmlSocket)
			{
				//Alert.show("XML Socket Start");
				xmlSocket = new XMLSocket();
				xmlSocket.connect("127.0.0.1", 58080);
				
				xmlSocket.addEventListener(DataEvent.DATA, onIncomingData);
				xmlSocket.addEventListener(IOErrorEvent.IO_ERROR,onSocketIOError);
				xmlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onSocketSecurityErr);
				xmlSocket.addEventListener(Event.CONNECT,onConnect);
				xmlSocket.addEventListener(Event.CLOSE,closeHandler);
				//collectionChangedHandler(null);//Call collection change handle for sending flexjs sdk to java when java server start
				flag = true;
			}
		}
		
		private function closeHandler(evt:Event):void{
			if(xmlSocket){
				xmlSocket.close();
				xmlSocket = null;
			}
			
		}
		
		private function onConnect(event:Event):void{
			collectionChangedHandler(null);//Call collection change handle for sending flexjs sdk to java when java server start
		}
		 private function onSocketIOError(event:IOErrorEvent):void {
			 ConsoleUtil.print("ioError " + event.text + ".");
			 ConsoleOutputter.formatOutput(HtmlFormatter.sprintfa("ioError "+event, null), 'weak');
			}
		
		private function onSocketSecurityErr(event:SecurityErrorEvent):void {
			ConsoleUtil.print("securityError " + event.text + ".");
			ConsoleOutputter.formatOutput(HtmlFormatter.sprintfa("securityError "+event, null), 'weak');
		}
		
		//Read Incoming data
		private function onIncomingData(event:DataEvent):void
		{
			var data:String = event.data;
			trace(data);
			//Alert.show("Data"+data);
			//Alert.show("incomeing data "+data);
			var object:Object = null;
			try
			{
				object = JSON.parse(data);
			}
			catch(error:Error)
			{
				trace("invalid JSON");
				return;
			}
			if("method" in object)
			{
				var method:String = object.method;
				if(method === "textDocument/publishDiagnostics")
				{
					var diagnosticsParams:Object = object.params;
					var uri:String = diagnosticsParams.uri;
					var path:String = (new File(uri)).nativePath;
					var resultDiagnostics:Array = diagnosticsParams.diagnostics;
					var diagnostics:Vector.<Diagnostic> = new <Diagnostic>[];
					var diagnosticsCount:int = resultDiagnostics.length;
					for(var i:int = 0; i < diagnosticsCount; i++)
					{
						var resultDiagnostic:Object = resultDiagnostics[i];
						diagnostics[i] = this.parseDiagnostic(path, resultDiagnostic);
					}
					GlobalEventDispatcher.getInstance().dispatchEvent(new DiagnosticsEvent(DiagnosticsEvent.EVENT_SHOW_DIAGNOSTICS, path, diagnostics));
				}
			}
			else if("result" in object && "id" in object)
			{
				var result:Object = object.result;
				var requestID:int = object.id as int;
				if("items" in result) //completion
				{
					var resultCompletionItems:Array = result.items as Array;
					if(resultCompletionItems)
					{
						var eventCompletionItems:Array = new Array();
						var completionItemCount:int = resultCompletionItems.length;
						for(i = 0; i < completionItemCount; i++)
						{
							var resultItem:Object = resultCompletionItems[i];
							eventCompletionItems[i] = parseCompletionItem(resultItem);
						}
						eventCompletionItems.sortOn("label",Array.CASEINSENSITIVE);
						GlobalEventDispatcher.getInstance().dispatchEvent(new CompletionItemsEvent(CompletionItemsEvent.EVENT_SHOW_COMPLETION_LIST,eventCompletionItems));
					}
				}
				if("signatures" in result) //signature help
				{
					var resultSignatures:Array = result.signatures as Array;
					if(resultSignatures && resultSignatures.length > 0)
					{
						var eventSignatures:Vector.<SignatureInformation> = new <SignatureInformation>[];
						var resultSignaturesCount:int = resultSignatures.length;
						for(i = 0; i < resultSignaturesCount; i++)
						{
							var resultSignature:Object = resultSignatures[i];
							eventSignatures[i] = parseSignatureInformation(resultSignature);
						}
						var signatureHelp:SignatureHelp = new SignatureHelp();
						signatureHelp.signatures = eventSignatures;
						signatureHelp.activeSignature = result.activeSignature;
						signatureHelp.activeParameter = result.activeParameter;
						GlobalEventDispatcher.getInstance().dispatchEvent(new SignatureHelpEvent(SignatureHelpEvent.EVENT_SHOW_SIGNATURE_HELP, signatureHelp));
					}
				}
				if("contents" in result) //hover
				{
					var resultContents:Array = result.contents as Array;
					if(resultContents)
					{
						var eventContents:Vector.<String> = new <String>[];
						var resultContentsCount:int = resultContents.length;
						for(i = 0; i < resultContentsCount; i++)
						{
							var resultContent:String = resultContents[i];
							//strip markdown formatting
							if(resultContent.indexOf(MARKDOWN_NEXTGENAS_START) === 0)
							{
								resultContent = resultContent.substr(MARKDOWN_NEXTGENAS_START.length);
							}
							if(resultContent.indexOf(MARKDOWN_MXML_START) === 0)
							{
								resultContent = resultContent.substr(MARKDOWN_MXML_START.length);
							}
							var expectedEndIndex:int = resultContent.length - MARKDOWN_CODE_END.length;
							if(resultContent.lastIndexOf(MARKDOWN_CODE_END) === expectedEndIndex)
							{
								resultContent = resultContent.substr(0, expectedEndIndex);
							}
							eventContents[i] = resultContent;
						}
						GlobalEventDispatcher.getInstance().dispatchEvent(new HoverEvent(HoverEvent.EVENT_SHOW_HOVER, eventContents));
					}
				}
				if(result is Array) //definitions
				{
					if(requestID in gotoDefinitionLookup)
					{
						var position:Position = gotoDefinitionLookup[requestID] as Position;
						delete gotoDefinitionLookup[requestID];
						var resultLocations:Array = result as Array;
						var eventLocations:Vector.<Location> = new <Location>[];
						var resultLocationsCount:int = resultLocations.length;
						for(i = 0; i < resultLocationsCount; i++)
						{
							var resultLocation:Object = resultLocations[i];
							eventLocations[i] = parseLocation(resultLocation);
						}
						GlobalEventDispatcher.getInstance().dispatchEvent(new GotoDefinitionEvent(GotoDefinitionEvent.EVENT_SHOW_DEFINITION_LINK, eventLocations, position));
					}
					else if(requestID in findReferencesLookup)
					{
						delete findReferencesLookup[requestID];
						var resultReferences:Array = result as Array;
						var eventReferences:Vector.<Location> = new <Location>[];
						var resultReferencesCount:int = resultReferences.length;
						for(i = 0; i < resultReferencesCount; i++)
						{
							var resultReference:Object = resultReferences[i];
							eventReferences[i] = parseLocation(resultReference);
						}
						GlobalEventDispatcher.getInstance().dispatchEvent(new ReferencesEvent(ReferencesEvent.EVENT_SHOW_REFERENCES, eventReferences));
					}
					else //document or workspace symbols
					{
						var resultSymbolInfos:Array = result as Array;
						var eventSymbolInfos:Vector.<SymbolInformation> = new <SymbolInformation>[];
						var resultSymbolInfosCount:int = resultSymbolInfos.length;
						for(i = 0; i < resultSymbolInfosCount; i++)
						{
							var resultSymbolInfo:Object = resultSymbolInfos[i];
							eventSymbolInfos[i] = parseSymbolInformation(resultSymbolInfo);
						}
						GlobalEventDispatcher.getInstance().dispatchEvent(new SymbolsEvent(SymbolsEvent.EVENT_SHOW_SYMBOLS, eventSymbolInfos));
					}
				}
			}
		}
		
		//For shutdown java socket
		public function shutdownHandler(event:Event):void{
			if(xmlSocket)xmlSocket.send("SHUTDOWN");
			xmlSocket = null;
		}

		private function parseSymbolInformation(original:Object):SymbolInformation
		{
			var vo:SymbolInformation = new SymbolInformation();
			vo.name = original.name;
			vo.kind = original.kind;
			vo.location = parseLocation(original.location);
			return vo;
		}

		private function parseDiagnostic(path:String, original:Object):Diagnostic
		{
			var vo:Diagnostic = new Diagnostic();
			vo.path = path;
			vo.message = original.message;
			vo.code = original.code;
			vo.range = parseRange(original.range);
			vo.severity = original.severity;
			return vo;
		}

		private function parseLocation(original:Object):Location
		{
			var vo:Location = new Location();
			vo.uri = original.uri;
			vo.range = parseRange(original.range);
			return vo;
		}

		private function parseRange(original:Object):Range
		{
			var vo:Range = new Range();
			vo.start = parsePosition(original.start);
			vo.end = parsePosition(original.end);
			return vo;
		}

		private function parsePosition(original:Object):Position
		{
			var vo:Position = new Position();
			vo.line = original.line;
			vo.character = original.character;
			return vo;
		}

		private function parseCompletionItem(original:Object):CompletionItem
		{
			var vo:CompletionItem = new CompletionItem();
			vo.label = original.label;
			vo.insertText = original.insertText;
			vo.detail  = original.detail;
			vo.kind = original.kind;
			if("command" in original)
			{
				vo.command = parseCommand(original.command);
			}
			return vo;
		}

		private function parseCommand(original:Object):Command
		{
			var vo:Command = new Command();
			vo.title = original.title;
			vo.command = original.command;
			vo.arguments = original.arguments;
			return vo;
		}

		private function parseSignatureInformation(original:Object):SignatureInformation
		{
			var vo:SignatureInformation = new SignatureInformation();
			vo.label = original.label;
			var originalParameters:Array = original.parameters;
			var parameters:Vector.<ParameterInformation> = new <ParameterInformation>[];
			var originalParametersCount:int = originalParameters.length;
			for(var i:int = 0; i < originalParametersCount; i++)
			{
				var resultParameter:Object = originalParameters;
				var parameter:ParameterInformation = new ParameterInformation();
				parameter.label = resultParameter[parameter];
				parameters[i] = parameter;
			}
			vo.parameters = parameters;
			return vo;
		}

		//Call Didopen from Java
		private function didOpenCall(evt:TypeAheadEvent):void{
			if(xmlSocket)
			{
				DidChangeConfigurationParams();
				var obj:Object = new Object();
				obj.jsonrpc = "2.0";
				obj.id = getNextRequestID();
				obj.method = "textDocument/didOpen";
				var textDocument:Object = new Object();
				textDocument.uri = evt.uri;
				textDocument.languageId = "1";
				textDocument.version = 1;
				textDocument.text = "";
				var params:Object = new Object();
				params.textDocument = textDocument;
				obj.params = params;
				var jsonstr:String = JSON.stringify(obj);
				xmlSocket.send(jsonstr);
				
				//Alert.show(jsonstr+"didopen");
			}
		}
		
		//Listen events for userSavedSDKs collection changed
		private function collectionChangedHandler(evt:CollectionEvent):void{
			if(xmlSocket)
			{
				
				var hasFlexJS:Boolean = checkFlexJSSDK();
				if(!hasFlexJS)
				{
					dispatcher.dispatchEvent(new Event(HelpPlugin.EVENT_TYPEAHEAD_REQUIRES_SDK));
					
					//Open an Alert for message
					/*if(!setFlexJSSDKPopup)
					{
						setFlexJSSDKPopup = PopUpManager.createPopUp(FlexGlobals.topLevelApplication as DisplayObject, SetFlexJSSDKMessagePopup ,false) as SetFlexJSSDKMessagePopup;
						setFlexJSSDKPopup.addEventListener(SetFlexJSSDKMessagePopup.SET_SDK, onFlexSDKUpdated);
						setFlexJSSDKPopup.addEventListener(SetFlexJSSDKMessagePopup.CONTINUE, onFlexSDKContinue);
						setFlexJSSDKPopup.addEventListener(SetFlexJSSDKMessagePopup.CANCELLED, onFlexSDKContinue);
						PopUpManager.centerPopUp(setFlexJSSDKPopup);
					}
					else
					{
						PopUpManager.centerPopUp(setFlexJSSDKPopup);
					}*/
				}
				else
				{
					dispatcher.dispatchEvent(new Event(MenuPlugin.CHANGE_MENU_SDK_STATE));
				}
			}
		}
		
		private function checkFlexJSSDK():Boolean
		{
			var hasFlex:Boolean = false;
			if(xmlSocket)
			{
				var path:String;
				var bestVersionValue:int = 0;
				for each (var i:ProjectReferenceVO in model.userSavedSDKs)
				{
					var sdkName:String = i.name;
					if (sdkName.indexOf(FLEXJS_NAME_PREFIX) != -1)
					{
						var sdkVersion:String = sdkName.substr(FLEXJS_NAME_PREFIX.length, sdkName.indexOf(" ", FLEXJS_NAME_PREFIX.length) - FLEXJS_NAME_PREFIX.length);
						var versionParts:Array = sdkVersion.split("-")[0].split(".");
						var major:int = 0;
						var minor:int = 0;
						var revision:int = 0;
						if (versionParts.length >= 3)
						{
							major = parseInt(versionParts[0], 10);
							minor = parseInt(versionParts[1], 10);
							revision = parseInt(versionParts[2], 10);
						}
						//FlexJS 0.7.0 is the minimum version supported by the
						//language server. this may change in the future.
						if (major > 0 || minor >= 7)
						{
							//convert the three parts of the version number
							//into a single value to compare to other versions.
							var currentValue:int = major * 1e6 + minor * 1000 + revision;
							if(bestVersionValue < currentValue)
							{
								//pick the newest available version of FlexJS
								//to power the language server.
								hasFlex = true;
								path = i.path;
								bestVersionValue = currentValue;
								model.isCodeCompletionJavaPresent = true;
							}
						}
					}
				}
				if(!hasFlex)
				{
					path = "";
				}
				trace("Language Server SDK: " + path);
				var obj:Object = new Object();
				obj.jsonrpc = "2.0";
				obj.id = getNextRequestID();
				obj.method = "textDocument/flexJSPath";
				var params:Object = new Object();
				params.flexJSPath = path;
				obj.params = params;
				var jsonstr:String = JSON.stringify(obj);
				xmlSocket.send(jsonstr);
		
			}
			return hasFlex;
		}
		
		private function onFlexSDKUpdated(evt:Event):void{
			//setFlexJSSDKPopup = null;
		}
		
		private function onFlexSDKContinue(evt:Event):void{
			//PopUpManager.removePopUp(setFlexJSSDKPopup);
			//setFlexJSSDKPopup = null;
		}
		
		private function DidChangeConfigurationParams():void{
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "workspace/didChangeConfiguration";
			var pvo:AS3ProjectVO = model.activeProject as AS3ProjectVO;
			if(pvo)
			{
				if(xmlSocket)
				{
				var DidChangeConfigurationParams:Object = new Object();
				DidChangeConfigurationParams.uri = pvo.targets[0].fileBridge.nativePath;
				var buildArgs:String = pvo.buildOptions.getArguments();
				var dbg:String;
				if (buildArgs.indexOf(" -debug=") > -1) dbg = "false";
				DidChangeConfigurationParams.debug = dbg;
				DidChangeConfigurationParams.config = pvo.air?"air":"flex";
				var params:Object = new Object();
				params.DidChangeConfigurationParams = DidChangeConfigurationParams;
				obj.params = params;
				var jsonstr:String = JSON.stringify(obj);
				xmlSocket.send(jsonstr); 
				//Alert.show(jsonstr+"didchangeconfi");
				}
			}
		}
		
		private function didChangeCall(evt:TypeAheadEvent):void{
			if(!xmlSocket)
			{
				return
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/didChange";
			
			var textDocument:Object = new Object();
			textDocument.version = 1;
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;
			
			var range:Object = new Object();
			var startposition:Object = new Object();
			startposition.line = evt.startLineNumber;
			startposition.character = evt.startLinePos;
			range.start = startposition;
			
			var endposition:Object = new Object();
			endposition.line =evt.endLineNumber;
			endposition.character = evt.endLinePos;
			range.end = endposition;
			
			var contentChangesArr:Array = new Array();
			var contentChanges:Object = new Object();
			contentChanges.range = null;//range;
			contentChanges.rangeLength = 0;//evt.textlen;
			contentChanges.text = evt.newText;
			
			var DidChangeTextDocumentParams:Object = new Object();
			DidChangeTextDocumentParams.textDocument = textDocument;
			DidChangeTextDocumentParams.contentChanges = contentChanges;
			
			var params:Object = new Object();
			params.DidChangeTextDocumentParams = DidChangeTextDocumentParams;
			obj.params = params;
			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}
		
		private function completionHandler(evt:TypeAheadEvent):void{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/completion";
			
			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;
			
			var position:Object = new Object();
			position.line = evt.endLineNumber;
			position.character = evt.endLinePos;
			
			var TextDocumentPositionParams:Object = new Object();
			TextDocumentPositionParams.textDocument = textDocument;
			TextDocumentPositionParams.position = position;
			
			var params:Object = new Object();
			params.TextDocumentPositionParams = TextDocumentPositionParams;
			obj.params = params;
			
			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}

		private function signatureHelpHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/signatureHelp";

			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;

			var position:Object = new Object();
			position.line = event.endLineNumber;
			position.character = event.endLinePos;

			var TextDocumentPositionParams:Object = new Object();
			TextDocumentPositionParams.textDocument = textDocument;
			TextDocumentPositionParams.position = position;

			var params:Object = new Object();
			params.TextDocumentPositionParams = TextDocumentPositionParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}

		private function hoverHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/hover";

			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;

			var position:Object = new Object();
			position.line = event.endLineNumber;
			position.character = event.endLinePos;

			var TextDocumentPositionParams:Object = new Object();
			TextDocumentPositionParams.textDocument = textDocument;
			TextDocumentPositionParams.position = position;

			var params:Object = new Object();
			params.TextDocumentPositionParams = TextDocumentPositionParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}
		
		private function gotoDefinitionHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/definition";
			gotoDefinitionLookup[obj.id] = new Position(event.endLineNumber, event.endLinePos); 

			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;

			var position:Object = new Object();
			position.line = event.endLineNumber;
			position.character = event.endLinePos;

			var TextDocumentPositionParams:Object = new Object();
			TextDocumentPositionParams.textDocument = textDocument;
			TextDocumentPositionParams.position = position;

			var params:Object = new Object();
			params.TextDocumentPositionParams = TextDocumentPositionParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}

		private function workspaceSymbolsHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var query:String = event.newText;

			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "workspace/symbol";

			var WorkspaceSymbolParams:Object = new Object();
			WorkspaceSymbolParams.query = query;

			var params:Object = new Object();
			params.WorkspaceSymbolParams = WorkspaceSymbolParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}

		private function documentSymbolsHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/documentSymbol";

			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;

			var DocumentSymbolParams:Object = new Object();
			DocumentSymbolParams.textDocument = textDocument;

			var params:Object = new Object();
			params.DocumentSymbolParams = DocumentSymbolParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}
		
		private function findReferencesHandler(event:TypeAheadEvent):void
		{
			if(!xmlSocket)
			{
				return;
			}
			var obj:Object = new Object();
			obj.jsonrpc = "2.0";
			obj.id = getNextRequestID();
			obj.method = "textDocument/references";
			findReferencesLookup[obj.id] = true;

			var textDocument:Object = new Object();
			textDocument.uri = (model.activeEditor as BasicTextEditor).currentFile.fileBridge.url;

			var position:Object = new Object();
			position.line = event.endLineNumber;
			position.character = event.endLinePos;

			var context:Object = new Object();
			context.includeDeclaration = true;

			var ReferenceParams:Object = new Object();
			ReferenceParams.textDocument = textDocument;
			ReferenceParams.position = position;
			ReferenceParams.context = context;

			var params:Object = new Object();
			params.ReferenceParams = ReferenceParams;
			obj.params = params;

			var jsonstr:String = JSON.stringify(obj);
			xmlSocket.send(jsonstr);
		}
	}
	
}