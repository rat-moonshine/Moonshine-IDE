package $GrailsDomainClassPackageName$
{
	public class $GrailsDomainClassName$Utils
	{	
		

		public function getMainKeyName() : String
		{
			return "id";
		}
		
		
		public function getMainKeyValue(object: $GrailsDomainClassName$) : uint
		{
			return object.id;
		}
		public function setMainKeyValue(object: $GrailsDomainClassName$, id : uint) : void
		{
			object.id = id;
		}
		
		public function getPropertyNames() : Array
		{
			var propertyNames:Array =  new Array();
			#for $field$ in $domainClassFields$#
			propertyNames.push("$field.GrailsName$");
			#endfor#
			return propertyNames;
			
		}
		public function getMultivaluesPropertyNames(): Array
		{
			var propertyNames:Array =  new Array();
			#for $field$ in $domainClassFields$#
			#if ($field.IsMultivalues$=='true')#
			propertyNames.push("$field.GrailsName$");
			#endif#
			#endfor#
			return propertyNames;
		}
		
		public function isMultivalues(propertyName: String) : Boolean
		{
			return getMultivaluesPropertyNames().indexOf(propertyName) > -1;
		}
		// TODO for arrays
		public function getProperty(object: $GrailsDomainClassName$, propertyName: String) : Object
		{
			if (isMultivalues(propertyName)) {
				return object[propertyName + "AsString"];
			} else {
				return object[propertyName];	
			}
			
		}
		
		public function setProperty(object: $GrailsDomainClassName$, propertyName: String, value: Object): void
		{
			if (isMultivalues(propertyName)) {
				object[propertyName + "AsString"] = value;
			} else {
				object[propertyName] = value;
			}
		}
		
		public function getPropertyGromRawType(propertyName: String): String
		{
			#for $field$ in $domainClassFields$#
			if (propertyName == '$field.GrailsName$') return '$field.GORMTypeCore$';
			#endfor#	
			return "String";
		}
		
		
		// Cloning is needed by any data access layer to do basic dirty checking
		// ActionScript object doesn't have clone by default
		public function clone(object: $GrailsDomainClassName$) : $GrailsDomainClassName$
		{
			var cloned : $GrailsDomainClassName$ = new $GrailsDomainClassName$();
			setMainKeyValue(cloned, getMainKeyValue(object));
			for each(var name:* in getPropertyNames()) 
			{
				cloned[name] = object[name];
			}
			
			return cloned;
		}
		

		
		public function dynamicalObjectToStaticTyped(object:Object) : $GrailsDomainClassName$
		{
			var staticTyped:$GrailsDomainClassName$ = new $GrailsDomainClassName$();
			staticTyped[getMainKeyName()] = object[getMainKeyName()];
			// no generated code in this section
			//for each(var name:* in getPropertyNames()) 
			//{staticTyped[name] = object[name];}
			
			#for $field$ in $domainClassFields$#
			#if ($field.GORMTypeCore$=='Date')# 
				// Since all Date controls are broken, we are using textinput now, thus FlexUI can only use plain strings
				//staticTyped['$field.GrailsName$'] = new Date(object['$field.GrailsName$']);
			    staticTyped['$field.GrailsName$'] = object['$field.GrailsName$'];
			#else#
				staticTyped['$field.GrailsName$'] = object['$field.GrailsName$'];
			#endif#
			#endfor#
			return staticTyped;
		}
		
		public function staticTypedToDynamicalObject(object:$GrailsDomainClassName$) : Object
		{
			// no generated code in this section
			var dynamical:Array = new Array();
			dynamical[getMainKeyName()] = getMainKeyValue(object);
			for each(var name:* in getPropertyNames()) 
			{
				dynamical[name] = getProperty(object, name);
			}
			return dynamical;
		}
		
		// by Pan: I don't know why but these function return type has to be Domain Class instead of Object
		// returning Object will cause strange problem in building and running
		public function findByMainKeyOfObject(list: Array, object:Object) : $GrailsDomainClassName$
			
		{
			return findByMainKey(list, object[getMainKeyName()]);
		}
		
		
		public function findByMainKey(list: Array, id:uint) : $GrailsDomainClassName$
		{
			var found : $GrailsDomainClassName$;
			
			for (var i:int = 0;i < list.length;i++) {
				var one = list[i];
				if (one != null && id == getMainKeyValue(one)) 
				{
					found = one;
				}
			}
			return found;
		}
		
		
		// All below code are static
		
		public function valueEquals(o:Object, t:Object) : Boolean
		{
			var  e:Boolean = true;
			if (o[getMainKeyName()] != t[getMainKeyName()]) {
				e = false;
			}
			if (e) {
				for each(var name:* in getPropertyNames()) 
				{
					if (new String(o[name]) != new String( t[name])) 
					{
						
						e = false;
						break;
					}
				}
			}
			return e;
			
		}
		
		public function containsById(col: Array, unid: uint) : Boolean
		{
			return findByMainKey(col, unid) != null;
			
		}
		
		public function objectToJson(o: Object): String 
		{
			// convert actionsript date json format to 
			return JSON.stringify(o).replace(/\.000Z/g, "Z");
		}
		
		public function jsonCollectionToObjectArray(json: String): Array
		{
			var objects : Array = new Array();
			var dynamicalObjects : Object = JSON.parse(json);
			
			for (var i:int = 0;i < dynamicalObjects.length;i++) {
				objects.push(dynamicalObjectToStaticTyped(dynamicalObjects[i]));
			}
			
			return objects;
		}
		
		public function getMainKeyValueFromSingleObjectJson(json: String) : uint
		{
			var dynamicalObject:Object = JSON.parse(json);
			return dynamicalObject[getMainKeyName()];
		}
		
		/* // Old JSON parsing code, may be useful as reference
		public function jsonToObject(json: String) : SimpleBook
		{
		var fields:Array = json.split(",");
		var id : uint ;
		var title : String;
		
		for (var i:int = 0;i < fields.length;i++) {
		var field : String = fields[i];
		if ( field.indexOf("\"id\"") == 0 ) {
		id = int(field.split(":")[1]);
		//id = int("888");
		}
		if ( field.indexOf("\"title\"") == 0 ) {
		title = field.split(":")[1];
		title = title.slice(1, title.length - 1 );
		}
		}
		
		var simpleBook: SimpleBook = new SimpleBook();
		simpleBook.id = id;
		simpleBook.title = title;
		return simpleBook;
		
		}*/
	}
}