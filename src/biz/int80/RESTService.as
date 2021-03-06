package biz.int80
{
	import flash.external.ExternalInterface;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.http.mxml.HTTPService;

	public class RESTService extends HTTPService
	{		
		public function RESTService()
		{
			super();
		}
		
		override public function send(parameters:Object=null):AsyncToken {
			if (! AppControllerBase.appController) {
				trace("You must instantiate an appController to use RESTService!");
				return null;
			}
			
			// add apibase to url if it isn't there already
			var apiBase:String = AppControllerBase.appController.getApiUrl();
			if (this.url.indexOf(apiBase) == -1) {
				if (this.url.indexOf('/') == 0)
					this.url = this.url.substring(1);
				this.url = apiBase + this.url;
			}
			
			if (! parameters)
				parameters = {};
			
			// this is panda, and don't you forget it buster!
			parameters['panda'] = 1;
			
			// tunnel method if it's not a GET
			if (! parameters["x-tunneled-method"]) {
				if (this.method && this.method.toUpperCase() != "GET") {
					parameters["x-tunneled-method"] = this.method;
					this.method = "POST"; // must be POST for Catalyst::Request::REST::ForBrowsers
				} else {
					this.method = "GET";
				}
			}

			return super.send(parameters);
		}
	}
}