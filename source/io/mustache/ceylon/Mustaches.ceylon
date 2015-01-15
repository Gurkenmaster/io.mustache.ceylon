interface Mustache {
	shared formal String render(Context data);
}
class Template(shared {Mustache*} childMustaches) satisfies Mustache {
	render(Context data) => "".join(childMustaches*.render(data));
}
class CommentMustache(shared String comment) satisfies Mustache {
	render(Context data) => "";
}
class HtmlMustache(shared String variable) satisfies Mustache {
	string => "HTML(``variable``)";
	shared actual String render(Context data) {
		if (exists str = data[variable]) {
			return escapeHtml(str.string);
		} else {
			return "";
		}
	}
}
class LiteralMustache(shared String text) satisfies Mustache {
	string => "LITERAL(``text``)";
	render(Context data) => text;
}
class SectionMustache(shared String variable, shared {Mustache*} childMustaches) satisfies Mustache {
	string => "SECTION(``variable``: ``",".join(childMustaches)``)";
	shared actual String render(Context data) {
		value item = data[variable];
		if (is [Context*] item) {
			return "".join { for (element in item) childMustaches*.render(element) };
		}
		if (is Context item) {
			return "".join(childMustaches*.render(item));
		}
		if (is ConstContext item) {
			return "".join(childMustaches*.render(data));
		}
		return "";
	}
}
class InvertedSectionMustache(shared String variable, shared {Mustache*} childMustaches) satisfies Mustache {
	string => "INVERTED_SECTION(``variable``: ``",".join(childMustaches)``)";
	shared actual String render(Context data) {
		value item = data[variable];
		if (is [Context*] item) {
			return "";
		}
		if (is Context item) {
			return "";
		}
		return "".join(childMustaches*.render(data));
	}
}
class TextMustache(shared String variable) satisfies Mustache {
	string => "TEXT(``variable``)";
	render(Context data) => data[variable]?.string else "";
}