$:.unshift(File.join(File.dirname(__FILE__), "..")) unless
  $:.include?(File.join(File.dirname(__FILE__), "..")) || $:.include?(File.expand_path(File.join(File.dirname(__FILE__), "..")))

require 'spec/autorun'

require 'lib/redlander'
include Redlander

Spec::Runner.configure do |config|
end
