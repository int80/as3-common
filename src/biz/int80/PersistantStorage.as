import flash.net.SharedObject;
import flash.utils.describeType;

private var _storageVersion:String = "";

public function get sharedObject():SharedObject {
	var className:String = this.sharedObjectKey;
	if (! className) return null;
		
	var savedState:SharedObject;
	try {
		savedState = SharedObject.getLocal(className);
	} catch (error:Error) {
		trace("Unable to create SharedObject\n" + error.message);
	}
	
	return savedState;
}

public function get sharedObjectKey():String {
	// get this window's class name, use it to save location/dimensions
	var classInfo:XML = describeType(this);
	var className:String = classInfo.@name.toString();
	if (! className) {
		trace("Failed to load class name for window state");
		return null;
	}
	
	// make className alphanumeric
	className = className.replace('.', '_');
	className = className.replace('::', '_');
	
	return this.sharedObjectPrefix + className + _storageVersion;
}