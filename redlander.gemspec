require File.expand_path('../lib/redlander/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'redlander'
  gem.authors     = ['Slava Kravchenko']
  gem.email       = ['slava.kravchenko@gmail.com']
  gem.version     = ("$Release: #{Redlander::VERSION} $" =~ /[\.\d]+/) && $&
  gem.platform    = Gem::Platform::RUBY
  gem.homepage    = "https://github.com/cordawyn/redlander"
  gem.summary     = "Advanced Ruby bindings for Redland runtime library (librdf)."
  gem.description = <<HERE
Redlander is Ruby bindings to Redland library (see http://librdf.org) written in C, which is used to manipulate RDF graphs. This is an alternative implementation of Ruby bindings (as opposed to the official bindings), aiming to be more intuitive, lightweight, high-performing and as bug-free as possible.
HERE

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # gem.add_dependency("librdf0", "~> 1.0.14")
  gem.add_dependency("xml_schema", "~> 0.1.0")
  gem.add_dependency("ffi", "~> 1.1")
  gem.add_development_dependency("rspec", "~> 2")

  gem.license = "The MIT License (MIT)"
  gem.extra_rdoc_files = ['README.rdoc', 'ChangeLog']
  gem.has_rdoc = false
end
