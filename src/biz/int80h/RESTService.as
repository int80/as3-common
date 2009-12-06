package biz.int80h
{
	import mx.rpc.http.mxml.HTTPService;
	import mx.rpc.AsyncToken;

	public class RESTService extends HTTPService
	{		
		public var apiUrl:String;
		
		public function RESTService(rootURL:String=null, destination:String=null)
		{
			super(rootURL, destination);
		}
		
		override public function send(parameters:Object=null):AsyncToken {
			if (this.method)
				this.headers["x-tunneled-method"] = this.method;
			
			return super.send(parameters);
		}
		
		override public function get url():String {
			if (! apiUrl)
				return super.url;
			
			return AppControllerBase.appController.getApiUrl(apiUrl);
		}
	}
}