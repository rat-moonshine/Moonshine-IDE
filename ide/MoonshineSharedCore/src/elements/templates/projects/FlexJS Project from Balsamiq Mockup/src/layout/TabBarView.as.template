package layout
{
	
	import org.apache.flex.html.Container;
	import org.apache.flex.html.SimpleAlert;
	import events.TabItemClickedEvent;
	
	
	public class TabBarView extends Container
	{
		public function TabBarView()
		{
			super();
			this.addEventListener(TabItemClickedEvent.TABITEMCLICKED,TabItemClickHandler);
		}
		
		public function TabItemClickHandler(event:TabItemClickedEvent):void{
			for(var i:int=0;i<=event.length;i++)
			{
				var container:Container = this.getElementAt(i) as Container;
				
				if(container.name == event.text)
				{
					container.visible = true;
				}
				else
					container.visible = false;
			}
		}
	}
}
	/*	public function TabItemClickHandler(event:TabItemClickedEvent):void{
			    var curElement:Object = null;
				var i:int;
				i = 0;
				curElement = this.getElementAt(i);
				while (curElement != null) {
					var container:Container = this.getElementAt(i) as Container;
					if(container.name == event.text)
						container.visible = true;
					else
						container.visible = false;
					i++;
					try {
						curElement = this.getElementAt(i);
					}
					catch (error:Error) {
						// when you exceed the number of available elements, it will throw an exception
						
						curElement = null;
					}
				} 
		}
	}
}*/