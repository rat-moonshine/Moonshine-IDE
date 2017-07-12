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
package actionScripts.plugin.core.importer
{
	import actionScripts.factory.FileLocation;
	import actionScripts.locator.IDEModel;
	import actionScripts.utils.UtilsCore;
	import actionScripts.valueObjects.ConstantsCoreVO;
	import actionScripts.valueObjects.ProjectVO;
	
	public class FlashDevelopImporterBase extends ProjectImporterBase
	{
		protected static function parsePaths(paths:XMLList, v:Vector.<FileLocation>, p:ProjectVO, attrName:String="path", customSDKPath:String=null):void 
		{
			for each (var pathXML:XML in paths)
			{
				var path:String = pathXML.attribute(attrName);
				// file separator fix
				path = UtilsCore.fixSlashes(path);
				var f:FileLocation = null;
				if (path.indexOf("${flexlib}") == -1)
				{
					f = p.folderLocation.resolvePath(path);
				}
				else
				{
					path = path.replace("${flexlib}", "");
					if (customSDKPath) f = new FileLocation(customSDKPath +"/frameworks"+ path);
					else if (!f && IDEModel.getInstance().defaultSDK) f = new FileLocation(IDEModel.getInstance().defaultSDK.fileBridge.nativePath +"/frameworks"+ path);
					if (!f) f = p.folderLocation.resolvePath(path);
				}
				
				if (ConstantsCoreVO.IS_AIR) f.fileBridge.canonicalize();
				v.push(f);
			}
		}
	}
}