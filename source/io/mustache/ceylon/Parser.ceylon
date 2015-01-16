import ceylon.collection {
	HashMap,
	ArrayList
}
shared [Mustache*] groupTags([String*] tags, String? closingTag = null, Boolean invertedSection = false) {
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
	if(start == -1) {
		list.add(builder.string);
	}
	return list.sequence();
}
