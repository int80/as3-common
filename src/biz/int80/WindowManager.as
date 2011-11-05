package biz.int80
{
	import flash.display.DisplayObject;
	
	import mx.managers.PopUpManager;

	public class WindowManager extends PopUpManager
	{
		public function WindowManager()
		{
			super();
		}

		public static function confirmDialog(parent:DisplayObject, question:String, title:String=null, cb:Function=null):void {
			var dialog:ConfirmDialog = ConfirmDialog(PopUpManager.createPopUp(parent, ConfirmDialog));
			dialog.question = question;
			dialog.title = title ? title : "Confirm";
			
			dialog.addEventListener("Confirmed", cb);
		}		
	}
}