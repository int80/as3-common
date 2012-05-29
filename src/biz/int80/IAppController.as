package biz.int80
{
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.core.IFlexModuleFactory;
	
	public interface IAppController extends IEventDispatcher
	{
		function getApiUrl(path:String="", args:URLVariables=null):String;
		function loadAllEntities(entityClass:Class, opts:Object=null, cb:Function=null):void;
		function showAlert(text:String = "", title:String = "",
								  flags:uint = 0x4 /* Alert.OK */, 
								  parent:Sprite = null, 
								  closeHandler:Function = null, 
								  iconClass:Class = null, 
								  defaultButtonFlag:uint = 0x4 /* Alert.OK */,
								  moduleFactory:IFlexModuleFactory = null):void;
		function defaultApiUrl():String;
		function getAllEntitiesFiltered(entityClass:Class, filterField:String, filterValue:Object=null):ArrayCollection;
		function getAllEntities(entityClass:Class):ArrayCollection;
		function get urlRoot():String;
	}
}