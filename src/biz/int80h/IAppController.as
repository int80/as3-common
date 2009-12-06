package biz.int80h
{
	import flash.net.URLVariables;
	
	public interface IAppController
	{
		function getApiUrl(path:String, args:URLVariables=null):String;
	}
}