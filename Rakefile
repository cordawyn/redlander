require 'spec/rake/spectask'
require 'rake/gempackagetask'
require 'lib/redlander/version'

Spec::Rake::SpecTask.new

spec = Gem::Specification.new do |s|
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

  files = Dir.glob('lib/redlander/**/*')
  files += Dir.glob('spec/**/*')
  files += Dir.glob('tasks/**/*')
  files += %w[ext/extconf.rb ext/redland-pre.i ext/redland-types.i ext/redland_wrap.c ext/README]
  files += %w[Rakefile lib/redlander.rb]
  s.files       = files
  s.test_files  = Dir.glob('spec/**/*')

  s.extensions  = ["ext/extconf.rb"]

  # s.extra_rdoc_files = ['README.rdoc', 'History.txt', 'LICENSE', 'Manifest.txt']
  s.has_rdoc = false
end

Rake::GemPackageTask.new(spec) do |pkg|
  # pkg.need_tar = true
end
