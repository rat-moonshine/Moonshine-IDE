package $GrailsDomainClassPackageName$
{
	import org.apache.flex.core.Application;
	import org.apache.flex.net.HTTPService;
	import org.apache.flex.net.HTTPHeader;
	import org.apache.flex.events.Event;
	import org.apache.flex.events.EventDispatcher;
	import org.apache.flex.html.Label;
	

	public class $GrailsDomainClassName$Manager extends EventDispatcher
	{
		public var utils:$GrailsDomainClassName$Utils = new $GrailsDomainClassName$Utils();
		public static const server: String = 'http://localhost:8080/$RESTUrl$';
		//http://localhost:8080/simpleBooks
		//$GrailsServerAddress$
		
		public static const DATALOADED:String = 'DATALOADED';
		public var debugLabel: Label;
		public var app: Application;
		// local cache of data, NOTE when using remote REST it should always be pulled from remote
		// futher note: it real multi layer application, this will be very slow
		public var localList:Array = new Array()
		
		
		
		public function createEntry(o: $GrailsDomainClassName$, onCreateOne:Function):void
		{
			service = new HTTPService();
			debugLabel.text += "to create !";
			service.url = server;
			service.method = "POST";
			var header:HTTPHeader = new HTTPHeader("Accept", "application/json");
			service.headers.push(header);
			//createResult;
			service.addEventListener("complete",  function (e:Event):void{createResult(e, o, onCreateOne)}); 
			service.addEventListener("ioError", createErrorResult); 
			service.contentType = "application/json";
			
			//service.contentData = '{"title":"' + o.title + '"}';
			service.contentData = utils.objectToJson(o);
			
			service.send(); 
			
		}
		
		public function updateEntry(o: $GrailsDomainClassName$):void
		{
			service = new HTTPService();
			
			service.url =server +"/" + o.id ;
			
			debugLabel.text = service.url;
			
			service.method = "POST";
			
			var header:HTTPHeader = new HTTPHeader("Accept", "application/json");
			service.headers.push(header);
			
			
			
			service.headers.push(new HTTPHeader("x-http-method-override", "PUT"));
			service.addEventListener("complete", updateResult); 
			service.addEventListener("ioError", updateErrorResult); 
			service.contentType = "application/json";
			//service.contentData = '{"title":"' + o.title + '"}';
			service.contentData = utils.objectToJson(o);
			service.send(); 
		}
		public function deleteEntry(o: $GrailsDomainClassName$):void
		{
			
			service = new HTTPService();
			service.url = server +"/" + o.id ;
			debugLabel.text = "<" + service.url + ">";
			service.method = "POST";
			service.headers.push(new HTTPHeader("x-http-method-override", "DELETE"));
			service.addEventListener("complete", deleteResult); 
			service.addEventListener("ioError", deleteErrorResult); 
			service.contentType = "application/json";
			
			//service.contentData = '{"title":"' + o.title + '"}';
			service.contentData = utils.objectToJson(o);
			service.send(); 
			
		}
		
		
		public function createResult(event:Event, o:$GrailsDomainClassName$, onCreateOne: Function):void { 
			
			//debugLabel.text += " create returns:" + service.data;
			
			var oldId:uint = utils.getMainKeyValue(o);
			//debugLabel.text += " oid=" + oldId;
			debugLabel.text += " oldlistsize=" + localList.length;
			debugLabel.text += " object in old list" + utils.findByMainKey(localList, oldId);
			
			var newIdByServer:uint = utils.getMainKeyValueFromSingleObjectJson(service.data)
			//debugLabel.text += " update id to :" +  utils.getMainKeyValueFromSingleObjectJson(service.data);
			// update the id created by server to the new object
			utils.setMainKeyValue(o,newIdByServer);
			//copyUiLayerDataToManagerLocalCache();
			utils.setMainKeyValue(utils.findByMainKey(localList, oldId),newIdByServer);
			onCreateOne(oldId, newIdByServer);
		} 
		
		
		
		
		public function objectValueChanged(objectArray: Array, o: $GrailsDomainClassName$) : Boolean
		{
			var objectWithSameIdInArray :  $GrailsDomainClassName$ = utils.findByMainKeyOfObject(objectArray, o);
			if (objectWithSameIdInArray != null) {
				return !utils.valueEquals(objectWithSameIdInArray, o);
			} else {
				return false;
			}
			
		}
		
		
		// Static code only!
		// DONT refer Domain class name or its properties directly after this line
		
		public function save(newList: Array, onCreateOne: Function):void
		{
			
			// 1 delete the entries not existing in newList
			var currentRemoteData: Array = query();
			debugLabel.text = "";
			for (var j:int = 0; j < currentRemoteData.length; j++) {
				//debugLabel.text += "newobjectid=" + utils.getMainKeyValue(newList[0]);
				//debugLabel.text += "objectid=" + currentRemoteData[j][utils.getMainKeyName()];
				//debugLabel.text += "equals=" + (utils.getMainKeyValue(newList[0]) == currentRemoteData[j][utils.getMainKeyName()]);
				//debugLabel.text += "findbyid=" + utils.findByMainKey(newList, currentRemoteData[j][utils.getMainKeyName()]);
				if (!utils.containsById(newList, currentRemoteData[j][utils.getMainKeyName()])) {
					debugLabel.text += currentRemoteData[j].id + " will be del;";
					deleteEntry(currentRemoteData[j]);
				} else {
					//debugLabel.text += currentRemoteData[j].id + " will be kept;";
				}
				
			}
			
			//debugLabel.text += "now we have " + currentRemoteData.length;
			debugLabel.text += "new list size=" + newList.length;
			for ( j = 0; j < newList.length; j++) {
				debugLabel.text += "new list #" + j + "=" +utils.getMainKeyValue(newList[j]) ;
				if (!utils.containsById(currentRemoteData, utils.getMainKeyValue(newList[j]))) {
					//debugLabel.text += "aaaa";
					//debugLabel.text += utils.getMainKeyValue(newList[j]) + " will be created;";
					createEntry(newList[j], onCreateOne);
				} else {
					if (objectValueChanged(currentRemoteData, newList[j])) {
						//debugLabel.text += "to update " +newList[j].id;
						
						updateEntry(newList[j]);
					} else {
						//debugLabel.text += "to ignore " +newList[j].id;
					}
				}
			}
			
			// refresh manager's local cache
			// reload from db to get correct data, 
			// problem: because actionscript's async io, load() isn't always finish after above updates
			// load();
			
			// clone from UI's data list
			// problem: it is possible that other user changes it
			debugLabel.text += "copying!to" + newList.length;
			copyUiLayerDataToManagerLocalCache(newList );
			
			
		}
		
		public function copyUiLayerDataToManagerLocalCache(newList: Array) :void
		{
			localList = new Array();
			for (var i:int = 0; i < newList.length; i++) {
				localList.push(utils.clone(newList[i]));
			}
		}
		
		
		public function httpResult(event:Event):void { 
			
			localList = utils.jsonCollectionToObjectArray(service.data);
			this.dispatchEvent(new Event(DATALOADED));
			
		} 
		
		private var service : HTTPService = new HTTPService();
		
		public function load():void
		{
			service = new HTTPService();
			service.url = server;
			
			service.send(); 
			
			service.addEventListener("complete", httpResult); 
		}
		
		
		
		public function query():Array
		{
			var cloned:Array = new Array();
			for (var i:int = 0; i < localList.length; i++) {
				cloned.push(utils.clone(localList[i]));
			}
			return cloned;
		}
		
		
		
		public function updateResult(event:Event):void { 
			
			debugLabel.text += " update returns:" + service.data;
			
			
		} 
		public function updateErrorResult(event:Event):void { 
			
			debugLabel.text += " update returns error:" + event.toString();
			
			
		} 
		
		
		public function createErrorResult(event:Event):void { 
			
			debugLabel.text += " create returns error:" + event.toString();
			
		} 
		
		
		public function deleteResult(event:Event):void { 
			
			debugLabel.text += " delete returns:" + service.data;
			
			
		} 
		public function deleteErrorResult(event:Event):void { 
			
			debugLabel.text += " delete returns error:" + event.toString();
			
			
		} 
		
		
		
		// Old code to save to local memory
		/*
		public function createEntry(o: SimpleBook):void
		{
		localList.push(o);
		
		}
		public function updateEntry(o: SimpleBook):void
		{
		for (var j:int = 0; j < localList.length; j++) {
		if (localList[j].id == o.id) {
		localList[j].title = o.title;
		} 
		
		}
		}
		public function deleteEntry(o: SimpleBook):void
		{
		
		var newList : Array = new Array();
		for (var j:int = 0; j < localList.length; j++) {
		if (o.id != localList[j].id) {
		newList.push(localList[j]);
		}
		
		}
		
		localList= newList;
		
		}
		*/
		
		
	}
}