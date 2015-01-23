import ceylon.collection {
	ArrayList
}
shared interface Mustache {
	shared formal String render(Context data);
	shared default Boolean standalone => true;
	shared default String variable => "";
}

"A Mustache Template
 Parses the given string template and offers the method template.render(context) to render all tags"
shared class Template(shared String template) satisfies Mustache {
	Boolean carriageReturnLineFeed = template.contains("\r\n");
	shared {Mustache*} childMustaches = groupTags(Parser(carriageReturnLineFeed
					then template.replace("\r\n", "\n")
					else template
		).findTags());
	render(Context data) => carriageReturnLineFeed
			then renderAll(childMustaches, data).replace("\n", "\r\n")
			else renderAll(childMustaches, data);
	
	string => "".join(childMustaches);
}

String renderAll({Mustache*} children, Context data)
		=> "".join(children*.render(data));

"{{! Comment}}
 This tag is simply ignored"
class CommentMustache(shared String comment) satisfies Mustache {
	render(Context data) => "";
	string => "COMMENT(``comment``)";
}
"HTML escaped variable tag: {{variable}}
 The tag will be substituted with the html escaped content of the variable"
class HtmlMustache(shared actual String variable) satisfies Mustache {
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
 
 The section tag can be inverted. That means it will only render if the variable points to false, an empty list.
 "
shared class SectionMustache(
	shared actual String variable,
	shared ArrayList<Mustache> childMustaches,
	shared Boolean inverted = false) satisfies Mustache {
	
	string => "`` inverted then "INVERTED" else "" ``SECTION(``variable``: ``",".join(childMustaches)``)";
	shared actual String render(Context data) {
		if (!inverted) {
			value item = data[variable];
			return "".join {
				for (element in SectionContext(item else ConstContext(false), data).sequence)
					renderAll(childMustaches, element)
			};
		} else if (data[variable]?.sequence?.empty else true) {
			return renderAll(childMustaches, data);
		}
		return "";
	}
}
"Normal variable Tag: {{{variable}}}
 The tag will be substituted with the content of the variable"
class TextMustache(shared actual String variable) satisfies Mustache {
	string => "TEXT(``variable``)";
	render(Context data) => data[variable]?.string else "";
	standalone => false;
}

"Partial Mustache: {{>hello}}
 If the Mustache is indented: every line of the partial template will be indented"
class PartialMustache(shared actual String variable, shared String indentation = "") satisfies Mustache {
	string => "PARTIAL(``variable``)";
	render(Context data) => "\n".join(Template(data["partials." + variable]?.string else "")
		.render(data).split('\n'.equals).map((String element) => indentation + element));
}
