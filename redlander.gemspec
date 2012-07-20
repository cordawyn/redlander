$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'lib/redlander/version'

Gem::Specification.new do |s|
  s.name        = 'redlander'
  s.author      = 'Slava Kravchenko'
  s.email       = 'slava.kravchenko@gmail.com'
  s.version     = ("$Release: #{Redlander::VERSION} $" =~ /[\.\d]+/) && $&
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/cordawyn/redlander"
  s.summary     = "Advanced Redland bindings."
  s.description = <<-END
    Advanced Redland bindings.
  END

  files = Dir.glob('lib/**/*.rb')
  files += Dir.glob('spec/**/*.rb')
  files += Dir.glob('tasks/**/*.rb')
  files += %w[Rakefile]
  s.files       = files
  s.test_files  = Dir.glob('spec/**/*_spec.rb')

  # s.add_dependency("redland", "~> 1.0")
  s.add_dependency("xml_schema", "~> 0.0.3")
  s.add_dependency("ffi", "~> 1.1")
  s.add_development_dependency("rspec", "~> 2")

  s.extra_rdoc_files = ['README.rdoc']
  s.has_rdoc = false
end
