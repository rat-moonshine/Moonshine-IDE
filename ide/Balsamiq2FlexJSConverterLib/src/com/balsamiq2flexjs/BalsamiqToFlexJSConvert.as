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
package com.balsamiq2flexjs
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	import mx.controls.Alert;
    
    public class BalsamiqToFlexJSConvert extends Sprite
    {
		public static const IS_MACOS:Boolean = !NativeApplication.supportsSystemTrayIcon;
		
        private var calledCount:int = 0;
		private var xmlData:XML;
		private var arrXMLData:Array;
		
		
	
		
		// Domain class properties, used by single object view and other files
		private var TableName:String;
		private var GrailsDomainClassPackageName:String;
		private var GrailsDomainClassName:String;
		private var GrailsSanitizerType:String;
		private var RESTUrl:String;
		
		
		// Domain class fields properties, used by FlexJS domain class and utils
		// NOTE the single object view doesn't use these, since it uses old custom code to generate
		private var domainClassFields: Array;
		
		

		// Used by single object view
		private var arrControls:Array;
        private var arrComponents:Array;
        
		
		private var strMXMLData:String;
		private var arrViewMXMLData:Array;
        private var strXMLPath:String;
        private var strMXMLExportFilePath:String;
		//private var strDomainClassNameInputted:String;
        private var XVarianceAllowed:int;
        private var YVarianceAllowed:int;
        private var Debugging:Boolean;
        private var blnValidXML:Boolean;
        public var callBackF:Function;
	private var isMultiFile:Boolean;
	private var fileNames:Array;
	private var fileStartCount:int;
	private var fileEndCount:int;
	private var allPhysicalFilesExist:Boolean;
	private var FilesPath:String;
	private var projectName:String;

		private var templatesFolder:File = File.applicationDirectory.resolvePath("templates");
        
        public function isValidXML():Boolean
        {
            return blnValidXML;
        }
        
     	public function setProjectName(_projectName:String):void
        {
            projectName=_projectName;
        }

        public function BalsamiqToFlexJSConvert(XMLPath:String, MXMLExportFilePath:String):void
        {
            try{
			var intIndex1:int;
			var intIndex2:int;
			var strFileName:String;
			var strFileNameFirstPart:String;
			var strFileNameToPush:String;
			
			fileNames = new Array();
			arrXMLData = new Array();
			
			strXMLPath = new File(XMLPath).url;
			
				//strXMLPath = "file://" + strXMLPath;
			strMXMLExportFilePath = MXMLExportFilePath;
				var file:File = new File(strMXMLExportFilePath);
				file.createDirectory();
			blnValidXML = true;
				//strDomainClassNameInputted = DomainClassName;			
			
			intIndex1 = 0;
			intIndex2 = strXMLPath.lastIndexOf("/");
			
			FilesPath = strXMLPath.substring(intIndex1, intIndex2);
			
			strFileName=strXMLPath.substring(intIndex2+1);
			
			
			intIndex1 = strFileName.indexOf("_of_");
			intIndex2 = strFileName.lastIndexOf("_", intIndex1 - 1);
			strFileNameFirstPart = strFileName.substring(0, intIndex2);
			

			intIndex1 = strXMLPath.indexOf("_of_");
			
			if (intIndex1 < 0)
			{
				strFileNameToPush = FilesPath + "/" + strFileName;
				isMultiFile = false;
				fileNames.push(strFileNameToPush);
			}
			else
			{
				var strValue:String;
				var intKtr:int;
				isMultiFile = true;
				intIndex2 = strXMLPath.indexOf(".bmml");
				strValue = strXMLPath.substring(intIndex1+4, intIndex2);
				
				fileEndCount = Number(strValue);
				
				fileStartCount = 1;
				
				for (intKtr = fileStartCount; intKtr <= fileEndCount; intKtr++)
				{
					strFileNameToPush = FilesPath + "/" + strFileNameFirstPart + "_" + intKtr + "_of_" + fileEndCount + ".bmml";
					
					fileNames.push(strFileNameToPush);
				}
				
			}
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        


		public function loadXMLMulti(mDebugging:Boolean):void
		{
			try{

				var intLen:int = fileNames.length;
				var intKtr:int;
				
				for (intKtr = 0; intKtr < intLen; intKtr++)
				{
					var myXML:XML = new XML();
					var XML_URL:String = fileNames[intKtr];
					
					
					
					Debugging = mDebugging;
					
					if (intKtr < intLen - 1)
					{
						var myXMLURL1:URLRequest = new URLRequest(XML_URL);
						var myLoader1:URLLoader = new URLLoader(myXMLURL1);
					
						myLoader1.addEventListener(Event.COMPLETE, xmlDownloadedMulti);
					}
					else if (intKtr == intLen - 1)
					{
						var myXMLURL2:URLRequest = new URLRequest(XML_URL);
						var myLoader2:URLLoader = new URLLoader(myXMLURL2);

						myLoader2.addEventListener(Event.COMPLETE, xmlDownloadedMultiComplete);
					}
					
						
					
				}
			
			}
			catch (e:Error)
			{
				Alert.show("Could not open the XML file for processing:  \"" + strXMLPath + "\"");
				blnValidXML = false;
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
		}
		
		private function onXMLDownloadIO(event:IOErrorEvent):void
		{
			trace(event.text);
		}

        public function validateXML(callback:Function):void
        {
            try{
            var myXMLURL:URLRequest = new URLRequest(strXMLPath);
            var myLoader:URLLoader = new URLLoader(myXMLURL);
            
            callBackF = callback;
            
            myLoader.addEventListener(Event.COMPLETE, xmlValidation);
            }
            catch (e:Error)
            {
                Alert.show("Could not open the XML file for validation:  \"" + strXMLPath + "\"");
                blnValidXML = false;
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }


        private function xmlValidation(event:Event):void
        {
            try{
                xmlData = new XML(event.target.data);
                callBackF();
            }
            catch (e:Error)
            {
                Alert.show("The XML file \"" + strXMLPath + "\" could not be parsed.");
                blnValidXML = false;
                callBackF();
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }

        
        private function xmlDownloadedMulti(event:Event):void
		{
			try{
				xmlData = new XML(event.target.data);
				
				arrXMLData.push(xmlData);
			}
			catch (e:Error)
			{
				Alert.show("The XML file \"" + strXMLPath + "\" could not be parsed during processing.");
				blnValidXML = false;
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
		}

		private function xmlDownloadedMultiComplete(event:Event):void
		{
			try{
				setTimeout(custom1, 5000);
				function custom1():void {
					xmlData = new XML(event.target.data);
					
					arrXMLData.push(xmlData);
					
					XVarianceAllowed = 10;
					YVarianceAllowed = 10;
					
					//extractControls();
					
					// ADDED by Pan @ 08,NOV
					
					extractDomainClassInformation();
					//trace("components checkpoint0=" + arrComponents.length);
					// single object view                
					// each field's meta information is parsed inside the method.
					extractControls();
					
					//trace("components checkpoint1=" + arrComponents.length);
					
					
					
					
					trace("Export single object view");
					exportToFile2();
					//trace("components checkpoint2=" + arrComponents.length);
					
					// domain class
					//trace("Export domain class and others");
					exportDomainClass();
					
					// domain class utils
					//trace("Export domain class utils");
					exportDomainClassUtils();
					
					
					// data access layer
					//trace("Export data access layer");
					exportDataAccessLayer();
					
					
					// moonshineide project file (fixed file content)
					//trace("Export project file");
					exportProjectFile();
					
					
					
					// object list view (fixed file content)
					//trace("Export project main mxml and object list view");
					exportMainViewAndObjectListView();
					
					
					// data access layer (fixed file content)
					//trace("Export data access layer");
					exportDataAccessLayer();
					
					
					// data access layer (fixed file content)
					//trace("Export Ui utils");
					exportUiUtils();
					
					
					copyStaticFileTo("TabBar.as", "src/layout/TabBar.as");
					copyStaticFileTo("TabBarView.as", "src/layout/TabBarView.as");
					copyStaticFileTo("TabItemClickedEvent.as", "src/events/TabItemClickedEvent.as");
					//				copyStaticFileTo("templates/TabBar.as", "src/layout/TabBar.as");
					
					
				}
			}
			catch (e:Error)
			{
				Alert.show("The XML file \"" + strXMLPath + "\" could not be parsed during processing.");
				blnValidXML = false;
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
		}
		
		
        private function collectMXMLData():void
        {
            try{
            
            var intLen:int = arrComponents.length;
            var intKtr:int;
			arrViewMXMLData = new Array();
            if(intLen>0)
                strMXMLData = "";
			
			trace("******inside collectMXMLData,intLen=" + intLen);
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
				//trace("******" + arrComponents[intKtr].controlID + " is custom =" +  (arrComponents[intKtr].controlTypeID == "custom"));
                if (arrComponents[intKtr].controlTypeID == "custom")
				{
					if (arrComponents[intKtr].IsChildCustomTAB)
					{
						var intKtr2:int;
						var intTABCount:int;
						intTABCount = arrComponents[intKtr].ChildCustomTABsData.length;
						
						for (intKtr2 = 0; intKtr2 < intTABCount; intKtr2++)
						{
							
							var strFileName:String;
//							strFileName = arrComponents[intKtr].ChildCustomTABs[intKtr2];
//							strFileName = strFileName.replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace("-", "").replace("-", "");
//							strFileName = strFileName + "Tab.mxml";
//							
//							arrViewMXMLData.push({fileName: strFileName, data: arrComponents[intKtr].ChildCustomTABsData[intKtr2]});
							
							strFileName = arrComponents[intKtr].ChildCustomTABsData[intKtr2].TABName;
							strFileName = strFileName.replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace("-", "").replace("-", "").replace("\\", "").replace("/", "").replace("\\", "").replace("/", "");
							strFileName = strFileName + "Tab.mxml";
							trace("****** push sub tab file=" + strFileName + "controlID=" + arrComponents[intKtr].controlID  + " controlTypeID=" + arrComponents[intKtr].controlTypeID)
							arrViewMXMLData.push({fileName: strFileName, data: arrComponents[intKtr].ChildCustomTABsData[intKtr2].text});
							
						}
					}
                    strMXMLData = strMXMLData + arrComponents[intKtr].text;
			}
            }
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
		
		private function getObjectViewFileName():String
		{
		
			//return strMXMLExportFilePath + "/src/" + getDomainName() + "View.mxml";
			return strMXMLExportFilePath + "/src/views/" + getDomainName() + "View.mxml";
		}
		
		
		private function getTabViewFileName(name : String): String
		{
			//return strMXMLExportFilePath + "/src/" + getDomainName() + "View.mxml";
			return strMXMLExportFilePath + "/src/views/" + name;
		}

		public function exportToFile2():void
		{
			try{
				//var file:File = File.desktopDirectory.resolvePath(strMXMLExportFilePath);
				var objectViewFileName:String = getObjectViewFileName();
				var file:File = File.desktopDirectory.resolvePath(objectViewFileName);
				var stream:FileStream = new FileStream();
				var strWrite:String;
				var intKtr:int;
				
				var strFileName:String;
				var strProjectPath:String;
				var strProjectViewPath:String;
				var strProjectViewFilePath:String;
				var fileView:File;
				
				
//				strFileName="MyInitialView.mxml";
//				strProjectPath = file.parent.nativePath;
//				strProjectViewPath = strProjectPath ;
//				strProjectViewFilePath = strProjectViewPath + "/" + strFileName;
//				
//				fileView = File.desktopDirectory.resolvePath(strProjectViewFilePath);
				fileView = file;
				
				collectMXMLData();
				
				stream.open(fileView, FileMode.WRITE);
				
				//strWrite = getMXMLCode(strMXMLData, true);
				
				var strMXMLAll:String = "";
				
				strMXMLAll = "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n<js:View  xmlns:fx=\"http://ns.adobe.com/mxml/2009\" xmlns:js=\"library://ns.apache.org/flexjs/basic\" xmlns:local=\"*\" xmlns:layout=\"layout.*\" xmlns:views=\"views.*\">\n";
				/*
				
				strMXMLAll +='<fx:Script><![CDATA[\n';
				
				strMXMLAll +='		import org.apache.flex.events.CustomEvent;\n';
				strMXMLAll +='					import org.apache.flex.events.Event;\n';
				strMXMLAll +='					private var _selectedObject:Object;\n';
				strMXMLAll +='					[Bindable("selectedObject")]\n';
				strMXMLAll +='					public function get selectedObject():Object\n';
				strMXMLAll +='					{return _selectedObject;}\n';
				strMXMLAll +='				public function set selectedObject(value:Object):void\n';
				strMXMLAll +='					{\n';
				strMXMLAll +='                      if (value != _selectedObject)\n';
				strMXMLAll +='						{\n';
				strMXMLAll +='							_selectedObject = value;\n';
				strMXMLAll +='							dispatchEvent(new Event("selectedObjectChanged"));\n';
				strMXMLAll +='						}\n';
				strMXMLAll +='					}\n';
				
				strMXMLAll +=']]></fx:Script>\n';
				*/
				
				//strMXMLAll +="<js:Container width=\"100%\" height=\"100%\"  style=\"border:1px solid red\">";
				
				//strMXMLAll = strMXMLAll + "<js:beads><js:VerticalLayout />  </js:beads>";
				
				strMXMLAll = strMXMLAll + strMXMLData;
				
				//strMXMLAll = strMXMLAll + "\n</js:Container> \n </js:View>";
				strMXMLAll = strMXMLAll + " \n </js:View>";
				
				
				
				
				
				var xml:XML = new XML(strMXMLAll);
				
				xml = moveBeadsToTop(xml);
				
				
				strMXMLAll = xml.toXMLString();
				
				
				
				strMXMLAll = strReplace(strMXMLAll, "  ", String.fromCharCode(9));
				stream.writeUTFBytes(strMXMLAll);
				//stream.writeUTFBytes(strWrite);
				
				stream.close();
				
				
				
				
				var intLen:int;
				trace("components");
				for (var i:uint = 0;i < arrComponents.length;i++)
				{
					trace("component#" + i + " id=" + arrComponents[i]);
					
					//trace("component#" + i + " id=" + arrComponents[i].controlID + " type=" + arrComponents[i].controlTypeID + " tabs=" + arrComponents[i].ChildCustomTABsData.length);
				}
				
//				intLen= arrComponents[0].ChildCustomTABsData.length;
//				trace("!!!!! tab count:" + intLen);
//				
//				for (intKtr = 0; intKtr < intLen; intKtr++)
//				{	
//					exportNestedTABs(arrComponents[0].ChildCustomTABsData[intKtr]);
//				}

				for (var j:uint = 0;j < arrComponents.length;j++)
				{
					intLen= arrComponents[j].ChildCustomTABsData.length;
					
					for (intKtr = 0; intKtr < intLen; intKtr++)
					{	
						exportNestedTABs(arrComponents[j].ChildCustomTABsData[intKtr]);
					}
				}
				
				
				
				
			} // try
			
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
		}
		
		private function moveBeadsToTop( mxml : XML) : XML 
		{
			var js:Namespace = mxml.namespace("js"); 
			var fx:Namespace = mxml.namespace("fx"); 
			
			if (mxml.js::beads[0] != null)
			{
				var beads:XML = mxml.js::beads[0].copy();
				delete mxml.js::beads[0];
				mxml.insertChildAfter(null, beads);
			}
			
			if (mxml.fx::Script[0] != null)
			{
				var script:XML = mxml.fx::Script[0].copy();
				delete mxml.fx::Script[0];
				mxml.insertChildAfter(null, script);
			}
			return mxml;
		}
		
		
		private function exportNestedTABs(objComponent:Object):void
		{
			
			var strFileXMLData:String;
			var file:File = File.desktopDirectory.resolvePath(strMXMLExportFilePath);
			var stream:FileStream = new FileStream();
			var strWrite:String;
			var intKtr:int;
			
			var strFileName:String;
			var strProjectPath:String;
			var strProjectViewPath:String;
			var strProjectViewFilePath:String;
			var fileView:File;
			var intLen:int = objComponent.ChildCustomTABsData.length;
			
			strFileName=objComponent.fileName;
			strFileXMLData=objComponent.text;
			
			if(intLen>0)
				strWrite = getMXMLCode(strFileXMLData, false);
			else
				strWrite = wrapMXMLCode(strFileXMLData);
			
			
			strProjectPath = file.parent.nativePath;
			
			strProjectViewPath = strProjectPath;
			strProjectViewFilePath = strProjectViewPath + "/" + strFileName;
			
			strProjectViewFilePath = getTabViewFileName(strFileName);
			
			fileView = File.desktopDirectory.resolvePath(strProjectViewFilePath);
			
			stream.open(fileView, FileMode.WRITE);
			stream.writeUTFBytes(strWrite);
			
			stream.close();
			
			
			
			for (intKtr = 0; intKtr < intLen; intKtr++)
			{
				exportNestedTABs(objComponent.ChildCustomTABsData[intKtr]);
			}
			
			return;
		}
		
		
		
		private function wrapMXMLCode(strCode:String):String
		{
			var strReturn:String;
			try{
			
			strReturn = "<js:Container xmlns:fx=\"http://ns.adobe.com/mxml/2009\" xmlns:js=\"library://ns.apache.org/flexjs/basic\" xmlns:layout=\"layout.*\" xmlns:views=\"views.*\" xmlns:local=\"*\" xmlns:ns=\"library://ns.apache.org/flexjs/html5\">";
			
			strReturn = strReturn + "<fx:Style>.alignTop{vertical-align: top;}</fx:Style>";
			strReturn = strReturn + "<js:Container width=\"100%\" height=\"100%\"  style=\"border:0px solid black\">";
			
			strReturn = strReturn + "<js:beads><js:VerticalLayout />	</js:beads>";
			
			strReturn = strReturn + strCode;
			
			strReturn = strReturn + "\n</js:Container> \n </js:Container> \n";						
			
			var xml:XML = new XML(strReturn);
			
			strReturn = xml.toXMLString();
			
			
			strReturn = strReplace(strReturn, "  ", String.fromCharCode(9));
			
			}
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
			return strReturn;
		}
		
		// This code is never called in this class, what for?
		
		public function getMXMLCode(strMXMLDataP:String, IsInitialView:Boolean):String
		{
			try{
				var strMXMLAll:String;
				var xml:XML;
				
				if(IsInitialView)
					strMXMLAll = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<js:View xmlns:fx=\"http://ns.adobe.com/mxml/2009\" xmlns:js=\"library://ns.apache.org/flexjs/basic\" \n xmlns:layout=\"layout.*\" xmlns:views = \"views.*\">\n";
				else
					strMXMLAll = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<js:Container xmlns:fx=\"http://ns.adobe.com/mxml/2009\" xmlns:js=\"library://ns.apache.org/flexjs/basic\" \n xmlns:layout=\"layout.*\" xmlns:views = \"views.*\">\n";
				
				
				strMXMLAll = strMXMLAll + strMXMLDataP;
				
				if(IsInitialView)
					strMXMLAll = strMXMLAll + "\n</js:View>";
				else
					strMXMLAll = strMXMLAll + "\n</js:Container>";
				
				xml = new XML(strMXMLAll);
				
				//var strWrite:String = strMXMLAll;
				var strWrite:String = xml.toXMLString();
				
				strWrite = strReplace(strWrite, "  ", String.fromCharCode(9));
				
				return strWrite;
			}
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
			return "";
		}
        
        private function strReplace(str:String, search:String, replace:String):String
        {
            return str.split(search).join(replace);
        }
        
        public function extractControls():void
        {
            try{
            var intParentContainerIndex:int;
            
            intParentContainerIndex = -1;
            //extractAllControls();
			extractAllControlsArray();
            resetXCoordinates();
            resetYCoordinates();
            resetAXAYCoordinates();
            //resetXHYHCoordinates();
			
			//trace("components checkpoint0.1=" + arrComponents.length);
            
            convertControlsInContainer(intParentContainerIndex);
            intParentContainerIndex = getInnerMostContainer();
            
            do
            {
                //convertControlsInContainer(intParentContainerIndex);
				//trace("before assemble! index=" + intParentContainerIndex + "id=" + arrComponents[intParentContainerIndex].controlID + " controlTypeID=" + arrComponents[intParentContainerIndex].controlTypeID);
				//trace("components checkpoint0.5=" + arrComponents.length);
				//Alert.show("components checkpoint0.5=" + arrComponents.length, "Color Selection", Alert.YES, this);
                assembleControlsInContainer(intParentContainerIndex);
				//trace("components checkpoint0.6=" + arrComponents.length);
				if (arrComponents.length < 10)
				{
					var i : int = 0;
					for (i = 0; i < arrComponents.length; i++)
					{
					  //trace ("component #" + i + ".id=" + arrComponents[i].controlID + " type=" + arrComponents[i].controlTypeID); 
					}
				}
                intParentContainerIndex = getInnerMostContainer();
                
                    //break;
            } while (intParentContainerIndex != -1);
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        public function getInnerMostContainer():int
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            var intPos:int = -1;
            var intLastContainerX:int;
            var intLastContainerY:int;
            
            //arrControls.sortOn("XY", Array.NUMERIC);
            
            intLen = arrComponents.length;
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                var intX:Number = 0;
                var intY:Number = 0;
                var blnContainerControl:Boolean = false;
                
                intX = arrComponents[intKtr].x;
                intY = arrComponents[intKtr].x;
                
                blnContainerControl = isContainerControl(arrComponents[intKtr].controlTypeID);
                
                if (blnContainerControl)
                {
                    if (intX >= intLastContainerX && intY >= intLastContainerY)
                    {
                        intPos = intKtr;
                        intLastContainerX = intX;
                        intLastContainerY = intY;
                    }
                }
                
            }
            
            return intPos;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return -1;
        }
        
        public function isContainerControl(strControlName:String):Boolean
        {
            try{
            switch (strControlName)
            {
			case "com.balsamiq.mockups::TabBar": 
				return true;
            case "com.balsamiq.mockups::BrowserWindow": 
                return true;
            case "com.balsamiq.mockups::Canvas": 
                return true;
            case "com.balsamiq.mockups::FieldSet": 
                return true;
            case "com.balsamiq.mockups::TitleWindow": 
                return true;
//          case "__group__": 
//              return true;
            }
            return false;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return false;
        }
        
        public function isChildOfContainer(Parent:Object, Child:Object):Boolean
        {
            try{
                var intParentx:int;
                var intParenty:int;
                var intParentHeight:int;
                var intParentWidth:int;
                var intChildx:int;
                var intChildy:int;
                var intChildHeight:int;
                var intChildWidth:int;
                var blnResult:Boolean = true;
                var strParentID:String = "";
                var strChildGroupID:String = "";
                var blnChildContainerControl:Boolean = false;
                            
                blnChildContainerControl = isContainerControl(Child.controlTypeID.toString());
                
                
                
                if (Parent != null)
                {
                    intParentx = parseInt(Parent.x);
                    intParenty = parseInt(Parent.y);
                    intParentWidth = parseInt(Parent.w);
                    intParentHeight = parseInt(Parent.h);
                    intChildx = parseInt(Child.x);
                    intChildy = parseInt(Child.y);1
                    intChildWidth = parseInt(Child.w);
                    intChildHeight = parseInt(Child.h);
                    strChildGroupID = Child.isInGroup.toString();
                    strParentID = Parent.controlID.toString();
					
					if (intParentx <= intChildx && intParenty <= intChildy && intParentx + intParentWidth >= intChildx + intChildWidth && intParenty + intParentHeight >= intChildy + intChildHeight)
					{
						blnResult = true;
					}
					else
						blnResult = false;
					
                    
//                    if (intParentx <= intChildx && intParenty <= intChildy)
//                    {
//                        if(! blnChildContainerControl || (intParentx + intParentWidth >= intChildx + intChildWidth && intParenty + intParentHeight >= intChildy + intChildHeight))
//                        {
//                            blnResult = true;
//                        }
//                        else
//                        {
//                            blnResult = false;
//                        }
//                            
//                    }
//                    else
//                        blnResult = false;
                }
                
                return blnResult;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return false;
        }
		
		
		private function readParameterInCustomData( full:String, parameter:String):String
		{
			//: paras of main canvas:$GrailsName=Firewall_Route;$RESTUrl=disableREST
			var pattern:RegExp = new RegExp('\\$' + parameter + "=([\\.-_\\w|,]*);", "sg");
			
			var result:Array = pattern.exec(full); 
			if (result != null) {
				return result[1];
			} else {
				var pattern2:RegExp = new RegExp('\\$' + parameter + "=([\\.-_\\w|,]*)$", "sg");
				
				var result2:Array = pattern2.exec(full); 
				if (result2 != null) {
					return result2[1];
				} else {
					return null;		
				}
				
			
			}
		}
		public function extractDomainClassInformation():void
		{
			// clear old information ( it is possible that someone can use this class to parse more than one files)
			domainClassFields = new Array();
			var processedFields:Array = new Array();
			trace("parse domain class meta information!");
			try{
				arrControls = new Array();
				
				for each (var object:XML in xmlData.controls..*)
				{
					// the Canvas holds information of the Domain class
					if (object.name() == "control" && object.@controlTypeID=="com.balsamiq.mockups::Canvas" &&  object.@controlID=="1")
					{
						var variables:String = object.controlProperties.customData.toString();
						
						trace("paras of main canvas:" + variables);
							GrailsSanitizerType = readParameterInCustomData(variables, "GrailsSanitizerType");
							TableName = readParameterInCustomData(variables, "TableName");
							RESTUrl = readParameterInCustomData(variables, "RESTUrl");
							GrailsDomainClassPackageName = readParameterInCustomData(variables, "GrailsDomainClassPackageName");
							GrailsDomainClassName = readParameterInCustomData(variables, "GrailsDomainClassName");
							
							trace("para:" + readParameterInCustomData(variables, "GrailsSanitizerType"));
							trace("paraGrailsName:" + readParameterInCustomData(variables, "GrailsName"));
						//$GrailsSanitizerType=notSanitizer; $TableName=simple_books; $GrailsDomainClassPackageName=demo; $GrailsDomainClassName=SimpleBook;
						
					}
					
				
					
					// the controls with FieldName holds information of fields of the Domain class
					if (object.name() == "control" && object.controlProperties != null && object.controlProperties.FieldName != null &&object.controlProperties.FieldName.toString().length>0 )
					{
					
						//<customData>$ToGrails=true;$NewDomain=false;$GrailsName=pageCount;$MultivalueFieldType=array;$GeneratedUIFlag=true;$GORMType=Integer;$CreateIndex=false;$DominoType=number;$IsMultivalues=false</customData> 
						
						
						//field["FieldName"] = object.controlProperties.FieldName.toString();
						
						
						var ToGrails:String = readParameterInCustomData(object.controlProperties.customData.toString(), "ToGrails");
						if ("true" == ToGrails && processedFields.indexOf(object.controlProperties.FieldName.toString()) < 0 ) {
							processedFields.push(object.controlProperties.FieldName.toString());
							//trace ("test:::::" + object.controlProperties.FieldName.toString());
							//trace ("index checkbox::::" + processedFields.indexOf("ExampleDialogBox"));
							//trace ("array::::" + processedFields);
							
							
							
							var flexJSComponent:String = componentMapper(object.@controlTypeID);
							
							//CheckBoxListText
							
							var field: Object = new Object();
							field["FlexJSComponent"] = flexJSComponent;
							field["FieldKind"] = object.controlProperties.FieldKind.toString();
							field["ControlType"] = object.controlProperties.ControlType.toString();
							field["customID"] = object.controlProperties.customID.toString();
							field["customData"] = object.controlProperties.customData.toString();
							
							field["GrailsName"] = readParameterInCustomData(object.controlProperties.customData.toString(), "GrailsName");
							field["ToGrails"] = readParameterInCustomData(object.controlProperties.customData.toString(), "ToGrails");
							field["NewDomain"] = readParameterInCustomData(object.controlProperties.customData.toString(), "NewDomain");
							field["OptionList"] = readParameterInCustomData(object.controlProperties.customData.toString(), "OptionList");
							field["CreateIndex"] = readParameterInCustomData(object.controlProperties.customData.toString(), "CreateIndex");
							field["DominoType"] = readParameterInCustomData(object.controlProperties.customData.toString(), "DominoType");
							field["IsMultivalues"] = readParameterInCustomData(object.controlProperties.customData.toString(), "IsMultivalues");
							//trace("[IsMultivalues]=" + field["IsMultivalues"]);
							field["MultivalueFieldType"] = readParameterInCustomData(object.controlProperties.customData.toString(), "MultivalueFieldType");
							field["GeneratedUIFlag"] = readParameterInCustomData(object.controlProperties.customData.toString(), "GeneratedUIFlag");
							var GORMType:String = readParameterInCustomData(object.controlProperties.customData.toString(), "GORMType"); 
							if (GORMType == null || GORMType == '') 
							{
								GORMType = 'String';
									
							}
							var GORMTypeCore: String = GORMType;
							if (GORMTypeCore != null) 
							{
								GORMTypeCore = GORMTypeCore.replace("]","").replace("[", "");	
							}
							
							
							field["GORMType"] = GORMType;
							field["GORMTypeCore"] = GORMTypeCore;
							
							domainClassFields.push(field);
						}

					}
				}
			}
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
		}
		
		public function updateFieldsTabInformation( fieldName: String,  tabName: String):void
		{
		     trace ("to udpate fields tab:field=" + fieldName + " tab=" + tabName);
			 //var field:Object;
			 for each (var field:Object in domainClassFields)
			 {
				field["Tab"] = tabName; 
			 }
		}
		
		
        
        public function extractAllControls():void
        {
            try{
            arrControls = new Array();
            
			for each (var object:XML in xmlData.controls..*)
			{
				if (object.name() == "control")
				{
					var strText:String = "";
					var intX:Number = 0;
					var intY:Number = 0;
					var intXY:Number = 0;
					var strSize:String = "";
					var strColor:String = "";
					var strAlign:String = "";
					var strIsInGroup:String = "";
					var strLocked:String = "";
					var strSelectedIndex:String = "";
					
					intX = parseInt(object.@x);
					intY = parseInt(object.@y);
					intXY = intY * 1000 + intX;
					
					strText = object.controlProperties.text.toString();
					strSize = object.controlProperties.size.toString();
					strColor = object.controlProperties.color.toString();
					strAlign = object.controlProperties.align.toString();
					strIsInGroup = object.@isInGroup.toString();
					strLocked = object.@locked.toString();
					strSelectedIndex = object.controlProperties.selectedIndex.toString();
					if (object.controlProperties!= null)
					{
						arrControls.push({controlProperties: object.controlProperties, SelectedIndex: strSelectedIndex, locked: strLocked, isInGroup: strIsInGroup, size: strSize, color: strColor, align: strAlign, text: strText, controlID: object.@controlID.toString(), controlTypeID: object.@controlTypeID.toString(), x: object.@x.toString(), y: object.@y.toString(), w: object.@w.toString(), h: object.@h.toString(), measuredW: object.@measuredW.toString(), measuredH: object.@measuredH.toString(), XY: intXY, IsCustomTAB: false});
					} else {
						arrControls.push({ SelectedIndex: strSelectedIndex,locked: strLocked, isInGroup: strIsInGroup, size: strSize, color: strColor, align: strAlign, text: strText, controlID: object.@controlID.toString(), controlTypeID: object.@controlTypeID.toString(), x: object.@x.toString(), y: object.@y.toString(), w: object.@w.toString(), h: object.@h.toString(), measuredW: object.@measuredW.toString(), measuredH: object.@measuredH.toString(), XY: intXY, IsCustomTAB: false});
					}
				}
			}
			}
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
        }
        
		
		public function extractAllControlsArray():void
        {
            try{
				var intKtr:int = 0;
				var intLen:int = 0;
				var intLastYPos:int = 0;
				var intLastMaxYPos:int = 0;
				var intFirstContainer:int = -1;
				
				arrControls = new Array();
				
				intLen = arrXMLData.length;
				
				for (intKtr = 0; intKtr < intLen; intKtr++)
				{
					var xmlDataTmp:XML;
					var intOffset:int;
					
					
					xmlDataTmp = arrXMLData[intKtr];
					intOffset = intLastMaxYPos;
					
					
					
					for each (var object:XML in xmlDataTmp.controls..*)
					{
						if (object.name() == "control")
						{
							var strText:String = "";
							var intX:Number = 0;
							var intWidth:Number = 0;
							var intY:Number = 0;
							var intXY:Number = 0;
							var strSize:String = "";
							var strColor:String = "";
							var strAlign:String = "";
							var strIsInGroup:String = "";
							var strLocked:String = "";
							var strSelectedIndex:String = "";
							var strControlTypeID:String = object.@controlTypeID.toString();
							var intH:int = object.@h;
							
							intX = parseInt(object.@x);
							intY = parseInt(object.@y)+intOffset;
							intXY = intY * 1000 + intX;
							intWidth = object.@w;
							
							strText = object.controlProperties.text.toString();
							strSize = object.controlProperties.size.toString();
							strColor = object.controlProperties.color.toString();
							strAlign = object.controlProperties.align.toString();
							strIsInGroup = object.@isInGroup.toString();
							strLocked = object.@locked.toString();
							strSelectedIndex = object.controlProperties.selectedIndex.toString();
							
							intLastYPos = intY + intWidth;
							
							if (intLastYPos > intLastMaxYPos)
								intLastMaxYPos = intLastYPos;
							
							if (strControlTypeID == "com.balsamiq.mockups::Canvas")
							{
								trace("Canvas");
							}
								
							if (!(strControlTypeID == "com.balsamiq.mockups::Canvas" && intX == 0 && parseInt(object.@y) == 10 && intH == 4096))
							{
								if (object.controlProperties!= null)
								{
									arrControls.push({controlProperties: object.controlProperties, SelectedIndex: strSelectedIndex, locked: strLocked, isInGroup: strIsInGroup, size: strSize, color: strColor, align: strAlign, text: strText, controlID: object.@controlID.toString(), controlTypeID: strControlTypeID, x: intX, y: intY, w: intWidth, h: intH, measuredW: object.@measuredW.toString(), measuredH: object.@measuredH.toString(), XY: intXY, IsCustomTAB: false});
								} else {
									arrControls.push({ SelectedIndex: strSelectedIndex,locked: strLocked, isInGroup: strIsInGroup, size: strSize, color: strColor, align: strAlign, text: strText, controlID: object.@controlID.toString(), controlTypeID: strControlTypeID, x: intX, y: intY, w: intWidth, h: intH, measuredW: object.@measuredW.toString(), measuredH: object.@measuredH.toString(), XY: intXY, IsCustomTAB: false});
								}
							}
							else
							{
								if (intFirstContainer ==-1)
								{
									arrControls.push({controlProperties: object.controlProperties, SelectedIndex: strSelectedIndex, locked: strLocked, isInGroup: strIsInGroup, size: strSize, color: strColor, align: strAlign, text: strText, controlID: object.@controlID.toString(), controlTypeID: strControlTypeID, x: intX, y: intY, w: intWidth, h: intH, measuredW: object.@measuredW.toString(), measuredH: object.@measuredH.toString(), XY: intXY, IsCustomTAB: false});
									intFirstContainer = intKtr;
								}
							}
						}
					}
				}
				if (intFirstContainer !=-1)
				{
					arrControls[intFirstContainer].h = intKtr * 4096;
					arrControls[intFirstContainer].measuredH = intKtr * 4096;
				}
			}
			catch (e:Error)
			{
				trace(e.getStackTrace()); Alert.show(e.getStackTrace());
			}
        }
		
		
		private var collectedTabNames:Object = new Object();
		
		private function getUniqueTabName(tabName: String) : String
		{
		
			var uniqueTabName:String;
			if (collectedTabNames.hasOwnProperty(tabName)) 
			{
				uniqueTabName = tabName + collectedTabNames[tabName] ;
				collectedTabNames[tabName] += 1;
				 
			} else {
				uniqueTabName = tabName;
				collectedTabNames[tabName] = 1;
			}
			return uniqueTabName;
		}
		
        public function convertControlsInContainer(intParentContainerIndex:int):void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            var innerMostTab:String;
            arrControls.sortOn("AXAY", Array.NUMERIC);
            
			//trace ("arrComponents is reset")
            arrComponents = new Array();
            
            intLen = arrControls.length;
            
			var producedInputControls : Array = new Array();
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                var strComponentName:String = "";
                var strCSSStyle:String = "";
                
                strComponentName = componentMapper(arrControls[intKtr].controlTypeID);
               
				//trace("componentname:" +strComponentName + " controltypeid=" + arrControls[intKtr].controlTypeID);
                if (strComponentName != "")
                {
                    var strPropertyName:String = "";
                    var strFJXML:String = "";
                    var intWidth:int = 0;
                    var intHeight:int = 0;
                    var strPrepareDataProvider:String = "";
                    var strID:String = "";
					var strTABName:String = "";
					
					var tograils:String = readParameterInCustomData(arrControls[intKtr].controlProperties.customData.toString(), "ToGrails");
					//trace("!!!!!" + arrControls[intKtr].controlProperties.FieldName + "=" + tograils);
					if (arrControls[intKtr].controlProperties != null 
						&& arrControls[intKtr].controlProperties.FieldName != null
						&& arrControls[intKtr].controlProperties.FieldName.toString().length > 0
					    && 'true' == readParameterInCustomData(arrControls[intKtr].controlProperties.customData.toString(), "ToGrails"))
					{
						//var toGrails: String = readParameterInCustomData(arrControls[intKtr].controlProperties.customData.toString(), "ToGrails");
						
						var GrailNameForThis:String = readParameterInCustomData(arrControls[intKtr].controlProperties.customData.toString(), "GrailsName");
						
						strID = GrailNameForThis;
					} else {
						if(intParentContainerIndex>=0) 
						{
							strID = "id" + intParentContainerIndex.toString() + "_" + intKtr.toString();
						
						}						
						else
							strID = "id" + intKtr.toString();
						
						
					}
					
					if (producedInputControls.indexOf(strID) > 0) 
					{
						strID = strID + intKtr.toString();
					}
					producedInputControls.push(strID);
					//trace ("produced:" + producedInputControls);
					
					
                        
                    strFJXML = "<" + strComponentName;
                    
                    strPropertyName = propertyMapper(arrControls[intKtr].controlID);
                    strFJXML = strFJXML + " id=\"" + strID + "\"";
                    
                    strPropertyName = propertyMapper(arrControls[intKtr].text);
                    if (strPropertyName != "")
                    {
                        if (strComponentName == "js:ComboBox" || strComponentName == "js:DropDownList" || strComponentName == "js:ButtonBar" || strComponentName == "js:List")
                            strPrepareDataProvider = prepareDataProvider(strPropertyName);
                        else if (strComponentName == "js:NumericStepper")
                            strFJXML = strFJXML + " maximum=\"100\" minimum=\"1\" stepSize=\"1\" value=\"" + strPropertyName + "\"";
                        else if (strComponentName == "js:HRule")
                            ""
						else if (strComponentName == "js:TabBar")
						{
							strTABName = getTABNameByIndex(strPropertyName, arrControls[intKtr].SelectedIndex);
							strTABName = getUniqueTabName(strTABName);
							innerMostTab = strTABName;
							//trace("---------swith tabname to" + strTABName);
							strFJXML = strFJXML + " text=\"" + strTABName + "\"";
						}
                        else
                            strFJXML = strFJXML + " text=\"" + htmlEscape(strPropertyName) + "\"";
                    }

                    intWidth = getControlWidth(arrControls[intKtr]);

                    if (strComponentName == "js:ButtonBar")
                        intWidth = intWidth * 1.8;
                        
                    strFJXML = strFJXML + " width=\"" + intWidth + "\"";
                    
                    intHeight = getControlHeight(arrControls[intKtr]);
                    
                    if (strComponentName == "js:HRule")
                        intHeight = intHeight/10;
                    
                    strCSSStyle = getCSSStyle(arrControls[intKtr]);
                    
                    strFJXML = strFJXML + " height=\"" + intHeight + "\"" + strCSSStyle + " className=\"alignTop\">";
                    
                    strFJXML = strFJXML + strPrepareDataProvider;

                    strFJXML = strFJXML + "</" + strComponentName + ">";
                    
                    strFJXML = unescape(strFJXML);
					
					//////strFJXML = convertGroupControls(strFJXML);
					addControlToArrComponents(strFJXML,strID, strComponentName, strTABName, arrControls[intKtr], intWidth, intHeight);
                
					// update tab information to fields meta
					
					updateFieldsTabInformation(strComponentName,innerMostTab );
				}
            }
            }
            catch (e:Error)
            {
				
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
			
			trace("convertControlsInContainer, controls=" + arrControls.length + " arrComponents=" + arrComponents.length);
        }
		
		private function addControlToArrComponents(strFJXML: String,strID:String, strComponentName: String, strTABName: String, arrControl:Object, intWidth:int, intHeight:int): void
		{
			//arrComponents.push({text: strFJXML, controlTypeID: arrControls[intKtr].controlTypeID, x: arrControls[intKtr].x, y: arrControls[intKtr].y, XY: arrControls[intKtr].XY, w: intWidth, h: intHeight, isInGroup: arrControls[intKtr].isInGroup, locked: arrControls[intKtr].locked, controlID: arrControls[intKtr].controlID, size: arrControls[intKtr].size, color: arrControls[intKtr].color, align: arrControls[intKtr].align});
			var optionList:String = readParameterInCustomData(arrControl.controlProperties.customData.toString(), "OptionList")
			//trace("~~~~~~~~~~~optionlist:" + strComponentName + ":" + optionList);
			var i : int = 0;
			var label:String;
			var value:String;
			var options: Array;
			var count: int;
			if (strComponentName == 'js:CheckBox')
			{
				if (optionList == null)
				{
					count = 0;
				} else {
				
					options = optionList.split(",");
					count = options.length;
					
				}
				
				var checkBoxFromBoxesToArray:String = strID + ".text='';";
				var checkBoxFromArrayToBoxes:String = "";
				for (i = 0; i < count; i++)
				{
					if (options[i].indexOf("|") > 0) 
					{
						value = options[i].split("|")[1];
					} else {
						value = options[i] ;
					}
					
					checkBoxFromBoxesToArray += "if ("+ strID + "_" + value + ".selected) " + strID + ".text+='" + value + "'+';';" ;
					//checkBoxFromArrayToBoxes +=  strID + "_" + value + ".selected=" +strID + ".text.indexOf('" + value + ";') > -1;";
					checkBoxFromArrayToBoxes +=  strID + "_" + value + ".selected=" +strID + ".text.split(';').indexOf('" + value + "') > -1;";
				}
				
				checkBoxFromBoxesToArray +='if ( ' + strID + ".text.lastIndexOf(';') == " + strID + '.text.length - 1) ' + strID +  '.text = ' + strID + '.text.substr(0, '+ strID + '.text.length - 1);';
				
						

				for (i = 0; i < count; i++)
				{
					//trace("~~~~~~~~~~~optionlist:" + strComponentName + ":" + options[i]);
					
					
					if (options[i].indexOf("|") > 0) 
					{
						label = options[i].split("|")[0];
						value = options[i].split("|")[1];
					} else {
						label = options[i];
						value =  options[i]  ;
					}
					
					// TODO replace text
					strFJXML = strFJXML.replace(/text=".*" /gis, 'text="' + label + '" ');
					strFJXML = strFJXML.replace(/id=".*" /gi, 'id="' +strID + "_" + value +'" text="' + label+'" change="' + checkBoxFromBoxesToArray +'" ');
					
					// it has no value
					if (i == count -1 ) {
						strFJXML +='\n <js:TextInput id="' + strID + '" text="" visible="false" change="' + checkBoxFromArrayToBoxes + '"/>\n'
					}
					//arrComponents.push({text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align});
					arrComponents.push({bmmlControl: arrControl, text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align, IsCustomTAB: false, TABName: strTABName, IsChildCustomTAB: false, ChildCustomTABsData: []});
					
				}
			} else if (strComponentName == 'js:RadioButton')
			{
				if (optionList == null)
				{
					count = 0;
				} else {
				
					options = optionList.split(",");
					count = options.length;
					
				}
				
				var radioButtonActualValueFieldOnChange:String = "";
				for (i = 0; i < count; i++)
				{
					if (options[i].indexOf("|") > 0) 
					{
					
						value = options[i].split("|")[1];
					} else {
						value = options[i]  ;
					}
					
					radioButtonActualValueFieldOnChange += "if ("+ strID + ".text=='" + value + "') " + strID + "_" + value + ".selected='true';" ;
				}
				//radioButtonActualValueFieldOnChange = 'ooooo';
				for (i = 0; i < count; i++)
				{
					//trace("~~~~~~~~~~~optionlist:" + strComponentName + ":" + options[i]);
					if (options[i].indexOf("|") > 0) 
					{
					   label = options[i].split("|")[0];
					   value = options[i].split("|")[1];
					   // TODO replace text
					} else {
						label = options[i];
						value = options[i];
					}
					
					strFJXML = strFJXML.replace(/text=".*" /gis, 'text="' + label + '" ');
					strFJXML = strFJXML.replace(/id=".*" /gi, 'id="' + strID + "_" + value +'" groupName="' + strID +'" text="' + label + '" value="' + value +'" change="if (' + strID + '.text!=\'' +  value + '\') ' + strID +'.text=\'' +  value + '\'" ');
				  //strFJXML = strFJXML.replace(/id=".*" /gi, 'id="' + strID + "_" + value +'" groupName="' + strID +'" text="' + label + '" value="' + value +'" change="' + strID +'.text=\'aaaa\'" ');
					
					
					if (i == count -1 ) {
					  strFJXML +='\n <js:TextInput id="' + strID + '" text="" visible="false" change="' + radioButtonActualValueFieldOnChange + '"/>\n'
					}
					//arrComponents.push({text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align});
					arrComponents.push({bmmlControl: arrControl,text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align, IsCustomTAB: false, TABName: strTABName, IsChildCustomTAB: false, ChildCustomTABsData: []});
				}
				
			} else {
				//arrComponents.push({text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align});
				arrComponents.push({bmmlControl: arrControl,text: strFJXML, controlTypeID: arrControl.controlTypeID, x: arrControl.x, y: arrControl.y, XY: arrControl.XY, w: intWidth, h: intHeight, isInGroup: arrControl.isInGroup, locked: arrControl.locked, controlID: arrControl.controlID, size: arrControl.size, color: arrControl.color, align: arrControl.align, IsCustomTAB: false, TABName: strTABName, IsChildCustomTAB: false, ChildCustomTABsData: []});
			}
			
			
		}
        
        private function getControlWidth(ObjControl:Object):int
        {
            try{
            var intWidth:int = 0;
            var intW:int = 0;
            var intMeasuredW:int = 0;
            var blnContainerControl:Boolean = false;
            var strControlName:String = ObjControl.controlTypeID.toString();
            
            blnContainerControl = isContainerControl(strControlName);
            
            intW = parseInt(ObjControl.w);
            intMeasuredW = parseInt(ObjControl.measuredW);

            if (ObjControl.w != "-1")
            {
                // Here we need to calculate the width based on the control type. 
                // For some controls, we need to take min width
                // and for container controls we need to take max width
                var intMinWidth:int = 0;
                var intMaxWidth:int = 0;
                
                if (intW > intMeasuredW)
                {
                    intMinWidth = intMeasuredW;
                    intMaxWidth = intW;
                }
                else
                {
                    intMinWidth = intW;
                    intMaxWidth = intMeasuredW;
                }
                
                if(blnContainerControl ||  strControlName == "com.balsamiq.mockups::HRule" || strControlName == "com.balsamiq.mockups::ComboBox")
                    intWidth = intMaxWidth;
                else
                    intWidth = intMinWidth;
            }
            else
                intWidth = intMeasuredW;
            
            return intWidth;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return -1;
        }

        private function getControlHeight(ObjControl:Object):int
        {
            try{
            var intHeight:int = 0;
            var intH:int = 0;
            var intMeasuredH:int = 0;
            var blnContainerControl:Boolean = false;
            
            blnContainerControl = isContainerControl(ObjControl.controlTypeID.toString());
            
            //trace("blnContainerControl : " + blnContainerControl);
            
            intH = parseInt(ObjControl.h);
            intMeasuredH = parseInt(ObjControl.measuredH);
            
            if(intH==0)
                intH = intMeasuredH;
            
            if(intMeasuredH==0)
                intMeasuredH = intH;
            

            //trace("intH : " + intH );
            //trace("intMeasuredH : " + intMeasuredH );

            if (intH>0)
            {
                // Here we need to calculate the Height based on the control type. 
                // For some controls, we need to take min Height
                // and for container controls we need to take max Height
                var intMinHeight:int = 0;
                var intMaxHeight:int = 0;
                
                if (intH > intMeasuredH)
                {
                    intMinHeight = intMeasuredH;
                    intMaxHeight = intH;
                }
                else
                {
                    intMinHeight = intH;
                    intMaxHeight = intMeasuredH;
                }
                
                if(blnContainerControl)
                    intHeight = intMaxHeight;
                else
                    intHeight = intMinHeight;
            }
            else
                intHeight = intMeasuredH;

            //trace("intHeight : " + intHeight );

            
            return intHeight;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return -1;
        }

        public function htmlEscape(str:String):String {
            try{
            var strReturn:String = "";
            
            strReturn = XML( new XMLNode( XMLNodeType.TEXT_NODE, str ) ).toXMLString();
            
            strReturn = strReturn.split("\"").join ("&quot;");
            
            strReturn = strReturn.replace(/</gi, "&lt;");
            strReturn = strReturn.replace(/>/gi, "&gt;");
    
            
            return strReturn;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return "";
        }
        
        private function getCSSStyle(objControl:Object):String
        {
            try{
            var strStyle:String = "";
            
            if (objControl.color != "")
                strStyle = strStyle + "color:'" + objControl.color + "';";

            if (objControl.size != "")
                strStyle = strStyle + "fontSize:" + objControl.size + ";";

            if (objControl.align != "")
                strStyle = strStyle + "textAlign:'" + objControl.align + "';";


            if (strStyle != "")
            {
                strStyle = strStyle.slice(0, -1);
                
                strStyle = " style=\"" + strStyle + "\" "
            }
            
            return strStyle;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return "";
        }
        
        public function prepareDataProvider(strData:String):String
        {
            try{
            var strDataProvider:String;
            var arrData:Array;
            
            var intLen:int = 0;
            var intKtr:int = 0;
            
            if (strData.indexOf(",") >= 0)
                arrData = strData.split(",");
            else if (strData.indexOf(String.fromCharCode(13)) >= 0)
                arrData = arrData.split(String.fromCharCode(13));
            else
                arrData = strData.split(String.fromCharCode(10));
            
            intLen = arrData.length;
            
            strDataProvider = "<js:dataProvider><fx:Array>";
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                strDataProvider = strDataProvider + "<fx:String>" + htmlEscape(arrData[intKtr]) + "</fx:String>";
            }
            
            strDataProvider = strDataProvider + "</fx:Array></js:dataProvider>";
            
            return strDataProvider;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return "";
        }
        
        public function resetXCoordinates():void
        {
            try{
                var intLen:int = 0;
                var intKtr:int = 0;
                var intLastX:int;
                var intLastAX:int;
                
                
                intLen = arrControls.length;

                if (intLen > 0)
                {
                arrControls.sortOn("x", Array.NUMERIC);

                intLastX = arrControls[0].x;
                
                for (intKtr = 1; intKtr < intLen; intKtr++)
                {
                    arrControls[intKtr].ax = arrControls[intKtr].x;
                    
                    if (arrControls[intKtr].x - intLastAX < XVarianceAllowed)
                    {
                        arrControls[intKtr].ax = intLastAX;
                    }
                    
                    intLastX = arrControls[intKtr].x
                    intLastAX = arrControls[intKtr].ax
                }
                    
                }
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        public function resetYCoordinates():void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            var intLastY:int;
            var intLastAY:int;
            
            intLen = arrControls.length;

            if (intLen > 0)
            {
            arrControls.sortOn("y", Array.NUMERIC);
            

            intLastY = arrControls[0].y;
            

            for (intKtr = 1; intKtr < intLen; intKtr++)
            {
                arrControls[intKtr].ay = arrControls[intKtr].y;
                if (arrControls[intKtr].y - intLastAY < YVarianceAllowed)
                {
                    arrControls[intKtr].ay = intLastAY;
                }
                
                intLastY = arrControls[intKtr].y;
                intLastAY = arrControls[intKtr].ay;
            }
            }
            
        
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        public function resetXYCoordinates():void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            
            intLen = arrControls.length;
            
            for (intKtr = 1; intKtr < intLen; intKtr++)
            {
                arrControls[intKtr].XY = Number(arrControls[intKtr].y) * 1000 + Number(arrControls[intKtr].x);
            }
            
            arrControls.sortOn("XY", Array.NUMERIC);
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        public function resetAXAYCoordinates():void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            
            intLen = arrControls.length;
            
            for (intKtr = 1; intKtr < intLen; intKtr++)
            {
                arrControls[intKtr].AXAY = Number(arrControls[intKtr].ay) * 1000 + Number(arrControls[intKtr].ax);
            }
            
            arrControls.sortOn("AXAY", Array.NUMERIC);
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        

        public function resetXHYHCoordinates():void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            
            intLen = arrControls.length;
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                var intWidth:int = 0;
                var intHeight:int = 0;
                
                if (!isContainerControl(arrControls[intKtr].controlTypeID.toString()))
                {
                    if (arrControls[intKtr].w != "-1")
                        intWidth = Number(arrControls[intKtr].w);
                    else
                        intWidth = Number(arrControls[intKtr].measuredW);
                    
                    if (arrControls[intKtr].h != "-1")
                        intHeight = arrControls[intKtr].h;
                    else
                        intHeight = arrControls[intKtr].measuredH;
                }
                
                arrControls[intKtr].XHYH = (Number(arrControls[intKtr].y) + intHeight) * 1000 + (Number(arrControls[intKtr].x) + intWidth);
            }
            
            arrControls.sortOn("XHYH", Array.NUMERIC);
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        public function assembleControlsInContainer(intParentContainerIndex:int):void
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            var strParentContainerHeader:String = "";
            var strParentContainerFooter:String = "";
            var strContainerHeader:String = "";
            var strContainerFooter:String = "";
            var intLastY:int = 0;
            var intLastX:int = 0;
            var intLastW:int = 0;
            var intLastH:int = 0;
            var intLastMaxH:int = 0;
            var intLastMaxY:int = 0;
            var intContainerX:int = 0;
            var intContainerY:int = 0;
            var blnFirstControl:Boolean = true;
			var blnFirstCustomTAB:Boolean = true;
            var intHCount:int=0;
            var intMarginH:int = 0;
			var strTABNames:String = "";
			var strFieldNames:String = "";
			var IsTabBarViewTagOpen:Boolean = false;
			
            
            strContainerHeader = "<js:Container style=\"border:0px solid black\" width=\"100%\"><js:beads><js:HorizontalLayout /></js:beads>"
            if (intParentContainerIndex >= 0)
            {
                var strCSSStyle:String = getCSSStyle(arrControls[intKtr]);
                // Need to append strCSSStyle in ParentContainerHeader. The style attributes in this are being lost otherwise
				var isTopView:Boolean = arrComponents[intParentContainerIndex].controlID == 1;
				if (isTopView)
				{
					strParentContainerHeader = "<js:Container height=\"" + "100%" + "\" width=\"" + arrComponents[intParentContainerIndex].w + "\" style=\"border:1px solid gold\"><js:beads><js:VerticalLayout /></js:beads>"

				} else {
				
					strParentContainerHeader = "<js:Container height=\"" + arrComponents[intParentContainerIndex].h + "\" width=\"" + arrComponents[intParentContainerIndex].w + "\" style=\"border:1px solid gold\"><js:beads><js:VerticalLayout /></js:beads>"
				}
               
				//strParentContainerHeader += '<js:Label text="intParentContainerIndex='+ arrComponents[intParentContainerIndex].controlID  + '"/>';
					//strParentContainerHeader = "<js:Container height=\"" + "100%" + "\" width=\"" + arrComponents[intParentContainerIndex].w + "\" style=\"border:1px solid black\"><js:beads><js:VerticalLayout /></js:beads>"
				
				strParentContainerFooter = "</js:Container>"
            }
            strContainerFooter = "</js:Container>"
            
            if (intParentContainerIndex >= 0)
            {
                intContainerX = arrComponents[intParentContainerIndex].x;
                intContainerY = arrComponents[intParentContainerIndex].y;
            }
            
            intLen = arrComponents.length;
            
            strMXMLData = "";
			
			
			var isTopTap : Boolean  = false;
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                var intSpacerW:int = 0;
                var intSpacerH:int = 0;
                var intInlineBlock:int = 4;     // To adjust the extra space due to Display:Inline-Block;
                var strSize:String = "";
                var strColor:String = "";
                var strAlign:String = "";
				var strTABName:String = "";
				var IsCustomTAB:Boolean = arrComponents[intKtr].IsCustomTAB;
				
				//strFieldNames+= arrComponents[intKtr].bmmlControl.controlProperties.FieldName + ",";
//				if (arrComponents[intKtr].bmmlControl.name == "control" && arrComponents[intKtr].bmmlControl.controlProperties != null && arrComponents[intKtr].bmmlControl.controlProperties.FieldName != null && arrComponents[intKtr].bmmlControl.controlProperties.FieldName.toString().length>0 )
				if (arrComponents[intKtr].bmmlControl.controlProperties != null && arrComponents[intKtr].bmmlControl.controlProperties.FieldName != null && arrComponents[intKtr].bmmlControl.controlProperties.FieldName.toString().length>0)
				{
					if (strFieldNames.length==0)
					{
						strFieldNames+= '"' + arrComponents[intKtr].bmmlControl.controlProperties.FieldName + '"';	
					} else {
						strFieldNames+= ',"' + arrComponents[intKtr].bmmlControl.controlProperties.FieldName + '"';	
					}
					
				}
				//trace("#" + intKtr + " " +  arrComponents[intKtr].controlTypeID + ".IsCustomTAB=" + arrComponents[intKtr].IsCustomTAB);
				var isChild:Boolean = isChildOfContainer(arrComponents[intParentContainerIndex], arrComponents[intKtr]);
                if (intParentContainerIndex != intKtr && !IsCustomTAB)
                {
                    var intDiff:int = arrComponents[intKtr].y - (intLastY + intContainerY);
					
                  
                    
                    strSize = arrComponents[intKtr].size;
                    strColor = arrComponents[intKtr].color;
                    strAlign = arrComponents[intKtr].align;
                    
                    if (isChild)
                    {
                        if (intDiff < 0)
                            intDiff = intDiff * -1;
                        
                        if (blnFirstControl)
                        {
                            intHCount = intHCount + 1;
                            intSpacerH = arrComponents[intKtr].y - intLastY - intContainerY - intInlineBlock;
                            strMXMLData = strMXMLData + strParentContainerHeader ;
                            if (intSpacerH > 0)
                                strMXMLData = strMXMLData + "\n" + "<js:Spacer style=\"border:0px solid blue\" height=\"" + intSpacerH + "\" width=\"100%\"/>";
                            
                            strMXMLData = strMXMLData + strContainerHeader;
                            
                            blnFirstControl = false;
                        }
                        else if ( (intLastY + intLastH) <= (arrComponents[intKtr].y - intContainerY) || intLastX >= arrComponents[intKtr].x)
                        {
                            intLastH = 0;
                            intLastW = 0;
                            intLastX = 0;
                            intSpacerH = arrComponents[intKtr].y - intLastY - intLastMaxH - intContainerY - intInlineBlock;
                            
                            if (intSpacerH > 0)
                                strMXMLData = strMXMLData + "\n" + "<js:Spacer style=\"border:0px solid blue\" height=\"" + intSpacerH + "\" width=\"100%\"/>";
                            
                            intLastMaxH = 0;
                            intLastMaxY = 0;
                            intMarginH = 0;
							if (IsTabBarViewTagOpen)
							{
								strMXMLData = strMXMLData + "</layout:TabBarView>";
								IsTabBarViewTagOpen = false;
							}
							
                            strMXMLData = strMXMLData + strContainerFooter;
                            strMXMLData = strMXMLData + strContainerHeader;
                        }
                        else
                        {
                            // Instead of Spacer, need to leave margin here.
                            intHCount = intHCount + 1;
                            intMarginH = intMarginH + parseInt(arrComponents[intKtr].y) - intLastY - intContainerY;

                            if (intMarginH > 0)
                                applyMargin(intKtr, intMarginH, 0, 0, 0);
                            
                            //  strMXMLData = strMXMLData + "\n" + "<js:Spacer style=\"border:0px solid blue\" height=\"" + intSpacerH + "\" width=\"100%\"/>";
                        }
                        
                        intSpacerW = arrComponents[intKtr].x - intLastX - intLastW - intContainerX;
                        
                        if (intSpacerW > 0)
                            strMXMLData = strMXMLData + "\n" + "<js:Spacer style=\"border:0px solid yellow\" width=\"" + intSpacerW + "\" height=\"1\"/>"
                        
                        strMXMLData = strMXMLData + "\n" + arrComponents[intKtr].text;
                        intLastY = arrComponents[intKtr].y - intContainerY;
                        intLastX = arrComponents[intKtr].x - intContainerX;
                        intLastW = arrComponents[intKtr].w;
                        intLastH = arrComponents[intKtr].h;
                        
                        if (arrComponents[intKtr].y > intLastMaxY)
                            intLastMaxY = arrComponents[intKtr].y;
                        
                        if (arrComponents[intKtr].h > intLastMaxH)
                            intLastMaxH = arrComponents[intKtr].h;
                        
                        arrComponents[intKtr] = "";
                    }// end if isChild
                }//end if 
				
				if (IsCustomTAB && isChild)
				{
					//trace ("!!!!!!!!!!!!!!!!! tab goes here: blnFirstCustomTAB=" + blnFirstCustomTAB);
					var strTABXMLData:String;
					var strTABNameNoSpace:String;
					
					var intLengthCustomTabs:int;
					var objChildCustomTAB:Object = {"fileName": "", "TABName": "", "text": "", "ChildCustomTABsData":""};
					
					intLengthCustomTabs = arrComponents[intParentContainerIndex].ChildCustomTABsData.length;
					strTABName = arrComponents[intKtr].TABName;
					strTABNameNoSpace = strTABName.replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "").replace("-", "").replace("-", "").replace("\\", "").replace("/", "").replace("\\", "").replace("/", "");
					arrComponents[intParentContainerIndex].IsChildCustomTAB = true;
					objChildCustomTAB.TABName = strTABName;
					objChildCustomTAB.fileName = strTABNameNoSpace+"Tab.mxml";
					
					// Here need to check if this component is customTab. If its a custom tab then need to integrate the child tabs also here by some means.
					// We need to create some child node in arrComponents to store the details.
					strTABXMLData = arrComponents[intKtr].text;
					
					objChildCustomTAB.text = strTABXMLData;
					
					objChildCustomTAB.ChildCustomTABsData = arrComponents[intKtr].ChildCustomTABsData;
					
					//trace("!!!!!!!!!!!!!!!!! tab added to " +  intLengthCustomTabs + " of arrComponents#" + intParentContainerIndex);
					arrComponents[intParentContainerIndex].ChildCustomTABsData[intLengthCustomTabs] = objChildCustomTAB;
					
					
					if (blnFirstCustomTAB)
					{
						if (!blnFirstControl)    /// Atin. Added this line while Pan is changing code
						{
							strMXMLData = strMXMLData + "</js:Container>";
							strMXMLData = strMXMLData + "<js:Container id=\"CTabBar\">";
							// OneFlexibleChildVerticalLayout should be inside "CTabBar". by Pan @ NOV 23
							strMXMLData = strMXMLData + "<js:beads><js:OneFlexibleChildVerticalLayout flexibleChild=\"tabbarview\"/></js:beads>";
							
							isTopTap = true;
						} else {
							isTopTap = false;
						}
						
						//strMXMLData = strMXMLData + '<js:Label text="' +  arrComponents[intKtr].w  + '"/>';
						strMXMLData = strMXMLData + "<layout:TabBar dataProvider=\"{labelFields}\" width=\"" + arrComponents[intKtr].w + "\" height=\"30\" id=\"tabbar\" viewContainer=\"{tabbarview}\" />";
						strMXMLData = strMXMLData + "<layout:TabBarView id=\"tabbarview\" width=\"50%\" height=\"50%\" x= \"1\" y=\"30\">";
						strTABNames = "\"" + strTABName + "\"";
						IsTabBarViewTagOpen = true;
					}
					else
					{
						strTABNames = strTABNames + "," + "\"" + strTABName + "\"";
					}
					
					
					strMXMLData = strMXMLData + "<views:"+strTABNameNoSpace+"Tab id=\""+strTABNameNoSpace+"\" name=\"" + strTABName + "\"  />";
					
					//trace("^^^^^^^^ not first tab!");
					blnFirstCustomTAB = false;
					arrComponents[intKtr] = "";
				}
				
                
            }
            
			
			if (arrComponents[intParentContainerIndex].IsChildCustomTAB && IsTabBarViewTagOpen)
			{
				strMXMLData = strMXMLData + "</layout:TabBarView>";
				IsTabBarViewTagOpen = false;
			}

			
            if(blnFirstControl==false)
                strMXMLData = strMXMLData + strContainerFooter + strParentContainerFooter;
            
            if (intParentContainerIndex >= 0)
            {
				var controlTypeID:String = arrComponents[intParentContainerIndex].controlTypeID;
				//trace("checking Tabbar:" + arrComponents[intParentContainerIndex].controlID + " tabname=" + arrComponents[intParentContainerIndex].TABName);
				if (controlTypeID == "com.balsamiq.mockups::TabBar")
				{
					arrComponents[intParentContainerIndex].controlTypeID = "customTab";
					arrComponents[intParentContainerIndex].IsCustomTAB = true;
					//trace("arrComponents " +  intParentContainerIndex + "is tabbar!");
				}
				else
					arrComponents[intParentContainerIndex].controlTypeID = "custom";
				
				
				
				//trace("!!!! producing script:" + arrComponents[intParentContainerIndex].controlID + "name=" + arrComponents[intParentContainerIndex].controlTypeID +  " tabname=" + arrComponents[intParentContainerIndex].TABName + " controls=" + strFieldNames.length + " tabs=" + strTABNames.length );
				if (arrComponents[intParentContainerIndex].IsChildCustomTAB/* && arrComponents[intParentContainerIndex].controlTypeID != "custom"*/)
				{
					var strFXScript:String;
					//trace ("to produce tab scripts");
					
					strFXScript = getFXScript(strTABNames, strFieldNames, true);
//					strMXMLData = strFXScript + "<js:beads><js:ViewDataBinding/><js:OneFlexibleChildVerticalLayout flexibleChild=\"tabbarview_"+intParentContainerIndex+"\" /></js:beads>" + strMXMLData;
					// Fixed for tab views, flexibleChild has to be the id of tabview
					if (isTopTap)
					{
						strMXMLData = strFXScript + "<js:beads><js:ViewDataBinding/></js:beads>" + strMXMLData;	
						// FlexJS works unpredicatable if this beads is not at the top of the container
						//strMXMLData = insertToTopOfView(strMXMLData, "<js:beads><js:ViewDataBinding/></js:beads>");
					} else {
						strMXMLData = strFXScript + "<js:beads><js:ViewDataBinding/><js:OneFlexibleChildVerticalLayout flexibleChild=\"tabbarview\"/></js:beads>" + strMXMLData;
					}
			
				} else {
					if (arrComponents[intParentContainerIndex].controlTypeID == 'customTab' || arrComponents[intParentContainerIndex].controlID == '1') {
					strFXScript = getFXScript(strTABNames, strFieldNames, false);
					//strFXScript+='<body>' + ' iiid==' + arrComponents[intParentContainerIndex].controlID + ' controlTypeID==' + arrComponents[intParentContainerIndex].controlTypeID + '</body>';
					strMXMLData = strFXScript + strMXMLData;
					}
				}
				
				arrComponents[intParentContainerIndex].text = strMXMLData;
            }
            
            arrComponents = trimArray(arrComponents);
            
            
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
		
		private function insertToTopOfView(view:String, textToInsert:String):String
		{
			var positionToInsert:uint = view.indexOf(">");
			
			//return (view.substr(0, positionToInsert) +  textToInsert +  view.substr(positionToInsert));
			return view;
			
		}
		
		private function getFXScript(strTABNames:String, strFieldNames:String, isCustomTAB:Boolean):String
		{
			var strReturn:String = "";
			
			strReturn = strReturn + "<fx:Script>"+"\n";
			strReturn = strReturn + "<![CDATA["+"\n";
			if (isCustomTAB) 
			{
			strReturn = strReturn + "		" + "import events.TabItemClickedEvent;" + "\n";
			strReturn = strReturn + "		" + "import org.apache.flex.events.Event;" + "\n";
			strReturn = strReturn + "		" + "import org.apache.flex.html.SimpleAlert;" + "\n";
			}
			strReturn +="		" + 'import org.apache.flex.events.CustomEvent;\n';
			strReturn +="		" + 'import org.apache.flex.events.Event;\n';
			
			strReturn +="		" +  "public var _controls:Array = new Array(" + strFieldNames + ");" + "\n";
			strReturn +="		" +  "[Bindable(\"__NoChangeEvent__\")]"+"\n";
			strReturn +="		" +  "public function get controls():Array"+"\n";
			strReturn +="		" +  "{"+"\n";
			strReturn +="		" +  "    return _controls;" + "\n";
			strReturn +="		" +  "}"+"\n";
			
			//if (isCustomTAB) 
			//{
			strReturn = strReturn +"		" +  "public var _labelFields:Array = new Array(" + strTABNames + ");" + "\n";
			strReturn = strReturn + "		" + "[Bindable(\"__NoChangeEvent__\")]"+"\n";
			strReturn = strReturn +"		" +  "public function get labelFields():Array"+"\n";
			strReturn = strReturn + "		" + "{"+"\n";
			strReturn = strReturn +"		" +  "return _labelFields;" + "\n";
			strReturn = strReturn +"		" +  "}"+"\n";
			//}
			
			
			strReturn +="		" + 'private var _selectedObject:Object;\n';
			strReturn +="		" + '[Bindable("selectedObject")]\n';
			strReturn +="		" + 'public function get selectedObject():Object\n';
			strReturn +="		" + '{return _selectedObject;}\n';
			strReturn +="		" + 'public function set selectedObject(value:Object):void\n';
			strReturn +="		" + '{\n';
			strReturn +="		" + '   if (value != _selectedObject)\n';
			strReturn +="		" + '	{\n';
			strReturn +="		" + '	    _selectedObject = value;\n';
			strReturn +="		" + '	    dispatchEvent(new Event("selectedObjectChanged"));\n';
			strReturn +="		" + '	}\n';
			strReturn +="		" + '}\n';
			
			strReturn = strReturn + "		" + "]]>"+"\n";
			
			strReturn = strReturn + "</fx:Script>"+"\n";
			
			return strReturn;
		}
		
		
		private function getTABNameByIndex(strText:String, strSelectedIndex:String):String
		{
			var strTABName:String;
			var intSelectedIndex:int;
			
			intSelectedIndex = parseInt(strSelectedIndex);
			
			var arrText:Array;
			
			
			arrText = strText.split(",");
			
			strTABName = arrText[intSelectedIndex];
			
			return strTABName;
			
		}
		
        
        private function applyMargin(intPos:int, intMarginT:int, intMarginR:int, intMarginB:int, intMarginL:int):void
        {
            try{
            var strMarginStyle:String = "";
            var strHTML:String = "";
            var strHTMLNew:String = "";
            var intStylePos:int = -1;           
            
            strHTML = arrComponents[intPos].text;
            intStylePos = strHTML.indexOf("style=");
            
            if (intStylePos == -1)
            {
                strMarginStyle = "margin:" + intMarginT.toString() + "px " + intMarginR.toString() + "px " + intMarginB.toString() + "px " + intMarginL.toString() + "px"
                intStylePos = strHTML.indexOf(">");
                strHTMLNew = strHTML.slice(0, intStylePos) + " style=\"" + strMarginStyle + "\"" + strHTML.slice(intStylePos);
            }
            else
            {
                strMarginStyle = "margin:" + intMarginT.toString() + "px " + intMarginR.toString() + "px " + intMarginB.toString() + "px " + intMarginL.toString() + "px;"
                strHTMLNew = strHTML.slice(0, intStylePos+7) + strMarginStyle + strHTML.slice(intStylePos+7);
            }
            
            arrComponents[intPos].text = strHTMLNew;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
        }
        
        private function trimArray(arrToTrim:Array):Array
        {
            try{
            var intLen:int = 0;
            var intKtr:int = 0;
            
            var arrTrimmed:Array = new Array();
            
            intLen = arrToTrim.length;
            
            for (intKtr = 0; intKtr < intLen; intKtr++)
            {
                if (arrToTrim[intKtr] != "")
                {
                    arrTrimmed.push(arrToTrim[intKtr]);
                }
            }
            
            return arrTrimmed;
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return null;
        }
        
        private function propertyMapper(strName:String):String
        {
            return unescape(strName);
        }
        
        private function componentMapper(strName:String):String
        {
            try{
            switch (strName)
            {
            case "com.balsamiq.mockups::DateChooser": 
               return "js:TextInput";
//			   return "js:DateChooser";
                break;
            
            case "com.balsamiq.mockups::Image": 
                return "js:Image";
                break;
            
            case "com.balsamiq.mockups::BarChart": 
                return "js:BarChart";
                break;
            
            case "com.balsamiq.mockups::ColumnChart": 
                return "js:ColumnChart";
                break;
            
            case "com.balsamiq.mockups::LineChart": 
                return "js:LineChart";
                break;
            
            case "com.balsamiq.mockups::PieChart": 
                return "js:PieChart";
                break;
            
            case "com.balsamiq.mockups::TabBar": 
                return "js:TabBar";
                break;
            
            case "com.balsamiq.mockups::ButtonBar": 
                return "js:ButtonBar";
                break;
            
            case "com.balsamiq.mockups::DropDownList": 
                return "js:DropDownList";
                break;
            
            case "com.balsamiq.mockups::ComboBox": 
                return "js:DropDownList";
                break;
            
            case "com.balsamiq.mockups::CheckBox": 
                return "js:CheckBox";
                break;
			case "com.balsamiq.mockups::CheckBoxGroup": 
				return "js:CheckBox";
				break;
    
            case "com.balsamiq.mockups::List": 
                return "js:List";
                break;
            
            case "com.balsamiq.mockups::HRule": 
                return "js:HRule";
                break;
            
            case "com.balsamiq.mockups::VRule": 
                return "js:VRule";
                break;
            
            case "com.balsamiq.mockups::NumericStepper": 
                return "js:NumericStepper";
                break;
            
            case "com.balsamiq.mockups::RadioButton": 
                return "js:RadioButton";
                break;
			
			case "com.balsamiq.mockups::RadioButtonGroup": 
				return "js:RadioButton";
			    break;
			
            
            case "com.balsamiq.mockups::TextArea": 
                return "js:TextArea";
                break;
            
            case "com.balsamiq.mockups::TextInput": 
                return "js:TextInput";
                break;
            
            case "com.balsamiq.mockups::Button": 
                return "js:TextButton";
                break;
            
            case "com.balsamiq.mockups::Label": 
                return "js:Label";
                break;
            
            case "com.balsamiq.mockups::Title": 
                return "js:Label";
                break;
            
            case "com.balsamiq.mockups::Paragraph": 
                return "js:Label";
                break;

            case "com.balsamiq.mockups::BrowserWindow": 
                return "js:Container";
                break;
            
            case "com.balsamiq.mockups::TitleWindow": 
                return "js:Container";
                break;
            
            case "com.balsamiq.mockups::TabBar": 
                return "js:Container";
                break;
            
            case "com.balsamiq.mockups::FieldSet": 
                return "js:Container";
                break;
            
            case "com.balsamiq.mockups::Canvas": 
                return "js:Container";
                break;

//          case "__group__": 
//              return "js:Container";
//              break;
            }
            
            }
            catch (e:Error)
            {
                trace(e.getStackTrace()); Alert.show(e.getStackTrace());
            }
            return "";

        }

		
		// TODO project directory?
		
		//private function 
		
		
		private function getPackageName(): String
		{
			return GrailsDomainClassPackageName;
		}
		
		private function getPackageAsFilePath(): String
		{
			if (getPackageName() != null) 
			{
			
				return getPackageName().split(".").join("/");
				
			} else {
			
				return null;
			}
		}
		
		private function getDomainName():String
		{
		
			return GrailsDomainClassName;
		}

		
		private const DOMAINCLASSUIUTILSTEMPLATE:String = "DomainClassUiUtils.as";
		private function getDomainClassUiUtilsFileName() : String
		{
			return strMXMLExportFilePath + "/src/" + getPackageAsFilePath()+"/" +getDomainName() + "UiUtils.as";
		}
		private function exportUiUtils():void
		{
			// TODO 
			// dummy file for now
			// it is possible that custom template system isn't enough
			var targetFileName:String = getDomainClassUiUtilsFileName();
			copyTemplateFileTo(DOMAINCLASSUIUTILSTEMPLATE, targetFileName);
		}

		
		
		private const DOMAINCLASSTEMPLATE:String = "DomainClass.as";
		private function getDomainClassFileName() : String
		{
			return strMXMLExportFilePath + "/src/" + getPackageAsFilePath()+"/" +getDomainName() + ".as";
		}
        private function exportDomainClass():void
        {
            // TODO 
            // dummy file for now
			// it is possible that custom template system isn't enough
			var targetFileName:String = getDomainClassFileName();
			trace(new File(targetFileName).exists);
			copyTemplateFileTo(DOMAINCLASSTEMPLATE, targetFileName);
        }



		private const DOMAINCLASSUTILSTEMPLATE:String = "DomainClassUtils.as";
		private function getDomainClassUtilsFileName() : String
		{
			
			
			return strMXMLExportFilePath + "/src/" + getPackageAsFilePath()+"/"  +getDomainName() + "Utils.as";
		}
		private function exportDomainClassUtils():void
		{
			// TODO 
			// dummy file for now
			// it is possible that custom template system isn't enough
			var targetFileName:String = getDomainClassUtilsFileName();
			copyTemplateFileTo(DOMAINCLASSUTILSTEMPLATE, targetFileName);
		}
		

        // moonshineide project file (fixed file content with variables)
		private function getProjectFileName():String
		{
			return strMXMLExportFilePath + "/" +getDomainName() + ".as3proj";
			
		}
		private const PROJECTTEMPLATE:String = "project.as3proj";
        private function exportProjectFile():void
        {
			var projectFileName:String = getProjectFileName();
			// it is possible that this step is already done by moonshineide
            copyTemplateFileTo(PROJECTTEMPLATE, projectFileName);
        }

		// object list view (fixed file content with variables)
		//private const LISTVIEWTEMPLATE:String = "templates/domainList.mxml";
		private const LISTVIEWTEMPLATE:String = "domainList.mxml";
		
        private function exportMainViewAndObjectListView():void
        {
		
			var listViewName:String = getListViewFileName();
            copyTemplateFileTo(LISTVIEWTEMPLATE, listViewName);
			
			var mainViewName:String = getMainViewFileName();
			copyTemplateFileTo(MAINVIEWTEMPLATE, mainViewName);
        }
		
		private const MAINVIEWTEMPLATE:String = "projectMain.mxml";
		
		private function getMainViewFileName():String
		{
			// some to project name, with .mxml
			//return strMXMLExportFilePath + "/src/"  +getDomainName() + "List.mxml";
			return strMXMLExportFilePath + "/src/" + getDomainName() + "Main.mxml";
		}
		
		private function getListViewFileName():String
		{
			// some to project name, with .mxml
			//return strMXMLExportFilePath + "/src/"  +getDomainName() + "List.mxml";
			return strMXMLExportFilePath + "/src/views/MyInitialView.mxml";
		}

		
		
		private function getDataAccessLayerFileName():String
		{
			return strMXMLExportFilePath + "/src/" + getPackageAsFilePath()+"/"  +getDomainName() + "Manager.as";
			
		}
        // data access layer (fixed file content with variables)
		private const DATAACCESSLAYERNAME:String = "DomainClassManager.as";
        private function exportDataAccessLayer():void
        {
			var dataAccessLayerName:String = getDataAccessLayerFileName();
			copyTemplateFileTo(DATAACCESSLAYERNAME, dataAccessLayerName);
        }

		private function copyStaticFileTo(templateFileName:String, relativeTargetFileName: String): void
		{
			copyTemplateFileTo(templateFileName, strMXMLExportFilePath + "/" + relativeTargetFileName);
		}
        private function copyTemplateFileTo( templateFileName:String,  targetFileName:String): void
        {
			// two possible path of templates:
			// 1 ../templates/xxx
			// 2 templates/xxx
			//trace("!!!!!!!!!" + new File("file://" + File.applicationDirectory.nativePath).resolvePath("../templates").url);
			//trace("xxxxxxxxx" + new File("file://" + File.applicationDirectory.nativePath).resolvePath("../templates").exists);
			
//			templateFileName = "../" + templateFileName;
         
			// Read from source file, process variable placeholders, then write to target 
			// We don't copy directly since we need to process text
			
			//var XML_URL:String = "app:///" + templateFileName;
			// detect if ../templates exists
			 
			/*if (templatesFolder.exists) 
			{
				XML_URL = templatesFolder.resolvePath(templateFileName).url;
			} else {
				XML_URL = "app:///" + templateFileName;
			}*/
			
			// @note
			// When File.applicationDirectory, 'url' in OSX comes
			// prefix with 'app:'. This can't be use in URLLoader/URLRequest,
			// neither we can use 'nativePath' value as '/Users/<userName>/..' path here. 
			// Thus we need to make it conditionally works across platforms
			var myXMLURL:URLRequest = new URLRequest((IS_MACOS ? "file://" : "")+ templatesFolder.resolvePath(templateFileName).nativePath);
			var myLoader:URLLoader = new URLLoader();
			
			myLoader.addEventListener(Event.COMPLETE,  function(e:Event) : void { 
				CopyTemplateFileTO_templateReaded(e.target.data, targetFileName) 
			} );
			
			myLoader.load(myXMLURL);
        }   
		
		private function CopyTemplateFileTO_templateReaded(templateContent:String, targetFileName:String) : void
		{
			
			var parameters: Object = new Object();

			parameters["TableName"] = TableName;
			parameters["RESTUrl"] = RESTUrl;
			
			parameters["GrailsDomainClassPackageName"] = GrailsDomainClassPackageName;
			parameters["GrailsDomainClassName"] = GrailsDomainClassName;
			parameters["GrailsSanitizerType"] = GrailsSanitizerType;
			
			parameters["domainClassFields"] = domainClassFields;
			
			
			var templateManager : TemplateManager = new TemplateManager();
			templateManager.CopyTemplateFileTO_templateReaded(templateContent, targetFileName, parameters);
		}
		
		
		private function CopyTemplateFileTO_templateReadedOld(templateContent:String, targetFileName:String) : void
		{
			
			var file:File = File.desktopDirectory.resolvePath(targetFileName);
			var stream:FileStream = new FileStream();
			var strMXMLAll:String;
			var xml:XML;
			var strWrite:String = templateContent;
			
			// process variables
			var domainName:String = getDomainName();
			strWrite = strWrite.replace(/#DomainName#/gi, domainName);
			
			//trace("copy tempalte to " + targetFileName);
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(strWrite);
			stream.close();
			
		}

    }
}
