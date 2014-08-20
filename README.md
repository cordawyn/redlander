# Redlander

Redlander is Ruby bindings to [Redland](http://librdf.org) library written in C,
which is used to manipulate RDF graphs. This is an alternative implementation
of Ruby bindings (as opposed to the official bindings), aiming to be more
intuitive, lightweight, high-performing and as bug-free as possible.


# Installing

Installing Redlander is simple:

    $ gem install redlander

Note, that you will have to install Redland runtime library (librdf) for Redlander to work.


# Usage

This README outlines most obvious use cases.
For more details please refer to [YARD documentation of Redlander](http://rubydoc.info/gems/redlander).

To start doing anything useful with Redlander, you need to initialize a model first:

    $ m = Redlander::Model.new

This creates a model where all RDF statements are stored in the memory.
Depending on the selected storage you may need to supply extra parameters
like `:user` or `:password`. Look-up the options for `Model.initialize`
for the list of available options.
Naturally, you don't need to create a model if you just want to play around
with independent statements, nodes and the like.


## RDF Statements

Now that you have created a model, you can access its RDF statements:

    $ m.statements

Most of Redlander functionality is accessable via these statements.
The API is almost identical to [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord):

    $ s = URI.parse('http://example.com/concepts#subject')
    $ p = URI.parse('http://example.com/concepts#label')
    $ o = "subject!"
    $ m.statements.create(:subject => s, :predicate => p, :object => o)

    $ m.statements.empty?  # => false

    $ st = Redlander::Statement.new(:subject => s, :predicate => p, :object => "another label")
    $ m.statements.add(st)

    $ m.statements.size    # => 2

    $ m.statements.each { |st| puts st }


### Finding and enumerating statements

    $ m.statements.find(:first, :object => "subject!")
    $ m.statements.all(:object => "another label")
    $ m.statements.each(:object => "subject!") { |statement|
        puts statement.subject
      }

Note that `m.statements.each` does not have to pull and instantiate all statements in one call,
while `m.statements.all` (and other finders) can potentially create huge arrays of data
before you can handle individual statements of it.

For those interested in laziness, `m.statements` has `lazy` method which works exactly as users of
Ruby 2+ would expect:

    $ m.statements.lazy.each {|s| puts s.object }

This, and other similar features are inherited by `m.statements` (which is actually an instance of
`Redlander::ModelProxy`) from `Enumerable` module.


### Accessing and querying subject, predicate and object

You can access the subject, predicate or object of a statement:

    $ m.statements.first.subject  # => (Redlander::Node)

Please refer to `Redlander::Node` API doc for details.

You can also use different query languages supported by [librdf](http://librdf.org/)
("SPARQL 1.0" being a default):

    $ m.query("SELECT ?s ?p ?o WHERE {}")  # => [{"s" => ..., "p" => ..., "o" => ...}, ...]

*ASK* queries return true/false, *SELECT* queries return arrays of binding hashes,
*CONSTRUCT* queries return an instance of a new memory-based model comprised from
the statements constructed by the query.
You can also supply a block to `Model#query`, which is ignored by *ASK* queries, but
yields the statements constructed by *CONSTRUCT* queries and yields the binding
hash for *SELECT* queries. Binding hash values are instances of `Redlander::Node`.

For query options and available query languages refer to `Model#query` documentation.


### Localized string literals

Localized string literals are instantiated as LocalizedString objects.
Refer to the documentation and README file in `xml_schema` gem for details
on LocalizedString.

    $ m.statments.first(:object => "bonjour".with_lang(:fr))

will return a first statement matching "bonjour@fr" literal as the object.


## Parsing Input

You can fill your model with statements by parsing some external sources like plain or streamed data.

    $ data = File.read("data.xml")
    $ m.from(data, :format => "rdfxml")

If the input is too large, you may prefer streaming it:

    $ source = URI("http://example.com/data.nt")
    $ m.from(source, :format => "ntriples")

If you want to get the data from a local file, you can use "file://" schema for your URI
or use `from_file` method with a local file name (without schema):

    $ m.from_file("../data.ttl", :format => "turtle")

Most frequently used parsing methods are aliased to save you some typing:
`from_rdfxml`, `from_ntriples`, `from_turtle`, `from_uri/from_file`.

Finally, you can filter the parsed input to prevent certain statements from getting into your model:

    $ m.from_turtle(data) do |statement|
        statement.object.value == "good"
      end

If the block returns `false`, the statement will not be added to the model.
The above example will add only statements having "literal" objects with a value of "good".


## Serializing Model

Naturally, you can convert your model into a portable syntax:

    $ m.to(:format => "rdfxml") # => RDF/XML output

There are aliases as well: `to_rdfxml`, `to_dot`, etc.

You can also dump the output directly into a local file:

    $ m.to_file("data.nt", :format => "ntriples")


## Transactions

It is possible to wrap all changes you perform on a model in a transaction,
if transactions are supported by the backend storage. If they are not supported,
all changes will be instantaneous.

    $ m.transaction { m.statements.delete_all }

There are also dedicated methods to start, commit and rollback a transaction,
should you not be able to explicitly wrap your changes in a block:

    $ m.transaction_start
    $ m.delete_all
    $ if lucky?
        m.transaction_commit
      else
        m.transaction_rollback
      end

All the above methods have their "banged" counterparts (`transaction_start!`,
`transaction_commit!` and `transaction_rollback!`) that would raise `RedlandError`
in case of an error.


# Exceptions

If anything unexpected happens, Redlander raises `RedlandError`.


# Known Issues

> Fixed in `redland-1.0.15`: [0000478](http://bugs.librdf.org/mantis/view.php?id=478)

All Enumerator-based aggregation methods of `Redlander::ModelProxy`
return invalid results - they are all copies of the last found statement.
For example,

    $ model.statements.to_a

returns statement copies, while

    $ model.statements.each { ... }

yields proper results in the block.
Update your `redland` library to 1.0.15 or newer to fix this.


SPARQL DESCRIBE is not implemented in librdf.

> See [0000135](http://bugs.librdf.org/mantis/view.php?id=135) for a temporal workaround.


# Authors and Contributors

[Slava Kravchenko](https://github.com/cordawyn)
[Anthony Bargnesi](https://github.com/abargnesi)


# Thanks

Thanks goes to [Dave Beckett](https://github.com/dajobe), the creator of Redland!
