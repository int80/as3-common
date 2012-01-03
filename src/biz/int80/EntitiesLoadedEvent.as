package biz.int80
{
	import flash.events.Event;

	public class EntitiesLoadedEvent extends Event
	{
		public static const ENTITIES_LOADED_EVENT:String = "EntitiesLoaded";

		public function EntitiesLoadedEvent(entityClass:Class, bubbles:Boolean=false, cancelable:Boolean=false)
		{	
			super(ENTITIES_LOADED_EVENT, bubbles, cancelable);
		}
		
	}
}