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
package actionScripts.ui.editor.text
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.Button;
	import spark.layouts.VerticalLayout;
	
	import __AS3__.vec.Vector;
	
	import actionScripts.events.ChangeEvent;
	import actionScripts.ui.editor.text.change.TextChangeInsert;
	import actionScripts.ui.editor.text.change.TextChangeMulti;
	import actionScripts.ui.editor.text.change.TextChangeRemove;
	import actionScripts.ui.editor.text.vo.CompletionContext;
	import actionScripts.ui.editor.text.vo.CompletionResult;
	
	import components.renderers.texteditor.CompletionList;
	
	public class CompletionManager
	{
		protected var editor:TextEditor;
		protected var model:TextEditorModel;
		
		protected var list:CompletionList;
		
		protected var context:CompletionContext;		
		protected var filterString:String;
		protected var completions:ArrayCollection;
		
		protected var maxListHeight:int;
		
		public var listItemHeight:int = 16;
		
		public function CompletionManager(editor:TextEditor, model:TextEditorModel)
		{
			this.editor = editor;
			this.model = model;
		}
		
		public function showCompletion(completions:ArrayCollection, context:CompletionContext):void
		{
			// Don't show empty box, it's just sad.
			if (!completions) return;
			if (completions.length == 0) return;
			if (!list) createList();

			this.context = context;
			this.completions = completions;
			// If we have a context we can filter based on what the user types			
			if (context)
			{
				completions.filterFunction = filterFunction;
				updateFilter();
			}
			
			list.dataProvider = completions;
			
			// We need to respond to certain key events
			editor.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown, false, 100);
			// Hide list on click outside the list
			editor.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			
			positionList(null);
		}
		
		
		public function updateFilter():void
		{
			// TODO: Also update list size
			if (!context) return;

			filterString = getFilterString().toLowerCase();
			trace("filterString: " + filterString);
			completions.refresh();
			
			list.selectedIndex = 0;
			
			sizeList();
		}
		
		public function isMouseOverList():Boolean
		{
			if (!list || !list.visible) return false;
			
			return list.hitTestPoint(editor.mouseX, editor.mouseY);
		}
		
		protected function filterFunction(obj:Object):Boolean
		{
			return obj.completion.toLowerCase().indexOf(filterString) == 0;
		}
		
		// Fetch filter string based on context & caret
		protected function getFilterString():String
		{
			var str:String = model.selectedLine.text.substring(context.filterCharStart, model.caretIndex);

			// Ignore chars after trigger chars
			//  Allows showing completion box when missing the completion
			//  For example it shows method params if '(' is set as trigger char
			if (str 
				&& context.dontFilterAfterTriggerChar 
				&& str.indexOf(context.dontFilterAfterTriggerChar) > -1)
			{
				return str.substring(0, str.indexOf(context.dontFilterAfterTriggerChar)); 
			}
			else if (str) return str;
			else return "";
		}
		
		protected function positionList(event:Event):void
		{
			list.width = calcListItemWidth();
			//// Figure out where the caret is in x,y
			// Which renderer is in focus?
			var rdrIdx:int = model.selectedLineIndex - model.scrollPosition;
			var rdr:TextLineRenderer = model.itemRenderersInUse[rdrIdx];
			
			var charBounds:Rectangle = rdr.getCharBounds(model.caretIndex);
			// .x is manually adjusted, so we can't use .topLeft:Point, instead we create a new Point.
			var charPoint:Point = rdr.localToGlobal(new Point(charBounds.x, charBounds.y));
			
			// Get center of char
			var middle:Point = new Point(charPoint.x+charBounds.width/2, charPoint.y+charBounds.height/2);
			
			var editorPoint:Point = editor.globalToLocal(charPoint);
			var editorRect:Rectangle = editor.getRect(editor);
			
			// Position below code line
			if (middle.y < editor.stage.stageHeight)
			{
				list.y = editorPoint.y+charBounds.height;
				list.x = editorPoint.x;
				
				maxListHeight = editorRect.bottom-list.y-10;
				list.height = Math.min(list.height, maxListHeight);
			}
			// Position above line
			else
			{
				maxListHeight = list.y-10;
				list.height = Math.min(list.height, maxListHeight);
				
				list.y = editorPoint.y - list.height - charBounds.height;
			}
			
			list.selectedIndex = 0;
			// BUG: setting selectedIndex straight away doesn't always work
			//  so we wait a frame & go at it again
			list.callLater(selectFirstItem); 
			
			sizeList();
			
			list.visible = true;
		}
		
		protected function calcListItemWidth():int
		{
			var maxItemWidth:int = 0;
 			for each (var completion:CompletionResult in completions)
 			{
 				// TODO: Need to derive from font metrics
 				maxItemWidth = Math.max(maxItemWidth, completion.label.length*7.82666015625);
 			}
 			
 			return maxItemWidth+9;
		}
		
		protected function sizeList():void
		{
			list.width = calcListItemWidth();
			
			// Don't overrun on the right side
			if (list.x+list.width+20 > editor.width) 
			{
				list.x = editor.width-20-list.width;
				if (list.x < 0)
				{
					list.x = 20;
					list.width = editor.width-40;
				}
			}
			
			var height:int = Math.min(maxListHeight, listItemHeight*completions.length);
			list.height = height;
		}
		
		protected function selectFirstItem():void
		{
			list.selectedIndex = 0;
		}
		
		protected function createList():void
		{
			list = new CompletionList();
			list.visible = false;
			list.minHeight = 50;
			list.minWidth = 50;
			
			list.addEventListener(MouseEvent.CLICK, handleListClick);
			
			editor.addChild(list);
		}
		
		protected function handleKeyDown(event:KeyboardEvent):void
		{
			var matched:Boolean = true;
			
			switch (event.keyCode)
			{
				case Keyboard.ENTER:
				case Keyboard.TAB:
				{
					performCompletion();
					break;
				}
				case Keyboard.ESCAPE:
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
				{
					cancelCompletion();
					break;
				}
				case Keyboard.UP:
				{
					if (list.selectedIndex-1 >= 0)
					{
						list.selectedIndex--;
					}
					else
					{
						// Wrap
						list.selectedIndex = list.dataProvider.length-1;
					}
					updateScrollPosition();
					break;
				}
				case Keyboard.DOWN:
				{
					if (list.selectedIndex+1 < list.dataProvider.length)
					{
						list.selectedIndex++;
					}
					else
					{
						list.selectedIndex = 0;
					}
					updateScrollPosition();
					break;
				}
				default:
				{
					matched = false;
				}
			}
			
			// Don't send these events to the editor
			if (matched)
			{
				event.preventDefault();
				event.stopImmediatePropagation();
			}
			else
			{
				list.callLater(updateFilter);
			}
		}
		
		protected function updateScrollPosition():void
		{
			var target:Number = list.selectedIndex*16;
			var l:VerticalLayout = VerticalLayout(list.layout);
			var rowHeight:int = l.rowHeight;
			
			if (target+(2*rowHeight) > list.layout.verticalScrollPosition
				&& target+(2*rowHeight) > list.layout.verticalScrollPosition+list.height) 
			{
				list.layout.verticalScrollPosition = (list.selectedIndex+2-l.rowCount)*rowHeight;
			}
			else if (target < list.layout.verticalScrollPosition
				&& target < list.layout.verticalScrollPosition+list.height)
			{
				list.layout.verticalScrollPosition = list.selectedIndex*rowHeight;	
			}
			
		}
		
		protected function handleMouseDown(event:MouseEvent):void
		{
			// Clicked the completion menu?
			if (list.getBounds(list.stage).contains(event.stageX, event.stageY) == false)
			{
				cancelCompletion();
			}
		}
		
		protected function handleListClick(event:Event):void
		{
			if (event.target is Button) return;
			
			performCompletion();
			editor.setFocus();
		}
		
		protected function cancelCompletion(event:Event=null):void
		{
			list.visible = false;
			
			editor.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
			editor.removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
		}
		
		protected function performCompletion():void
		{
			var completion:CompletionResult = CompletionResult(list.selectedItem); 
			var str:String = completion.completion;
			// Split into lines in case we have multiple lines to complete
			var split:Array = str.split("\n");
			var lines:Vector.<String> = Vector.<String>(split);
			
			// Add to editor
			var insert:TextChangeInsert;
			
			var event:ChangeEvent;
			//If we complete for 'foo.backgroundal' with 'backgroundAlpha', backtrack & remove.
			if (context)
			{
				var remove:TextChangeRemove = new TextChangeRemove(
					model.selectedLineIndex, 
					context.filterCharStart, 
					model.selectedLineIndex, 
					model.caretIndex
				);
				
				insert = new TextChangeInsert(model.selectedLineIndex, context.filterCharStart, lines);
				
				var multi:TextChangeMulti = new TextChangeMulti(remove, insert);
				event = new ChangeEvent(ChangeEvent.TEXT_CHANGE, multi);
				
				// Temp solution to allow completion list to show while typing method + params out
				if (context.dontFilterAfterTriggerChar)
				{
					str = getFilterString();
					if (str && str.indexOf(context.dontFilterAfterTriggerChar))
					{
						// Assume user typed it out
						event = null;
					}
				}
			}
			else
			{
				event = new ChangeEvent(
					ChangeEvent.TEXT_CHANGE,
					new TextChangeInsert(model.selectedLineIndex, model.caretIndex, lines)
				);
			}
			
			// Tell editor to act
			if (event)
				editor.dispatchEvent(event);
			
			
			// If doing a completion has additional actions bound to it, perform them
			if (context && context.action)
			{
				var actionEvent:ChangeEvent = context.action.apply(completion);
				if (actionEvent) 
				{
					var caretIndex:int = model.caretIndex;
					var lineIndex:int = model.selectedLineIndex;
					
					editor.dispatchEvent(actionEvent);
					
					if (actionEvent.change is TextChangeInsert)
					{
						var ins:TextChangeInsert = actionEvent.change as TextChangeInsert;
						if (ins.startLine < lineIndex)
						{
							lineIndex += ins.textLines.length-1;
						}
					}
					
					model.selectedLineIndex = lineIndex;
					model.caretIndex = caretIndex;
				}
			}
			
			// Clean up after us
			cancelCompletion();
		}

	}
}