package biz.int80
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.IFlexModuleFactory;
	
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
				
		// override this for AIR apps, since AIR doesn't have DBAppController.appController.showAlert()
		public function showAlert(text:String = "", title:String = "",
										   flags:uint = 0x4 /* Alert.OK */, 
										   parent:Sprite = null, 
										   closeHandler:Function = null, 
										   iconClass:Class = null, 
										   defaultButtonFlag:uint = 0x4 /* Alert.OK */,
										   moduleFactory:IFlexModuleFactory = null):void {
			Alert.show(text, title, flags, parent, closeHandler, iconClass, defaultButtonFlag, moduleFactory);
		}
		
		public function getApiUrl(path:String="", args:URLVariables=null):String {
			var url:String = urlRoot + "/api/" + path;
			
			if (! args || ! args.toString())
				return url;
				
			return url + "?" + args.toString(); 
		}
		
		public function get urlRoot():String {
			var urlRoot:String = FlexGlobals.topLevelApplication.parameters.base_url;
			
			if (! urlRoot) {
				urlRoot = this.defaultApiUrl();
				if (! urlRoot)
					urlRoot = "http://localhost:3000";
			}

			return urlRoot;
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