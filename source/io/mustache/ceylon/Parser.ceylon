import ceylon.collection {
	HashMap,
	ArrayList
}
shared [Mustache*] groupTags([String*] tags) {
	value topLevelSection = SectionMustache("", ArrayList<Mustache>());
	value sectionStack = ArrayList<SectionMustache> { topLevelSection };
	SectionMustache peek {
		"Stack empty"
		assert (exists last = sectionStack.last);
		return last;
	}
	SectionMustache pop() {
		sectionStack.remove(peek);
		return peek;
	}
	void push(SectionMustache must) {
		sectionStack.add(must);
	}
	if (tags.empty) {
		return [];
	}
	for (i->tag in tags.indexed) {
		if (tag.startsWith("{{"), tag.endsWith("}}")) {
			switch (tag[2])
			case ('{') {
				value variable = tag[3 .. tag.size - 4].trimmed;
				peek.childMustaches.add(TextMustache(variable));
			}
			case ('#') {
				value variable = tag[3 .. tag.size - 3].trimmed;
				value sectionMustache = SectionMustache(variable, ArrayList<Mustache>());
				peek.childMustaches.add(sectionMustache);
				push(sectionMustache);
			}
			case ('/') {
				value variable = tag[3 .. tag.size - 3].trimmed;
				if (variable == peek.variable) {
					pop();
				}
			}
			case ('&') {
				value variable = tag[3 .. tag.size - 3].trimmed;
				peek.childMustaches.add(TextMustache(variable));
			}
			case ('!') {
				value comment = tag[3 .. tag.size - 3];
				peek.childMustaches.add(CommentMustache(comment));
			}
			case ('^') {
				value variable = tag[3 .. tag.size - 3].trimmed;
				value sectionMustache = SectionMustache(variable, ArrayList<Mustache>(), true);
				peek.childMustaches.add(sectionMustache);
				push(sectionMustache);
			}
			else {
				value variable = tag[2 .. tag.size - 3].trimmed;
				peek.childMustaches.add(HtmlMustache(variable));
			}
		} else {
			peek.childMustaches.add(LiteralMustache(tag));
		}
	}
	assert (exists first = sectionStack.first);
	return first.childMustaches.sequence();
}
shared [Mustache*] stripStandaloneWhitespace([Mustache*] mustaches) {
	value list = ArrayList<Mustache>();
	list.addAll(mustaches);
	for (i->element in mustaches.indexed) {
		if (is SectionMustache element) {
			value newMustache = SectionMustache(element.variable, ArrayList<Mustache> { *stripStandaloneWhitespace(element.childMustaches.sequence()) });
			list.set(i, newMustache);
		}
		if (!is LiteralMustache element, element.standalone) {
			if (is LiteralMustache previous = list[i - 1]) {
				value split = previous.text.split('\n'.equals).last;
				if (exists split, split.trimmed == "") {
					list.set(i - 1, LiteralMustache(previous.text[... previous.text.size - split.size - 1]));
				} else {
					continue;
				}
			}
			if (is LiteralMustache next = mustaches[i + 1]) {
				value split = next.text.split('\n'.equals).first;
				if (exists split, split.trimmed == "") {
					list.set(i + 1, (LiteralMustache(next.text[split.size + 1 ...])));
				}
			}
		}
	}
	return list.sequence();
}
Map<Character,String> htmlEscapeCharacters = HashMap {
	'&'->"&amp;",
	'<'->"&lt;",
	'>'->"&gt;",
	'"'->"&quot;"
};
String escapeHtml(String html)
		=> String(expand(html.map((char) => htmlEscapeCharacters[char] else char.string)));

shared [String*] findTags(String template) {
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
	if (start == -1) {
		list.add(builder.string);
	}
	return list.sequence();
}
