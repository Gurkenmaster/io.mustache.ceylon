import ceylon.collection {
	HashMap
}
String sampleTemplate = """Hello {{name}}
                           You have just won {{value}} dollars!
                           {{#in_ca}}Well, {{taxed_value}} dollars, after taxes.{{/in_ca}}""";
String expectedOutput = """Hello Chris
                           You have just won 10000.0 dollars!
                           Well, 6000.0 dollars, after taxes.""";
Context sampleData = asContext(HashMap {
		"name"->"Chris",
		"value"->10000.0,
		"taxed_value" -> 10000 - (10000 * 0.4),
		"in_ca"->true
	});

"Run the module `io.mustache.ceylon`."
shared void testMustache() {
	value rendered = Template(sampleTemplate).render(sampleData);
	print("Expected:");
	print(expectedOutput);
	print("Got:");
	print(rendered);
	assert (rendered == expectedOutput);
}
