package biz.int80h
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	
	[Bindable] dynamic public class Entity extends EventDispatcher
	{
		private static var _entities:Object = {};
		
		public function Entity(fields:Object=null)
		{
			this.setFields(fields);
		}
		
		
		// override in subclass
	
		public virtual function get className():String { return "noclass" };
		
		
		//// fields
		
		[Bindable(event="FieldsChanged")] public function field(fieldName:String):* {
			if (! this.hasOwnProperty(fieldName))
				return undefined;
			 
			return this[fieldName];
		}
		
		public function setField(fieldName:String, value:Object, fireFieldsChangedEvent:Boolean=true):void {
			if (value is ObjectProxy) {
				var type:String = getQualifiedClassName(this[fieldName]);
				var typeInfo:Object = describeType(this);
				
				// try normal property
				var typeName:String = typeInfo..variable.(@name == fieldName).@type;
				
				if (! typeName) {
					// try bindable accessor method
					typeName = typeInfo..accessor.(@name == fieldName).@type;
				}
				
				if (! typeName) {
					// failed to find it
					trace("failed to find type info for " + type + "." + fieldName);
					return;
				}
				
				var typeClass:Class = getDefinitionByName(typeName) as Class;
				
				this[fieldName] = new typeClass(value);
			} else {
				this[fieldName] = value;
			}
		
			if (fireFieldsChangedEvent)
				this.fieldsChanged();
		}
		
		public function setFields(fields:Object):void {
			if (! fields) fields = {};

			for (var field:* in fields) {
				this.setField(field, fields[field], false);
			}
			
			this.fieldsChanged();
		}
		
		protected function fieldsChanged():void {
			this.dispatchEvent(new Event("FieldsChanged"));
		}
		
		// CRUD
		
		static public function create(entityClass:Class, fields:Object=null, cb:Function=null):void {
			var entityFactory:ClassFactory = new ClassFactory(entityClass);
			var self:Entity = entityFactory.newInstance();
			
			self.doRequest("", function (evt:ResultEvent):void {
				self.loadAll();
				if (cb != null)
					cb.apply(self, [ evt ]);
			}, "PUT", fields);
		}
		
		public function deleteEntity():void {
			this.doRequest("/" + this.id + "", function (evt:ResultEvent):void {
				
			}, "DELETE");
		}
				
		[Bindable(event="EntitiesUpdated")] public function get all():ArrayCollection {
			return Entity._entities[this.className];
		}
		
		[Bindable(event="EntitiesUpdated")]
		static public function getEntities(className:String):ArrayCollection {
			return _entities[className];
		}
		
		public function load(cb:Function=null):void {			
			var self:Entity = this;
			doRequest(
				"", 
				function (evt:ResultEvent):void {
					if (cb != null)
						cb.apply(self);
					self.loadComplete(evt);
				},
				"GET",
				{
					'search.id': this.id
				}
			);
		}
		
		[Bindable(event="EntitiesUpdated")] public function loadAll(search:Object=null):void {
			var self:Entity = this;
			doRequest("", function (evt:ResultEvent):void { self.loadEntitiesComplete(evt) }, "GET", search);
		}
		
		public function update(fields:Object):void {
			var self:Entity = this;
			doRequest("/" + this.id, function (evt:ResultEvent):void { self.updateComplete(evt) }, "PUT", fields);
		}
		
		
		//// events
		
		protected function loadComplete(res:ResultEvent):void {
			this.setFields(res.result.opt.data.list);
		}
		
		//public static function instantiateLoadedEntities(resultSource:Object, classCtor:Object) {
		
		protected function loadEntitiesComplete(res:ResultEvent):void {
			var entityList:ArrayCollection = _entities[this.className];
			if (! entityList)
				entityList = _entities[this.className] = new ArrayCollection();
			else
				entityList.removeAll();
			
			var list:ArrayCollection = res.result.opt.data.list as ArrayCollection;
			if (! list) list = new ArrayCollection([ res.result.opt.data.list ]);

			for each (var entityFields:Object in list) {
				var entityInstance:Object = new this.constructor;
				entityInstance.setFields(entityFields);
				
				entityList.addItem(entityInstance);
			}
			
			this.dispatchEvent(new Event("EntitiesUpdated"));
		}
		
		protected function updateComplete(evt:ResultEvent):void {
			this.load();
		}
		
		
		// utility
		// this has been deprecated in favor of RESTService
		protected function doRequest(url:String="", cb:Function=null, method:String="POST", params:Object=null):void {
			var vars:URLVariables = new URLVariables();
			for (var f:String in params) {
				if (! params.hasOwnProperty(f)) continue;
				vars[f] = params[f];
			}
			
			vars['x-tunneled-method'] = method;
						
			var req:HTTPService = new HTTPService();
			req.method = method == "GET" ? "GET" : "POST";
			req.url = AppControllerBase.appController.getApiUrl("rest/" + this.className + url);
			req.addEventListener(ResultEvent.RESULT, cb);
			
			req.send(vars);
		}
	}
}