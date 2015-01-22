import ceylon.test {
	test
}
import io.mustache.ceylon {
	Template,
	asContext
}
import ceylon.json {
	Object,
	Array,
	parse
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
shared void testDelimiters() {
	for (test in retrieveTestsFromSpec("delimiters")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value partials = test["partials"] else {};
		value teTemplate = Template(template);
		value context = asContext(data.chain{"partials"->partials});
		value got = teTemplate.render(context);
		if (got == expected) {
			continue;
		}
		print(context);
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
shared void testPartials() {
	for (test in retrieveTestsFromSpec("partials")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		assert (is Object partials = test["partials"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value context = asContext(data.chain(["partials"->partials]));
		value got = teTemplate.render(context);
		if (got == expected) {
			continue;
		}
		print(context);
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
shared void testInverted() {
	for (test in retrieveTestsFromSpec("inverted")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value context = asContext(data);
		value got = teTemplate.render(context);
		if (got == expected) {
			continue;
		}
		//print(context);
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
shared void testSections() {
	for (test in retrieveTestsFromSpec("sections")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value context = asContext(data);
		value got = teTemplate.render(context);
		if (got == expected) {
			continue;
		}
		//print(context);
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
shared void testInterpolationSpec() {
	for (test in retrieveTestsFromSpec("interpolation")) {
		assert (is Object test);
		assert (is Object data = test["data"]);
		value template = test.getString("template");
		value expected = test.getString("expected");
		value teTemplate = Template(template);
		value got = teTemplate.render(asContext(data));
		if (got == expected) {
			continue;
		}
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
		value got = teTemplate.render(asContext());
		print("-".repeat(30));
		if (got == expected) {
			continue;
		}
		print(got == expected then "PASSED:" else "FAIL:");
		print(test["desc"]);
		print(teTemplate);
		print("Template:\n ``template``");
		print("Expected:\n ``expected``");
		print("Got:\n ``got``");
		print("-".repeat(30));
	}
}
