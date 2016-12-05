package layout
{
	
	import org.apache.flex.html.ButtonBar;
	import org.apache.flex.html.SimpleAlert;
	import org.apache.flex.events.MouseEvent;
	import org.apache.flex.html.Container;
	import events.TabItemClickedEvent;
	
	[Event(name="tabitemClicked", type="events.TabItemClickedEvent")]
	public class TabBar extends ButtonBar
	{
		protected var _viewContainer:Container;
		
		public function TabBar()
		{
			super();
			this.addEventListener("click",TabItemClickHandler);
			
		}
	
		public function TabItemClickHandler(event:MouseEvent):void{
			_viewContainer.dispatchEvent(new TabItemClickedEvent (TabItemClickedEvent.TABITEMCLICKED,event.target.text,this.dataProvider.length,false,true));
		}
		public function set viewContainer(value:Container):void{
		_viewContainer = value;
			for(var i:int=1;i<=this.dataProvider.length;i++)
			{
				var container:Container = _viewContainer.getElementAt(i) as Container;
				container.visible = false;
			
			}
		}
		
		
	}
}
	
	/*	public function set viewContainer(value:Container):void{
			_viewContainer = value;
			var curElement:Object = null;
			var i:int;
			i = 1;
			curElement = _viewContainer.getElementAt(i);
			while (curElement != null) {
				(_viewContainer.getElementAt(i) as Container).visible = false;
				i++;
				try {
					curElement = _viewContainer.getElementAt(i);
				}
				catch (error:Error) {
						// when you exceed the number of available elements, it will throw an exception
						curElement = null;
					}
			} 
		}
		
		
	}
}*/