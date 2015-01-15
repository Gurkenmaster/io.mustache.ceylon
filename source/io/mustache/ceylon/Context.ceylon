import ceylon.collection {
	HashMap
}
shared abstract class Context(parent)
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

Context asContext(Map<String,Anything> map, Context? parent = null) {
	value hashmap = HashMap<String,Context>();
	value context = MapContext(hashmap);
	hashmap.putAll(map.mapItems((String key, Anything item) {
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
