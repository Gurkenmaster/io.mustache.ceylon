Mustache
=========
This is an implementation of the logicless template language called [Mustache](http://mustache.github.io/) written in Ceylon.

[The Mustache specification can be found here](https://github.com/mustache/spec)

The optional lambda module is currently not implented.

Partials have to be provided with the context object with the key "partials".

Usage
-----

The Template class and the asContext() function is all you need to get started.

```ceylon
import io.mustache.ceylon {
  Template,
  asContext
}

shared void run() {
  print(Template("{{var}}").render(asContext({"var"->"Hello World"});
}
```