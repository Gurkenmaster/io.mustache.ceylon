import ceylon.test {
	test
}
import ceylon.json {
	parse,
	Array,
	Object
}
import io.mustache.ceylon {
	Context,
	asContext,
	Template,
	findTags,
	groupTags
}
String sampleTemplate = """Hello {{name}}
                           You have just won {{value}} dollars!
                           {{#in_ca}}Well, {{taxed_value}} dollars, after taxes.{{/in_ca}}
                           
                           * {{name}}
                           * {{age}}
                           * {{company}}
                           * {{{company}}}
                           
                           Shown.
                           {{#person}}Never shown!{{/person}}""";
String expectedOutput = """Hello Chris
                           You have just won 10000.0 dollars!
                           Well, 6000.0 dollars, after taxes.
                           
                           * Chris
                           * 
                           * &lt;b&gt;GitHub&lt;/b&gt;
                           * <b>GitHub</b>
                           
                           Shown.
                           """;
Context sampleData = asContext {
	"name"->"Chris",
	"value"->10000.0,
	"taxed_value" -> 10000 - (10000 * 0.4),
	"in_ca"->true,
	"name"->"Chris",
	"company"->"<b>GitHub</b>",
	"person"->false,
	"repo"->{
		"name"->"resque",
		"name"->"hub",
		"name"->"rip"
	}
};

void testMustache() {
	value rendered = Template(sampleTemplate).render(sampleData);
	print("Expected:");
	print(expectedOutput);
	print("Got:");
	print(rendered);
	assert (rendered == expectedOutput);
	print("Passed");
}

test
void testParse() {
	value tags = findTags("12345 {{! Comment Block! }} 67890");
	print(tags);
	print(groupTags(tags));
}

test
void testCommentSpec() {
	value comments = `module test.mustache.ceylon`.resourceByPath("specs/comments.json");
	assert (exists comments);
	assert (is Object parsedJson = parse(comments.textContent()));
	print(parsedJson["overview"]);
	print("");
	assert (is Array tests = parsedJson["tests"]);
	for (test in tests) {
		assert (is Object test);
		value data = test["data"];
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value got = teTemplate.render(asContext { });
		
		print(got == expected then "PASSED:" else "FAIL:");
		
		print("-".repeat(30));
		print(test["desc"]);
		print(teTemplate);
		print("Data:\n`` data else "<nothing>" ``");
		print("Template:\n ``template``");
		print("Expected:\n ``expected``");
		print("Got:\n ``got``");
		print("-".repeat(30));
	}
}
