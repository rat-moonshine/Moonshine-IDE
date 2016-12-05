package $GrailsDomainClassPackageName$
{
	import org.apache.flex.events.Event;
	import org.apache.flex.html.SimpleAlert;
	import org.apache.flex.core.View;

	public class $GrailsDomainClassName$UiUtils
	{	
		#for $field$ in $domainClassFields$#
		//$field.GrailsName$=$field.FlexJSComponent$
		#endfor#
		private static const CheckBox : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:CheckBox')#,'$field.GrailsName$'#endif##endfor#);
		private static const RadioButton : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:RadioButton')#,'$field.GrailsName$'#endif##endfor#);
		private static const TextArea : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:TextArea')#,'$field.GrailsName$'#endif##endfor#);
		private static const TextInput : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:TextInput')#,'$field.GrailsName$'#endif##endfor#);
		private static const DropDownList : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:DropDownList')#,'$field.GrailsName$'#endif##endfor#);
		private static const JsList : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:List')#,'$field.GrailsName$'#endif##endfor#);
		private static const DateChooser : Array = new Array(null#for $field$ in $domainClassFields$##if ($field.FlexJSComponent$=='js:DateChooser')#,'$field.GrailsName$'#endif##endfor#);
		
		
		public static function controlTypeOfField(fieldName):String
		{
			if (TextInput.indexOf(fieldName) > -1) return "js:TextInput";
			if (TextArea.indexOf(fieldName) > -1) return "js:TextArea";
			if (RadioButton.indexOf(fieldName) > -1) return "js:RadioButton";
			if (CheckBox.indexOf(fieldName) > -1) return "js:CheckBox";
			if (DropDownList.indexOf(fieldName) > -1) return "js:DropDownList";
			if (JsList.indexOf(fieldName) > -1) return "js:List";
			if (DateChooser.indexOf(fieldName) > -1) return "js:DateChooser";
			
			// we can only assume it is text input
			return "js:TextInput";
		}
		
		public static const optionLists:Object = {head:""
			#for $field$ in $domainClassFields$#
			,$field.GrailsName$ : '$field.OptionList$'
			#endfor#
		};
		
		public static function getDescriptionToValueMap(fieldName: String) : Array
		{
			
			var descriptionToValueMapFullString:String = optionLists[fieldName];
			var descriptionToValueMapStrings:Array = descriptionToValueMapFullString.split(",");
			var descriptionToValueMap:Array = new Array();
			var oneEntry:Array;
			for each(var descriptionToValueMapString:* in descriptionToValueMapStrings) 
			{
				oneEntry =  descriptionToValueMapString.split("|");
				descriptionToValueMap.push ( {description: oneEntry[0], value: oneEntry[1]});
			}
			return descriptionToValueMap;
		}
		
	
		public static function descriptionToValue(fieldName: String, description) : String
		{
		
			var descriptionToValueMap:Array = getDescriptionToValueMap(fieldName);
			for each(var oneEntry:* in descriptionToValueMap) 
			{
				
				//oneEntry =  descriptionToValueMapString.split("|");
				//descriptionToValueMap.push ( {description: oneEntry[0], value: oneEntry[1]});
			}
			return "ddd";
		}
		
		public static function valueToDescription(fieldName: String, value: String) : String
		{
			
			var descriptionToValueMap:Array = getDescriptionToValueMap(fieldName);
			var found : String = null;
			for each(var oneEntry:* in descriptionToValueMap) 
			{
				if (oneEntry != null && oneEntry.value == value)
				{
					found = oneEntry.description;
				}
					
			}
			return found;
		}
		
		public static function valueToIndex(fieldName: String, value: Object) : int
		{
			
			var descriptionToValueMapArray:Array = getDescriptionToValueMap(fieldName);

			
			var found : Object = null;
						for each(var oneEntry:* in descriptionToValueMapArray) 
						{
							if (oneEntry != null && oneEntry.value == value)
							{
								found = oneEntry;
								
							}
							
						}
			if (found != null ) 
			{
				var index:int = descriptionToValueMapArray.indexOf(found);
				return index;
			} else {
				return 0;
			}
			
		}
		
		public static function indexToValue(fieldName: String, index: int) : String
		{
			
			var descriptionToValueMapArray:Array = getDescriptionToValueMap(fieldName);
			if (descriptionToValueMapArray != null && descriptionToValueMapArray[index] != null) 
			{
				return descriptionToValueMapArray[index].value;
			} else {
				return null;
			}

		}
		
		public static function tabOfField(fieldName:String): String
		{
			#for $field$ in $domainClassFields$#
			  if (fieldName == '$field.GrailsName$') return '$field.Tab$';
			#endfor#
			return null;
		}
		
		
		public static function findControlInChildrenById(container: View, id: String): Object
		{
			
			var tab:String = tabOfField(id);
			if (tab == null || tab == 'null') 
			{
				return container[id];
			} else {
				var fullPath : String = getFullTabPath(container, tab);
				if (fullPath != null) 
				{
					
					var tabPathes:Array = fullPath.split('.');
					var tabOfTheField: Object = container;
					for each(var name:String in tabPathes)
					{
						tabOfTheField = tabOfTheField[name];
					}
					return tabOfTheField[id];
				} else {
					return null;
				}
				//return container[tab][id];
			}
			//return null;
			
		}
		
		
		
		public static function getFullTabPath(container: View, tabName : String) : String
		{
			var full : String = tabName ;
			
			var current : String = tabName;
			while (findParent(container, current) != null && findParent(container, current) != 'root')
			{
				
				current = findParent(container, current);
				full = current + "." + full;
			}
			return full;
		}
		
		public static function findParent(container: View,tabName : String): String
		{
			var tabs : Array = buildTabTree(container);
			
			for each(var node:* in tabs)
			{
				if (tabName == node['name']) 
				{
					return node['parent'];
				}
			}
			return null;
			
		}
		public static function buildTabTree(view: View) : Array
		{
			var allTabWithParent:Array = new Array();
			var rootView:Object = new Object();
			rootView['parent'] = null;
			rootView['name'] = 'root';
			allTabWithParent.push(rootView);
			addSubTabs(view, "root", allTabWithParent);
			
			
			return allTabWithParent ;
		}
		
		public static function addSubTabs(view: View, name: String, allTabWithParent: Array) : void
		{
			if (view['labelFields'] != null) 
			{
				for each(var subName:* in view['labelFields'])
				{
					var subTab:Object = new Object();
					subTab['parent'] = name;
					subTab['name'] = subName;
					allTabWithParent.push(subTab);
				}
				for each(var subTabName:* in view['labelFields'])
				{
					//var subTab = new Object();
					addSubTabs(view[subTabName], subTabName, allTabWithParent);
				}
			}
		}
		

		
		public static function valueOfControl( control:Object,  fieldName:String): String
		{
			// TODO
			if (control == null) return "";
				var controlType:String = controlTypeOfField(fieldName);
				switch(controlType) 
				{
					case 'js:TextInput':
						return control['text'];
					case 'js:TextArea':
						return control['text'];
					case 'js:CheckBoxSingle':
						return new String(control['selected']);
					case 'js:List':
						return indexToValue(fieldName, control['selectedIndex']);
					case 'js:DropDownList':
						//return new String(control['selectedItem']);
						return indexToValue(fieldName, control['selectedIndex']);
						//return new String(control['selectedIndex']);
					case 'js:CheckBox':
						return control['text'];
					case 'js:RadioButton':
						return control['text'];
				
					case 'js:DateChooser':
						return control['selectedDate'];
					default:
						return 'does not support control type of ' + fieldName;
				}
		}
		
		
		public static function updateControlToValue( control:Object,  fieldName: String ,  value:Object) : void
		{
			if (control == null) return;
			var controlType:String = controlTypeOfField(fieldName);
			switch(controlType) 
			{
				case 'js:TextInput':
					if (value != null)
					{
						//control['text'] = "ddd"
					    control['text'] = new String(value);
					}
					break;
				case 'js:TextArea':
					if (value != null)
					control['text'] = new String(value);
					break;
				case 'js:CheckBoxSingle':
					if (value != null) 
					{
					if (new String(value) == 'true') 
					{
						control['selected'] = true;
					} else {
						control['selected'] = false;
					}
					}
					break;
				case 'js:CheckBox':
					control['text'] = new String(value);
					control.dispatchEvent(new Event("change"));
					break;
				case 'js:RadioButton':
					control['text'] = new String(value);
					control.dispatchEvent(new Event("change"));
					break;
				case 'js:List':
					if (value != null)
					{
						//var index:int = valueToIndex(fieldName, value);
						control['selectedIndex'] = valueToIndex(fieldName, value);
					}
					break;
				case 'js:DropDownList':
					//control['selectedItem'] = valueToDescription(fieldName,new String(value));
					//indexToValue(fieldName, control['selectedIndex']);
					if (value != null)
					{
						//var index:int = valueToIndex(fieldName, value);
						control['selectedIndex'] = valueToIndex(fieldName, value);
					}
					break;
				case 'js:DateChooser':
					//SimpleAlert.show("bindSingleViewToSelect", this.parent);
					if (value != null)
					{
						// it is one string
						control['selectedDate'] = value;
					}
						
					break;
				default:
					trace('doesnot support type of ' + fieldName);
					break;
			}
		}
		
	}
}
