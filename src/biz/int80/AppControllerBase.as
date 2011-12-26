package biz.int80
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	
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
		
		public function getApiUrl(path:String="", args:URLVariables=null):String {
			var urlRoot:String = FlexGlobals.topLevelApplication.parameters.base_url;
			
			if (! urlRoot) {
				urlRoot = this.defaultApiUrl();
				if (! urlRoot)
					urlRoot = "http://localhost:3000";
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
			dispatchEvent(new Event("EntityListUpdated"));
		}
		
		public function loadAllEntities(entityClass:Class, opts:Object=null, cb:Function=null):void {
			var ent:Entity = entities[entityClass];
			if (! ent) {
				ent = this.getEntitySingleton(entityClass);
			}
			
			ent.loadAll(opts, cb);
		}
		
		[Bindable(event="EntityListUpdated")]
		public function getAllEntitiesFiltered(entityClass:Class, filterField:String, filterValue:Object=null):ArrayCollection {
			var ent:Entity = this.getEntitySingleton(entityClass);
			var all:Array = ent.all ? ent.all.toArray() : [];
			
			var allCollection:ArrayCollection = new ArrayCollection(all);
			
			allCollection.filterFunction = function (item:Object):Boolean {
				if (! filterValue) {
					return ! item[filterField];
				}
				
				return item[filterField] == filterValue;
			};
			allCollection.refresh();

			return allCollection;
		}
		
		[Bindable(event="EntityListUpdated")]
		public function getAllEntities(entityClass:Class):ArrayCollection {
			var ent:Entity = this.getEntitySingleton(entityClass);
			return ent.all;
		}
		
		public static function isDebugPlayer() :Boolean {
			return Capabilities.isDebugger;
		}
		
		public static function isDebugBuild() :Boolean {
			return new Error().getStackTrace().search(/:[0-9]+]$/m) > -1;
		}
			
		public static function isReleaseBuild() :Boolean {
			return !isDebugBuild();
		}
	}
}