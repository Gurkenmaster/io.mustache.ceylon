import ceylon.collection {
	HashMap
}
shared alias PrimitiveData => Integer|Float|Boolean|String;

shared abstract class Context(parent)
		satisfies Correspondence<String,Context> {
	shared Context? parent;
	shared formal [Context*] sequence;
}
class MapContext(HashMap<String,Context> map, Context? parent = null) extends Context(parent) {
	get(String key) => map[key] else parent?.get(key);
	defines(String key) => map.defines(key);
	string => "";
	sequence => [this];
}
class ListContext(shared [Context*] elements, Context? parent = null) extends Context(parent) {
	shared actual Context? get(String key) {
		return parent?.get(key);
	}
	defines(String key) => false;
	string => elements.string;
	shared Boolean empty => elements.empty;
	sequence => elements;
}
class ConstContext(shared PrimitiveData const, Context? parent = null) extends Context(parent) {
	shared actual Context? get(String key) {
		return parent?.get(key);
	}
	defines(String key) => false;
	string => const.string;
	sequence => [this];
}

shared Context asContext({<String->Anything>*} entries, Context? parent = null) {
	value hashmap = HashMap<String,Context>();
	value context = MapContext(hashmap);
	hashmap.putAll(HashMap<String,Anything> { *entries }.mapItems((String key, Anything item) {
				if (is PrimitiveData item) {
					return ConstContext(item, context);
				}
				if (is Map<String,Anything> item) {
					return asContext(item, context);
				}
				return ConstContext(false);
			}));
	return context;
}
