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
	import mx.core.IVisualElement;
	
	import actionScripts.plugin.settings.renderers.StringRenderer;
	
	public class StringSetting extends AbstractSetting
	{
		private var restrict:String;
		
		public function StringSetting(provider:Object, name:String, label:String, restrict:String=null)
		{
			super();
			this.provider = provider;
			this.name = name;
			this.label = label;
			this.restrict = restrict;
			defaultValue = "";
		}
		
		override public function get renderer():IVisualElement
		{
			var rdr:StringRenderer = new StringRenderer();
			if (restrict) rdr.text.restrict = restrict;
			//rdr.text.setStyle("backgroundColor","")
			rdr.setting = this;
			return rdr;
		}
		
	}
}