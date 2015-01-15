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

"Run the module `io.mustache.ceylon`."
shared void run() {
	value tags = groupTags(findTags(sampleTemplate));
	print(Template(tags).render(sampleData));
}
