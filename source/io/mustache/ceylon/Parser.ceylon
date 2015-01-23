import ceylon.collection {
	HashMap,
	ArrayList
}
shared [Mustache*] groupTags([String*] tags) {
	value topLevelSection = SectionMustache("", ArrayList<Mustache>());
	value sectionStack = ArrayList<SectionMustache> { topLevelSection };
	SectionMustache peek {
		"The Stack is empty"
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
Map<Character,String> htmlEscapeCharacters = HashMap {
	'&'->"&amp;",
	'<'->"&lt;",
	'>'->"&gt;",
	'"'->"&quot;"
};
String escapeHtml(String html)
		=> String(expand(html.map((char) => htmlEscapeCharacters[char] else char.string)));

[Character*] standaloneModifiers = ['#', '/', '!', '^', '>', '='];

class Parser(String rawTemplate) {
	
	"Default opening delimiter"
	value dOpen = "{{";
	"Default closing delimiter"
	value dClose = "}}";
	
	value output = ArrayList<String>();
	variable Integer standaloneCharactersLeft = 0;
	variable String openingDelimiter = dOpen;
	variable String closingDelimiter = dClose;
	shared [String*] findTags() {
		output.clear();
		variable Integer pos = 0;
		while (pos < rawTemplate.size) {
			value consumed = processLine(rawTemplate[pos...]);
			if (standaloneCharactersLeft > 0) {
				standaloneCharactersLeft -= consumed;
			}
			pos += consumed;
		}
		return output.sequence();
	}
	
	void checkDelimiter(String mustacheyTag, String tag) {
		if (exists third = mustacheyTag[2],
			third == '=',
			exists thirdToLast = mustacheyTag[tag.size - 3],
			thirdToLast == '=') {
			value openCloseDelimiters = mustacheyTag[3 .. tag.size - 4].trimmed.split();
			openingDelimiter = openCloseDelimiters.first else dOpen;
			closingDelimiter = openCloseDelimiters.last else dClose;
		}
	}
	
	"Replaces custom delimiters with the default mustached delimiters {{ and }}"
	String mustachefy(String tag)
			=> tag.replaceFirst(openingDelimiter, dOpen).replaceLast(closingDelimiter, dClose);
	
	Integer processLine(String line) {
		if (exists index = line.firstInclusion(openingDelimiter)) {
			value tthird = line[index + openingDelimiter.size];
			Boolean trippleMustache = tthird?.equals('{') else false;
			Boolean partial = tthird?.equals('>') else false;
			value closingTag = trippleMustache then "}" + closingDelimiter else closingDelimiter;
			if (exists closingIndex = line[index + closingTag.size ...].firstInclusion(closingTag)) {
				//standalone tag or multiple tags
				value offset = closingTag.size - 1;
				value tagEndIndex = index + offset + closingTag.size + closingIndex; //custom delimiter messes this line up
				
				value beforeTag = line[... index - 1];
				value afterTag = line[tagEndIndex + 1 ...];
				Boolean standalonePreceeding = beforeTag.split('\n'.equals).last?.trimmed?.equals("") else false;
				Boolean standaloneSucceeding = afterTag.split('\n'.equals).first?.trimmed?.equals("") else false;
				value tag = line[index..tagEndIndex];
				value mustacheyTag = mustachefy(tag);
				
				checkDelimiter(mustacheyTag, tag);
				
				value untilLineBreak = afterTag.split('\n'.equals).first else afterTag;
				if (standaloneCharactersLeft == 0,
					standalonePreceeding, standaloneSucceeding,
					exists third = mustacheyTag[2], standaloneModifiers.contains(third)) {
					
					value lineBreakTillTag = beforeTag.split('\n'.equals).last else beforeTag;
					output.add(beforeTag[... beforeTag.size - lineBreakTillTag.size - 1]);
					if (partial) {
						output.add(lineBreakTillTag);
					}
					output.add(mustacheyTag);
					output.add(afterTag[afterTag.size - untilLineBreak.size ...]);
					return beforeTag.size + tag.size + untilLineBreak.size + 1;
				}
				//not standalone, possibly multiple tags
				output.add(beforeTag);
				output.add(mustacheyTag);
				if (exists nextTag = untilLineBreak.firstInclusion(openingDelimiter)) {
					//handle multiple tags
					standaloneCharactersLeft = untilLineBreak.size;
					output.add(untilLineBreak[... nextTag - 1]);
					return line[...index].size + tag.size + nextTag - 1;
				}
				output.add(afterTag[...untilLineBreak.size]);
				return line[...index].size + tag.size + untilLineBreak.size;
			} else {
				//TODO error handling for unmatched {{
			}
		}
		output.add(line);
		return line.size;
	}
}
