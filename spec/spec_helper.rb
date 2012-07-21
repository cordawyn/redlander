require 'redlander'
include Redlander

# Helpful testing methods
Redlander.module_eval <<HERE
  class << self
    def root
      '#{File.expand_path(File.join(File.dirname(__FILE__), ".."))}'
    end

    def fixture_path(filename = "")
      File.join(root, "spec", "fixtures", filename)
    end
  end
HERE

RSpec.configure do |config|
end
