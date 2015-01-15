import ceylon.collection {
	ArrayList,
	HashMap
}
shared alias PrimitiveData => Integer|Float|Boolean|String;

String sampleTemplate = """Hello {{name}}
                           You have just won {{value}} dollars!
                           {{#in_ca}}Well, {{taxed_value}} dollars, after taxes. {{/in_ca}}""";
Context sampleData = asContext(HashMap {
		"name"->"Chris",
		"value"->10000,
		"taxed_value" -> 10000 - (10000 * 0.4),
		"in_ca"->true
	});

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

"Run the module `io.mustache.ceylon`."
shared void run() {
	value tags = groupTags(findTags(sampleTemplate));
	print(Template(tags).render(sampleData));
}

[Mustache*] groupTags([String*] tags, String? closingTag = null, Boolean invertedSection = false) {
	value mustaches = ArrayList<Mustache>();
	if (tags.empty) {
		return [];
	}
	for (i->tag in tags.indexed) {
		if (tag.startsWith("{{"), tag.endsWith("}}")) {
			switch (tag[2])
			case ('{') {
				value variable = tag[3 .. tag.size - 4];
				mustaches.add(TextMustache(variable));
			}
			case ('#') {
				value variable = tag[3 .. tag.size - 3];
				value submustaches = groupTags(tags.skip(i + 1).sequence(), variable.string);
				return mustaches.sequence().append(submustaches);
			}
			case ('/') {
				value variable = tag[3 .. tag.size - 3];
				if (exists closingTag, variable == closingTag) {
					value submustaches = groupTags(tags.skip(i + 1).sequence());
					if (invertedSection) {
						return [InvertedSectionMustache(closingTag, mustaches)].append(submustaches);
					} else {
						return [SectionMustache(closingTag, mustaches)].append(submustaches);
					}
				}
			}
			case ('&') {}
			case ('!') {
				value comment = tag[3 .. tag.size - 3];
				mustaches.add(CommentMustache(comment));
			}
			case ('^') {
				value variable = tag[3 .. tag.size - 3];
				value submustaches = groupTags(tags.skip(i + 1).sequence(), variable.string, true);
				return mustaches.sequence().append(submustaches);
			}
			else {
				value variable = tag[2 .. tag.size - 3];
				mustaches.add(HtmlMustache(variable));
			}
		} else {
			mustaches.add(LiteralMustache(tag));
		}
	}
	return mustaches.sequence();
}

Map<Character,String> htmlEscapeCharacters = HashMap {
	'&'->"&amp;",
	'<'->"&lt;",
	'>'->"&gt;",
	'"'->"&quot;",
	'\''->"&#39;",
	'/'->"&#x2F;"
};
String escapeHtml(String html)
		=> String(expand(html.map((char) => htmlEscapeCharacters[char] else char.string)));

[String*] findTags(String template) {
	value list = ArrayList<String>();
	variable Integer braces = 0;
	variable Integer start = -1;
	variable StringBuilder builder = StringBuilder();
	for (i->ch in template.indexed) {
		switch (ch)
		case ('{') {
			braces++;
			if (start == -1) {
				list.add(builder.string);
				builder = StringBuilder();
				start = i;
			}
		}
		case ('}') {
			braces--;
			if (braces == 0) {
				list.add(template[start..i]);
				start = -1;
			}
		}
		else {
			if (start == -1) {
				builder.append(ch.string);
			}
		}
	}
	return list.sequence();
}
