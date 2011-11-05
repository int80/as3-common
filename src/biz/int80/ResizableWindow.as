package biz.int80
{	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	import mx.events.MoveEvent;
	import mx.events.SandboxMouseEvent;
	
	public class ResizableWindow extends Window
	{
		private var clickOffset:Point;
		private var prevWidth:Number;
		private var prevHeight:Number;
		
		[SkinPart("false")]
		public var resizeHandle:UIComponent;
		
		
		override protected function partAdded(partName:String, instance:Object) : void
		{
			super.partAdded(partName, instance);
			
			if (instance == resizeHandle)
			{
				resizeHandle.addEventListener(MouseEvent.MOUSE_DOWN, resizeHandle_mouseDownHandler);
			}
		}
		
		override protected function partRemoved(partName:String, instance:Object):void
		{
			if (instance == resizeHandle)
			{
				resizeHandle.removeEventListener(MouseEvent.MOUSE_DOWN, resizeHandle_mouseDownHandler);
			}
			
			super.partRemoved(partName, instance);
		}
		protected function resizeHandle_mouseDownHandler(event:MouseEvent):void
		{
			if (enabled && isPopUp && !clickOffset)
			{        
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
		
		protected function resizeHandle_mouseMoveHandler(event:MouseEvent):void
		{
			// during a resize, only the TitleWindow should get mouse move events
			// we don't check the target since this is on the systemManager and the target
			// changes a lot -- but this listener only exists during a resize.
			event.stopImmediatePropagation();
			
			if (!clickOffset)
			{
				return;
			}
			
			width = prevWidth + (event.stageX - clickOffset.x);
			height = prevHeight + (event.stageY - clickOffset.y);
			event.updateAfterEvent();
		}
		
		protected function resizeHandle_mouseUpHandler(event:Event):void
		{
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
		}
		
		public function ResizableWindow()
		{
			super();
			this.setStyle("skinClass", ResizableWindowSkin);
		}
	}
}