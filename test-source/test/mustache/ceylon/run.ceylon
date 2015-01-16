import ceylon.test {
	test
}
import io.mustache.ceylon {
	findTags,
	groupTags,
	stripStandaloneWhitespace,
	Template,
	asContext
}
import ceylon.json {
	Object,
	Array,
	parse
}

test
void testParse() {
	value tags = findTags("12345 {{! Comment Block! }} 67890");
	print(tags);
	print(groupTags(tags));
}
String string = "12345
                    {{! Comment Block! }}   
                 67890";
test
shared void testStripWhitespace() {
	value tags = stripStandaloneWhitespace(groupTags(findTags(string)));
	print(tags);
}

Array retrieveTestsFromSpec(String filename) {
	value comments = `module test.mustache.ceylon`.resourceByPath("specs/" + filename + ".json");
	assert (exists comments);
	assert (is Object parsedJson = parse(comments.textContent()));
	print(parsedJson["overview"]);
	print("");
	assert (is Array tests = parsedJson["tests"]);
	return tests;
}

test
shared void testSpec() {
	for (test in retrieveTestsFromSpec("interpolation")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value got = teTemplate.render(asContext(data.sequence()));
		
		print(got == expected then "PASSED:" else "FAIL:");
		print("-".repeat(30));
		print(test["desc"]);
		print(teTemplate);
		print("Template:\n ``template``");
		print("Expected:\n ``expected``");
		print("Got:\n ``got``");
		print("-".repeat(30));
	}
}
test
shared void testCommentSpec() {
	for (test in retrieveTestsFromSpec("comments")) {
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
		print("Template:\n ``template``");
		print("-".repeat(30));
	}
}
