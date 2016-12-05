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
package actionScripts.impls
{
	
	import com.balsamiq2flexjs.BalsamiqToFlexJSConvert;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.controls.HTML;
	import mx.core.IFlexDisplayObject;
	import mx.core.IVisualElement;
	
	import actionScripts.events.AddTabEvent;
	import actionScripts.events.ChangeLineEncodingEvent;
	import actionScripts.events.GlobalEventDispatcher;
	import actionScripts.events.NewProjectEvent;
	import actionScripts.events.OpenFileEvent;
	import actionScripts.events.ProjectEvent;
	import actionScripts.events.SettingsEvent;
	import actionScripts.factory.FileLocation;
	import actionScripts.interfaces.IFlexCoreBridge;
	import actionScripts.locator.IDEModel;
	import actionScripts.plugin.actionscript.as3project.AS3ProjectPlugin;
	import actionScripts.plugin.actionscript.as3project.clean.cleanProject;
	import actionScripts.plugin.actionscript.as3project.save.SaveFilesPlugin;
	import actionScripts.plugin.actionscript.as3project.vo.AS3ProjectVO;
	import actionScripts.plugin.actionscript.as3project.vo.SWFOutputVO;
	import actionScripts.plugin.console.ConsolePlugin;
	import actionScripts.plugin.core.compiler.CompilerEventBase;
	import actionScripts.plugin.findreplace.FindReplacePlugin;
	import actionScripts.plugin.fullscreen.FullscreenPlugin;
	import actionScripts.plugin.help.HelpPlugin;
	import actionScripts.plugin.project.ProjectPlugin;
	import actionScripts.plugin.recentlyOpened.RecentlyOpenedPlugin;
	import actionScripts.plugin.settings.SettingsPlugin;
	import actionScripts.plugin.settings.SettingsView;
	import actionScripts.plugin.settings.vo.ISetting;
	import actionScripts.plugin.settings.vo.MultiOptionSetting;
	import actionScripts.plugin.settings.vo.NameValuePair;
	import actionScripts.plugin.settings.vo.PathSetting;
	import actionScripts.plugin.settings.vo.SettingsWrapper;
	import actionScripts.plugin.settings.vo.StaticLabelSetting;
	import actionScripts.plugin.settings.vo.StringSetting;
	import actionScripts.plugin.splashscreen.SplashScreenPlugin;
	import actionScripts.plugin.syntax.AS3SyntaxPlugin;
	import actionScripts.plugin.syntax.CSSSyntaxPlugin;
	import actionScripts.plugin.syntax.HTMLSyntaxPlugin;
	import actionScripts.plugin.syntax.JSSyntaxPlugin;
	import actionScripts.plugin.syntax.MXMLSyntaxPlugin;
	import actionScripts.plugin.syntax.XMLSyntaxPlugin;
	import actionScripts.plugin.templating.TemplatingHelper;
	import actionScripts.plugin.templating.TemplatingPlugin;
	import actionScripts.plugins.ant.AntBuildPlugin;
	import actionScripts.plugins.ant.AntBuildScreen;
	import actionScripts.plugins.ant.AntConfigurePlugin;
	import actionScripts.plugins.as3project.exporter.FlashBuilderExporter;
	import actionScripts.plugins.as3project.exporter.FlashDevelopExporter;
	import actionScripts.plugins.as3project.importer.FlashBuilderImporter;
	import actionScripts.plugins.as3project.importer.FlashDevelopImporter;
	import actionScripts.plugins.as3project.mxmlc.MXMLCJavaScriptPlugin;
	import actionScripts.plugins.as3project.mxmlc.MXMLCPlugin;
	import actionScripts.plugins.fdb.FDBPlugin;
	import actionScripts.plugins.fdb.event.FDBEvent;
	import actionScripts.plugins.help.view.TourDeFlexContentsView;
	import actionScripts.plugins.svn.SVNPlugin;
	import actionScripts.plugins.swflauncher.SWFLauncherPlugin;
	import actionScripts.plugins.ui.editor.TourDeTextEditor;
	import actionScripts.ui.IPanelWindow;
	import actionScripts.ui.editor.BasicTextEditor;
	import actionScripts.ui.menu.MenuPlugin;
	import actionScripts.ui.menu.vo.MenuItem;
	import actionScripts.ui.tabview.CloseTabEvent;
	import actionScripts.utils.SHClassTest;
	import actionScripts.utils.SWFTrustPolicyModifier;
	import actionScripts.utils.Untar;
	import actionScripts.valueObjects.ConstantsCoreVO;
	import actionScripts.valueObjects.FileWrapper;
	import actionScripts.valueObjects.Settings;
	
	import components.containers.DownloadNewFlexSDK;
	import components.popup.DefineFolderAccessPopup;
	import components.popup.SoftwareInformation;
	
	public class IFlexCoreBridgeImp implements IFlexCoreBridge
	{
		public var activeType:uint = AS3ProjectPlugin.AS3PROJ_AS_AIR;
		
		private var isActionProject:Boolean;
		private var isBalsamiqProject:Boolean;
		private var templateLookup:Object = {};
		private var cookie:SharedObject;
		private var model:IDEModel = IDEModel.getInstance();
		private var _folderPath:String;
		private var _balsamiqFilePath:String;
		
		//--------------------------------------------------------------------------
		//
		//  INTERFACE METHODS
		//
		//--------------------------------------------------------------------------
		
		public function parseFlashDevelop(project:AS3ProjectVO=null, file:FileLocation=null):AS3ProjectVO
		{
			return FlashDevelopImporter.parse(file);
		}
		
		public function parseFlashBuilder(file:FileLocation):AS3ProjectVO
		{
			return FlashBuilderImporter.parse(file);
		}
		
		public function testFlashDevelop(file:Object):FileLocation
		{
			return FlashDevelopImporter.test(file as File);
		}
		
		public function testFlashBuilder(file:Object):FileLocation
		{
			return FlashBuilderImporter.test(file as File);
		}
		
		public function updateFlashPlayerTrustContent(value:FileLocation):void
		{
			SWFTrustPolicyModifier.updatePolicyFile(value.fileBridge.nativePath);
		}
		
		public function swap(fromIndex:int, toIndex:int,myArray:Array):void
		{
			var temp:* = myArray[toIndex];
			myArray[toIndex] = myArray[fromIndex];
			myArray[fromIndex] = temp;	
		}
		
		public function createAS3Project(event:NewProjectEvent):void
		{
			cookie = SharedObject.getLocal("moonshine-ide-local");
			//Read recent project path from shared object
			
			// Only template for those we can handle
			if (event.projectFileEnding != "as3proj") return;
			
			var project:AS3ProjectVO = FlashDevelopImporter.parse(event.settingsFile);
			// remove any ( or ) stuff
			var tempName: String = event.templateDir.fileBridge.name.substr(0, event.templateDir.fileBridge.name.indexOf("("));
			if (event.templateDir.fileBridge.name.indexOf("Balsamiq") != -1) project.projectName = "NewBalsamiqFlexJSBrowserProject";
			else if (event.templateDir.fileBridge.name.indexOf("FlexJS") != -1) project.projectName = "NewFlexJSBrowserProject";
			else project.projectName = "New"+tempName;
			
			if (cookie.data.hasOwnProperty('recentProjectPath')){
				model.recentSaveProjectPath.source = cookie.data.recentProjectPath;
				project.folderLocation = new FileLocation(model.recentSaveProjectPath.source[0]);
			}
			else{
				project.folderLocation = new FileLocation(File.documentsDirectory.nativePath);
				model.recentSaveProjectPath.addItem(project.folderLocation.fileBridge.nativePath);
			}
			
			var settingsView:SettingsView = new SettingsView();
			settingsView.Width = 150;
			settingsView.defaultSaveLabel = "Create";
			
			settingsView.addCategory("");
			// Remove spaces from project name
			project.projectName = project.projectName.replace(/ /g, "");
			
			var nvps:Vector.<NameValuePair> = Vector.<NameValuePair>([
				new NameValuePair("AIR", AS3ProjectPlugin.AS3PROJ_AS_AIR),
				new NameValuePair("Web", AS3ProjectPlugin.AS3PROJ_AS_WEB)
			]);
			
			var settings:SettingsWrapper = new SettingsWrapper("Name & Location", Vector.<ISetting>([
				new StaticLabelSetting('New '+ event.templateDir.fileBridge.name),
				new StringSetting(project, 'projectName', 'Project Name', 'a-zA-Z0-9._'), // No space input either plx
				new PathSetting(project, 'folderPath', 'Project Directory', true, null, false, true)
			]));
			
			if (event.templateDir.fileBridge.name.indexOf("Actionscript Project") != -1)
			{
				isActionProject = true;
				settings.getSettingsList().push(new MultiOptionSetting(this, "activeType", "Select Project Type", nvps));
			}
			else
			{
				isActionProject = false;
			}
			
			if (event.templateDir.fileBridge.name.indexOf("Balsamiq") != -1)
			{
				var varPathSettings:PathSetting = new PathSetting(project, 'balsamiqPath', 'Balsamiq File', false, project.balsamiqPath,false,false);

				isBalsamiqProject = true;
				
				settings.getSettingsList().push(varPathSettings);
			}
			else
			{
				isBalsamiqProject = false;
			}


			if(isBalsamiqProject)
				settingsView.addEventListener(SettingsView.EVENT_SAVE, createSaveBalsamiq);
			else
				settingsView.addEventListener(SettingsView.EVENT_SAVE, createSave);

			settingsView.addEventListener(SettingsView.EVENT_CLOSE, createClose);
			
			
			settingsView.addSetting(settings, "");
			
			settingsView.label = "New Project";
			settingsView.associatedData = project;
			
			GlobalEventDispatcher.getInstance().dispatchEvent(
				new AddTabEvent(settingsView)
			);
			
			templateLookup[project] = event.templateDir;
		}
		
		public function deleteProject(projectWrapper:FileWrapper, finishHandler:Function):void
		{
			try
			{
				projectWrapper.file.fileBridge.deleteDirectory(true);
			} 
			catch (e:Error)
			{
				projectWrapper.file.fileBridge.deleteDirectoryAsync(true);
			}
			
			// when done call the finish handler
			finishHandler(projectWrapper);
		}
		
		public function exportFlashDevelop(project:AS3ProjectVO, file:FileLocation):void
		{
			FlashDevelopExporter.export(project, file);	
		}
		
		public function exportFlashBuilder(project:AS3ProjectVO, file:FileLocation):void
		{
			FlashBuilderExporter.export(project, file.fileBridge.getFile as File);
		}
		
		public function getTourDeView():IPanelWindow
		{
			return (new TourDeFlexContentsView);
		}
		
		public function getTourDeEditor(swfSource:String):BasicTextEditor
		{
			return (new TourDeTextEditor(swfSource));
		}
		
		public function getCorePlugins():Array
		{
			return [
				SettingsPlugin, 
				ProjectPlugin,
				TemplatingPlugin,
				HelpPlugin,
				FindReplacePlugin,
				RecentlyOpenedPlugin,
				ConsolePlugin,
				//AntConfigurePlugin,
				FullscreenPlugin,
				AntBuildPlugin,
			];
		}
		
		public function getDefaultPlugins():Array
		{
			return [
				MXMLCPlugin,
				MXMLCJavaScriptPlugin,
				SWFLauncherPlugin,
				AS3ProjectPlugin,
				AS3SyntaxPlugin,
				CSSSyntaxPlugin,
				JSSyntaxPlugin,
				HTMLSyntaxPlugin,
				MXMLSyntaxPlugin,
				XMLSyntaxPlugin,
				SplashScreenPlugin,
				cleanProject,
				SVNPlugin,
				FDBPlugin,
				SaveFilesPlugin
			];
		}
		
		public function getPluginsNotToShowInSettings():Array
		{
			return [ProjectPlugin, HelpPlugin, FindReplacePlugin, RecentlyOpenedPlugin, SWFLauncherPlugin, AS3ProjectPlugin, cleanProject, FDBPlugin, MXMLCJavaScriptPlugin];
		}
		
		public function getQuitMenuItem():MenuItem
		{
			return (new MenuItem("Quit", null, MenuPlugin.MENU_QUIT_EVENT, "q", [Keyboard.COMMAND], "f4", [Keyboard.ALTERNATE]));
		}
		
		public function getSettingsMenuItem():MenuItem
		{
			return (new MenuItem("Settings", null, SettingsEvent.EVENT_OPEN_SETTINGS, ",", [Keyboard.COMMAND]));
		}
		
		public function getAboutMenuItem():MenuItem
		{
			return (new MenuItem("About", null, MenuPlugin.EVENT_ABOUT));
		}
		
		public function getWindowsMenu():Vector.<MenuItem>
		{
			var wmn:Vector.<MenuItem> = Vector.<MenuItem>([
				new MenuItem("File", [
					new MenuItem("New",[]),
					new MenuItem("Open", null, OpenFileEvent.OPEN_FILE,
						'o', [Keyboard.COMMAND],
						'o', [Keyboard.CONTROL]),
					new MenuItem(null),
					new MenuItem("Save", null, MenuPlugin.MENU_SAVE_EVENT,
						's', [Keyboard.COMMAND],
						's', [Keyboard.CONTROL]),
					new MenuItem("Save As", null, MenuPlugin.MENU_SAVE_AS_EVENT,
						's', [Keyboard.COMMAND, Keyboard.SHIFT],
						's', [Keyboard.CONTROL, Keyboard.SHIFT]),
					new MenuItem("Close", null, CloseTabEvent.EVENT_CLOSE_TAB,
						'w', [Keyboard.COMMAND],
						'w', [Keyboard.CONTROL]),
					/*new MenuItem("Define Workspace", null, ProjectEvent.SET_WORKSPACE),*/
					new MenuItem(null),
					new MenuItem("Line Endings", [
						new MenuItem("Windows (CRLF - \\r\\n)", null, ChangeLineEncodingEvent.EVENT_CHANGE_TO_WIN),
						new MenuItem("UNIX (LF - \\n)", null, ChangeLineEncodingEvent.EVENT_CHANGE_TO_UNIX),
						new MenuItem("OS9 (CR - \\r)", null, ChangeLineEncodingEvent.EVENT_CHANGE_TO_OS9)
					])
				]),
				new MenuItem("Edit", [
					new MenuItem("Find", null, FindReplacePlugin.EVENT_FIND_NEXT,
						'f', [Keyboard.COMMAND],
						'f', [Keyboard.CONTROL]),
					new MenuItem("Find previous", null, FindReplacePlugin.EVENT_FIND_PREV,
						'f', [Keyboard.COMMAND, Keyboard.SHIFT],
						'f', [Keyboard.CONTROL, Keyboard.SHIFT]),
					new MenuItem(null),
					new MenuItem("Find Resource", null, FindReplacePlugin.EVENT_FIND_RESOURCE,
						'r', [Keyboard.COMMAND, Keyboard.SHIFT],
						'r', [Keyboard.CONTROL, Keyboard.SHIFT])
				]),
				new MenuItem("View", [
					new MenuItem('Project view', null, ProjectEvent.SHOW_PROJECT_VIEW),
					new MenuItem('Fullscreen', null, FullscreenPlugin.EVENT_FULLSCREEN),
					new MenuItem('Debug view', null, FDBEvent.SHOW_DEBUG_VIEW),
					new MenuItem('Home', null, SplashScreenPlugin.EVENT_SHOW_SPLASH)
				]),
				new MenuItem("Project",[
					new MenuItem('Open/Import Flex Project', null, ProjectEvent.EVENT_IMPORT_FLASHBUILDER_PROJECT),
					new MenuItem(null),
					new MenuItem("Build Project", null, CompilerEventBase.BUILD,
						'b', [Keyboard.COMMAND],
						'b', [Keyboard.CONTROL]),
					new MenuItem("Build & Run", null, CompilerEventBase.BUILD_AND_RUN, 
						"\n", [Keyboard.COMMAND],
						"\n", [Keyboard.CONTROL]),
					new MenuItem("Build as JavaScript", null, CompilerEventBase.BUILD_AS_JAVASCRIPT,
						'j', [Keyboard.COMMAND],
						'j', [Keyboard.CONTROL]),
					new MenuItem("Build & Run as JavaScript",null,CompilerEventBase.BUILD_AND_RUN_JAVASCRIPT),
					new MenuItem("Build Release", null, CompilerEventBase.BUILD_RELEASE),
					new MenuItem("Clean Project", null,  CompilerEventBase.CLEAN_PROJECT),
					new MenuItem("Build with Apache® Ant", null,  AntBuildPlugin.SELECTED_PROJECT_ANTBUILD)
				]),
				new MenuItem("Debug",[
					new MenuItem("Build & Debug", null, CompilerEventBase.BUILD_AND_DEBUG, 
						"d", [Keyboard.COMMAND],
						"d", [Keyboard.CONTROL]),
					new MenuItem(null),
					new MenuItem("Step Over", null, CompilerEventBase.DEBUG_STEPOVER, 
						"e",[Keyboard.COMMAND],
						"f6", []),
					new MenuItem("Resume", null, CompilerEventBase.CONTINUE_EXECUTION,
						"r",[Keyboard.COMMAND],
						"f8", []),
					new MenuItem("Stop", null, CompilerEventBase.TERMINATE_EXECUTION,
						"t",[Keyboard.COMMAND],
						"t", [Keyboard.CONTROL])
				]),
				new MenuItem("Ant", [
					new MenuItem('Build Apache® Ant File', null, AntBuildPlugin.EVENT_ANTBUILD)
				/*	new MenuItem('Configure', null, AntConfigurePlugin.EVENT_ANTCONFIGURE)*/
				]),
				new MenuItem("Subversion", [
					new MenuItem("Checkout", null, SVNPlugin.CHECKOUT_REQUEST)
				]),
				new MenuItem("Help", Settings.os == "win"? [ 
					new MenuItem('About', null, MenuPlugin.EVENT_ABOUT),
					new MenuItem('API Docs', null, HelpPlugin.EVENT_AS3DOCS),
					new MenuItem('Tour De Flex', null, HelpPlugin.EVENT_TOURDEFLEX)]:
					[new MenuItem('API Docs', null, HelpPlugin.EVENT_AS3DOCS),
					new MenuItem('Tour De Flex', null, HelpPlugin.EVENT_TOURDEFLEX)
					])
			]);
			
			// add a new menuitem after Access Manager
			// in case of osx and if bundled with sdks
			CONFIG::OSX
				{
					var firstMenuItems:Vector.<MenuItem> = wmn[0].items;
					for (var i:int; i < firstMenuItems.length; i++)
					{
						if (firstMenuItems[i].label == "Close")
						{
							firstMenuItems.splice(i+1, 0, (new MenuItem(null)));
							firstMenuItems.splice(i+2, 0, (new MenuItem("Access Manager", null, ProjectEvent.ACCESS_MANAGER)));
							firstMenuItems.splice(i+3, 0, (new MenuItem(ConstantsCoreVO.IS_BUNDLED_SDK_PRESENT ? "Extract Bundled SDK" : "Moonshine Helper Application", null, ConstantsCoreVO.IS_BUNDLED_SDK_PRESENT ? HelpPlugin.EVENT_SDK_UNZIP_REQUEST : HelpPlugin.EVENT_SDK_HELPER_DOWNLOAD_REQUEST)));
							break;
						}
					}
				}
			
			return wmn;
		}
		
		public function getHTMLView(url:String):DisplayObject
		{
			var tmpHTML:HTML = new HTML();
			tmpHTML.location = url;
			return tmpHTML;
		}
		
		public function getAccessManagerPopup():IFlexDisplayObject
		{
			return (new DefineFolderAccessPopup);
		}
		
		public function getSDKInstallerView():IFlexDisplayObject
		{
			return (new DownloadNewFlexSDK);
		}
		
		public function getSoftwareInformationView():IVisualElement
		{
			return (new SoftwareInformation());
		}
		
		public function getNewAntBuild():IFlexDisplayObject
		{
			return (new AntBuildScreen());
		}
		
		public function exitApplication():void
		{
			NativeApplication.nativeApplication.exit();
		}
		
		public function untar(fileToUnzip:FileLocation, unzipTo:FileLocation, unzipCompleteFunction:Function, unzipErrorFunction:Function = null):void
		{
			var tmpUnzip:Untar = new Untar(fileToUnzip, unzipTo, unzipCompleteFunction, unzipErrorFunction);
		}
		
		public function removeExAttributesTo(path:String):void
		{
			var tmp:SHClassTest = new SHClassTest();
			tmp.removeExAttributesTo(path);
		}
		
		public function get runtimeVersion():String
		{
			return NativeApplication.nativeApplication.runtimeVersion;
		}
		
		public function get version():String
		{
			var appDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = new Namespace(appDescriptor.namespace());
			var appVersion:String = appDescriptor.ns::versionNumber;
			
			return appVersion;
		}
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE LISTENERS
		//
		//--------------------------------------------------------------------------
		
		private function createClose(event:Event):void
		{
			var settings:SettingsView = event.target as SettingsView;
			
			settings.removeEventListener(SettingsView.EVENT_CLOSE, createClose);
			settings.removeEventListener(SettingsView.EVENT_SAVE, createSave);
			
			delete templateLookup[settings.associatedData];
			
			GlobalEventDispatcher.getInstance().dispatchEvent(
				new CloseTabEvent(CloseTabEvent.EVENT_CLOSE_TAB, event.target as DisplayObject)
			);
		}
		
		private function createSave(event:Event):void
		{
			var view:SettingsView = event.target as SettingsView;
			var pvo:AS3ProjectVO = view.associatedData as AS3ProjectVO;
			var templateDir:FileLocation = templateLookup[pvo];
			var projectName:String = pvo.projectName;
			var targetFolder:FileLocation = pvo.folderLocation;
				
			var comparePath:Boolean=false;

			//save  project path in shared object
			cookie = SharedObject.getLocal("moonshine-ide-local");
			if(!cookie.data.hasOwnProperty("recentProjectPath"))
				cookie.data.recentProjectPath = new Array();

			//Avoid to add duplicate entry in shared object
			for(var i:int=0;i<cookie.data.recentProjectPath.length;i++)
			{
				if(cookie.data.recentProjectPath[i]==targetFolder.fileBridge.nativePath)
				{
					swap(0,i,cookie.data.recentProjectPath);
					comparePath = true;
					break;
				}
			}
			if(!comparePath)
				cookie.data.recentProjectPath.splice(0,0,targetFolder.fileBridge.nativePath);
			
			
			var movieVersion:String = "10.0";
			// lets load the target flash/air player version
			// since swf and air player both versioning same now,
			// we can load anyone's config file
			movieVersion = SWFOutputVO.getSDKSWFVersion().toString()+".0";
			
			// Create project root directory
			targetFolder = targetFolder.resolvePath(projectName);
			targetFolder.fileBridge.createDirectory();
			
			// Time to do the templating thing!
			var th:TemplatingHelper = new TemplatingHelper();
			th.templatingData["$ProjectName"] = projectName;
			
			var pattern:RegExp = new RegExp(/(_)/g);
			th.templatingData["$ProjectID"] = projectName.replace(pattern, "");
			th.templatingData["$ProjectSWF"] = projectName+".swf";
			th.templatingData["$ProjectFile"] = projectName+(isActionProject ? ".as" : ".mxml");
			th.templatingData["$DesktopDescriptor"] = projectName+"-app.xml";
			th.templatingData["$Settings"] = projectName;
			th.templatingData["$Certificate"] = projectName+"Certificate";
			th.templatingData["$Password"] = projectName+"Certificate";
			th.templatingData["$FlexHome"] = (IDEModel.getInstance().defaultSDK) ? IDEModel.getInstance().defaultSDK.fileBridge.nativePath : "";
			th.templatingData["$MovieVersion"] = movieVersion;
			th.projectTemplate(templateDir, targetFolder);

			// If this an ActionScript Project then we need to copy selective file/folders for web or desktop
			var descriptorFile:FileLocation;
			if (isActionProject)
			{
				if (activeType == AS3ProjectPlugin.AS3PROJ_AS_AIR)
				{
					// build folder modification
					th.projectTemplate(templateDir.resolvePath("build_air"), targetFolder.resolvePath("build"));
					descriptorFile = targetFolder.resolvePath("build/"+projectName+"-app.xml");
					try
					{
						descriptorFile.fileBridge.moveTo(targetFolder.resolvePath("src/"+projectName+"-app.xml"), true);
					}
					catch(e:Error)
					{
						descriptorFile.fileBridge.moveToAsync(targetFolder.resolvePath("src/"+projectName+"-app.xml"), true);
					}
				}
				else
				{
					th.projectTemplate(templateDir.resolvePath("build_web"), targetFolder.resolvePath("build"));
					th.projectTemplate(templateDir.resolvePath("bin-debug_web"), targetFolder.resolvePath("bin-debug"));
				}
				
				// we also needs to delete unnecessary folders
				var folderToDelete1:FileLocation = targetFolder.resolvePath("build_air");
				var folderToDelete2:FileLocation = targetFolder.resolvePath("build_web");
				var folderToDelete3:FileLocation = targetFolder.resolvePath("bin-debug_web");
				try
				{
					folderToDelete1.fileBridge.deleteDirectory(true);
					folderToDelete2.fileBridge.deleteDirectory(true);
					folderToDelete3.fileBridge.deleteDirectory(true);
				} catch (e:Error)
				{
					folderToDelete1.fileBridge.deleteDirectoryAsync(true);
					folderToDelete2.fileBridge.deleteDirectoryAsync(true);
					folderToDelete3.fileBridge.deleteDirectoryAsync(true);
				}
			}
			
			// creating certificate conditional checks
			if (!descriptorFile || !descriptorFile.fileBridge.exists)
			{
				descriptorFile = targetFolder.resolvePath("application.xml");
				if (!descriptorFile.fileBridge.exists)
				{
					descriptorFile = targetFolder.resolvePath("src/"+projectName+"-app.xml");
				}
			}
			
			if (descriptorFile.fileBridge.exists)
			{
				// lets update $SWFVersion with SWF version now
				var stringOutput:String = descriptorFile.fileBridge.read() as String;
				var firstNamespaceQuote:int = stringOutput.indexOf('"', stringOutput.indexOf("<application xmlns=")) + 1;
				var lastNamespaceQuote:int = stringOutput.indexOf('"', firstNamespaceQuote);
				var currentAIRNamespaceVersion:String = stringOutput.substring(firstNamespaceQuote, lastNamespaceQuote);
				
				stringOutput = stringOutput.replace(currentAIRNamespaceVersion, "http://ns.adobe.com/air/application/"+ movieVersion);
				descriptorFile.fileBridge.save(stringOutput);
			}
			
			// Figure out which one is the settings file
			var settingsFile:FileLocation = targetFolder.resolvePath(projectName+".as3proj");
			
			// Set some stuff to get the paths right
			pvo = FlashDevelopImporter.parse(settingsFile);
			pvo.projectName = projectName;

			// Write settings
			FlashDevelopExporter.export(pvo, settingsFile); 
			
			GlobalEventDispatcher.getInstance().dispatchEvent(
				new ProjectEvent(ProjectEvent.ADD_PROJECT, pvo)
			);

			// Close settings view
			createClose(event);
			// Open main file for editing
			GlobalEventDispatcher.getInstance().dispatchEvent( 
				new OpenFileEvent(OpenFileEvent.OPEN_FILE, pvo.targets[0])
			);
			
		}
		
		
		private function createSaveBalsamiq(event:Event):void
		{
			var view:SettingsView = event.target as SettingsView;
			var pvo:AS3ProjectVO = view.associatedData as AS3ProjectVO;
			var templateDir:FileLocation = templateLookup[pvo];
			var projectName:String = pvo.projectName;
			var balsamiqPath:String;
			var targetFolder:FileLocation = pvo.folderLocation;
			var comparePath:Boolean=false;
			var targetProjectPath:String = targetFolder.fileBridge.nativePath + "/" + projectName;
			//var targetMXML:String = targetFolder.fileBridge.nativePath + "/" + projectName + "/src/" + projectName + ".mxml";
			var blnValidBalsamiq:Boolean=false;
			
			if(pvo.balsamiqPath != null)
			{
				balsamiqPath =  pvo.balsamiqPath
			}
			else
			{
				Alert.show("Please specify Balsamiq File Path");
				return;
			}
			
			if(isBalsamiqProject)
			{
				var convert1:BalsamiqToFlexJSConvert = new BalsamiqToFlexJSConvert(balsamiqPath, targetProjectPath);
				convert1.validateXML(
					function():void{
						if(! convert1.isValidXML())
						{
							// This was already alerted in validateXML
							//Alert.show("Error Occured in Reading XML File. Returning");
							return;
						}
						else
						{
							exportBalsamiq(balsamiqPath, targetProjectPath, projectName);
							
							setTimeout(custom1, 1000);
							
							function custom1():void {
								//save  project path in shared object
								cookie = SharedObject.getLocal("moonshine-ide-local");
								if(!cookie.data.hasOwnProperty("recentProjectPath"))
									cookie.data.recentProjectPath = new Array();
	
								//Avoid to add duplicate entry in shared object
								for(var i:int=0;i<cookie.data.recentProjectPath.length;i++)
								{
									if(cookie.data.recentProjectPath[i]==targetFolder.fileBridge.nativePath)
									{
										swap(0,i,cookie.data.recentProjectPath);
										comparePath = true;
										break;
									}
								}
								if(!comparePath)
									cookie.data.recentProjectPath.splice(0,0,targetFolder.fileBridge.nativePath);
								
								var movieVersion:String = "10.0";
								// lets load the target flash/air player version
								// since swf and air player both versioning same now,
								// we can load anyone's config file
								movieVersion = SWFOutputVO.getSDKSWFVersion().toString()+".0";
	
								
								// Create project root directory
								targetFolder = targetFolder.resolvePath(projectName);
								targetFolder.fileBridge.createDirectory();
								
	
	
								// Time to do the templating thing!
								var th:TemplatingHelper = new TemplatingHelper();
								th.templatingData["$ProjectName"] = projectName;
								th.templatingData["$ProjectSWF"] = projectName+".swf";
								th.templatingData["$ProjectFile"] = projectName+(isActionProject ? ".as" : ".mxml");
								th.templatingData["$DesktopDescriptor"] = projectName+"-app.xml";
								th.templatingData["$Settings"] = projectName;
								th.templatingData["$Certificate"] = projectName+"Certificate";
								th.templatingData["$Password"] = projectName+"Certificate";
								th.templatingData["$FlexHome"] = (IDEModel.getInstance().defaultSDK) ? IDEModel.getInstance().defaultSDK.fileBridge.nativePath : "";
								th.templatingData["$MovieVersion"] = movieVersion;
								th.projectTemplate(templateDir, targetFolder);
	
								var descriptorFile:FileLocation;
								
								// creating certificate conditional checks
								if (!descriptorFile || !descriptorFile.fileBridge.exists)
								{
									descriptorFile = targetFolder.resolvePath("application.xml");
									if (!descriptorFile.fileBridge.exists)
									{
										descriptorFile = targetFolder.resolvePath("src/"+projectName+"-app.xml");
									}
								}
								
								if (descriptorFile.fileBridge.exists)
								{
									var stringOutput:String = descriptorFile.fileBridge.read() as String;
									var firstNamespaceQuote:int = stringOutput.indexOf('"', stringOutput.indexOf("<application xmlns=")) + 1;
									var lastNamespaceQuote:int = stringOutput.indexOf('"', firstNamespaceQuote);
									var currentAIRNamespaceVersion:String = stringOutput.substring(firstNamespaceQuote, lastNamespaceQuote);
									
									stringOutput = stringOutput.replace(currentAIRNamespaceVersion, "http://ns.adobe.com/air/application/"+ movieVersion);
									descriptorFile.fileBridge.save(stringOutput);
								}
								
								// Figure out which one is the settings file
								var settingsFile:FileLocation = targetFolder.resolvePath(projectName+".as3proj");
								
								// Set some stuff to get the paths right
								pvo = FlashDevelopImporter.parse(settingsFile);
								pvo.projectName = projectName;
	
	
								// Write settings
								FlashDevelopExporter.export(pvo, settingsFile); 
								
								GlobalEventDispatcher.getInstance().dispatchEvent(
									new ProjectEvent(ProjectEvent.ADD_PROJECT, pvo)
								);
	
								// Close settings view
								createClose(event);
								// Open main file for editing
								GlobalEventDispatcher.getInstance().dispatchEvent( 
									new OpenFileEvent(OpenFileEvent.OPEN_FILE, pvo.targets[0])
								);
							}// End Function Custom1							
							
						}
	
					}
					);
			}
			
		}
		
		private function exportBalsamiq(fromBalsamiq:String, toAS:String, projectName:String):void
		{
			try{
				var convert1:BalsamiqToFlexJSConvert = new BalsamiqToFlexJSConvert(fromBalsamiq, toAS);
				convert1.setProjectName(projectName);
				convert1.loadXMLMulti(false);
			}
			catch (e:Error)
			{
				trace(e);
			}
		}
		
		
	}
}
