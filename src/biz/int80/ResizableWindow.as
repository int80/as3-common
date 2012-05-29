package biz.int80
{	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	import mx.events.SandboxMouseEvent;
	
	import spark.core.IDisplayText;
	
	public class ResizableWindow extends Window implements IPersistantStorage {
		private var clickOffset:Point;
		private var prevWidth:Number;
		private var prevHeight:Number;
		
		[SkinPart("false")]
		public var resizeHandle:UIComponent;
		
		
		override protected function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			
			if (instance == resizeHandle)
				resizeHandle.addEventListener(MouseEvent.MOUSE_DOWN, resizeHandle_mouseDownHandler);
		}
		
		override protected function partRemoved(partName:String, instance:Object):void {
			if (instance == resizeHandle) {
				resizeHandle.removeEventListener(MouseEvent.MOUSE_DOWN, resizeHandle_mouseDownHandler);
			}
			
			super.partRemoved(partName, instance);
		}
		
		protected function resizeHandle_mouseDownHandler(event:MouseEvent):void {
			if (enabled && isPopUp && !clickOffset) {        
				clickOffset = new Point(event.stageX, event.stageY);
				prevWidth = width;
				prevHeight = height;
				
				var sbRoot:DisplayObject = systemManager.getSandboxRoot();
				
				sbRoot.addEventListener(
					MouseEvent.MOUSE_MOVE, resizeHandle_mouseMoveHandler, true);
				sbRoot.addEventListener(
					MouseEvent.MOUSE_UP, resizeHandle_mouseUpHandler, true);
				sbRoot.addEventListener(
					SandboxMouseEvent.MOUSE_UP_SOMEWHERE, resizeHandle_mouseUpHandler)
			}
		}
		
		protected function resizeHandle_mouseMoveHandler(event:MouseEvent):void {
			// during a resize, only the TitleWindow should get mouse move events
			// we don't check the target since this is on the systemManager and the target
			// changes a lot -- but this listener only exists during a resize.
			event.stopImmediatePropagation();
			
			if (! clickOffset) {
				return;
			}
			
			width = prevWidth + (event.stageX - clickOffset.x);
			height = prevHeight + (event.stageY - clickOffset.y);
						
			event.updateAfterEvent();
		}
		
		protected function resizeHandle_mouseUpHandler(event:Event):void {
			clickOffset = null;
			prevWidth = NaN;
			prevHeight = NaN;
			
			var sbRoot:DisplayObject = systemManager.getSandboxRoot();
			
			sbRoot.removeEventListener(
				MouseEvent.MOUSE_MOVE, resizeHandle_mouseMoveHandler, true);
			sbRoot.removeEventListener(
				MouseEvent.MOUSE_UP, resizeHandle_mouseUpHandler, true);
			sbRoot.removeEventListener(
				SandboxMouseEvent.MOUSE_UP_SOMEWHERE, resizeHandle_mouseUpHandler);
			
			checkDimensions();
		}
		
		// make sure window is not taller/wider than the screen
		// and stuff
		protected function checkDimensions(evt:Event=null):void {
			var margin:int = 10;
			
			var parentBounds:Rectangle = this.screen;
			if (! parentBounds) return;
			
			if (width < this.minWidth) width = minWidth;
			if (height < this.minHeight) height = minHeight;

			if (width > parentBounds.width + margin)
				width = parentBounds.width - margin;
			
			if (height > parentBounds.height + margin)
				height = parentBounds.height - margin;
		}
		
		public function ResizableWindow() {
			super();
			this.setStyle("skinClass", ResizableWindowSkin);
			
			this.addEventListener(ResizeEvent.RESIZE, checkDimensions);
		}
	}
}