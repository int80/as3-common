package biz.int80h
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.ClassFactory;
	import biz.int80h.IAppController;
	
	[Bindable] public class AppControllerBase extends EventDispatcher implements IAppController
	{
		private var entities:Object = {};
		private var lastEntities:Object = {};
		
		static public var appController:IAppController;
		
		public function defaultApiUrl():String {
			return null;
		}
		
		public function AppControllerBase()
		{
		}
		
		public function getApiUrl(path:String, args:URLVariables=null):String {
			var urlRoot:String = Application.application.parameters.base_url;
			
			if (! urlRoot) {
				urlRoot = this.defaultApiUrl();
				if (! urlRoot)
					urlRoot = "http://localhost:3002";
			}
			
			var url:String = urlRoot + "/api/" + path;
			
			if (! args || ! args.toString())
				return url;
				
			return url + "?" + args.toString(); 
		} 
		
		public function getEntitySingleton(entityClass:Class):Entity {
			var entFactory:ClassFactory = new ClassFactory(entityClass);
			var ent:Entity = entFactory.newInstance();
			ent.addEventListener("EntitiesUpdated", function ():void { entityListUpdated(ent) });
			return ent;
		}

		// todo: figure out a way to see if the list changed and not dispatch event unless it's different		
		private function entityListUpdated(ent:Entity):void {
			this.dispatchEvent(new Event("EntityListUpdated"));
		}
		
		public function loadAllEntities(entityClass:Class, opts:Object=null):void {
			var ent:Entity = entities[entityClass];
			if (! ent) {
				ent = this.getEntitySingleton(entityClass);
			}
			
			ent.loadAll(opts);
		}
		
		[Bindable(event="EntityListUpdated")]
		public function getAllEntities(entityClass:Class):ArrayCollection {
			var ent:Entity = this.getEntitySingleton(entityClass);
			return ent.all;
		}
	}
}