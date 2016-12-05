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
package actionScripts.plugin.settings.vo
{
	import actionScripts.plugin.settings.renderers.PathRenderer;
	
	import mx.core.IVisualElement;
	
	public class PathSetting extends AbstractSetting
	{
		[Bindable]
		public var directory:Boolean;
		
		private var isSDKPath:Boolean;
		private var isDropDown:Boolean
		
		public function PathSetting(provider:Object, name:String, label:String, directory:Boolean, path:String=null, isSDKPath:Boolean=false, isDropDown:Boolean = false)
		{
			super();
			this.provider = provider;
			this.name = name;
			this.label = label;
			this.directory = directory;
			this.isSDKPath = isSDKPath;
			this.isDropDown = isDropDown;
			defaultValue = stringValue = (path != null) ? path : stringValue ? stringValue :"";
		}
		
		override public function get renderer():IVisualElement
		{
			var rdr:PathRenderer = new PathRenderer();
			rdr.setting = this;
			rdr.isSDKPath = isSDKPath;
			rdr.isDropDown = isDropDown;
			return rdr;
		}
		
	}
}