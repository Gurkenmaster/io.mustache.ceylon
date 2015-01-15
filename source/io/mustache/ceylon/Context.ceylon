import ceylon.collection {
	HashMap
}
shared abstract class Context(parent) of MapContext | ConstContext
		satisfies Correspondence<String,Context> {
	shared Context? parent;
}
class MapContext(HashMap<String,Context> map, Context? parent = null) extends Context(parent) {
	get(String key) => map[key] else parent?.get(key);
	defines(String key) => map.defines(key);
	string => "";
}
class ConstContext(shared PrimitiveData const, Context? parent = null) extends Context(parent) {
	shared actual Context? get(String key) {
		return parent?.get(key);
	}
	defines(String key) => false;
	string => const.string;
}
