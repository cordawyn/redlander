require File.expand_path('../lib/redlander/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'redlander'
  gem.authors     = ['Slava Kravchenko']
  gem.email       = ['slava.kravchenko@gmail.com']
  gem.version     = ("$Release: #{Redlander::VERSION} $" =~ /[\.\d]+/) && $&
  gem.platform    = Gem::Platform::RUBY
  gem.homepage    = "https://github.com/cordawyn/redlander"
  gem.summary     = "Advanced Redland bindings."
  gem.description = "Advanced Redland bindings."

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # gem.add_dependency("librdf0", "~> 1.0.14")
  gem.add_dependency("xml_schema", "~> 0.0.3")
  gem.add_dependency("ffi", "~> 1.1")
  gem.add_development_dependency("rspec", "~> 2")

  gem.licenses = ["LICENSE"]
  gem.extra_rdoc_files = ['README.rdoc']
  gem.has_rdoc = false
end
