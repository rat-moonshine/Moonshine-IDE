package events
{

	import org.apache.flex.events.CustomEvent;
	
	public class TabItemClickedEvent extends CustomEvent
	{
	    public static const TABITEMCLICKED:String = "tabitemClicked";
		
		public var text:String;
		public var length:int;
	
		public function TabItemClickedEvent(type:String, text:String ,length:int,bubbles:Boolean = false, cancelable:Boolean = false   )
		{
           this.text = text;
		   this.length = length;
		   
            super(type, false, true);                    
      	}
		
		override public function cloneEvent():org.apache.flex.events.Event
		{
			return new TabItemClickedEvent(type,text ,length, bubbles, cancelable);
		}
	}
}
