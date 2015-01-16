import ceylon.collection {
	HashMap
}
shared alias PrimitiveData => Integer|Float|Boolean|String;

shared abstract class Context(parent)
		satisfies Correspondence<String,Context> {
	shared Context? parent;
	shared formal [Context*] sequence;
	shared actual default Context? get(String key)
			=> key == "" then this else parent?.get(key);
}
class MapContext(HashMap<String,Context> map, Context? parent = null) extends Context(parent) {
	defines(String key) => map.defines(key);
	string => map.string;
	sequence => [this];
	get(String key) => key == "" then this else findDots(key) else parent?.get(key);
	
	Context? findDots(String key) {
		if (nonempty split = key.split('.'.equals).sequence()) {
			return map[key[... split.first.size - 1]]?.get(key[split.first.size + 1 ...]);
		}
		return map[key];
	}
}
class ListContext(shared [Context*] elements, Context? parent = null) extends Context(parent) {
	defines(String key) => false;
	string => elements.string;
	shared Boolean empty => elements.empty;
	sequence => elements;
}
class ConstContext(shared PrimitiveData const, Context? parent = null) extends Context(parent) {
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
