import ceylon.test {
	test
}
import io.mustache.ceylon {
	Context,
	asContext,
	Template
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
Context sampleData = asContext{
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

"Run the module `io.mustache.ceylon`."
test
void testMustache() {
	value rendered = Template(sampleTemplate).render(sampleData);
	print("Expected:");
	print(expectedOutput);
	print("Got:");
	print(rendered);
	assert (rendered == expectedOutput);
	print("Passed");
}
