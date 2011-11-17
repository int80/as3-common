package biz.int80
{
	import flash.net.SharedObject;

	public interface IPersistantStorage
	{
		function get sharedObjectPrefix():String;
		function get sharedObjectKey():String;
	}
}