package biz.int80
{
	import flash.events.IEventDispatcher;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	
	public interface IAppController extends IEventDispatcher
	{
		function getApiUrl(path:String="", args:URLVariables=null):String;
		function loadAllEntities(entityClass:Class, opts:Object=null, cb:Function=null):void;
		function defaultApiUrl():String;
		function getAllEntitiesFiltered(entityClass:Class, filterField:String, filterValue:Object=null):ArrayCollection;
		function getAllEntities(entityClass:Class):ArrayCollection;
		function get urlRoot():String;
	}
}