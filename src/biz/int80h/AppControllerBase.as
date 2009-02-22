package biz.int80h
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	
	[Bindable] public class AppControllerBase extends EventDispatcher
	{
		private var entities:Object = {};
		
		
		public function AppControllerBase()
		{
		}
		
		public static function getApiUrl(path:String, args:URLVariables=null):String {
			if (! args) args = new URLVariables();
			
			var url:String = "http://localhost:3003/api/" + path;
			if (! args || ! args.toString())
				return url;
				
			return url + "?" + args.toString(); 
		} 
		
		public function getEntitySingleton(entityClass:Class):Entity {
			var entFactory:ClassFactory = new ClassFactory(entityClass);
			var ent:Entity = entFactory.newInstance();
			var self:Object = this;
			ent.addEventListener("EntitiesUpdated", function ():void { self.dispatchEvent(new Event("EntityListUpdated")) });
			return ent;
		}
		
		// fixme: have binding update only when this class entityList changes
		public function loadAllEntities(entityClass:Class):void {
			var ent:Entity = entities[entityClass];
			if (! ent) {
				ent = this.getEntitySingleton(entityClass);
			}
			
			ent.loadAll();
		}
		
		[Bindable(event="EntityListUpdated")]
		public function getAllEntities(entityClass:Class):ArrayCollection {
			var ent:Entity = this.getEntitySingleton(entityClass);
			return ent.all;
		}
	}
}