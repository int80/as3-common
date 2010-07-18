package biz.int80h
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
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
				if (this.hasOwnProperty(fieldName)) {
					if (value == "")
						value = null;
						
					this[fieldName] = value;
				} else {
					trace("ERROR: property " + fieldName + " does not exist on "
						+ getQualifiedClassName(this));
				}
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
		
		public function deleteEntity(callback:Function=null):void {
			var self:Entity = this;
			this.doRequest("/" + this.id + "", function (evt:ResultEvent):void {
				if (callback != null)
					callback(self);
			}, "DELETE", this.primaryKey());
		}
				
		[Bindable(event="EntitiesUpdated")] public function get all():ArrayCollection {
			if (! Entity._entities[this.className]) {
				Entity._entities[this.className] = new ArrayCollection();
			}
			
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
				self.primaryKey()
			);
		}
		
		// override if PK is not "id"
		public function primaryKey():Object {
			return { "search.id": this.id };
		}
		
		[Bindable(event="EntitiesUpdated")] public function loadAll(search:Object=null, cb:Function=null):void {
			var self:Entity = this;
			doRequest("", function (evt:ResultEvent):void {
				self.loadEntitiesComplete(evt);
				if (cb != null) { cb(); }
			}, "GET", search);
		}
		
		public function update(fields:Object):void {
			var self:Entity = this;
			
			var pk:Object = this.primaryKey();
			for (var key:String in pk) {
				if (fields[key] || key == 'search.id') continue;
				
				fields[String(key)] = pk[key];
			}
			
			doRequest("/" + this.id, function (evt:ResultEvent):void { self.updateComplete(evt) }, "POST", fields);
		}
		
		
		//// events
		
		protected function loadComplete(res:ResultEvent):void {
			this.setFields(res.result.opt.data.list);
			this.dispatchEvent(new Event("EntityLoaded"))
		}
				
		protected function loadEntitiesComplete(res:ResultEvent):void {
			var entityList:ArrayCollection = _entities[this.className];
			if (! entityList)
				entityList = _entities[this.className] = new ArrayCollection();
				
			if (! res || ! res.result || ! res.result.opt || ! res.result.opt.data)
				return;
				
			if (res.result.opt.data.list)
				Entity.instantiateList(res.result.opt.data.list, this.constructor, entityList);
			else
				entityList.removeAll();
				
			this.dispatchEvent(new Event("EntitiesUpdated"));
			entityList.dispatchEvent(new Event("EntitiesLoaded"));
		}
		
		protected function updateComplete(evt:ResultEvent):void {
			this.load();
			this.dispatchEvent(new Event("EntityUpdated"));
		}
		
		
		//// utility
		
		static public function instantiateList(listObj:Object, ctor:Object, newList:ArrayCollection):void {
			// force into arraycollection, even if it is a single object
			var list:ArrayCollection = listObj as ArrayCollection;
			if (! list && listObj) list = new ArrayCollection([ listObj ]);

			newList.removeAll();
			
			if (! list || ! listObj)
				return;

			for each (var entityFields:Object in list) {
				var entityInstance:Entity = Entity.instantiateRow(entityFields, ctor);
				
				if (! entityInstance) {
					trace("Error instantiating " + ctor);
					continue;
				}
				
				newList.addItem(entityInstance);
			}
		}
		
		static public function instantiateRow(rowObj:Object, ctor:Object):Entity {
			var entityInstance:Object = new ctor;
			entityInstance.setFields(rowObj);
			return entityInstance as Entity;
		}
		
		private function gotFault(evt:FaultEvent, url:String):void {
			trace("Got error for URL " + url + ": " + evt.fault.faultDetail);
			trace("[Stack trace]\n" + evt.fault.getStackTrace());
			this.dispatchEvent(evt);
		}
		
		// this has been deprecated in favor of RESTService
		protected function doRequest(url:String="", cb:Function=null, method:String="POST", params:Object=null):void {
			var vars:URLVariables = new URLVariables();
			for (var f:String in params) {
				if (! params.hasOwnProperty(f)) continue;
				vars[f] = params[f];
			}
			
			var req:RESTService = new RESTService();
			req.method = method;
			req.apiUrl = "rest/" + this.className + url;
			req.addEventListener(ResultEvent.RESULT, cb);
			req.addEventListener(FaultEvent.FAULT, function (evt:FaultEvent):void {
				gotFault(evt, url);
			});
			
			req.send(vars);
		}
	}
}