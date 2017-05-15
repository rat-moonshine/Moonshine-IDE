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
package actionScripts.plugin.help
{
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	
	import actionScripts.events.AddTabEvent;
	import actionScripts.events.GlobalEventDispatcher;
	import actionScripts.locator.IDEModel;
	import actionScripts.plugin.IPlugin;
	import actionScripts.plugin.PluginBase;
	import actionScripts.plugin.help.view.AS3DocsView;
	import actionScripts.ui.IContentWindow;
	import actionScripts.ui.IPanelWindow;
	import actionScripts.ui.tabview.CloseTabEvent;
	import actionScripts.utils.SDKUtils;
	import actionScripts.valueObjects.ConstantsCoreVO;
	
	import components.popup.JavaPathSetupPopup;
	import components.popup.MinSDKMissingAlert;
	import components.popup.SDKUnzipConfirmPopup;
	
	public class HelpPlugin extends PluginBase implements IPlugin
	{
		public static const EVENT_TOURDEFLEX:String = "EVENT_TOURDEFLEX";
		public static const EVENT_AS3DOCS:String = "EVENT_AS3DOCS";
		public static const EVENT_ABOUT:String = "EVENT_ABOUT";
		public static const EVENT_SDK_UNZIP_REQUEST:String = "EVENT_SDK_UNZIP_REQUEST";
		public static const EVENT_SDK_HELPER_DOWNLOAD_REQUEST:String = "EVENT_SDK_HELPER_DOWNLOAD_REQUEST";
		public static const EVENT_CHECK_MINIMUM_SDK_REQUIREMENT:String = "EVENT_CHECK_MINIMUM_SDK_REQUIREMENT";
		public static const EVENT_APACHE_SDK_DOWNLOADER_REQUEST:String = "EVENT_APACHE_SDK_DOWNLOADER_REQUEST";
		public static const EVENT_ENSURE_JAVA_PATH:String = "EVENT_ENSURE_JAVA_PATH";
		public static const EVENT_TYPEAHEAD_REQUIRES_SDK:String = "EVENT_TYPEAHEAD_REQUIRES_SDK";
		
		override public function get name():String			{ return "Help Plugin"; }
		override public function get author():String		{ return "Moonshine Project Team"; }
		override public function get description():String	{ return "Help Plugin. Esc exits."; }
		
		private var tourdeContentView: IPanelWindow;
		private var idemodel:IDEModel = IDEModel.getInstance();
		private var as3DocsPanel:IPanelWindow = new AS3DocsView();
		private var minSDKRequirementAlert:MinSDKMissingAlert;
		private var sdkUnzipView:SDKUnzipConfirmPopup;
		private var javaPathDetection:JavaPathSetupPopup;
		
		override public function activate():void
		{
			super.activate();
			
			if (ConstantsCoreVO.IS_AIR)
			{
				tourdeContentView = idemodel.flexCore.getTourDeView();
				dispatcher.addEventListener(EVENT_TOURDEFLEX, handleTourDeFlexConfigure);
				dispatcher.addEventListener(EVENT_CHECK_MINIMUM_SDK_REQUIREMENT, checkMinimumSDKPresence);
			}
			CONFIG::OSX
				{
					dispatcher.addEventListener(EVENT_SDK_UNZIP_REQUEST, onSDKUnzipRequest);
					dispatcher.addEventListener(EVENT_SDK_HELPER_DOWNLOAD_REQUEST, onSDKhelperDownloadRequest);
				}
			
			dispatcher.addEventListener(EVENT_ABOUT, handleAboutShow);
			dispatcher.addEventListener(EVENT_AS3DOCS, handleAS3DocsShow);
			dispatcher.addEventListener(CloseTabEvent.EVENT_TAB_CLOSED, handleTreeRefresh);
			dispatcher.addEventListener(EVENT_ENSURE_JAVA_PATH, checkJavaPathPresenceForTypeahead);
			dispatcher.addEventListener(EVENT_TYPEAHEAD_REQUIRES_SDK, onTypeaheadFailedDueToSDK);
		}
		
		protected function handleTourDeFlexConfigure(event:Event):void
		{
			IDEModel.getInstance().mainView.addPanel(tourdeContentView);
		}
		
		protected function handleAS3DocsShow(event:Event):void
		{
			as3DocsPanel.height = 60;
			IDEModel.getInstance().mainView.addPanel(as3DocsPanel);
		}
		
		protected function handleAboutShow(event:Event):void
		{
			// Show About Panel in Tab
			for each (var tab:IContentWindow in model.editors)
			{
				if (tab["className"] == "AboutScreen") 
				{
					model.activeEditor = tab;
					return;
				}
			}
			
			var aboutScreen: IFlexDisplayObject = model.aboutCore.getNewAbout(null);
			GlobalEventDispatcher.getInstance().dispatchEvent(
				new AddTabEvent(aboutScreen as IContentWindow)
			);
		}
		
		protected function onSDKUnzipRequest(event:Event):void
		{
			if (!sdkUnzipView)
			{
				triggerUnzipViewWIthParam(false, false);
			}
		}
		
		protected function onSDKhelperDownloadRequest(event:Event):void
		{
			if (!sdkUnzipView)
			{
				triggerUnzipViewWIthParam(true, false);
			}
		}
		
		protected function checkMinimumSDKPresence(event:Event):void
		{
			var requisiteSDKs:Object = SDKUtils.checkMoonshineRequisiteSDKAvailability();
			if ((!requisiteSDKs.flex || !requisiteSDKs.flexjs) && !minSDKRequirementAlert && !sdkUnzipView)
			{
				triggerUnzipViewWIthParam(false, true);
			}
			else
			{
				checkJavaPathPresenceForTypeahead(null);
			}
		}
		
		private function onMinSDKAlertClose(event:Event):void
		{
			minSDKRequirementAlert.removeEventListener(Event.CLOSE, onMinSDKAlertClose);
			FlexGlobals.topLevelApplication.removeElement(minSDKRequirementAlert);
			minSDKRequirementAlert = null;
		}
		
		private function handleTreeRefresh(event:CloseTabEvent):void
		{
			if (!event.tab || (event.tab is IPanelWindow)) Object(tourdeContentView).refresh();
		}
		
		private function checkJavaPathPresenceForTypeahead(event:Event):void
		{
			if (!model.javaPathForTypeAhead && !javaPathDetection)
			{
				setTimeout(function():void
				{
					triggerJavaSetupViewWithParam(false);
					
				}, 1000);
			}
			else if (model.javaPathForTypeAhead)
			{
				// starting server
				model.flexCore.startTypeAheadWithJavaPath(model.javaPathForTypeAhead.fileBridge.nativePath);
			}
		}
		
		private function onTypeaheadFailedDueToSDK(event:Event):void
		{
			triggerJavaSetupViewWithParam(true);
		}
		
		private function triggerJavaSetupViewWithParam(showAsRequiresSDKNotif:Boolean):void
		{
			javaPathDetection = new JavaPathSetupPopup;
			javaPathDetection.showAsRequiresSDKNotification = showAsRequiresSDKNotif;
			javaPathDetection.horizontalCenter = javaPathDetection.verticalCenter = 0;
			javaPathDetection.addEventListener(Event.CLOSE, onJavaPromptClosed, false, 0, true);
			FlexGlobals.topLevelApplication.addElement(javaPathDetection);
		}
		
		private function triggerUnzipViewWIthParam(showAsDownloader:Boolean, showAsRequiresSDKNotif:Boolean):void
		{
			sdkUnzipView = new SDKUnzipConfirmPopup;
			sdkUnzipView.showAsHelperDownloader = showAsDownloader;
			sdkUnzipView.showAsRequiresSDKNotification = showAsRequiresSDKNotif;
			sdkUnzipView.horizontalCenter = sdkUnzipView.verticalCenter = 0;
			if (showAsRequiresSDKNotif) sdkUnzipView.addEventListener(EVENT_APACHE_SDK_DOWNLOADER_REQUEST, onApacheSDKDownloader, false, 0, true);
			sdkUnzipView.addEventListener(Event.CLOSE, onSDKUnzipPromptClosed, false, 0, true);
			FlexGlobals.topLevelApplication.addElement(sdkUnzipView);
		}
		
		private function onSDKUnzipPromptClosed(event:Event):void
		{
			sdkUnzipView.removeEventListener(EVENT_APACHE_SDK_DOWNLOADER_REQUEST, onApacheSDKDownloader);
			sdkUnzipView.removeEventListener(Event.CLOSE, onSDKUnzipPromptClosed);
			FlexGlobals.topLevelApplication.removeElement(sdkUnzipView);
			sdkUnzipView = null;
		}
		
		private function onJavaPromptClosed(event:Event):void
		{
			javaPathDetection.removeEventListener(Event.CLOSE, onJavaPromptClosed);
			FlexGlobals.topLevelApplication.removeElement(javaPathDetection);
			javaPathDetection = null;
		}
		
		/**
		 * In case of Windows we'll open
		 * integrated SDK Downloader view
		 */
		private function onApacheSDKDownloader(event:Event):void
		{
			if (!model.sdkInstallerView)
			{
				model.sdkInstallerView = model.flexCore.getSDKInstallerView();
				Object(model.sdkInstallerView).requestedSDKDownloadVersion = ConstantsCoreVO.REQUIRED_FLEXJS_SDK_VERION_MINIMUM;
				model.sdkInstallerView.addEventListener(CloseTabEvent.EVENT_TAB_CLOSED, onDefineSDKClosed, false, 0, true);
			}
			else
			{
				model.activeEditor = (model.sdkInstallerView as IContentWindow);
				return;
			}
			
			GlobalEventDispatcher.getInstance().dispatchEvent(
				new AddTabEvent(model.sdkInstallerView as IContentWindow)
			);
		}
		
		/**
		 * On SDK Downloader view closed
		 */
		private function onDefineSDKClosed(event:CloseTabEvent):void
		{
			model.sdkInstallerView.removeEventListener(CloseTabEvent.EVENT_TAB_CLOSED, onDefineSDKClosed);
			model.sdkInstallerView = null;
		}
	}
}