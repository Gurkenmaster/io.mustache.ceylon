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
			case ('>') {
				value variable = tag[3 .. tag.size - 3].trimmed;
				value list = peek.childMustaches;
				if (is LiteralMustache precedingText = list.last, precedingText.text.trimmed == "") {
					print("Indentation: |``precedingText.text``|");
					peek.childMustaches.add(PartialMustache(variable, precedingText.text));
					peek.childMustaches.removeLast(precedingText);
				} else {
					peek.childMustaches.add(PartialMustache(variable));
				}
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

Integer? findOpeningMustache(String str)
		=> str.firstInclusion("{{");

[Character*] standaloneModifiers = ['#', '/', '!', '^', '>'];

class Parser(String rawTemplate) {
	value output = ArrayList<String>();
	variable Integer standaloneCharactersLeft = 0;
	
	shared [<String>*] findTags() {
		output.clear();
		variable Integer pos = 0;
		while (pos < rawTemplate.size) {
			value consumed = processLine(rawTemplate[pos...]);
			if (standaloneCharactersLeft > 0) {
				//print("left: ``standaloneCharactersLeft`` but consumed: ``consumed``");
				standaloneCharactersLeft -= consumed;
				//assert (standaloneCharactersLeft >= 0);
			}
			pos += consumed;
		}
		if (pos > rawTemplate.size) {
			print("Consumed too much text: `` rawTemplate.size - pos `` characters too much");
		}
		return output.sequence();
	}
	
	Integer processLine(String line) {
	variable Boolean trippleMustache = false;
		variable Boolean partial = false;
		if (exists index = findOpeningMustache(line)) {
			if (exists third = line[index + 2]) {
				if (third == '{') {
					trippleMustache = true;
				}
				if (third == '>') {
					partial = true;
				}
			}
			value closingTag = trippleMustache then "}}}" else "}}";
			if (exists closingIndex = line[index + 2 ...].firstInclusion(closingTag)) {
				trippleMustache = false;
				//standalone tag or multiple tags
				variable Boolean standalonePreceeding = false;
				variable Boolean standaloneSucceeding = false;
				if (exists preceeding = line[... index - 1].split('\n'.equals).last) {
					if (preceeding.trimmed == "") {
						standalonePreceeding = true;
					}
				}
				if (exists succeeding = line[index + 2 + closingTag.size + closingIndex ...].split('\n'.equals).first) {
					if (succeeding.trimmed == "") {
						standaloneSucceeding = true;
					}
				}
				value tag = line[index .. index + 1 + closingTag.size + closingIndex];
				if (standaloneCharactersLeft == 0,
					standalonePreceeding, standaloneSucceeding,
					exists third = tag[2], standaloneModifiers.contains(third)) {
					
					
					value beforeTag = line[... index - 1];
					value lineBreakTillTag = beforeTag.split('\n'.equals).last else beforeTag;
					value before = beforeTag[... beforeTag.size - lineBreakTillTag.size - 1];
					output.add(before);
					if(partial) {
						print("Standalone partial found. Indentation: |``lineBreakTillTag``|");
						output.add(lineBreakTillTag);
					}
					output.add(tag);
					value skipTag = line[index + 2 + closingTag.size + closingIndex ...];
					value untilLineBreak = skipTag.split('\n'.equals).first else skipTag;
					output.add(skipTag[skipTag.size - untilLineBreak.size ...]);
					return beforeTag.size + tag.size + untilLineBreak.size + 1;
				} else {
					output.add(line[... index - 1]);
					output.add(tag);
					value skipTag = line[index + 2 + closingTag.size + closingIndex ...];
					value untilLineBreak = skipTag.split('\n'.equals).first else skipTag;
					if (exists nextTag = untilLineBreak.firstInclusion("{{")) {
						//handle multiple tags
						standaloneCharactersLeft = untilLineBreak.size;
						output.add(untilLineBreak[... nextTag - 1]);
						return line[...index].size + tag.size + nextTag - 1;
					}
					output.add(skipTag[...untilLineBreak.size]);
					return line[...index].size + tag.size + untilLineBreak.size;
				}
			} else {
				//TODO error handling for unmatched {{
			}
		}
		output.add(line);
		return line.size;
	}
}
