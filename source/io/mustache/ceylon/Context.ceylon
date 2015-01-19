import ceylon.collection {
	HashMap
}
shared alias PrimitiveData => Integer|Float|Boolean|String;

shared abstract class Context(parent)
		satisfies Correspondence<String,Context> {
	shared Context? parent;
	shared formal [Context*] sequence;
	
	shared actual default
	Boolean defines(String key) => false;
	shared actual default
	Context? get(String key)
			=> (key == "" || key == ".") then this
			else parent?.get(key);
}
class MapContext(HashMap<String,Context> map, Context? parent = null) extends Context(parent) {
	string => map.string;
	sequence => [this];
	get(String key) => (key == "" || key == ".") then this
			else findDots(key)
			else parent?.get(key);
	
	Context? findDots(String key) {
		if (nonempty split = key.split('.'.equals).sequence()) {
			return map[key[... split.first.size - 1]]?.get(key[split.first.size + 1 ...]);
		}
		return map[key];
	}
}
class ListContext(shared [Context*] elements, Context? parent = null) extends Context(parent) {
	string => elements.string;
	shared Boolean empty => elements.empty;
	sequence => elements;
}
class SectionContext(shared Context intercepted, Context? parent = null) extends Context(parent) {
	sequence => [for (prox in intercepted.sequence) SectionContext(prox, parent)];
	get(String key) => intercepted[key] else parent?.get(key);
}

class ConstContext(shared PrimitiveData const, Context? parent = null) extends Context(parent) {
	string => const.string;
	sequence => const == false then [] else [this];
}
shared alias ComplexType => PrimitiveData|{<String->Anything>*}|List<Anything>;

shared Context asContext(ComplexType entries = {}, Context? parent = null) {
	if (is PrimitiveData entries) {
		return ConstContext(entries, parent);
	}
	if (is {<String->Anything>*} entries) {
		value hashmap = HashMap<String,Context>();
		value context = MapContext(hashmap, parent);
		hashmap.putAll(HashMap<String,Anything> { *entries }.mapItems((String key, Anything item) {
					assert (is ComplexType item);
					return asContext(item, context);
				}));
		return context;
	}
	if (is List<Anything> entries) {
		return ListContext(entries.map((Anything element) {
					assert (is ComplexType element);
					return asContext(element, parent);
				}).sequence(), parent);
	}
	return ConstContext(false, parent);
}
