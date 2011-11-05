package biz.int80
{
	import flash.events.Event;

	public class EntitiesLoadedEvent extends Event
	{
		public function EntitiesLoadedEvent(type:String, entityClass:Class, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}