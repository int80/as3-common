package biz.int80
{
	import flash.events.Event;
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
		// lists of singletons by class
		protected static var _entities:Object = {};
		
		// the actual singletons by class / pk
		protected static var _singletons:Object = {};
				
		// should all entities created be singletons?
		// this does not affect singleton ArrayCollections accessed with all()
		public static var USE_SINGLETONS_ONLY:Boolean = true;

		public static var DEBUG:Boolean = false;

		// constructor
		public function Entity(fields:Object=null) {
			this.setFields(fields);
		}
		
		// events
		public static const FIELDS_CHANGED_EVENT:String = "FieldsChanged";
		public static const ENTITY_LOADED_EVENT:String  = "EntityLoaded";
		public static const ENTITY_UPDATED_EVENT:String = "EntityUpdated";
		
		// use this instead of auto-generated _classIdentifier
		// "shadow" this in your subclass if you wish to use a different name
		// for the entity class and REST path part
		// (this is the only way to inherit a static property associated with a class)
		private static const classIdentifier:String = null;
		
		// trace if DEBUG
		protected static function debug(str:String):void {
			if (! DEBUG) return;
			trace(str);
		}
		
		//// fields

		// list of fields that have been set on our instance
		protected var fieldList:Array = [];

		// returns value of a field
		[Bindable(event="FieldsChanged")] public function field(fieldName:String):* {
			if (! this.hasOwnProperty(fieldName))
				return undefined;
			 
			return this[fieldName];
		}
		
		// field setter for an Entity instance
		public function setField(fieldName:String, value:Object, fireFieldsChangedEvent:Boolean=true):void {
			// if we got an object, this may be a sub-entity child
			//trace("value: " + (typeof(value)) + " is object: " + (value is Object) + " prototype is Object: " + (value.hasOwnProperty("prototype") && value.prototype == Object));
			if (typeof(value) == 'object') {
				if (! this.hasOwnProperty(fieldName)) {
					trace("ERROR: sub-property " + fieldName + " does not exist on " +
						getQualifiedClassName(this) + " --- " + Object(this).type_name);
					return;
				}
				
				// get class and type info for this field
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
			
			// keep track of what fields we have set
			if (fieldList.indexOf(fieldName) == -1)
				fieldList.push(fieldName);
		
			if (fireFieldsChangedEvent)
				this.fieldsChanged();
		}
		
		// populate properties of an instance
		// best: pass in ObjectProxy
		// ok: pass in Object
		// shady: pass in Entity
		public function setFields(fields:Object):void {
			if (! fields)
				return;
			
			var fieldName:String;
			
			if (! (fields as Entity)) {
				// this makes things easy. assume Object or ObjectProxy
				for (fieldName in fields) {
					this.setField(fieldName, fields[fieldName], false);
				}
			} else {
				// not so easy, we have an instance. we need to find out what fields are on this instance.
				// hope to god that we saved the list of fields which are set on this instance:
				if (fieldList && fieldList.length) {
					for each (fieldName in fieldList) {
						this.setField(fieldName, fields[fieldName], false);
					}
				} else {
					// we are probably boned. this is unlikely to work.
					trace("Failed to find field list on " + getQualifiedClassName(this) + 
						". Please don't pass an Entity to Entity.setFields or the Entity constructor");
				
					var def:XML = describeType(fields);
					var properties:XMLList = def..variable.@name + def..accessor.@name;				
					for(var i:int; i < properties.length(); i++){
						trace(properties[i].@name+':'+ this[properties[i].@name]);
						fieldName = properties[i].@name;
						this.setField(fieldName, fields[fieldName], false);
					}
				}
			}
			
			this.fieldsChanged();
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
			this.doRequest("/" + this.id, function (evt:ResultEvent):void {
				// remove self from singleton list
				var entities:ArrayCollection = self.all;
				var idx:int = entities.getItemIndex(self);
				if (idx > -1) entities.removeItemAt(idx);
				
				if (callback != null)
					callback(self);
			}, "DELETE", this.primaryKey());
		}
				
		// simple accessor for Entity.getEntities()
		[Bindable(event="EntitiesUpdated")] public function get all():ArrayCollection {
			return getEntities(this._class);
		}
		
		// returns entity singleton list
		// does not do any requests
		[Bindable(event="EntitiesUpdated")]
		static public function getEntities(entityClass:Class):ArrayCollection {			
			var className:String = _classIdentifier(entityClass);
			
			if (! Entity._entities[className]) {
				Entity._entities[className] = new ArrayCollection();
			}
			
			return _entities[className];
		}
		
		// probably shouldn't be used
		static public function setEntities(entityClass:Class, list:ArrayCollection):void {			
			var className:String = _classIdentifier(entityClass);
			
			if (_entities[className]) {
				ArrayCollection(_entities[className]).removeAll();
				ArrayCollection(_entities[className]).addAll(list);
			} else {
				_entities[className] = list;
			}
		}
		
		// reloads a single entity's fields
		public function load(cb:Function=null):void {			
			var self:Entity = this;
						
			doRequest(
				"", 
				function (evt:ResultEvent):void {
					self.loadComplete(evt);
					if (cb != null)
						cb.apply(self);
				},
				"GET",
				self.primaryKey()
			);
		}
		
		// override if PK is not "id"
		public function primaryKey():Object {
			return { "search.id": this.id };
		}
		
		// populate singleton list
		[Bindable(event="EntitiesUpdated")] public function loadAll(search:Object=null, cb:Function=null):void {
			var self:Entity = this;
			var entityClass:Class = this._class;
			this.doRequest("", function (evt:ResultEvent):void {
				Entity.loadEntitiesComplete(entityClass, evt);
				if (cb != null) { cb(); }
			}, "GET", search);
		}
		
		public static function loadAll(entityClass:Class, search:Object=null, cb:Function=null):void {
			doRequest(entityClass, "", function (evt:ResultEvent):void {
				Entity.loadEntitiesComplete(entityClass, evt);
				if (cb != null) { cb(); }
			}, "GET", search);
		}
		
		// save changes to an entity
		public function update(fields:Object, cb:Function=null):void {
			var self:Entity = this;
			
			// add primary key fields for update
			var pk:Object = this.primaryKey();
			for (var pkey:String in pk) {
				if (fields[pkey] || pkey == 'search.id') continue;
				fields[String(pkey)] = pk[pkey];
			}
				
			// update instance immediately
			for (var fkey:String in fields) {
				self[fkey] = fields[fkey];
			}
			
			doRequest("/" + this.id, function (evt:ResultEvent):void {
				self.updateComplete(evt);
				if (cb != null)
					cb();
			}, "POST", fields);
		}
		
		
		//// events
		
		protected function fieldsChanged():void {
			this.dispatchEvent(new Event(FIELDS_CHANGED_EVENT));
		}
		
		protected function loadComplete(res:ResultEvent):void {
			if (typeof(res.result) == 'string') {
				// error
				trace("Failed to load " + getQualifiedClassName(this) + ": " + res.result + ": " + res);
				return;
			}
			
			this.setFields(res.result.opt.data.list);
			this.dispatchEvent(new Event(ENTITY_LOADED_EVENT));
		}
		
		// for compatibility
		protected static function loadEntitiesComplete(entityClass:Class, res:ResultEvent):void {
			var cf:ClassFactory = new ClassFactory(entityClass);
			return Entity.loadEntitiesCompleteWithFactory(cf, res);
		}
		
		protected static function loadEntitiesCompleteWithFactory(entityClassFactory:ClassFactory, res:ResultEvent):void {
			var cid:String = _classIdentifier(entityClassFactory.generator);
			debug("loadEntitiesComplete for " + cid);
			
			var entityList:ArrayCollection = _entities[cid];
			if (! entityList)
				entityList = _entities[cid] = new ArrayCollection();
			
			// response content should be in res.result.opt
			// entity list should be in res.result.opt.data.list
			
			// we really should have these
			if (! res || ! res.result)
				return;
			
			// unable to parse XML, most likely non-2xx response
			if (res.result is String) {
				trace("Failed to parse response from " + _classIdentifier(entityClassFactory.generator) + ": " + res.result);
				return;
			}
			
			// empty response
			if (! res.result.opt || ! res.result.opt.data)
				return;
				
			// got our list of entities
			if (res.result.opt.data.list)
				Entity.instantiateListWithFactory(res.result.opt.data.list, entityClassFactory, entityList);
			else
				entityList.removeAll();
				
			entityList.dispatchEvent(new EntitiesLoadedEvent(entityClassFactory.generator));
		}
		
		protected function updateComplete(evt:ResultEvent):void {
			this.load();
			this.dispatchEvent(new Event(ENTITY_UPDATED_EVENT));
		}
		
		
		//// utility
		
		// populates listObj with entities of class ctor from data returned from the server in newList
		static public function instantiateList(listObj:Object, ctor:Class, newList:ArrayCollection):void {
			var cf:ClassFactory = new ClassFactory(ctor);
			return instantiateListWithFactory(listObj, cf, newList);
		}
		static public function instantiateListWithFactory(listObj:Object, factory:ClassFactory, newList:ArrayCollection):void {
			// force into arraycollection, even if it is a single object
			var list:ArrayCollection = listObj as ArrayCollection;
			if (! list && listObj) list = new ArrayCollection([ listObj ]);

			newList.removeAll();
			
			if (! list || ! listObj)
				return;

			for each (var entityFields:Object in list) {
				var entityInstance:* = Entity.instantiateRow(entityFields, factory);
				
				if (! entityInstance) {
					trace("Error instantiating " + factory);
					continue;
				}
				
				newList.addItem(entityInstance);
			}
		}
		
		// creates a new instance or returns one if one already exists
		// unique singleton id is class / PK
		static public function getSingleton(rowObj:Object, factory:ClassFactory):* {
			var ctor:Class = factory.generator;
			
			var singletons:Object = Entity._singletons[ctor];
			if (! singletons)
				singletons = Entity._singletons[ctor] = new Object();
			
			// for now assume rowObj.id is the PK
			var pk:String = rowObj.id;
			
			var entityInstance:Entity;
			
			if (pk) {
				entityInstance = singletons[pk] as Entity;
				
				// singleton exists
				if (entityInstance) {
					debug("found singleton for " + ctor + " pk: " + pk);
				}			
			}
			
			if (! entityInstance) {
				debug("failed to find singleton for " + ctor + " pk: " + pk);
				// create new singleton
				entityInstance = factory.newInstance();
				singletons[pk] = entityInstance;
			}
			
			if (! entityInstance) {
				debug("Failed to create singleton instance for " + ctor + " and PK " + pk);
				return null;
			}
			
			entityInstance.setFields(rowObj);
			return entityInstance;
		}
		
		// returns an Entity instance using the factory with the fields in rowObj set
		public static function instantiateRow(rowObj:Object, factory:ClassFactory):Entity {
			if (USE_SINGLETONS_ONLY) {
				// get singleton for this instance
				return getSingleton(rowObj, factory);
			} else {
				// NON-singleton behavior (for individual entities, still singleton lists for .all)
				var entityInstance:Object = factory.newInstance();
				entityInstance.setFields(rowObj);
				return entityInstance as Entity;
			}
		}
		
		// server error
		protected static function gotFault(evt:FaultEvent, url:String):void {
			trace("Got error for URL " + url + ": " + evt.fault.faultDetail);
			trace("[Stack trace]\n" + evt.fault.getStackTrace());
			//dispatchEvent(evt);
		}
		
		protected function doRequest(url:String="", cb:Function=null, method:String="POST", params:Object=null):void {
			Entity.doRequest(this._class, url, cb, method, params);
		}
		
		// do REST request for rest/className/url
		protected static function doRequest(entityClass:Class, url:String="", cb:Function=null, method:String="POST", params:Object=null):void {
			var className:String = _classIdentifier(entityClass);
			
			var vars:URLVariables = new URLVariables();
			for (var f:String in params) {
				if (! params.hasOwnProperty(f)) continue;
				vars[f] = params[f];
			}
			
			var req:RESTService = new RESTService();
			req.method = method;
			req.url = "rest/" + className + url;
			req.addEventListener(ResultEvent.RESULT, cb);
			req.addEventListener(FaultEvent.FAULT, function (evt:FaultEvent):void {
				gotFault(evt, url);
			});
			
			req.send(vars);
		}
		
		protected function get _class():Class {
			return this.constructor;
		}
		
		protected function get _classIdentifier():String {
			if (Object(this.constructor).classIdentifier)
				return Object(this.constructor).classIdentifier;
			
			return Entity._classIdentifier(this._class);
		}
		
		// turn a class into a canonical unique identifier to be used internally
		protected static function _classIdentifier(c:Class):String {
			// get type name
			var typeInfo:Object = describeType(c);
			var cname:String = typeInfo.@name;
			
			// is there a "shadowed" (inherited static constant) that should
			// be used instead of an auto-generated class identifier name?
			var ti:XMLList = typeInfo..constant.(@name == 'classIdentifier');
			if (ti.length()) {
				debug("found static classid for " + cname + ": " + Object(c).classIdentifier);
				// return static const classIdentifier property
				// for some reason it needs to be cast as Object first
				return Object(c).classIdentifier;
			}
			
			// cname is now something like "com.doctorbase.entity::Appointment"
			// transform into "notification"
			var matches:Array = cname.match(/\w+$/i);
			if (! matches || ! matches.length) {
				trace("Failed to look up class identifier for " + c);
				return Object(c).toString();
			}
			
			cname = matches[0];
			
			// transform CamelCase into reasonable_names
			cname = cname.replace(/(.)([A-Z])/, "$1_$2");
			cname = cname.toLowerCase();
						
			debug("_classIdentifier(" + c + ") = " + cname);
			return cname;
		}
	}
}