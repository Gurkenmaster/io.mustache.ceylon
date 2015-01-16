shared interface Mustache {
	shared formal String render(Context data);
	shared default Boolean standalone => true;
}
"A Mustache Template
 
 Parses the given string template and offers the method template.render(context) to render all tags"
shared class Template(shared String template) satisfies Mustache {
	shared {Mustache*} childMustaches = stripStandaloneWhitespace(groupTags(findTags(template)));
	render(Context data) => "".join(childMustaches*.render(data));
	string => "".join(childMustaches);
}
"{{! Comment}}
 This tag is simply ignored"
class CommentMustache(shared String comment) satisfies Mustache {
	render(Context data) => "";
	string => "COMMENT(``comment``)";
}
"HTML escaped variable tag: {{variable}}
 The tag will be substituted with the content of the variable"
class HtmlMustache(shared String variable) satisfies Mustache {
	string => "HTML(``variable``)";
	shared actual String render(Context data) {
		if (exists str = data[variable]) {
			return escapeHtml(str.string);
		} else {
			return "";
		}
	}
	standalone => false;
}
"This class is not a real tag. It's just a literal string"
class LiteralMustache(shared String text) satisfies Mustache {
	string => "LITERAL(``text``)";
	render(Context data) => text;
}
"Section Tag: {{#variable}}ForEachElement{{/variable}}
 
 If a list is given the section tag will be applied for every element in the list. (Non-lists are treated as 1 sized list)
 Nothing will be rendered for these inputs: false, empty list
 
 Variables inside the section are first searched in the given variable context.
 
 {{#people}}{{name}}{{/people}}
 
 Would first try to find it in 'people.name'. 
 If there is no match it tries to recursively find a value for the variable in the parent context.
 In this case it will search just for 'name'.
 "
class SectionMustache(shared String variable, shared {Mustache*} childMustaches) satisfies Mustache {
	string => "SECTION(``variable``: ``",".join(childMustaches)``)";
	shared actual String render(Context data) {
		print("start sect");
		value item = data[variable];
		if (is ConstContext item, item.const == false) {
			return "";
		}
		if (is ListContext item, item.empty) {
			return "";
		}
		return "".join {
			for (element in item?.sequence else [])
				"".join(childMustaches*.render(element))
		};
	}
}
"Inverted Section Tag: {{^variable}}List is empty{{/variable}}
 
 Functionality is the same as the Section Tag but the tag is rendered if the given variable is false or an empty list"
class InvertedSectionMustache(shared String variable, shared {Mustache*} childMustaches) satisfies Mustache {
	string => "INVERTED_SECTION(``variable``: ``",".join(childMustaches)``)";
	shared actual String render(Context data) {
		value item = data[variable];
		if (is ConstContext item, item.const == false) {
			return "".join(childMustaches*.render(data));
		}
		if (is ListContext item, item.empty) {
			return "".join(childMustaches*.render(data));
		}
		return "";
	}
}
"Normal variable Tag: {{{variable}}}
 The tag will be substituted with the content of the variable"
class TextMustache(shared String variable) satisfies Mustache {
	string => "TEXT(``variable``)";
	render(Context data) => data[variable]?.string else "";
	standalone => false;
}
