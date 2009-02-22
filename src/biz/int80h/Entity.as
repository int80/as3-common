package biz.int80h
{
	import flash.events.EventDispatcher;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	
	[Bindable] dynamic public class Entity extends EventDispatcher
	{
		private static var _entities:Object = {};
		private var fields:Object;
		
		public function Entity(fields:Object=null)
		{
			if (! fields) fields = {};
			this.fields = fields;
		}
		
		
		// override in subclass
	
		public virtual function get className():String { return "noclass" };
		
		
		//// fields
		
		[Bindable(event="FieldsChanged")] public function field(fieldName:String):* {
			if (! this.fields.hasOwnProperty(fieldName))
				return undefined;
			 
			return this.fields[fieldName];
		}
		
		public function setField(fieldName:String, value:Object):void {
			this.fields[fieldName] = value;
			this[fieldName] = value;
			this.fieldsChanged();
		}
		
		public function setFields(fields:Object):void {
			if (! fields) fields = {};
			this.fields = fields;
			
			for (var field:String in fields) {
				this[field] = fields[field];
			}
			
			//this.fieldsChanged();
		}
		
		protected function fieldsChanged():void {
			this.dispatchEvent(new Event("FieldsChanged"));
		}


		// identifier
		
		public function get id():Number {
			return this.field("id");
		}
		
		public function set id(id:Number):void {
			this.setField("id", id);
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
		
		[Bindable(event="EntitiesUpdated")] public function loadAll():void {
			var self:Entity = this;
			doRequest("", function (evt:ResultEvent):void { self.loadEntitiesComplete(evt) }, "GET");
		}
		
		public function update(fields:Object):void {
			var self:Entity = this;
			doRequest("/" + this.id, function (evt:ResultEvent):void { self.updateComplete(evt) }, "PUT", fields);
		}
		
		
		//// events
		
		protected function loadComplete(res:ResultEvent):void {
			this.setFields(res.result.opt.data.list);
		}
		
		protected function loadEntitiesComplete(res:ResultEvent):void {
			var entityList:ArrayCollection = _entities[this.className];
			if (! entityList)
				entityList = _entities[this.className] = new ArrayCollection();
			else
				entityList.removeAll();
			
			var list:ArrayCollection = res.result.opt.data.list as ArrayCollection;
			if (! list) list = new ArrayCollection([ res.result.opt.data.list ]);
				
			for each (var entityFields:ObjectProxy in list) {
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
		
		protected function doRequest(url:String="", cb:Function=null, method:String="POST", params:Object=null):void {
			var vars:URLVariables = new URLVariables();
			for (var f:String in params) {
				if (! params.hasOwnProperty(f)) continue;
				vars[f] = params[f];
			}
			
			if (! vars['content-type'])
				vars['content-type'] = 'text/xml';
			
			vars['x-tunneled-method'] = method;
						
			var req:HTTPService = new HTTPService();
			req.method = method == "GET" ? "GET" : "POST";
			req.url = AppControllerBase.getApiUrl("rest/" + this.className + url);
			req.addEventListener(ResultEvent.RESULT, cb);
			
			req.headers = { // I wish this worked with GETs
				'Accept': 'application/xml'
			}; 

			req.send(vars);
		}
	}
}